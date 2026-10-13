#!/usr/bin/env bash

# Ajusta o brilho (brightnessctl) e mostra um OSD via notify-send (swaync) com barra de progresso.

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || -z "${1:-}" ]]; then
    cat <<'EOF'
Usage: brightness_osd.sh [+N | -N]
Raise / lower screen brightness by N percent and show an on-screen notification.

Options:
    -h, --help          Show this help message
EOF
    exit 0
fi

command -v brightnessctl >/dev/null 2>&1 || { notify-send -u critical "Brilho" "brightnessctl não encontrado"; exit 1; }

MIN_PERCENT=1   # nunca apaga totalmente a tela pelas teclas
SYNC_HINT="string:x-canonical-private-synchronous:osd-brightness"

case "$1" in
    +[0-9]*) step="${1#+}"; brightnessctl -q set "+${step}%" ;;
    -[0-9]*) step="${1#-}"; brightnessctl -q set "${step}%-" ;;
    *) echo "Argumento inválido: $1" >&2; exit 1 ;;
esac

IFS=, read -r _ _ _ value _ < <(brightnessctl -m)
percent="${value%\%}"

if (( percent < MIN_PERCENT )); then
    brightnessctl -q set "${MIN_PERCENT}%"
    percent=$MIN_PERCENT
fi

notify-send -t 2000 -h "$SYNC_HINT" -u low -i display-brightness-symbolic \
    -h "int:value:$percent" "Brilho: ${percent}%"
