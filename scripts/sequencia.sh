#!/usr/bin/env bash
# Aplica o tema inteiro a partir de um wallpaper, usando python-pywal.
#
# 1) `wal -c` limpa ~/.cache/wal/schemes e `wal -i` gera a paleta em
#    ~/.cache/wal (colors.css, colors-waybar.css, colors-kitty.conf, ...).
#    Esse diretorio e a fonte de verdade do tema.
# 2) os 9 scripts em ~/.local/bin reparseiam o mesmo ~/.cache/wal/colors.css e
#    escrevem o arquivo de cada app, recarregando o app quando ele esta vivo.
#
# Por que `wal -c` antes: o pywal cacheia esquema por CAMINHO em
# ~/.cache/wal/schemes/, nao por conteudo. Como o random-wallpaper.sh passa a
# imagem por um caminho fixo em varios casos, o pywal reusaria a paleta da
# imagem anterior daquele caminho. `-c` e o que garante que a paleta sempre
# corresponda ao wallpaper atual.
#
# Sem argumento, usa a imagem que o swaybg esta exibindo (caminho real do
# wallpaper); se o swaybg nao estiver rodando, cai para
# ~/.cache/current_wallpaper.png. Com argumento, gera a paleta desse arquivo.
#
# Flag do pywal: -n nao deixa o wal mexer no wallpaper (quem aplica o fundo e o
# swaybg, via random-wallpaper.sh).

set -u

# Caminho da imagem que o swaybg esta exibindo agora.
wallpaper_do_swaybg() {
    local pid
    pid="$(pgrep -x swaybg | head -1)"
    [[ -n "$pid" ]] || return 1
    # cmdline do swaybg: "swaybg" "-i" "<imagem>" ... (o arg vem depois do -i).
    tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null |
        awk 'p {print; exit} /^-i$|^--image$/ {p=1}'
}

WALLPAPER="${1:-$(wallpaper_do_swaybg)}"
WALLPAPER="${WALLPAPER:-$HOME/.cache/current_wallpaper.png}"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "sequencia: wallpaper nao encontrado: $WALLPAPER" >&2
    exit 1
fi

if ! command -v wal >/dev/null 2>&1; then
    echo "sequencia: pywal nao instalado (pacote python-pywal)" >&2
    exit 1
fi

echo "sequencia: paleta a partir de $WALLPAPER"

# -c remove o cache de esquemas e sai; so depois dele o -i reanalisa a imagem.
wal -c
# -n: nao deixa o wal trocar o wallpaper (quem aplica o fundo e o swaybg).
# -e: pula reload.env() e reload.gtk(). Nesse setup nao ha nada para recarregar
# nessa lista: xrdb e X11, i3/sway/polybar nao sao usados (o compositor e o
# MangoWM) e o reload.gtk() do pywal ainda depende de python2, o que so gerava
# o aviso "GTK2 reload support requires Python 2". O kitty, que era o unico
# relevante, e recarregado pelos nossos proprios scripts.
#
# Filtro no stderr: o backend padrao do pywal (backends/wal.py) chama
# `magick convert`, e o ImageMagick 7 responde "The convert command is
# deprecated in IMv7" a cada execucao. O aviso e upstream e sempre o mesmo, e
# nao ha como remove-lo sem editar o pacote (que some em qualquer update do
# python-pywal). Qualquer outro erro do wal continua aparecendo.
wal -n -e -i "$WALLPAPER" 2> >(grep -v "convert command is deprecated in IMv7") || exit 1

for app in cava cadroc kitty fuzzel mango qbittorrent waybar zathura swaylock swaync; do
    "$HOME/.local/bin/${app}-colors.sh"
done