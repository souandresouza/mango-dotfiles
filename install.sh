#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

step_title() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local answer

    while true; do
        read -p "$prompt (y/n): " answer
        case "$answer" in
            y|Y|yes|Yes|YES)
                return 0
                ;;
            n|N|no|No|NO)
                return 1
                ;;
            *)
                echo "Por favor, responda 'y' ou 'n'"
                ;;
        esac
    done
}

# ============================================================================
# BLOCK 1: CHECK AND INSTALL DEPENDENCIES (yay, git, curl)
# ============================================================================
step_title "1 - VERIFICAR E INSTALAR DEPENDÊNCIAS (yay, git, curl)"

# Verifica se o pacman está disponível
if ! command -v pacman >/dev/null 2>&1; then
    log_error "Você não está em uma distribuição baseada em Arch."
    log_error "Instale os pacotes necessários manualmente."
    exit 1
fi

# Instala git e curl se estiverem ausentes
if ! command -v git >/dev/null 2>&1; then
    log_info "Instalando git..."
    sudo pacman -S --needed git
fi

if ! command -v curl >/dev/null 2>&1; then
    log_info "Instalando curl..."
    sudo pacman -S --needed curl
fi

# Instala yay se estiver ausente
if command -v yay >/dev/null 2>&1; then
    log_ok "yay está instalado."
else
    if ask_yes_no "===> Deseja instalar o yay agora?"; then
        log_info "Clonando yay do AUR..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        log_ok "yay foi instalado com sucesso."
    else
        log_warn "Você precisa do yay para a instalação automática de pacotes."
        exit 1
    fi
fi

# ============================================================================
# BLOCK 2: VERIFICAR DOTFILES E INSTALAR PACOTES
# ============================================================================
step_title "2 - VERIFICAR DOTFILES E INSTALAR PACOTES DAS LISTAS"

DOTFILES="$HOME/mango-dotfiles"

# Verifica se o diretório de dotfiles existe
if [[ ! -d "$DOTFILES" ]]; then
    log_warn "Diretório de dotfiles não encontrado em $DOTFILES"
    if ask_yes_no "===> Clonar dotfiles do repositório?"; then
        read -p "Insira a URL do repositório (padrão: https://github.com/souandresouza/mango-dotfiles): " REPO_URL
        REPO_URL="${REPO_URL:-https://github.com/souandresouza/mango-dotfiles}"
        git clone "$REPO_URL" "$DOTFILES"
    else
        log_error "Dotfiles são obrigatórios. Saindo."
        exit 1
    fi
fi

# Instala pacotes das listas
if [[ -f "$DOTFILES/lista_pacman.txt" ]]; then
    log_info "Instalando pacotes dos repositórios oficiais..."
    # shellcheck disable=SC2046
    sudo pacman -S --needed --noconfirm $(cat "$DOTFILES/lista_pacman.txt")
    log_ok "Pacotes oficiais instalados."
else
    log_warn "lista_pacman.txt não encontrada em $DOTFILES"
fi

if [[ -f "$DOTFILES/lista_aur.txt" ]]; then
    log_info "Instalando pacotes do AUR..."
    # shellcheck disable=SC2046
    yay -S --needed --noconfirm $(cat "$DOTFILES/lista_aur.txt")
    log_ok "Pacotes do AUR instalados."
else
    log_warn "lista_aur.txt não encontrada em $DOTFILES"
fi

# ============================================================================
# BLOCK 3: COPY DOTFILES
# ============================================================================
step_title "3 - COPIAR DOTFILES"

# Cria o diretório de configuração
mkdir -p "$HOME/.config"

# Fazer backup de configurações existentes
backup_dir="$HOME/.config/mango-dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

CONFIG_DIRS=(cava fastfetch fuzzel mango kitty music-tui scripts mako wallpapers waybar zathura)

for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$DOTFILES/$dir" ]]; then
        # Backup da configuração existente, se houver
        if [[ -e "$HOME/.config/$dir" ]]; then
            mkdir -p "$backup_dir"
            mv "$HOME/.config/$dir" "$backup_dir/$dir"
            log_info "Backup de '$dir' criado em $backup_dir"
        fi
        cp -r "$DOTFILES/$dir" "$HOME/.config/"
        log_ok "Copiado $dir"
    else
        log_warn "$dir não encontrado nos dotfiles"
    fi
done

copy_user_image() {
    if [[ -f "$DOTFILES/assets/user.png" ]]; then
        cp "$DOTFILES/assets/user.png" "${XDG_DOCUMENTS_DIR:-$HOME/Documentos}/user.png"
        log_ok "Imagem de usuário copiada com sucesso!"
    else
        log_warn "Imagem não encontrada em $DOTFILES/assets/user.png"
    fi
}

# ============================================================================
# BLOCK 4: SET PERMISSIONS
# ============================================================================
step_title "4 - DEFINIR PERMISSÕES"

log_info "Definindo permissões de execução..."

# Scripts
chmod +x "$HOME/.config/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/scripts/colors"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/mango/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts"/*.py 2>/dev/null || true

log_ok "Permissões definidas"

# ============================================================================
# BLOCK 5: FINALIZAÇÃO
# ============================================================================
step_title "5 - FINALIZAÇÃO"

copy_user_image

if [[ -n "${backup_dir:-}" && -d "$backup_dir" ]]; then
    log_warn "Configurações antigas foram movidas para: $backup_dir"
    log_warn "Revise e exclua este diretório quando estiver satisfeito."
fi

log_ok "Instalação concluída com sucesso!"
