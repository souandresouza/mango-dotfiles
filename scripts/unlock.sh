#!/usr/bin/env bash
# unlock.sh — chamado pelo swayidle após o desbloqueio
makoctl mode -r do-not-disturb 2>/dev/null || :
exit 0
