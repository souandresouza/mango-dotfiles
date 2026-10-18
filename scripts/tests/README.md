# Testes do image_dup.py

Roda o `image_dup.py` como subprocesso e confere o código de saída e o
`kind` do JSON.

```sh
scripts/tests/run.py           # tudo
scripts/tests/run.py -v        # mostra o motivo de cada caso
scripts/tests/run.py --so dup  # só as duplicatas
```

Testar as funções de dentro passaria, mas deixaria passar por cima do que
mais quebrou aqui: o reshape dos pixels, a rotação por EXIF e o contrato
`@@JSON@@` que o loopgui consome. Por isso o teste vai pelo executável.

## Dependências

- **numpy** — precisa porque é o que roda o script sob teste. Usa o venv do
  loopdetect se existir, senão o `python3` do sistema.
- **Pillow** — só para gerar as imagens do corpus. O `image_dup.py` em si
  não usa nada além de numpy.

## O corpus é sintético

`fixture.py` fabrica as fotos, e não usa nenhuma foto de verdade. Duas
razões:

A primeira é privada — a foto que calibrou os limiares era uma do
Downloads. Testar com ela levaria uma foto particular para dentro do
repositório, e o teste não rodaria em nenhuma outra máquina.

A segunda é que dá na mesma. A foto precisa ter as três coisas que o script
mede: textura de alta frequência (que o JPEG destrói), bordas duras (que o
JPEG borra) e uma escala de brilho grande (que o `--tol-tonal` olha). A
função monta as três, e o resultado bate com a foto real: recompressão em
q15 dá `dist_norm` 0,079 contra 0,062 da foto que calibrou.

`foto(seed=N)` com seed diferente muda a composição inteira, não só as
cores. Duas imagens com o mesmo layout e cores diferentes seriam
"semelhantes", e o teste passaria sem exercitar a rejeição de foto
diferente de verdade.

O corpus é montado num diretório temporário e apagado no fim. Nada é
escrito no repositório.

## Sobre o limiar

Os limiares (`TOL_NORM`, `MIN_R`, `NOISE_DELTA`, `NOISE_MAX`, `BIG_MIN`)
foram escolhidos medindo este corpus. Mudou o comportamento, mexa no
número **e** no caso de teste que representa aquele comportamento — senão os
dois passam a mentir junto, e o teste vira parte do problema.