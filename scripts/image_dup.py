#!/usr/bin/env python3
"""image_dup.py - diz se duas imagens são a mesma foto ou não.

Mesma ideia do loop_detect.py: comparar conteúdo, não byte. Duas cópias da
mesma foto quase nunca têm o mesmo hash - um re-salvamento em JPEG mexe em
alguns níveis de cada pixel e já quebra o md5. Mas comparar byte a byte também
não resolve: basta uma marca d'água no canto para dar "diferentes" quando o
que a gente quer saber é "isso é a mesma imagem?".

Só precisa de ffmpeg/ffprobe + numpy. Sem OpenCV, sem GPU, sem Pillow.

O que decide
------------
Duas medições, e as duas precisam concordar:

  dist_norm  diferença média depois de centralizar e escalar as duas imagens.
             Vira "quantos desvios-padrão de distância", então não depende de
             a foto ser clara ou escura, contrastada ou chapada. Recomprimir a
             mesma foto em JPEG deixa isto em 0,01-0,10; outra foto deixa em
             0,2 ou mais.

  r_lum      correlação dos desenhos. Invariante a brilho e contraste, e é o
             que reprova duas fotos da mesma cena feitas em momentos
             diferentes (correlação ~0,5).

A diferença absoluta (dist_raw) NÃO decide: escurecer uma foto leva o valor
absoluto para 26 sem mudar um pixel do desenho, e aí a mesma foto é reprovada
como se fosse outra. Ela só entra depois, já aprovada, para dizer o QUE mudou
- recompressão, ajuste de tom ou edição local.

Quando as duas medições aprovam, a diferença absoluta e o mapa de onde ela
está separam o resto:

  local_edit  a diferença está concentrada numa faixa - marca d'água, logo,
              tarja, canto cortado. É a mesma foto com um carimbo.
  tonal       o desenho é o mesmo, mudou o tom/contraste (filtro, edição).
  visual      só recompressão de novo, o conteúdo está lá dentro.
  crop        uma das duas é um recorte da outra (mesma foto, outro
              enquadramento).

O recorte merece uma nota: cortar a borda não muda a proporção da foto, então
ele se disfarça de "mesma proporção em outro tamanho". Por isso a busca por
recorte roda ANTES de qualquer redimensionamento - depois de igualar os dois
tamanhos não sobra mais sinal de que uma tinha sido cortada.

Igual, semelhante, diferente
---------------------------
O script separa os três, porque eles não servem para a mesma coisa:

  IGUAL        as duas imagens são a mesma foto e a diferença entre elas é
               só o ruído de recompressão. duplicate=true, exit 0.

  SEMELHANTE   mesma foto de base, mas com alguma coisa a mais ou a menos:
               marca d'água, logo, tarja, tom mudado, enquadramento
               diferente. duplicate=false, exit 1, e o `kind` diz qual.

  DIFERENTE    nem são a mesma foto. duplicate=false, exit 1.

O critério é o que o senso comum de "duplicata" já diz: se uma imagem tem um
pixel a mais, a menos ou diferente, ela não é igual - é parecida. Por isso
mudança de tom e edição local NÃO entram como duplicata, mesmo quando o
desenho bate. E o JPEG só é perdoado se o estrago for pequeno.

Quem chama para limpar pasta não quer "quase igual" na lista de descarte,
então semelhante sai com o mesmo código de saída que diferente. O relatório
humano conta o que o JSON não precisa carregar: o `kind` ("crop",
"local_edit", "tonal", "noise") diz em qual dos casos estamos.

Contrato de saída (mesmo formato do loopdetect):
  --json  imprime @@JSON@@ seguido de UMA linha de JSON em stdout;
          todo o relatório humano vai para stderr.
  exit 0  as imagens são duplicadas (iguais)
  exit 1  não são duplicadas - podem ser diferentes ou apenas semelhantes
  exit 2  erro de uso/ferramenta (o JSON não sai)
"""

import argparse
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys

try:
    import numpy as np
except ImportError:  # pragma: no cover
    sys.stderr.write("imagedup: numpy ausente. Crie o venv:\n"
                     "  python3 -m venv ~/.local/share/loopdetect/venv\n"
                     "  ~/.local/share/loopdetect/venv/bin/pip install numpy\n")
    raise SystemExit(2)

# --- ajustes de precisão -------------------------------------------------
# Os limiares de estrutura saíram medindo um corpus de casos com resposta
# conhecida (recompressão, resize, ajuste de tom, quanto pior JPEG, e fotos
# diferentes da mesma cena). Os de "mesma foto" ficaram até 0,10 e os de
# "foto diferente" começam em 0,21 - com o limite em 0,15 no meio, longe dos
# dois lados.
#
# DUPLICIDADE É ESTRITA DE PROPÓSITO
# -----------------------------------
# Igual não é o mesmo que semelhante. Se uma imagem tem algo que a outra não
# tem - uma marca d'água, um logo, um rosto tapado - as duas não são
# duplicadas: são semelhantes. Então "tons diferentes" NÃO conta como
# duplicata (mudar o brilho já é mexer em pixels), e uma edição local
# pequena NÃO conta (é conteúdo presente numa e ausente na outra).
# Duplicata é só quando a diferença é ruído de recompressão, e nem sempre:
# o JPEG só é perdoado se for pequeno. Acima de NOISE_MAX de pixels mexidos a
# diferença já é um borrão ou um texto e reprova. Resize e enquadramento
# também não são duplicata - mudar o enquadramento é mudar a imagem.
#
# O script ainda diz o que encontrou (mesma foto, mesma foto com edição, só
# outro tom), mas essas respostas saem com duplicate=false e exit 1: quem
# chama para limpar pasta não quer "quase igual" na lista de descarte.
WORK_MAX = 1024       # lado máximo da grade de trabalho (0 desliga)
TOL_NORM = 0.15       # diferença de estrutura que ainda é a mesma foto
MIN_R = 0.99          # correlação mínima dos desenhos
TOL_TONAL = 12.0      # (informativo) bruta alta = mudou o tom, não o desenho
NOISE_MAX = 0.02      # 2% dos pixels: teto do perdão ao ruído de JPEG.
                      # Medido: recomprimir no q15 (o pior caso razoável)
                      # mexe 1,33% dos pixels. Um pixel só passando de
                      # NOISE_DELTA já é conteúdo, e isso é tratado antes,
                      # pelo BIG_MIN - aqui o que sobra é degradação geral.
PIX_TOL = 16          # diferença num único pixel para contar como "mudou"
NOISE_DELTA = 80      # pixel que difere MAIS que isto não é ruído de JPEG.
                      # Medido: recompressão no q15 chega a 58/255; uma
                      # marca d'água chega a 196/255. O corte fica no meio.
BIG_MIN = 2e-5        # 0,002% dos pixels: acima disto já há conteúdo a mais
                      # numa imagem que na outra, e não é ruído
BLOB_EDIT = 0.005     # 0,5%: acima disto há um bloco visível editado à mão
DITHER_MAX = 0.06     # 6% dos pixels: editar é repintar coisas diferentes
CROP_MAX = 0.15       # 15%: a maior borda que ainda conta como o mesmo
                      # enquadramento (o resto da foto tem que estar dentro)
ALIGN = 2             # busca de deslocamento, em pixels da grade de trabalho
BLOB_GRID = 256       # grade usada para achar a edição local
MAX_PIXELS = 80e6     # recusa imagens gigantes em vez de estourar a RAM

ASPECT_TOL = 0.01     # 1%: proporção diferente = outra foto, não é resize
LOW_DETAIL = 4.0      # desvio menor que isto e a imagem é chapada demais


class Abort(Exception):
    """Sai com código, sem stack trace (código != 1 é um caso conhecido)."""

    def __init__(self, msg, code):
        super().__init__(msg)
        self.code = code


def need(tool):
    if not shutil.which(tool):
        raise Abort("'%s' não encontrado no PATH" % tool, 2)


def report(msgs):
    for m in msgs:
        sys.stderr.write(m + "\n")
    sys.stderr.flush()


def file_hash(path):
    """SHA-256 do arquivo inteiro, lido em blocos."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for blk in iter(lambda: f.read(1 << 20), b""):
            h.update(blk)
    return h.hexdigest()


# --- EXIF ----------------------------------------------------------------
# O ffmpeg NÃO gira a imagem pelo tag de orientação: ele entrega os pixels
# como estão no arquivo. Sem ler o tag, uma foto de celular deitada e a mesma
# foto em pé comparam como duas imagens completamente diferentes.

def _tiff_orientation(tiff):
    """Tag 0x0112 de um bloco TIFF (little/big endian). 1 se não achar."""
    if len(tiff) < 8:
        return 1
    if tiff[:2] == b"II":
        e = "little"
    elif tiff[:2] == b"MM":
        e = "big"
    else:
        return 1

    def u16(b):
        return int.from_bytes(b, e)

    off = int.from_bytes(tiff[4:8], e)
    if off < 8 or off + 2 > len(tiff):
        return 1
    count = u16(tiff[off:off + 2])
    if count > 512:                       # lixo no meio do arquivo
        return 1
    for k in range(count):
        ent = off + 2 + k * 12
        if ent + 12 > len(tiff):
            break
        if u16(tiff[ent:ent + 2]) == 0x0112:
            return u16(tiff[ent + 8:ent + 10]) or 1
    return 1


def exif_orientation(path):
    """Orientação declarada no EXIF (1..8). 1 para quem não tem EXIF."""
    try:
        with open(path, "rb") as f:
            head = f.read(256 * 1024)
    except OSError:
        return 1
    if len(head) < 4 or head[:2] != b"\xff\xd8":
        return 1                       # não é JPEG: não há tag para ler

    i = 2
    while i + 4 <= len(head):
        if head[i] != 0xFF:
            i += 1
            continue
        marker = head[i + 1]
        if marker in (0xD8, 0x01) or 0xD0 <= marker <= 0xD7:
            i += 2
            continue
        if marker in (0xDA, 0xD9):     # entrou no scan dos pixels
            break
        seglen = int.from_bytes(head[i + 2:i + 4], "big")
        if seglen < 2:
            break
        seg = head[i + 4:i + 2 + seglen]
        if marker == 0xE1 and seg[:6] == b"Exif\x00\x00":
            return _tiff_orientation(seg[6:])
        i += 2 + seglen
    return 1


def apply_orientation(img, o):
    """Gira a imagem como manda o EXIF. Mesma tabela do exif_transpose."""
    if o == 2:
        return img[:, ::-1]
    if o == 3:
        return img[::-1, ::-1]
    if o == 4:
        return img[::-1, :]
    if o == 5:
        return np.rot90(img, -1)[:, ::-1]
    if o == 6:
        return np.rot90(img, -1)
    if o == 7:
        return np.rot90(img, 1)[:, ::-1]
    if o == 8:
        return np.rot90(img, 1)
    return img


# --- leitura -------------------------------------------------------------

def probe_image(path):
    """(largura, altura) em pixels."""
    need("ffprobe")
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", path],
        capture_output=True, text=True)
    if r.returncode != 0:
        raise Abort("ffprobe não leu %s: %s"
                    % (path, r.stderr.strip()[:200]), 1)
    try:
        w, h = (int(v) for v in r.stdout.strip().split("x")[:2])
    except ValueError:
        raise Abort("não consegui as dimensões de %s" % path, 1)
    if w <= 0 or h <= 0:
        raise Abort("%s não tem imagem decodificável" % path, 1)
    if w * h > MAX_PIXELS:
        raise Abort("%s é grande demais (%dx%d)" % (path, w, h), 1)
    return w, h


def load_image(path):
    """(H, W, 3) uint8, girada pelo EXIF.

    O -noautorotate é obrigatório: o ffmpeg gira a imagem pelo tag de
    orientação sozinho, MAS o ffprobe continua reportando as dimensões
    como estão no arquivo. Sem desligar isso, o reshape dos pixels sai com a
    altura e a largura trocadas e a comparação vira scrambled - foi
    exatamente o que aconteceu na primeira versão deste script.
    """
    need("ffmpeg")
    w, h = probe_image(path)
    r = subprocess.run(
        ["ffmpeg", "-v", "error", "-noautorotate", "-i", path, "-frames:v", "1",
         "-pix_fmt", "rgb24", "-f", "rawvideo", "-"], capture_output=True)
    if r.returncode != 0 or len(r.stdout) < w * h * 3:
        raise Abort("ffmpeg não decodificou %s: %s"
                    % (path, r.stderr.decode("utf-8", "replace").strip()[:200]), 1)
    img = np.frombuffer(r.stdout[:w * h * 3],
                        dtype=np.uint8).reshape(h, w, 3)
    return np.ascontiguousarray(apply_orientation(img, exif_orientation(path)))


# --- redução -------------------------------------------------------------

def box_resize(img, out_w, out_h):
    """Média por bloco (filtro de área), sem PIL.

    Diferente de nearest neighbour: o grão do JPEG vira serrilhado e a
    diferença sobe. Área é o mesmo que o scale=...:flags=area do loop_detect.
    """
    h, w = img.shape[:2]
    if out_w == w and out_h == h:
        return img
    ii = np.pad(img.astype(np.float32).cumsum(0).cumsum(1),
                ((1, 0), (1, 0), (0, 0)))
    ys = np.linspace(0, h, out_h + 1).round().astype(int)
    xs = np.linspace(0, w, out_w + 1).round().astype(int)
    s = (ii[ys[1:, None], xs[1:]] - ii[ys[:-1, None], xs[1:]]
         - ii[ys[1:, None], xs[:-1]] + ii[ys[:-1, None], xs[:-1]])
    area = ((ys[1:] - ys[:-1])[:, None] * (xs[1:] - xs[:-1])[None, :])[..., None]
    return np.clip(np.rint(s / area), 0, 255).astype(np.uint8)


def to_work(img, work_max):
    """Reduz para a grade de trabalho (0 desliga a redução)."""
    if not work_max:
        return img
    h, w = img.shape[:2]
    m = max(h, w)
    if m <= work_max:
        return img
    s = work_max / m
    return box_resize(img, max(1, int(round(w * s))),
                      max(1, int(round(h * s))))


# --- métricas ------------------------------------------------------------

def luma(img):
    """Luma BT.601: o olho não pesa os três canais igual, e o grão do JPEG
    aparece mais forte num deles do que nos outros."""
    return (0.299 * img[..., 0] + 0.587 * img[..., 1]
            + 0.114 * img[..., 2]).astype(np.float32)


def zunit(x):
    """Centraliza e escala para desvio 1. Devolve (z, desvio original)."""
    s = float(x.std())
    if s < 1e-6:
        return np.zeros_like(x), s          # imagem chapada: nada a descrever
    return (x - float(x.mean())) / s, s


def pearson(x, y):
    """Correlação de Pearson: invariante a deslocar e escalar."""
    x = x.ravel().astype(np.float64)
    y = y.ravel().astype(np.float64)
    x = x - x.mean()
    y = y - y.mean()
    d = float(np.sqrt((x * x).sum() * (y * y).sum()))
    return 0.0 if d == 0 else float((x * y).sum() / d)


def crop_pair(a, b, dy, dx):
    """Recorta os dois com o deslocamento (dy, dx), devolvendo o mesmo
    tamanho dos dois."""
    ha, wa = a.shape[:2]
    hb, wb = b.shape[:2]
    A = a[max(0, dy):ha + min(0, dy), max(0, dx):wa + min(0, dx)]
    B = b[max(0, -dy):hb + min(0, -dy), max(0, -dx):wb + min(0, -dx)]
    return A, B


def crop_inside(a, b, dy, dx):
    """A janela do tamanho de B que começa em (dy, dx) dentro de A.

    Diferente do crop_pair: aqui não estamos deslocando as duas imagens uma
    contra a outra, estamos procurando a região de A que casa com a imagem
    inteira de B. Por isso os dois lados saem do mesmo tamanho de verdade -
    se usarmos o crop_pair aqui, A e B ficam com alturas diferentes e a
    comparação estoura.
    """
    ha, wa = a.shape[:2]
    hb, wb = b.shape[:2]
    if dy < 0 or dx < 0 or dy + hb > ha or dx + wb > wa:
        return None, None
    return a[dy:dy + hb, dx:dx + wb], b


def align(a, b, shift):
    """Procura um deslocamento de até ±shift px que diminua a diferença."""
    best = (float("inf"), 0, 0)
    for dy in range(-shift, shift + 1):
        for dx in range(-shift, shift + 1):
            A, B = crop_pair(a, b, dy, dx)
            d = float(np.abs(A.astype(np.float32)
                             - B.astype(np.float32)).mean())
            if d < best[0]:
                best = (d, dy, dx)
    return best[1], best[2]


def box_align(a, b, work_max):
    """Descobre se uma das imagens é um RECORTE da outra.

    Cortar 5% da borda de uma foto não muda um pixel do desenho, só em qual
    janela ele aparece. A busca fina do align() (feita para absorver 1-2 px
    de folga) nunca acha isso. A intuição aqui é outra:

      - as duas são reduzidas pelo MESMO fator, senão o recorte deixa de ser
        uma janela e vira uma miniatura levemente torta;
      - a correlação cruzada por FFT acha de uma vez em qual deslocamento o
        pedaço de uma casa dentro da outra.

    Importante: isto roda nas imagens ORIGINAIS. Depois do to_work() as duas
    são reduzidas para o mesmo lado, a diferença de escala some e não sobra
    sinal de que uma era recorte da outra.

    Devolve (dy, dx, sobreposicao) em pixels da imagem original, ou None.
    """
    m = max(a.shape[0], a.shape[1], b.shape[0], b.shape[1])
    if not m or work_max <= 0:
        return None
    ha, wa = a.shape[:2]
    hb, wb = b.shape[:2]
    # já são do mesmo tamanho: não há o que descobrir aqui
    if abs(ha - hb) < 4 or abs(wa - wb) < 4:
        return None
    # uma tem que caber dentro da outra; se for a primeira, troca os nomes
    b_inside_a = (hb <= ha and wb <= wa)
    if not b_inside_a and not (ha <= hb and wa <= wb):
        return None
    if not b_inside_a:
        ha, wa, hb, wb = hb, wb, ha, wa

    s = work_max / m
    ah = max(1, int(round(ha * s)))
    aw = max(1, int(round(wa * s)))
    bh = max(1, int(round(hb * s)))
    bw = max(1, int(round(wb * s)))
    if ah <= bh or aw <= bw:
        return None
    A = luma(box_resize(a, aw, ah)).astype(np.float32)
    B = luma(box_resize(b, bw, bh)).astype(np.float32)

    # correlação cruzada: o pico em (y, x) é onde B encaixa dentro de A
    H, W = ah + bh, aw + bw
    Ap = np.zeros((H, W), np.float32)
    Ap[:ah, :aw] = A - A.mean()
    Bp = np.zeros((H, W), np.float32)
    Bp[:bh, :bw] = B - B.mean()
    cc = np.fft.irfft2(np.fft.rfft2(Ap) * np.conj(np.fft.rfft2(Bp)), s=(H, W))
    valid = cc[:ah - bh + 1, :aw - bw + 1]
    if not valid.size:
        return None
    y, x = np.unravel_index(int(np.argmax(valid)), valid.shape)

    dy = int(round(y / s))               # volta para pixels da original
    dx = int(round(x / s))
    ov = (1.0 - abs(dy) / float(hb)) * (1.0 - abs(dx) / float(wb))
    # 1 = foi a imagem A que entrou dentro da imagem B
    return dy, dx, ov, 0 if b_inside_a else 1


def metrics(A, B):
    """As duas medições que decidem, mais o PSNR para o relatório."""
    a = A.astype(np.float32)
    b = B.astype(np.float32)
    diff = np.abs(a - b)

    dist_raw = float(diff.mean())
    mse = float((diff ** 2).mean())
    psnr = 99.0 if mse <= 1e-9 else min(99.0, 10.0 * math.log10(255.0 ** 2 / mse))

    za, sa = zunit(a)
    zb, sb = zunit(b)
    dist_norm = float(np.abs(za - zb).mean())
    r_lum = pearson(luma(A), luma(B))

    dmax = diff.max(axis=2)
    # fração de pixels com diferença grande: a medida que separa "recomprimiu"
    # de "colocou alguma coisa". Ruído de JPEG fica abaixo de NOISE_DELTA.
    big = float((dmax > NOISE_DELTA).mean())
    return {"dist_raw": dist_raw, "dist_norm": dist_norm, "r_lum": r_lum,
            "psnr": psnr, "detail": (sa + sb) * 0.5, "big": big}, dmax


# --- onde a diferença está -----------------------------------------------

def largest_blob(mask):
    """(n_pixels, bbox) do maior pedaço conexo (4-vizinhança)."""
    h, w = mask.shape
    m = mask.copy()
    best, bbox = 0, None
    for y0 in range(h):
        for x0 in range(w):
            if not m[y0, x0]:
                continue
            m[y0, x0] = False
            stack = [(y0, x0)]
            cnt = 0
            ylo = yhi = y0
            xlo = xhi = x0
            while stack:
                y, x = stack.pop()
                cnt += 1
                if y < ylo:
                    ylo = y
                if y > yhi:
                    yhi = y
                if x < xlo:
                    xlo = x
                if x > xhi:
                    xhi = x
                for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= ny < h and 0 <= nx < w and m[ny, nx]:
                        m[ny, nx] = False
                        stack.append((ny, nx))
            if cnt > best:
                best, bbox = cnt, (ylo, xlo, yhi, xhi)
    return best, bbox


def dilate(mask, r):
    """Engorda a máscara em r pixels, sem executar as bordas."""
    acc = mask.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            sh = np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
            if dy > 0:
                sh[:dy] = False
            elif dy < 0:
                sh[dy:] = False
            if dx > 0:
                sh[:, :dx] = False
            elif dx < 0:
                sh[:, dx:] = False
            acc |= sh
    return acc


def localize(dmax):
    """Onde a diferença está: (fração de pixels, maior_blob, caixa).

    A máscara é reduzida antes do BFS e dilatada um pouco: as letras de uma
    marca d'água são blobs separados por 1-2 px, e sem dilatar a gente conta
    cinco edições diferentes em vez de um texto só.
    """
    h, w = dmax.shape
    frac = float((dmax > PIX_TOL).mean())
    if frac == 0.0:
        return 0.0, 0.0, None

    s = min(1.0, BLOB_GRID / max(h, w))
    small = (dmax if s >= 1.0 else
             box_resize(dmax[:, :, None],
                        max(1, int(round(w * s))),
                        max(1, int(round(h * s))))[:, :, 0])
    mask = small > PIX_TOL
    sh = dilate(mask, max(1, int(round(0.012 * max(mask.shape)))))

    cnt, bbox = largest_blob(sh)
    bh, bw = mask.shape
    rel = None
    if bbox is not None:
        y0, x0, y1, x1 = bbox
        rel = (y0 / bh, x0 / bw, y1 / bh, x1 / bw)
    return frac, cnt / float(mask.size), rel


# --- comparação ----------------------------------------------------------

def compare(pa, pb, args):
    """Junta tudo: devolve (resultado_json, linhas do relatório humano)."""
    out = {"a": os.path.abspath(pa), "b": os.path.abspath(pb),
           "duplicate": False, "kind": None, "reason": "", "score": 0.0}
    lines = []

    ha, hb = file_hash(pa), file_hash(pb)
    out["sha256_a"], out["sha256_b"] = ha, hb
    if ha == hb:
        out.update({"duplicate": True, "kind": "bytes", "score": 1.0,
                    "reason": "arquivos byte a byte idênticos"})
        lines.append("sha256      : %s..." % ha[:16])
        lines.append("")
        lines.append("DUPLICADA: os dois arquivos têm exatamente o mesmo "
                     "conteúdo, byte por byte.")
        return out, lines

    A = load_image(pa)
    B = load_image(pb)
    oa, ob = exif_orientation(pa), exif_orientation(pb)
    wa, ha_ = A.shape[1], A.shape[0]
    wb, hb_ = B.shape[1], B.shape[0]
    out.update({"size_a": [wa, ha_], "size_b": [wb, hb_],
                "exif_a": oa, "exif_b": ob})

    lines.append("imagem      : %s  (%dx%d%s)"
                 % (pa, wa, ha_, ", exif %d" % oa if oa != 1 else ""))
    lines.append("             %s  (%dx%d%s)"
                 % (pb, wb, hb_, ", exif %d" % ob if ob != 1 else ""))

    mesma_caixa = (A.shape[0], A.shape[1]) == (B.shape[0], B.shape[1])
    if not mesma_caixa and args.no_resize:
        out["reason"] = ("dimensões diferentes (%dx%d e %dx%d)"
                         % (wa, ha_, wb, hb_))
        lines.append("")
        lines.append("NÃO DUPLICADA: dimensões diferentes (%dx%d e %dx%d)."
                     % (wa, ha_, wb, hb_))
        return out, lines

    # --- recorte? VEM ANTES de qualquer redimensionamento.
    # Cortar a borda não muda a proporção da foto, então o caso "mesma
    # proporção, tamanho diferente" abaixo cairia nela e igualaria os dois
    # tamanhos - apagando justamente a pista de que uma tinha sido cortada.
    crop_note = None
    if not mesma_caixa and not args.no_crop:
        hit = box_align(A, B, args.work)
        if hit:
            cdy, cdx, ov, who = hit
            if ov >= 1.0 - args.crop_max and (cdy or cdx):
                dentro, fora = (A, B) if who == 0 else (B, A)
                A2, B2 = crop_inside(dentro, fora, cdy, cdx)
                if A2 is not None and A2.size:
                    A2 = to_work(A2, args.work)
                    B2 = to_work(B2, args.work)
                    m2, dmax2 = metrics(A2, B2)
                    # quem aprova é a medida de verdade, nunca o pico da
                    # correlação: duas fotos sem relação nenhuma sempre têm
                    # algum pico em algum deslocamento.
                    if (m2["dist_norm"] <= args.tol_norm
                            and m2["r_lum"] >= args.min_r):
                        crop_note = (cdy, cdx, ov, who)
                        A, B = A2, B2
                        nome = "primeira" if who == 0 else "segunda"
                        lines.append("enquadramento : a %s aparece %.1f%% maior "
                                     "dentro da outra (deslocamento %+d,%+d px)"
                                     % (nome, ov * 100, cdy, cdx))

    resized = False
    if not crop_note and not mesma_caixa:
        ar_a, ar_b = wa / ha_, wb / hb_
        if abs(ar_a - ar_b) / max(ar_a, ar_b) > ASPECT_TOL:
            out["reason"] = ("proporções diferentes (%.3f e %.3f): não é a "
                             "mesma foto redimensionada" % (ar_a, ar_b))
            lines.append("")
            lines.append("NÃO DUPLICADA: as proporções são diferentes "
                         "(%.3f e %.3f)." % (ar_a, ar_b))
            lines.append("Não é a mesma foto em outro tamanho.")
            return out, lines
        # Mesma proporção e não é recorte: a mesma foto em outra resolução.
        nw, nh = min(wa, wb), min(ha_, hb_)
        A, B = box_resize(A, nw, nh), box_resize(B, nw, nh)
        resized = True
        lines.append("redimensionado: comparando os dois em %dx%d" % (nw, nh))

    A = to_work(A, args.work)
    B = to_work(B, args.work)

    dy, dx = align(A, B, 0 if args.no_align else args.shift)
    if dy or dx:
        lines.append("alinhamento : deslocado em %+d,%+d px antes de comparar"
                     % (dy, dx))
    A, B = crop_pair(A, B, dy, dx)

    m, dmax = metrics(A, B)
    frac, blob, rel = localize(dmax)
    same = m["dist_norm"] <= args.tol_norm and m["r_lum"] >= args.min_r

    out.update({
        "dist_raw": round(m["dist_raw"], 3),
        "dist_norm": round(m["dist_norm"], 4),
        "r_lum": round(m["r_lum"], 5),
        "psnr": round(m["psnr"], 2),
        "diff_area": round(frac, 5),
        "big_area": round(m["big"], 7),
        "edit_area": round(blob, 5),
        "resized": resized,
        "shift": [dy, dx],
        "crop": ([crop_note[0], crop_note[1], round(crop_note[2], 4),
                  crop_note[3]] if crop_note else None),
        "score": round(max(0.0, 1.0 - m["dist_norm"]), 4),
    })

    lines.append("")
    lines.append("diferença   : estrutura %.3f   |   correlação %.5f   |   "
                 "bruta %.2f" % (m["dist_norm"], m["r_lum"], m["dist_raw"]))
    lines.append("psnr        : %.2f dB" % m["psnr"])
    lines.append("pixels diferentes (>%d) : %.2f%% da foto"
                 % (PIX_TOL, frac * 100))
    if rel:
        lines.append("área editada : %.2f%% numa faixa (%.0f%%..%.0f%% em y, "
                     "%.0f%%..%.0f%% em x)"
                     % (blob * 100, rel[0] * 100, rel[2] * 100,
                        rel[1] * 100, rel[3] * 100))
    lines.append("limiares    : estrutura %g   correlação %g   tonal %g"
                 % (args.tol_norm, args.min_r, args.tol_tonal))

    # Detalhe quase nenhum (foto chapada, borrão, céu liso): a comparação
    # quase não tem sobre o que se apoiar e qualquer limiar vira chute.
    if m["detail"] < LOW_DETAIL and not same:
        out["reason"] = ("imagens sem detalhe (desvio %.1f) para comparar"
                         % m["detail"])
        lines.append("")
        lines.append("INDECISIVO: as duas imagens são quase chapadas "
                     "(desvio %.1f/255)." % m["detail"])
        lines.append("Não há desenho suficiente para dizer se são a mesma foto.")
        return out, lines

    if same:
        # Aqui sabemos que as duas são a MESMA FOTO de base. Isso ainda não
        # faz delas duplicadas: falta ver o que mudou. Igual exige que a
        # diferença seja só o ruído de recompressão - nada a mais, nada a
        # menos, nada diferente.
        #
        # O critério que separa as duas coisas é a MAGNITUDE, não a área.
        # Recomprimir a mesma foto mexe poucos níveis em cada pixel (medido:
        # no pior caso, 58 de 255). Colocar um texto mexe muito (196 de 255).
        # Área engana: um JPEG bem esmagado espalha ruído pela foto inteira e
        # pareceria com uma edição espalhada.

        # 1. Recorte: a segunda tem pixels que a primeira não tem. another
        #    enquadramento da mesma foto, não a mesma imagem.
        if crop_note:
            out["kind"] = "crop"
            out["reason"] = ("mesma foto, uma delas recortada (%.1f%% maior "
                             "dentro da outra)" % (crop_note[2] * 100))
            lines.append("")
            lines.append("SEMELHANTE: %s." % out["reason"])
            lines.append("O enquadramento mudou, então uma tem pixels que a "
                         "outra não tem. Não são iguais.")
            return out, lines

        # 2. Redimensionada: mesmo conteúdo, outra quantidade de pixels.
        #    Uma cópia em 4K e a mesma foto em 1080p não são a mesma imagem.
        if resized:
            out["kind"] = "resize"
            out["reason"] = ("mesma foto em outra resolução (%dx%d e %dx%d)"
                             % (wa, ha_, wb, hb_))
            lines.append("")
            lines.append("SEMELHANTE: %s." % out["reason"])
            lines.append("O conteúdo é o mesmo, mas o tamanho não. A que está "
                         "maior tem pixels que a outra não tem.")
            return out, lines

        # 3. Conteúdo grande numa que na outra não tem: marca d'água, logo,
        #    tarja, o que for. É a definição de "uma tem algo que a outra
        #    não tem" - e é por isso que NÃO é duplicata.
        if m["big"] >= args.big_min:
            out["kind"] = "local_edit"
            out["reason"] = ("mesma foto, mas uma tem conteúdo que a outra "
                             "não tem (%.2f%% da área, pixels até %d de "
                             "diferença)" % (blob * 100, int(dmax.max())))
            lines.append("")
            lines.append("SEMELHANTE: %s." % out["reason"])
            lines.append("A diferença fica toda em %.2f%% da imagem (%.2f%% "
                         "dos pixels)" % (blob * 100, frac * 100))
            if rel:
                lines[-1] += (", no canto de baixo à direita "
                              "(%.0f%%..%.0f%% em y, %.0f%%..%.0f%% em x)"
                              % (rel[0] * 100, rel[2] * 100,
                                 rel[1] * 100, rel[3] * 100))
            lines.append("Tem algo presente numa imagem e ausente na outra - "
                         "por isso não são iguais.")
            return out, lines

        # 4. Mudou o tom/brilho. É diferença de pixel espalhada, mas ainda
        #    assim não é a mesma imagem.
        if m["dist_raw"] > args.tol_tonal:
            out["kind"] = "tonal"
            out["reason"] = ("mesma foto com tom/contraste diferente "
                             "(bruta %.2f)" % m["dist_raw"])
            lines.append("")
            lines.append("SEMELHANTE: %s." % out["reason"])
            lines.append("O desenho é o mesmo, mas os tons mudaram. Para "
                         "escolher qual guardar, olhe brilho e contraste, "
                         "não conteúdo.")
            return out, lines

        # 5. Sobrou ruído de recompressão. Aqui sim é a mesma imagem - mas
        #    ainda com teto: JPEG muito esmagado degrada tanto que já não dá
        #    para dizer que as duas têm o mesmo conteúdo.
        if frac > args.noise_max:
            out["kind"] = "noise"
            out["reason"] = ("mesma foto, mas degradada: %.2f%% dos pixels "
                             "diferentes, acima do ruído normal de JPEG "
                             "(%.2f%%)" % (frac * 100, args.noise_max * 100))
            lines.append("")
            lines.append("SEMELHANTE: %s." % out["reason"])
            lines.append("A diferença é pequena por pixel, mas mexe em parte "
                         "grande demais da foto para ser só recompressão.")
            return out, lines

        # Mesma foto, e a diferença é só o JPEG fazendo o que faz.
        out.update({"duplicate": True, "kind": "visual",
                    "reason": "mesma foto, só recomprimida (bruta %.2f)"
                              % m["dist_raw"]})
        lines.append("")
        lines.append("DUPLICADA: %s." % out["reason"])
        if frac > 0:
            lines.append("%.3f%% dos pixels têm diferença, e nenhum passa de "
                         "%d de diferença - é o ruído de sempre do JPEG. As "
                         "duas têm o mesmo conteúdo." % (frac * 100,
                                                         NOISE_DELTA))
        return out, lines

    # Não é a mesma foto. Aponta QUAL das duas medições reprovou: é o que diz
    # à pessoa se é outra foto ou só a mesma foto com outro tom.
    why = []
    if m["dist_norm"] > args.tol_norm:
        why.append("a estrutura é outra (%.3f > %g)"
                   % (m["dist_norm"], args.tol_norm))
    if m["r_lum"] < args.min_r:
        why.append("os desenhos não acompanham (correlação %.5f < %g)"
                   % (m["r_lum"], args.min_r))
    out["reason"] = "; ".join(why)
    lines.append("")
    lines.append("NÃO DUPLICADA: nem são a mesma foto.")
    lines.append(" - ".join(why))
    return out, lines


# --- texto curto (notificação) --------------------------------------------

VEREDITO = {"bytes": "DUPLICADA", "visual": "DUPLICADA",
            "crop": "SEMELHANTE", "resize": "SEMELHANTE",
            "local_edit": "SEMELHANTE", "tonal": "SEMELHANTE",
            "noise": "SEMELHANTE"}


def pct(v):
    """Formata 0.0111 como 1,11% no padrão daqui."""
    s = ("%.2f" % (v * 100)).replace(".", ",")
    return s + "%"


def brief(res):
    """(titulo, corpo) - o veredito em no máximo três linhas.

    Vai para o swaync, que é uma notificação de 600px: cabe pouco. Então o
    corpo carrega a resposta e o número que a sustenta, e nada mais. O
    relatório completo continua no --json e na saída normal.
    """
    kind = res.get("kind")
    titulo = VEREDITO.get(kind) if kind else "NÃO DUPLICADA"

    nome = os.path.basename(res.get("src") or "?")
    outro = os.path.basename(res.get("dst") or "?")
    corpo = ["%s  x  %s" % (nome, outro)]

    # Cada caso escreve UMA frase. O `reason` completo não vem para cá: ele
    # foi escrito para o relatório do terminal, com números em ponto e
    # repetindo o que a linha de estatística já diz.
    if kind == "bytes":
        corpo.append("arquivos idênticos, byte a byte")
    elif kind == "visual":
        corpo.append("mesma foto, só recomprimida - nem um pixel a mais "
                     "nem a menos")
    elif kind == "local_edit":
        corpo.append("diferença concentrada em %s da área"
                     % pct(res.get("edit_area") or 0))
    elif kind == "resize":
        a, b = res.get("size_a"), res.get("size_b")
        corpo.append("mesma foto, outra resolução (%dx%d e %dx%d)"
                     % (a[0], a[1], b[0], b[1]) if a and b
                     else "mesma foto, outra resolução")
    elif kind == "crop":
        crop = res.get("crop")
        corpo.append("mesma foto, uma recortada%s"
                     % (" (%.0f%% maior)" % (crop[2] * 100) if crop else ""))
    elif kind == "tonal":
        corpo.append("mesma foto, mas o tom/contraste mudou")
    elif kind == "noise":
        corpo.append("mesma foto, degradada demais para contar como a mesma")
    elif (res.get("dist_norm") or 9.0) <= TOL_NORM:
        # A estrutura bateu, mas alguma coisa grande quebrou a correlação.
        # Casi sempre é um bloco (marca d'água, tarja) - não outra foto.
        corpo.append("uma tem alteração que a outra não tem")
    else:
        corpo.append("o conteúdo é outro - nem é a mesma foto")

    corpo.append("%s dos pixels diferentes · psnr %s dB"
                 % (pct(res.get("diff_area") or 0),
                    ("%.1f" % (res.get("psnr") or 0)).replace(".", ",")))
    return titulo, "\n".join(c for c in corpo if c)


# --- main ----------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        prog="imagedup",
        description="diz se duas imagens são a mesma foto")
    ap.add_argument("a")
    ap.add_argument("b")
    ap.add_argument("--json", action="store_true",
                    help="imprime @@JSON@@ + uma linha de JSON em stdout")
    ap.add_argument("--brief", action="store_true",
                    help="imprime o veredito curto em stdout, para notificação")
    ap.add_argument("--diff", metavar="ARQ",
                    help="salva um mapa de calor da diferença em ARQ")
    ap.add_argument("--work", type=int, default=WORK_MAX, metavar="N",
                    help="lado da grade de trabalho, 0 usa o tamanho real")
    ap.add_argument("--shift", type=int, default=ALIGN, metavar="N",
                    help="busca de alinhamento em px (padrão %(default)s)")
    ap.add_argument("--no-align", action="store_true",
                    help="não busca deslocamento")
    ap.add_argument("--no-resize", action="store_true",
                    help="dimensões diferentes = não duplicada, sem comparar")
    ap.add_argument("--tol-norm", type=float, default=TOL_NORM, metavar="T",
                    help="limiar de diferença de estrutura (padrão %(default)s)")
    ap.add_argument("--min-r", type=float, default=MIN_R, metavar="R",
                    help="correlação mínima dos desenhos (padrão %(default)s)")
    ap.add_argument("--tol-tonal", type=float, default=TOL_TONAL, metavar="T",
                    help="bruta acima disso conta como mudança de tom")
    ap.add_argument("--noise-max", type=float, default=NOISE_MAX, metavar="F",
                    help="máxima fração de pixels que é ruído de JPEG "
                         "(padrão %(default)s)")
    ap.add_argument("--big-min", type=float, default=BIG_MIN, metavar="F",
                    help="fração de pixels com diferença grande que já conta "
                         "como conteúdo a mais (padrão %(default)s)")
    ap.add_argument("--blob-edit", type=float, default=BLOB_EDIT, metavar="F",
                    help="área que conta como edição local (padrão %(default)s)")
    ap.add_argument("--dither-max", type=float, default=DITHER_MAX, metavar="F",
                    help="máxima fração de pixels editados (padrão %(default)s)")
    ap.add_argument("--no-crop", action="store_true",
                    help="não procura uma das imagens dentro da outra")
    ap.add_argument("--crop-max", type=float, default=CROP_MAX, metavar="F",
                    help="maior borda cortada que ainda conta como o mesmo "
                         "enquadramento (padrão %(default)s)")
    args = ap.parse_args()

    for p in (args.a, args.b):
        if not os.path.isfile(p):
            raise Abort("não achei o arquivo: %s" % p, 1)

    result, lines = compare(args.a, args.b, args)
    result["src"] = result.pop("a")
    result["dst"] = result.pop("b")

    if args.diff:
        write_diff(args.a, args.b, args.diff)

    if args.brief:
        titulo, corpo = brief(result)
        print(titulo + "\n" + corpo, flush=True)
    else:
        report(["imagedup: %s  x  %s" % (args.a, args.b), ""] + lines)
    if args.json:
        print("@@JSON@@" + json.dumps(result, ensure_ascii=False), flush=True)
    raise SystemExit(0 if result["duplicate"] else 1)


def write_diff(pa, pb, dest):
    """Mapa de calor: preto = igual, vermelho vivo = muito diferente."""
    A = to_work(load_image(pa), WORK_MAX)
    B = to_work(load_image(pb), WORK_MAX)
    A, B = crop_pair(A, B, *align(A, B, ALIGN))
    d = np.abs(A.astype(np.float32) - B.astype(np.float32)).max(axis=2)
    heat = np.clip(d / 32.0 * 255.0, 0, 255).astype(np.uint8)
    rgb = np.stack([heat, np.zeros_like(heat), np.zeros_like(heat)], axis=2)
    parent = os.path.dirname(os.path.abspath(dest))
    if parent:
        os.makedirs(parent, exist_ok=True)
    r = subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "rawvideo",
                        "-pix_fmt", "rgb24",
                        "-s", "%dx%d" % (rgb.shape[1], rgb.shape[0]),
                        "-i", "-", dest],
                       input=rgb.tobytes(), capture_output=True)
    if r.returncode != 0 or not os.path.exists(dest):
        raise Abort("não consegui salvar o diff em %s: %s"
                    % (dest, r.stderr.decode("utf-8", "replace").strip()[:200]), 1)


if __name__ == "__main__":
    try:
        main()
    except Abort as e:
        report(["imagedup: %s" % e])
        raise SystemExit(e.code)
    except KeyboardInterrupt:
        raise SystemExit(130)