#!/usr/bin/env python3
"""Testa o image_dup.py pelo contrato de linha de comando.

Roda o script de verdade, como subprocesso, e confere o codigo de saida e o
`kind` do JSON. Testar as funções de dentro passaria, mas deixaria passar
por cima do que mais quebrou aqui: o reshape dos pixels, o EXIF, e o
contrato @@JSON@@ que o loopgui consome.

O corpus é gerado na hora, com a fixture.py, num diretório temporário. Nada
é escrito no repositório e nada depende da foto de quem roda.

    ./run.py              roda tudo
    ./run.py -v           mostra o detalhe de cada caso
    ./run.py --so dup     só as duplicatas
    ./run.py --so nao     só as que não são

Precisa de numpy (para rodar o script sob teste) e Pillow (só para gerar as
imagens do corpus). O script sob teste não usa Pillow.

O venv do loopdetect é usado se existir, porque é o mesmo numpy que roda na
prática; senão cai no python3 do sistema.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(os.path.dirname(HERE), "image_dup.py")
VENV = os.path.expanduser("~/.local/share/loopdetect/venv/bin/python")

sys.path.insert(0, HERE)


def python_do_script():
    """Interpretador que tem numpy - o venv do loopdetect, ou o sistema."""
    if os.access(VENV, os.X_OK):
        if subprocess.run([VENV, "-c", "import numpy"],
                          capture_output=True).returncode == 0:
            return VENV
    p = shutil.which("python3")
    if not p:
        sys.exit("nenhum python3 no PATH")
    if subprocess.run([p, "-c", "import numpy"],
                      capture_output=True).returncode != 0:
        sys.exit("falta numpy. Crie o venv:\n"
                 "  python3 -m venv ~/.local/share/loopdetect/venv\n"
                 "  ~/.local/share/loopdetect/venv/bin/pip install numpy")
    return p


def casos(base, dirtmp):
    """(nome, imagem a salvar, exit esperado, kind esperado)."""
    import numpy as np
    from fixture import foto
    from PIL import Image, ImageFilter

    def salva(nome, im, q=95):
        p = os.path.join(dirtmp, nome)
        im.save(p, quality=q)
        return p

    W, H = base.size
    a = np.asarray(base).astype(np.float32)
    r = np.random.default_rng

    # (nome, caminho, exit esperado, kind esperado, shift esperado)
    # shift None = não checar; shift de 2 ints = conferir o campo "shift"
    out = []
    add = lambda n, im, rc, kind, q=95, shift=None: out.append(  # noqa: E731
        (n, salva(n, im, q), rc, kind, shift))

    def exif(orient):
        e = base.getexif()
        e[274] = orient
        return e

    def com_exif(nome, im, orient, rc, kind):
        p = os.path.join(dirtmp, nome)
        im.save(p, quality=95, exif=exif(orient))
        out.append((nome, p, rc, kind, None))

    # --- DUPLICATA: mesma foto, e a diferença é só o JPEG fazendo o que faz
    add("01_recompressao_q15.jpg", base, 0, "visual", q=15)
    add("02_recompressao_q60.jpg", base, 0, "visual", q=60)
    add("03_recompressao_q100.jpg", base, 0, "visual", q=100)
    com_exif("04_exif_deitada.jpg", base.transpose(Image.ROTATE_90), 6, 0, "visual")
    com_exif("05_exif_180.jpg", base.transpose(Image.ROTATE_180), 3, 0, "visual")
    com_exif("06_exif_espelhada.jpg", base.transpose(Image.FLIP_LEFT_RIGHT),
             2, 0, "visual")
    # Deslocada 2 px NÃO é duplicata, e isso é o certo: a borda dura foi
    # mexida, então uma imagem tem pixels que a outra não tem. O que este
    # caso verifica é o alinhamento - o --shift precisa achar o deslocamento
    # e reportá-lo, senão a estrutura inteira explodiria por causa de 2 px.
    # O sort do nome é o que faz o teste pegar este caso pelo filtro --so.
    add("zz_07_alinhamento_2px.jpg",
        Image.fromarray(np.pad(np.asarray(base), ((0, 0), (2, 0), (0, 0)),
                               mode="edge")[:, :-2]), 1, None, shift=[0, 2])

    # --- SEMELHANTE: mesma foto, com algo a mais, a menos ou diferente
    add("20_resize_50.jpg", base.resize((W // 2, H // 2)), 1, "resize")
    add("21_resize_200.jpg", base.resize((W * 2, H * 2)), 1, "resize")
    add("22_brilho_contraste.jpg",
        Image.fromarray(np.clip(a * 0.75 + 45, 0, 255).astype(np.uint8)),
        1, "tonal")
    add("23_grayscale.jpg", base.convert("L").convert("RGB"), 1, None)
    add("24_recorte_5pct.jpg",
        base.crop((20, 30, W - 20, H - 30)), 1, "crop")
    b = np.asarray(base).copy()
    b[H - int(H * .18):, W - int(W * .38):] = 255
    add("25_mancha_branca.jpg", Image.fromarray(b), 1, None)
    wm = np.asarray(base).copy()
    wm[int(H * .93):int(H * .97), int(W * .70):int(W * .99)] = 255
    add("26_marca_dagua.jpg", Image.fromarray(wm), 1, None)

    # kind "noise": a diferença está espalhada por todo canto mas é PEQUENA
    # em cada pixel - nenhum passa do NOISE_DELTA. É o que um desfoque faz.
    #
    # JPEG esmagado NÃO cai aqui: ele produz pixels grandes nos blocos, e
    # isso dispara "local_edit" antes. Medindo: q10 dá 2,4e-3 de fração de
    # pixels grandes, acima do BIG_MIN de 2e-3, então nunca chega no "noise".
    # O desfoque r=3 dá dist_norm 0,032, 2,2% de pixels mexidos e zero pixel
    # grande - bem no meio da faixa.
    add("27_desfocada.jpg", base.filter(ImageFilter.GaussianBlur(3)), 1, "noise")
    # Ruído de sensor forte: mesma faixa, por um caminho diferente. Vai em
    # PNG de propósito - em JPEG o proprio recompressor joga o ruído fora e
    # a fração de pixels mexidos cai abaixo de 2%, e o caso deixa de provar
    # o que se propõe a provar.
    p = os.path.join(dirtmp, "28_ruido_sensor.png")
    Image.fromarray(np.clip(
        a + r(4).normal(0, 7, a.shape), 0, 255).astype(np.uint8)).save(p)
    out.append(("28_ruido_sensor.png", p, 1, "noise", None))

    # --- DIFERENTE: nem é a mesma foto
    add("40_outra_foto.jpg", foto(seed=2), 1, None)
    add("41_outra_foto2.jpg", foto(seed=3), 1, None)
    add("42_metade_esquerda.jpg", base.crop((0, 0, W // 2, H)), 1, None)
    add("43_ruido.jpg", Image.fromarray(np.clip(
        a + r(1).normal(0, 25, a.shape), 0, 255).astype(np.uint8)), 1, None)
    add("44_espelhada.jpg", base.transpose(Image.FLIP_LEFT_RIGHT), 1, None)
    add("45_embaralhada.jpg", Image.fromarray(r(7).permutation(
        np.asarray(base).reshape(-1, 3), axis=0)
        .reshape(H, W, 3).astype(np.uint8)), 1, None)
    add("46_chapada_128.jpg", Image.new("RGB", (W, H), (128, 128, 128)), 1, None)
    add("47_chapada_140.jpg", Image.new("RGB", (W, H), (140, 140, 140)), 1, None)

    # --- o script com ele mesmo: byte a byte
    out.append(("50_consigo_mesma.jpg", os.path.join(dirtmp, "50_consigo_mesma.jpg"),
                0, "bytes", None))
    base.save(os.path.join(dirtmp, "50_consigo_mesma.jpg"), quality=95)
    return out


def roda(python, a, b):
    r = subprocess.run([python, SCRIPT, a, b, "--json"],
                       capture_output=True, text=True)
    js = None
    for linha in r.stdout.splitlines():
        if linha.startswith("@@JSON@@"):
            js = json.loads(linha[len("@@JSON@@"):])
    return r.returncode, js


def main():
    ap = argparse.ArgumentParser(description="testa o image_dup.py")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="mostra o motivo de cada caso")
    ap.add_argument("--so", metavar="GRUPO", choices=("dup", "nao"),
                    help="roda só as duplicatas (dup) ou só as que não são "
                         "(nao). Não há como separar 'semelhante' de "
                         "'diferente' por aqui: as duas saem com o mesmo 1")
    args = ap.parse_args()

    if not os.path.isfile(SCRIPT):
        sys.exit("não achei %s" % SCRIPT)
    try:
        import PIL  # noqa: F401
    except ImportError:
        sys.exit("falta Pillow, que é só para gerar as imagens do corpus:\n"
                 "  pip install Pillow")

    from fixture import foto

    python = python_do_script()
    tmp = tempfile.mkdtemp(prefix="imagedup-testes-")
    try:
        base = foto(seed=1)
        base_path = os.path.join(tmp, "00_base.jpg")
        base.save(base_path, quality=95)

        lista = casos(base, tmp)
        if args.so:
            lista = [c for c in lista
                     if (c[2] == 0) == (args.so == "dup")]

        print("script : %s" % SCRIPT)
        print("python  : %s" % python)
        print("corpus  : %s (%d casos)\n"
              % (tmp, len(lista)))

        print("%-26s %-4s %-6s %-8s %-10s %-9s %s"
              % ("caso", "exit", "saida", "bruta", "estrutura", "grandes%",
                 "kind"))
        print("-" * 96)

        falhas = []
        for nome, caminho, rc_esp, kind_esp, shift_esp in lista:
            rc, js = roda(python, base_path, caminho)
            ok = rc == rc_esp
            if ok and kind_esp is not None:
                ok = (js or {}).get("kind") == kind_esp
            if ok and shift_esp is not None:
                # O sinal é convenção do crop_pair (desloca A para um lado e B
                # para o outro), então o teste compara o módulo: o que importa
                # é que o script tenha achado 2 px, e não para que lado ele os
                # aplica.
                achou = list((js or {}).get("shift") or [])
                ok = (len(achou) == len(shift_esp) and
                      all(abs(x) == abs(y) for x, y in zip(achou, shift_esp)))
            if not ok:
                falhas.append((nome, rc_esp, kind_esp, shift_esp, rc, js))
            marca = "OK" if ok else "FALHA"
            print("%-26s %-4d %-6s %-8s %-10s %-9s %s%s"
                  % (nome[:26], rc_esp, marca,
                     (js or {}).get("dist_raw"), (js or {}).get("dist_norm"),
                     "%.4f" % (100 * ((js or {}).get("big_area") or 0)),
                     (js or {}).get("kind"), "" if ok else "   <<<"))
            if args.verbose and js:
                print("    %s" % (js.get("reason") or ""))

        print()
        if falhas:
            print("%d FALHA(S):" % len(falhas))
            for nome, rc_esp, kind_esp, shift_esp, rc, js in falhas:
                print("  %-26s esperava exit=%d kind=%s shift=%s;"
                      " saiu exit=%d kind=%s shift=%s"
                      % (nome, rc_esp, kind_esp, shift_esp, rc,
                         (js or {}).get("kind"), (js or {}).get("shift")))
            return 1
        print("Todos os %d casos bateram." % len(lista))
        return 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())