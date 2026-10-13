#!/usr/bin/env bash
# unlock.sh — chamado pelo swayidle após o desbloqueio
# Reativa as notificações (mako não é mais usado; SwayNC usa --dnd-off).
swaync-client --dnd-off >/dev/null 2>&1 || :
exit 0
