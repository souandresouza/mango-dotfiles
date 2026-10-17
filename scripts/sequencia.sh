#!/usr/bin/env bash
# Aplica o tema inteiro a partir de um wallpaper, usando o ruwall.
#
# 1) `ruwall -c` limpa ~/.cache/wal/schemes e `ruwall -i` gera a paleta em
#    ~/.cache/wal (colors.css, colors-waybar.css, colors-kitty.conf, ...).
#    Esse diretorio e a fonte de verdade do tema.
# 2) os 10 scripts em ~/.local/bin reparseiam o mesmo ~/.cache/wal/colors.css e
#    escrevem o arquivo de cada app, recarregando o app quando ele esta vivo.
#
# Ferramenta: ruwall por padrao, sobrescreva com PALETTE_TOOL=wal para voltar
# ao pywal sem editar nada. pywal esta arquivado no GitHub (ultimo commit em
# 2021-09-09) e era a opcao ate aqui; o ruwall e um porte em Rust com a mesma
# CLI e o mesmo cache. Ver o bloco da PALETTE_TOOL mais abaixo.
#
# Por que `-c` antes: tanto o pywal quanto o ruwall cacheiam esquema por
# CAMINHO em ~/.cache/wal/schemes/, nao por conteudo. Como o
# random-wallpaper.sh passa a imagem por um caminho fixo em varios casos, a
# paleta anterior daquele caminho seria reusada. `-c` e o que garante que a
# paleta sempre corresponda ao wallpaper atual.
#
# Sem argumento, usa a imagem que o swaybg esta exibindo (caminho real do
# wallpaper); se o swaybg nao estiver rodando, cai para
# ~/.cache/current_wallpaper.png. Com argumento, gera a paleta desse arquivo.
#
# Flag -n: nao deixa a ferramenta mexer no wallpaper (quem aplica o fundo e o
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

# pywal esta arquivado no GitHub desde 2021 (ultimo commit 2021-09-09), sem
# correcao ha 5 anos. O ruwall e um porte em Rust, mesmo cache em
# ~/.cache/wal e mesma interface de linha de comando, entao trocar aqui e
# trocar duas linhas. Para voltar: e so repor o `wal` nas duas linhas abaixo
# e o filtro de stderr que vinha depois.
#
# A busca e pelo mesmo diretorio deste script, e nao pelo PATH: os scripts de
# cor abaixo ja sao chamados por caminho absoluto, e depender do PATH
# quebrava em shell nao-login e em servico agendado. O PATH segue como
# fallback, caso a ferramenta esteja instalada em outro lugar.
PALETTE_TOOL="${PALETTE_TOOL:-ruwall}"
_here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
if [[ -x "$_here/$PALETTE_TOOL" ]]; then
    PALETTE="$_here/$PALETTE_TOOL"
elif command -v "$PALETTE_TOOL" >/dev/null 2>&1; then
    PALETTE="$(command -v "$PALETTE_TOOL")"
else
    echo "sequencia: $PALETTE_TOOL nao encontrado" >&2
    echo "  procurado em: $_here/ e no PATH" >&2
    echo "  ruwall: https://github.com/souandresouza/ruwall" >&2
    echo "  pywal (fallback): sudo pacman -S python-pywal" >&2
    exit 1
fi

echo "sequencia: paleta a partir de $WALLPAPER (via $PALETTE)"

# -c remove o cache de esquemas e sai; so depois dele o -i reanalisa a imagem.
"$PALETTE" -c
# -n: nao deixa a ferramenta trocar o wallpaper (quem aplica o fundo e o swaybg).
# -e: pula reload.env() e reload.gtk(). Nesse setup nao ha nada para recarregar
# nessa lista: xrdb e X11, i3/sway/polybar nao sao usados (o compositor e o
# MangoWM). O kitty, que era o unico relevante, e recarregado pelos nossos
# proprios scripts.
#
# Sem filtro de stderr aqui: o backend do pywal chamava `magick convert` e o
# ImageMagick 7 respondia "convert command is deprecated in IMv7" a cada
# execucao, aviso que nao dava para remover sem editar o pacote (que some em
# qualquer update). O ruwall nao depende do ImageMagick, entao o aviso deixou
# de existir e o filtro tambem.
"$PALETTE" -n -e -i "$WALLPAPER" || exit 1

for app in cava cadroc kitty fuzzel mango qbittorrent waybar zathura swaylock swaync; do
    "$HOME/.local/bin/${app}-colors.sh"
done