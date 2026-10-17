#!/bin/bash
# ~/.config/scripts/random-wallpaper.sh

set -euo pipefail

# Configuração
WALLPAPER_DIR="$HOME/.config/wallpapers"
CACHE_DIR="$HOME/.cache/wallpapers"
HISTORY_FILE="$CACHE_DIR/wallpaper_history.txt"
CURRENT_WALLPAPER="$HOME/.cache/current_wallpaper.png"
HISTORY_SIZE=10

# ============================================
# FUNÇÕES
# ============================================

# Detecta resolução da tela (usado só para log; o swaybg usa "-m fill")
detect_resolution() {
    local res=""

    # MangoWM: IPC 'get all-monitors' -> {"monitors":[{"name":..,"width":..,"height":..,"active":true}]}
    local mango_pid
    mango_pid=$(pgrep -x mango 2>/dev/null | head -1)
    if [[ -n "$mango_pid" ]]; then
        local sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mango-${mango_pid}.sock"
        if [[ -S "$sock" ]]; then
            res=$(printf 'get all-monitors\n' | timeout 2 python3 -c '
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(1.5)
s.connect(sys.argv[1])
s.sendall(b"get all-monitors\n")
buf = b""
while not buf.endswith(b"\n"):
    c = s.recv(8192)
    if not c:
        break
    buf += c
sys.stdout.write(buf.decode(errors="replace"))
' "$sock" 2>/dev/null | jq -r '.monitors[] | select(.active) | "\(.width)x\(.height)"' 2>/dev/null | head -1)
        fi
    fi

    if [[ -z "$res" ]] && command -v wlr-randr &>/dev/null; then
        res=$(wlr-randr 2>/dev/null | grep -oP 'current mode: \K\d+x\d+' | head -1)
    fi

    echo "${res:-desconhecida}"
}

# Verifica e cria diretórios necessários
ensure_directories() {
    mkdir -p "$CACHE_DIR"
    mkdir -p "$(dirname "$CURRENT_WALLPAPER")"
    touch "$HISTORY_FILE"
}

# Obtém o wallpaper atual do histórico
get_current_wallpaper() {
    if [[ -f "$HISTORY_FILE" ]]; then
        head -n 1 "$HISTORY_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Lista todos os wallpapers disponíveis
list_available_wallpapers() {
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        return 1
    fi

    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" \
        -o -iname "*.png" -o -iname "*.gif" \
        -o -iname "*.webp" -o -iname "*.bmp" \
    \) -print0 2>/dev/null | sort -z | xargs -0 -n1 echo
}

# Seleciona wallpaper aleatório diferente do atual
select_wallpaper() {
    local all_wallpapers=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && all_wallpapers+=("$file")
    done < <(list_available_wallpapers)

    if [[ ${#all_wallpapers[@]} -eq 0 ]]; then
        echo "❌ Nenhum wallpaper encontrado em: $WALLPAPER_DIR" >&2
        return 1
    fi

    echo "📸 Encontrados ${#all_wallpapers[@]} wallpapers" >&2

    local current=$(get_current_wallpaper)
    if [[ -n "$current" ]]; then
        echo "🖼️  Wallpaper atual: $(basename "$current")" >&2
    fi

    # Remove o wallpaper atual da lista
    local available=()
    for w in "${all_wallpapers[@]}"; do
        [[ "$w" != "$current" ]] && available+=("$w")
    done

    # Se não há wallpapers diferentes, usa qualquer um
    if [[ ${#available[@]} -eq 0 ]]; then
        available=("${all_wallpapers[@]}")
    fi

    local idx=$((RANDOM % ${#available[@]}))
    local selected="${available[$idx]}"
    echo "🎯 Selecionado: $(basename "$selected")" >&2
    echo "$selected"
}

# Atualiza o histórico
update_history() {
    local wallpaper="$1"

    echo "📝 Atualizando histórico..." >&2

    local history_lines=()
    if [[ -f "$HISTORY_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && history_lines+=("$line")
        done < <(tail -n +2 "$HISTORY_FILE" 2>/dev/null | head -n $((HISTORY_SIZE - 1)))
    fi

    {
        echo "$wallpaper"
        printf '%s\n' "${history_lines[@]}"
    } > "$HISTORY_FILE"

    echo "✅ Histórico atualizado" >&2
}

# Aplica wallpaper
apply_wallpaper() {
    local wallpaper="$1"

    if [[ ! -f "$wallpaper" ]]; then
        echo "❌ Wallpaper não encontrado: $wallpaper" >&2
        return 1
    fi

    pkill -x swaybg 2>/dev/null || true

    if command -v swaybg &>/dev/null; then
        swaybg -i "$wallpaper" -m fill 2>/dev/null &
        echo "✅ Wallpaper aplicado com swaybg" >&2
        return 0
    fi

    if command -v feh &>/dev/null; then
        feh --bg-fill "$wallpaper" 2>/dev/null
        echo "✅ Wallpaper aplicado com feh" >&2
        return 0
    fi

    echo "❌ Nenhum backend encontrado" >&2
    return 1
}

# ============================================
# MAIN
# ============================================

main() {
    echo "🚀 Iniciando troca de wallpaper..." >&2

    ensure_directories

    SELECTED=$(select_wallpaper)

    if [[ -z "$SELECTED" ]]; then
        echo "❌ Falha ao selecionar wallpaper" >&2
        exit 1
    fi

    echo "📌 Aplicando: $(basename "$SELECTED")" >&2

    RESOLUTION=$(detect_resolution)
    echo "🖥️  Resolução: $RESOLUTION" >&2

    apply_wallpaper "$SELECTED"

    update_history "$SELECTED"

    # Cria cópia do wallpaper
    cp "$SELECTED" "$CURRENT_WALLPAPER" 2>/dev/null || true

    # sequencia.sh gera a paleta (ruwall) e depois chama os 10 scripts de cor,
    # que escrevem os arquivos de tema de cada app e os recarregam.
    "$HOME/.local/bin/sequencia.sh" "$SELECTED"
    echo "✨ Concluído!" >&2
}

# Executa
main "$@"
