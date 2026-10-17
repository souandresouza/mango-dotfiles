#!/usr/bin/env python3
"""loop_detect.py - acha o trecho unico de um video que se repete em loop.

Videos de live-wallpaper / clip costumam vir como [trecho unico][loop][loop]...
Aqui descobrimos o periodo de repeticao, isolamos a janela que NAO se
repete e (opcionalmente) cortamos so ela.

So precisa de ffmpeg/ffprobe + numpy. Sem OpenCV, sem GPU.

Como o periodo e decidido
-------------------------
Amostramos o video em quadros cinza reduzidos (64x64) e montamos a matriz de
distancia media absoluta entre cada par de quadros. Para um deslocamento p
observamos os deslocamentos ao longo da diagonal (i, i+p):

  - se o video repete, ali os quadros sao praticamente iguais;
  - procuramos o p cujo melhor "trecho" (corrida de diagonais iguais) tenha
    comprimento >= p, ou seja, um bloco inteiro repetindo em seguida;
  - entre os candidatos fica o de menor distancia relativa dentro do trecho.

Esse ultimo criterio e o que separa um loop de verdade de movimento suave:
zoom lento casa consigo mesmo em qualquer lag minimo, mas com distancia bem
maior que a de uma repeticao exata.

Contrato de saida (consumido por loopbatch e loopgui):
  --json  imprime  @@JSON@@ seguido de UMA linha de JSON em stdout;
          todo o relatorio humano vai para stderr.
  exit 0  achou loop, ou o arquivo ja e um loop continuo
  exit 1  nao achou nem um nem outro (o JSON ainda sai, com loop=false)
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys

try:
    import numpy as np
except ImportError:  # pragma: no cover
    sys.stderr.write("loopdetect: numpy ausente. Crie o venv:\n"
                     "  python3 -m venv ~/.local/share/loopdetect/venv\n"
                     "  ~/.local/share/loopdetect/venv/bin/pip install numpy\n")
    raise SystemExit(2)

# --- ajustes de precisao -------------------------------------------------
SAMPLE_FPS = 4.0      # quadros por segundo amostrados
GRAY = 64             # lado do quadro reduzido (GRAY*GRAY por amostra)
MATCH_TOL = 3.0       # distancia media absoluta (0..255) para chamar de igual
MIN_PERIOD = 0.5      # abaixo disso nao ha loop, ha movimento suave
MAX_SAMPLES = 6000    # teto de amostras (a matriz é n*n)
SEAM_MIN_DB = 24.0    # acima disso a emenda fecha: já é loop contínuo
MAX_QUALITY = 0.05    # repetição real fica em 1-2%; acima disso é conteúdo parecido
STATIC_LIMIT = 2.0    # salto < 2/255 entre quadros => cena praticamente parada

AUDIO_SR = 8000       # taxa do PCM para a assinatura de audio
AUDIO_WIN = 1024      # 0,128 s por assinatura
AUDIO_BANDS = 16      # bandas do espectro
AUDIO_TOL_FRAC = 0.25  # tolerância de áudio, relativa à escala da assinatura


class Abort(Exception):
    """Sai com código, sem stack trace (código != 1 é um caso conhecido)."""

    def __init__(self, msg, code):
        super().__init__(msg)
        self.code = code


def need(tool):
    if not shutil.which(tool):
        raise Abort("'%s' não encontrado no PATH" % tool, 2)


def fmt_time(t):
    """0:07 / 1:23 / 0:03:41 - mesmo formato do human() do loopbatch."""
    t = max(0.0, float(t))
    m, s = divmod(int(round(t)), 60)
    h, m = divmod(m, 60)
    return "%d:%02d:%02d" % (h, m, s) if h else "%d:%02d" % (m, s)


def report(msgs):
    for m in msgs:
        sys.stderr.write(m + "\n")
    sys.stderr.flush()


# --- ffprobe ------------------------------------------------------------

def probe(path):
    """(duração em segundos, tem vídeo, tem áudio)."""
    need("ffprobe")
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries",
         "format=duration:stream=codec_type", "-of", "json", path],
        capture_output=True, text=True)
    if r.returncode != 0:
        raise Abort("ffprobe falhou em %s: %s" % (path, r.stderr.strip()[:200]), 1)
    try:
        data = json.loads(r.stdout)
    except json.JSONDecodeError:
        raise Abort("ffprobe devolveu lixo em %s" % path, 1)

    kinds = {s.get("codec_type") for s in data.get("streams", [])}
    try:
        dur = float(data.get("format", {}).get("duration"))
    except (TypeError, ValueError):
        raise Abort("não consegui ler a duração de %s" % path, 1)
    return dur, "video" in kinds, "audio" in kinds


# --- amostragem ---------------------------------------------------------

def _unframe(raw, per):
    n = len(raw) // per
    if n < 4:
        raise Abort("vídeo curto demais para amostrar (%d quadros)" % n, 1)
    return np.frombuffer(raw[:n * per], dtype=np.uint8).reshape(n, per).astype(np.float32)


def sample_video(path, max_scene_change=None):
    """(quadros n x GRAY*GRAY em float32, tempos, maior salto entre quadros).

    O maior salto serve ao --max-scene-change, que descarta imagem parada.
    """
    need("ffmpeg")
    r = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-an", "-sn",
         "-vf", "fps=%g,scale=%d:%d:flags=area,format=gray"
                % (SAMPLE_FPS, GRAY, GRAY),
         "-f", "rawvideo", "-"], capture_output=True)
    if r.returncode != 0 or not r.stdout:
        raise Abort("ffmpeg não extraiu quadros de %s: %s"
                    % (path, r.stderr.decode("utf-8", "replace").strip()[:200]), 1)

    frames = _unframe(r.stdout, GRAY * GRAY)
    deltas = (np.abs(np.diff(frames, axis=0)).mean(axis=1)
              if len(frames) > 1 else np.zeros(1))
    scene_change = float(deltas.max())
    if max_scene_change is not None and scene_change < max_scene_change:
        raise Abort("cena estática (máx Δ%.2f < %.2f): nada a extrair"
                    % (scene_change, max_scene_change), 3)
    times = np.arange(len(frames), dtype=np.float64) / SAMPLE_FPS
    return frames, times, scene_change


def sample_audio(path):
    """(assinatura n x AUDIO_BANDS normalizada, tempos em segundos)."""
    need("ffmpeg")
    r = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-vn", "-sn",
         "-ac", "1", "-ar", str(AUDIO_SR), "-f", "s16le", "-"], capture_output=True)
    if r.returncode != 0 or not r.stdout:
        raise Abort("ffmpeg não extraiu áudio de %s" % path, 1)

    pcm = np.frombuffer(r.stdout, dtype=np.int16).astype(np.float32) / 32768.0
    n = len(pcm) // AUDIO_WIN
    if n < 4:
        raise Abort("áudio curto demais para amostrar", 1)
    blocks = pcm[:n * AUDIO_WIN].reshape(n, AUDIO_WIN) * np.hanning(AUDIO_WIN)

    spec = np.abs(np.fft.rfft(blocks, axis=1))
    edges = np.linspace(0, spec.shape[1], AUDIO_BANDS + 1).astype(int)
    sig = np.stack([np.log1p(spec[:, edges[i]:edges[i + 1] + 1].mean(axis=1))
                    for i in range(AUDIO_BANDS)], axis=1)
    sig -= sig.mean(axis=1, keepdims=True)   # só o desenho relativo importa
    times = np.arange(n, dtype=np.float64) * AUDIO_WIN / AUDIO_SR
    return sig, times


def distance_matrix(sig):
    """RMS por pixel entre cada par de amostras.

    Decomposição de ||a-b||² = |a|² + |b|² - 2·a·b, então isto é uma
    multiplicação de matrizes em BLAS em vez de um array (n, n, d) de 100 GB.
    O resultado fica na mesma escala 0..255 da diferença média.
    """
    s = sig.astype(np.float32)
    d = s.shape[1]
    sq = (s * s).sum(axis=1)
    msd = np.maximum(sq[:, None] + sq[None, :] - 2.0 * (s @ s.T), 0.0) / d
    return np.sqrt(msd, out=msd)


def thin(sig, times):
    """Reduz a sequência para caber na memória da matriz n*n."""
    n = len(sig)
    if n <= MAX_SAMPLES:
        return sig, times, 1
    stride = (n + MAX_SAMPLES - 1) // MAX_SAMPLES
    return sig[::stride], times[::stride], stride


# --- detecção ------------------------------------------------------------

def longest_run(flags):
    """(início, comprimento) da maior corrida de True em flags."""
    f = np.asarray(flags, dtype=bool)
    if not f.any():
        return 0, 0
    # transições 0->1 marcam o começo de cada corrida, 1->0 o fim
    edges = np.diff(np.concatenate(([0], f.view(np.int8), [0])))
    starts = np.flatnonzero(edges == 1)
    lengths = np.flatnonzero(edges == -1) - starts
    k = int(lengths.argmax())
    return int(starts[k]), int(lengths[k])


def find_period(dist, tol, min_period, dt, max_quality):
    """Escolhe o deslocamento que representa uma repetição real.

    Devolve (p_em_segundos, qualidade, início_do_trecho, base) ou None,
    onde base é a distância típica entre quadros não relacionados.
    """
    n = dist.shape[0]
    if n < 8:
        return None

    off = dist[np.triu_indices(n, 2)]
    base = float(np.median(off)) or 1.0

    best = None
    lo = max(1, int(math.ceil(min_period / dt)))
    for p in range(lo, n // 2 + 1):
        diag = np.diagonal(dist[p:, :n - p])
        run_start, run_len = longest_run(diag <= tol)
        if run_len < p:                  # nem um bloco inteiro repetindo
            continue
        quality = float(diag[run_start:run_start + run_len].mean()) / base
        if best is None or quality < best[1]:
            best = (p * dt, quality, (run_start, run_len), base)

    # Repetição de verdade é praticamente idêntica: nos clips que cortam em
    # loop a qualidade fica em 1-2%. Passando de ~5% o que achamos é
    # conteúdo parecido (recorrência de cenário, música com espectro
    # estável), não um bloco que se repete. Afrouxe com --max-quality se
    # quiser a leitura permissiva.
    if best is None or best[1] > max_quality:
        return None
    return best


def find_unique(dist, p, tol):
    """Janela que NÃO segue o período - o conteúdo único.

    Devolve (i_início, i_fim) no espaço amostrado, ou None se o arquivo
    inteiro é periódico (já é um loop contínuo).
    """
    n = dist.shape[0]
    if p <= 0 or p >= n:
        return None
    periodic = np.zeros(n - p, dtype=bool)
    periodic[:] = np.diagonal(dist[p:, :n - p]) <= tol
    start, length = longest_run(~periodic)
    if length == 0:
        return None
    return start, start + length


def psnr(a, b):
    """PSNR em dB entre dois blocos uint8, saturado em 99."""
    mse = float(((a.astype(np.float64) - b.astype(np.float64)) ** 2).mean())
    if mse <= 1e-9:
        return 99.0
    return min(99.0, 10.0 * math.log10(255.0 * 255.0 / mse))


# --- corte ---------------------------------------------------------------

def cut(path, start, end, dest, crf):
    need("ffmpeg")
    dur = max(0.1, end - start)
    parent = os.path.dirname(os.path.abspath(dest))
    if parent:
        os.makedirs(parent, exist_ok=True)
    r = subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-ss", "%.3f" % start, "-i", path,
         "-t", "%.3f" % dur,
         "-c:v", "libx264", "-crf", str(crf), "-preset", "slow",
         "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", dest],
        capture_output=True)
    if r.returncode != 0 or not os.path.exists(dest):
        raise Abort("falha ao cortar: %s"
                    % r.stderr.decode("utf-8", "replace").strip()[:200], 1)


# --- main ----------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(prog="loopdetect")
    ap.add_argument("src")
    ap.add_argument("--json", action="store_true",
                    help="imprime @@JSON@@ + uma linha de JSON em stdout")
    ap.add_argument("--cut", metavar="DEST", help="recorta o trecho único em DEST")
    ap.add_argument("--crf", type=int, default=18, help="qualidade do corte (padrão 18)")
    ap.add_argument("--only-visual", action="store_true", help="ignora o áudio")
    ap.add_argument("--only-audio", action="store_true", help="ignora o vídeo")
    ap.add_argument("--max-scene-change", type=float, metavar="F",
                    help="aborta se todo quadro diferir menos que F de 0 a 255")
    ap.add_argument("--max-quality", type=float, default=MAX_QUALITY, metavar="Q",
                    help="rejeita repetição mais diferente que Q (padrão %(default)s)")
    ap.add_argument("--tol", type=float, default=MATCH_TOL, metavar="T",
                    help="distância que ainda conta como o mesmo quadro (padrão %(default)s)")
    args = ap.parse_args()

    src = args.src
    if not os.path.isfile(src):
        raise Abort("não achei o arquivo: %s" % src, 1)

    result = {"src": os.path.abspath(src), "loop": False, "loop_start": None,
              "unique_end": None, "period": None, "seam_psnr": None, "dest": None}

    def finish(code=0):
        if args.json:
            print("@@JSON@@" + json.dumps(result, ensure_ascii=False), flush=True)
        raise SystemExit(code)

    dur, has_v, has_a = probe(src)

    # o loopbatch passa --max-scene-change para descartar slideshow/imagem
    # parada: mede o quanto o conteúdo realmente se mexe antes de gastar
    # tempo cortando. Não é erro, é "nada a extrair", então ainda saímos
    # com JSON válido e loop=false.
    if args.max_scene_change is not None:
        try:
            sample_video(src, args.max_scene_change)
        except Abort as e:
            if e.code != 3:
                raise
            report(["cena estática: nada a extrair"])
            finish(1)

    use_video = has_v and not args.only_audio
    use_audio = has_a and not args.only_visual and not use_video
    if not (use_video or use_audio):
        raise Abort("o arquivo não tem nem vídeo nem áudio", 1)

    report(["loopdetect: %s" % src,
            "modo        : %s" % ("vídeo" if use_video else "áudio"),
            "duração     : %s" % fmt_time(dur), ""])

    scene_change = None
    if use_video:
        sig, times, scene_change = sample_video(src)
        tol = args.tol
    else:
        sig, times = sample_audio(src)
        # assinatura float: a tolerância é relativa à escala do próprio áudio
        spread = float(np.abs(sig).mean()) or 1.0
        tol = max(spread * AUDIO_TOL_FRAC, 1e-6)

    raw_n = len(sig)
    sig, times, stride = thin(sig, times)
    dt = float(times[1] - times[0]) if len(times) > 1 else 1.0 / SAMPLE_FPS
    dist = distance_matrix(sig)

    hit = find_period(dist, tol, MIN_PERIOD, dt, args.max_quality)
    if hit is None:
        report(["não encontrei um bloco que se repete em sequência."])
        finish(1)

    period, quality, (run_start, run_len), base = hit
    p = max(1, min(int(round(period / dt)), len(times) - 1))
    result["period"] = round(period, 3)

    # O loopbatch mostra estes no relatório: quantas vezes o bloco repete,
    # e a similaridade das cópias contra a de pares não relacionados.
    diag = np.diagonal(dist[p:, :len(dist) - p])
    run_dist = float(diag[run_start:run_start + run_len].mean())
    repeats = (run_len + p) / p
    result["repeats"] = round(repeats, 2)
    result["sim"] = round(max(0.0, 1.0 - run_dist / 255.0), 4)
    result["ctrl"] = round(max(0.0, 1.0 - base / 255.0), 4)
    if scene_change is not None:
        result["scene_change"] = round(scene_change, 3)
        result["static_scene"] = bool(scene_change < STATIC_LIMIT)

    # sem acento: o loopgui faz grep por 'periodo\s+:\s+'
    report(["periodo    : %.2f s   (%dx no vídeo, diferença %.2f%% entre as cópias)"
            % (period, repeats, quality * 100),
            "similaridade: %.3f (controle %.3f)"
            % (result["sim"], result["ctrl"]),
            "amostras    : %d de %d%s   (1 a cada %.2f s)"
            % (len(times), raw_n, " (reduzido)" if stride > 1 else "", dt), ""])

    win = find_unique(dist, p, tol)

    # --- o arquivo já é um loop contínuo: mede a emenda, não recorta
    if win is None:
        if use_video:
            # a emenda é o primeiro quadro contra o início do período seguinte
            seam = psnr(sig[0], sig[p])
            seam_diff = float(np.sqrt(((sig[0] - sig[p]) ** 2).mean()))
        else:
            seam = seam_diff = None
        if seam is not None and seam >= SEAM_MIN_DB:
            result.update({"seamless": True, "seam_psnr": round(seam, 2),
                           "seam_diff": round(seam_diff, 3)})
            report(["emenda inicio/fim a %.2f dB" % seam, "",
                    "o arquivo já é um loop contínuo: não há trecho único a recortar."])
            finish(0)
        report(["o arquivo inteiro segue o período, mas a emenda não fecha "
                "(%.2f dB)." % (seam if seam is not None else 0.0),
                "nada de trecho único."])
        finish(1)

    # --- tem trecho único
    i0, i1 = win
    start = float(times[i0])
    # se a janela encosta no fim da região comparável, o trecho único
    # chega até o fim do arquivo
    end = float(dur) if i1 >= len(times) - p else float(times[i1])

    if end - start < 0.4:
        report(["a parte que não se repete é curta demais (%.2f s)." % (end - start)])
        finish(1)

    result.update({"loop": True, "loop_start": round(start, 3),
                   "unique_end": round(end, 3),
                   "unique_len": round(end - start, 3)})

    # deriva: o último ciclo ainda parece com openúltimo? Comparar com o
    # início do arquivo não serve - num layout [único][loop] o começo é
    # justamente a parte que não repete.
    if use_video and 2 * p <= len(sig):
        tail = sig[len(sig) - p:].mean(axis=0)
        prev = sig[len(sig) - 2 * p:len(sig) - p].mean(axis=0)
        result["drift_last"] = round(
            max(0.0, 1.0 - float(np.sqrt(((tail - prev) ** 2).mean())) / 255.0), 4)

    report(["comeca em : %s" % fmt_time(start),
            "TRECHO UNICO : %s   (%.2f s)" % (fmt_time(end), end - start),
            "o resto repete a cada %.2f s" % period])

    if args.cut:
        if start >= dur - 0.2:
            report(["", "corte suprimido: o trecho único encosta no fim."])
        else:
            cut(src, start, end, args.cut, args.crf)
            result["dest"] = os.path.abspath(args.cut)
            report(["", "salvo : %s" % args.cut])

    finish(0)


if __name__ == "__main__":
    try:
        main()
    except Abort as e:
        report(["loopdetect: %s" % e])
        raise SystemExit(e.code)
    except KeyboardInterrupt:
        raise SystemExit(130)
