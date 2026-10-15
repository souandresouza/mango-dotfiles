#!/usr/bin/env bash
# Reaplica o tema a partir de um wallpaper, usando matugen.
#
# Substitui a versao anterior, que rodava 9 scripts isolados, cada um
# reparseando o mesmo ~/.cache/wal/colors.css. Agora um unico comando gera
# os 10 arquivos e ja recarrega os apps pelos post_hook do config.toml.
#
# Sem argumento, reaplica a partir do wallpaper atual em cache.
# Com argumento, gera a paleta a partir desse arquivo.

set -u

WALLPAPER="${1:-$HOME/.cache/current_wallpaper.png}"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "sequencia: wallpaper nao encontrado: $WALLPAPER" >&2
    exit 1
fi

if ! command -v matugen >/dev/null 2>&1; then
    echo "sequencia: matugen nao instalado" >&2
    exit 1
fi

# --prefer evita a pergunta interativa quando a imagem tem varias cores
# dominantes (o matugen 4.2.0 aborta sem isso fora de um terminal real).
exec matugen image "$WALLPAPER" \
    --prefer "${MATUGEN_PREFER:-saturation}" \
    --mode "${MATUGEN_MODE:-dark}"