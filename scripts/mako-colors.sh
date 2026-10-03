#!/bin/bash
# Gera config do mako com cores do pywal

WAL_COLORS="$HOME/.cache/wal/colors"
MAKO_CONFIG="$HOME/.config/mako/config"

if [[ ! -f "$WAL_COLORS" ]]; then
    echo "Pywal colors not found. Run 'wal -i <wallpaper>' first." >&2
    exit 1
fi

# Cores do pywal
BACKGROUND=$(sed -n '1p' "$WAL_COLORS" | tr -d '#')
FOREGROUND=$(sed -n '2p' "$WAL_COLORS" | tr -d '#')
COLOR1=$(sed -n '3p' "$WAL_COLORS" | tr -d '#')

# Gera config temporário
cat > "${MAKO_CONFIG}.tmp" << EOF
sort=-time
layer=top
anchor=top-right
width=300
margin=12
height=250
border-size=4
border-radius=8
padding=20
icons=1
icon-location=left
markup=1
max-icon-size=64
default-timeout=5000
ignore-timeout=1
font=JetBrainsMono Nerd Font 10
text-alignment=center
max-visible=5

[urgency=normal]
background-color=#${BACKGROUND}
text-color=#${FOREGROUND}
border-color=#${COLOR1}

[urgency=high]
background-color=#${BACKGROUND}
text-color=#${FOREGROUND}
border-color=#${COLOR1}

[urgency=critical]
background-color=#${BACKGROUND}
text-color=#${FOREGROUND}
border-color=#${COLOR1}
EOF

# Substitui config
mv "${MAKO_CONFIG}.tmp" "$MAKO_CONFIG"

# Reinicia mako
pkill -x mako 2>/dev/null || true
mako &
