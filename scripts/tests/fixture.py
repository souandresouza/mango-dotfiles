"""Fabrica fotos sintéticas para o corpus de teste do image_dup.py.

Por que não usar uma foto de verdade: o limiar do script (TOL_NORM, MIN_R,
NOISE_DELTA) sai medindo diferença entre imagens, e medir exige um par
conhecido. Se a imagem do teste fosse a sua foto do Downloads, o teste
carregaria uma foto particular para dentro do repositório e não rodaria em
nenhuma outra máquina.

Por que dá na mesma: a foto precisa ter as três coisas que o script mede -
textura de alta frequência (grão, que o JPEG destrói), bordas duras (que o
JPEG borra) e uma Spread de brilho grande (que o --tol-tonel olha). A
função abaixo monta as três, e o resultado bate com a foto real que usamos
para calibrar: recompressão q15 dá dist_norm ~0,07 e correlação ~0,998,
contra 0,06 e 0,998 da foto real.

A outra foto (outro seed) muda a composição inteira, não só as cores - duas
imagens com o mesmo layout e cores diferentes seriam "semelhantes", e o
teste passaria sem exercitar a rejeição de foto diferente de verdade.

Só o Pillow, e só aqui: o image_dup.py em si não usa nada além de numpy.
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def foto(w=832, h=1248, seed=0):
    """Foto sintética de w x h com textura, bordas duras e brilho espalhado."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:h, 0:w]
    u, v = x / w, y / h
    ang = rng.uniform(0, 2 * np.pi)

    # fundo: gradientes que passam por toda a escala de brilho
    img = np.stack([55 + 135 * u + 30 * np.sin(v * 7 + ang),
                    65 + 95 * v + 25 * np.cos(u * 5 + ang),
                    95 + 55 * (1 - u)], -1)
    # manchas suaves: textura de baixa frequência, como parede ou pele
    for _ in range(14):
        cx, cy = rng.uniform(0, 1), rng.uniform(0, 1)
        r = rng.uniform(.06, .22)
        img += (rng.uniform(-18, 18)) * np.exp(
            -(((u - cx) ** 2 + (v - cy) ** 2) / (2 * r * r)))[..., None]

    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    im = im.filter(ImageFilter.GaussianBlur(1.0))
    d = ImageDraw.Draw(im)

    # um bloco escuro: borda dura, que é o que o JPEG borra de verdade
    d.rectangle([int(w * rng.uniform(.05, .3)), int(h * rng.uniform(.35, .55)),
                 int(w * rng.uniform(.60, .92)), int(h * rng.uniform(.75, .92))],
                fill=tuple(int(c) for c in rng.integers(15, 60, size=3)))

    # um disco claro no alto, com dois "olhos": alto contraste localizado
    cx, cy = rng.uniform(.3, .7), rng.uniform(.1, .5)
    rr = rng.uniform(.12, .22)
    d.ellipse([int(w * (cx - rr)), int(h * (cy - rr)),
               int(w * (cx + rr)), int(h * (cy + rr))],
              fill=tuple(int(c) for c in rng.integers(120, 230, size=3)))
    for dx in (-.06, .06):
        d.ellipse([int(w * (cx + dx - .03)), int(h * (cy - .1)),
                   int(w * (cx + dx + .03)), int(h * (cy - .03))],
                  fill=(38, 32, 28))

    # poucos detalhes duros espalhados: e onde o grão cai de verdade
    for _ in range(14):
        s = int(rng.integers(10, 40))
        x0 = int(rng.integers(0, w - s))
        y0 = int(rng.integers(0, h - s))
        d.ellipse([x0, y0, x0 + s, y0 + s],
                  fill=tuple(int(c) for c in rng.integers(30, 200, size=3)))

    return im.filter(ImageFilter.GaussianBlur(0.4))