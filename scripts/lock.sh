#!/usr/bin/env bash
# lock.sh — wrapper de bloqueio adaptado de srgvg/dotfiles (bin/swayidle.sh + bin/swaylock-image.sh)
# - debounce: ignora rajadas de sinal de lock (ex.: fonte desconhecida disparando ~25 sinais/s)
# - não empilha swaylock se já estiver rodando
# - pausa notificações (mako mode) durante o bloqueio
# - usa a config em ~/.config/swaylock/config (screenshot+blur+pywal); fallback p/ fundo preto

set -u

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/swayidle"
mkdir -p "$STATE_DIR"
DEBOUNCE_FILE="$STATE_DIR/lock-debounce"
DEBOUNCE_SECONDS=2

# debounce
if [ -f "$DEBOUNCE_FILE" ]; then
    last=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo 0)
    now=$(date +%s)
    elapsed=$((now - last))
    if [ "$elapsed" -lt "$DEBOUNCE_SECONDS" ]; then
        echo "lock (ignorado: debounce, ${elapsed}s desde o último)"
        exit 0
    fi
fi

# já bloqueado?
if pgrep -x swaylock >/dev/null; then
    echo "lock (ignorado: swaylock já está rodando)"
    exit 0
fi

date +%s >"$DEBOUNCE_FILE"

# pausa notificações (best-effort; requer seção [mode=do-not-disturb] no mako, se quiser efeito real)
makoctl mode -a do-not-disturb 2>/dev/null || :

# swaylock: tenta a config completa; se falhar no primeiro segundo, cai para fundo preto simples
if ! swaylock -f "$@"; then
    swaylock -f -c 000000 "$@"
fi
