#!/bin/bash
# Módulo waybar para cmus
# Detecta se o cmus está tocando e exibe informações

# Função para escapar caracteres especiais para markup GTK
escape_markup() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    echo "$text"
}

# Verifica se cmus está rodando
if ! pgrep -x "cmus" > /dev/null; then
    echo ""
    exit 0
fi

# Obtém status do cmus via cmus-remote
STATUS=$(cmus-remote -Q 2>/dev/null | grep "^status " | awk '{print $2}')
TITLE=$(cmus-remote -Q 2>/dev/null | grep "^tag title " | cut -d' ' -f3-)
ARTIST=$(cmus-remote -Q 2>/dev/null | grep "^tag artist " | cut -d' ' -f3-)

# Se não conseguir obter metadados, exibe status genérico
if [ -z "$TITLE" ]; then
    TITLE="Desconhecido"
fi
if [ -z "$ARTIST" ]; then
    ARTIST="Desconhecido"
fi

# Escapa caracteres especiais
TITLE=$(escape_markup "$TITLE")
ARTIST=$(escape_markup "$ARTIST")
STATUS=$(escape_markup "$STATUS")

# Formata saída para waybar
case "$STATUS" in
    "playing")
        ICON=""
        ;;
    "paused")
        ICON="⏸"
        ;;
    *)
        ICON="⏹"
        ;;
esac

# Retorna apenas o texto formatado (não JSON)
echo "$ICON $TITLE - $ARTIST"
