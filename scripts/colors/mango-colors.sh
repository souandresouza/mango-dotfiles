#!/bin/sh
# ~/.config/scripts/colors/mango-colors.sh
# Gera configuração de cores do Mango baseado no wallpaper atual (via Pywal)

COLORS_FILE="$HOME/.cache/wal/colors.css"
MANGO_FILE="$HOME/.config/mango/theme.conf"

if [ ! -f "$COLORS_FILE" ]; then
    echo "ERRO: sem paleta em $COLORS_FILE"
    echo "Gere uma com:"
    echo "  ~/.local/bin/sequencia.sh            # usa o wallpaper atual"
    echo "  ~/.local/bin/sequencia.sh <imagem>   # de um arquivo"
    echo "  (PALETTE_TOOL=wal volta ao pywal)"
    echo "Sem paleta em ~/.cache/wal. Gere uma com:"
    echo "  ~/.local/bin/sequencia.sh            # usa o wallpaper atual"
    echo "  ~/.local/bin/sequencia.sh <imagem>   # de um arquivo"
    echo "  (ou PALETTE_TOOL=wal para voltar ao pywal)"
    exit 1
fi

# Extrair cores do formato Pywal/CSS (--color0: #xxx;)
extract_color() {
    grep -- "--color$1:" "$COLORS_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '; '
}

# Extrair também background, foreground e cursor
background=$(grep -- "--background:" "$COLORS_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '; ')
foreground=$(grep -- "--foreground:" "$COLORS_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '; ')
cursor=$(grep -- "--cursor:" "$COLORS_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '; ')

# Extrair cores 0-15
color0=$(extract_color 0)
color1=$(extract_color 1)
color2=$(extract_color 2)
color3=$(extract_color 3)
color4=$(extract_color 4)
color5=$(extract_color 5)
color6=$(extract_color 6)
color7=$(extract_color 7)
color8=$(extract_color 8)
color9=$(extract_color 9)
color10=$(extract_color 10)
color11=$(extract_color 11)
color12=$(extract_color 12)
color13=$(extract_color 13)
color14=$(extract_color 14)
color15=$(extract_color 15)

# Limpar cores (remover #, colchetes, espaços e outros caracteres especiais)
clean_color() {
    echo "$1" | sed 's/[^a-fA-F0-9]//g'
}

# Limpar todas as cores
background=$(clean_color "$background")
foreground=$(clean_color "$foreground")
cursor=$(clean_color "$cursor")
color0=$(clean_color "$color0")
color1=$(clean_color "$color1")
color2=$(clean_color "$color2")
color3=$(clean_color "$color3")
color4=$(clean_color "$color4")
color5=$(clean_color "$color5")
color6=$(clean_color "$color6")
color7=$(clean_color "$color7")
color8=$(clean_color "$color8")
color9=$(clean_color "$color9")
color10=$(clean_color "$color10")
color11=$(clean_color "$color11")
color12=$(clean_color "$color12")
color13=$(clean_color "$color13")
color14=$(clean_color "$color14")
color15=$(clean_color "$color15")

# Verificar se as cores foram extraídas
if [ -z "$color0" ] || [ -z "$background" ] || [ -z "$foreground" ]; then
    echo "ERRO: a paleta em $COLORS_FILE não tem cores utilizáveis."
    echo "Regere com: ~/.local/bin/sequencia.sh"
    exit 1
fi

mkdir -p "$(dirname "$MANGO_FILE")"

# Criar configuração com alpha ff
cat > "$MANGO_FILE" << EOF
shadows_color= 0x${color0}ff
root_color=0x${color0}ff
border_color=0x${color6}ff
drop_color=0x${color6}55
split_color=0x${color14}ff
focus_color=0x${color5}ff
maximized_screen_color=0x${color6}ff
urgent_color=0x${color7}ff
scratchpad_color=0x${color13}ff
global_color=0x${color5}ff
overlay_color=0x${color14}ff
EOF

echo "✅ Configuração gerada em $MANGO_FILE"

# Recarrega o Mango se estiver em execução
if command -v mangoctl &>/dev/null; then
    mangoctl reload 2>/dev/null || true
else
    echo "⚠️  mangoctl não encontrado, configuração será aplicada no próximo início."
fi
