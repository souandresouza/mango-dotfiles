#!/usr/bin/env bash

# Recarrega a configuração do MangoWM.
#
# O Mango não expõe IPC de reload (o socket só aceita comandos como
# exec/spawn/kill) e NÃO trata nenhum sinal de reload — SIGHUP encerra o
# compositor abruptamente. Ele recarrega sozinho via 'auto_reload_config',
# que observa os arquivos de config. Então aqui só validamos e informamos.

if pgrep -x mango >/dev/null; then
    echo "ℹ️  Mango recarrega sozinho via auto_reload_config (nenhum sinal necessário)."
    echo "   Para validar a config: mango -p -c ~/.config/mango/config.conf"
else
    echo "⚠️  Mango não está em execução, configuração será aplicada no próximo início."
    exit 1
fi