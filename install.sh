#!/usr/bin/env bash
#
# MangoWM Dotfiles — Automated Installer
# Replicates the full configuration on a fresh Arch Linux install.
#
# Usage:
#   ./install.sh              Full install
#   ./install.sh --dry-run    Preview changes without executing
#   ./install.sh --skip-packages   Only copy dotfiles, skip package installation
#

set -euo pipefail

# ── Flags ────────────────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_PACKAGES=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)        DRY_RUN=true ;;
        --skip-packages)  SKIP_PACKAGES=true ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run          Preview changes without executing"
            echo "  --skip-packages    Skip package installation, only copy dotfiles"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
BIN_DIR="${HOME}/.local/bin"
WALLPAPER_DIR="${HOME}/.config/wallpapers"

PACMAN_LIST="${SCRIPT_DIR}/lista_pacman.txt"
AUR_LIST="${SCRIPT_DIR}/lista_aur.txt"

# ── Functions ─────────────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[${NC}${BOLD}INFO${NC}${BLUE}]${NC} $*"; }
success() { echo -e "${GREEN}[${NC}${BOLD} OK ${NC}${GREEN}]${NC} $*"; }
warn()    { echo -e "${YELLOW}[${NC}${BOLD}WARN${NC}${YELLOW}]${NC} $*"; }
error()   { echo -e "${RED}[${NC}${BOLD}FAIL${NC}${RED}]${NC} $*"; }
header()  { echo -e "\n${CYAN}${BOLD}═══ $* ═══${NC}\n"; }

run() {
    if $DRY_RUN; then
        info "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

confirm() {
    local prompt="${1:-Are you sure?}"
    if $DRY_RUN; then
        info "[DRY-RUN] Would ask: $prompt"
        return 0
    fi
    local response
    echo -ne "${YELLOW}[?]${NC} ${prompt} [y/N] "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

check_command() {
    command -v "$1" &>/dev/null
}

# ── Package Installation ─────────────────────────────────────────────────────

install_pacman_packages() {
    header "Installing Official Packages"

    if [[ ! -f "$PACMAN_LIST" ]]; then
        error "Package list not found: $PACMAN_LIST"
        exit 1
    fi

    run "sudo pacman -Syu --needed - < $PACMAN_LIST"
    success "Official packages installed."
}

install_yay() {
    header "Installing AUR Helper (yay)"

    if check_command yay; then
        success "yay already installed."
        return
    fi

    info "Cloning and building yay..."
    local tmpdir
    tmpdir="$(mktemp -d)"
    run "git clone https://aur.archlinux.org/yay.git $tmpdir/yay"
    if ! $DRY_RUN; then
        cd "$tmpdir/yay"
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
    fi
    run "rm -rf $tmpdir"
    success "yay installed."
}

install_aur_packages() {
    header "Installing AUR Packages"

    if [[ ! -f "$AUR_LIST" ]]; then
        warn "AUR package list not found: $AUR_LIST"
        return
    fi

    run "yay -Syu --needed - < $AUR_LIST"
    success "AUR packages installed."
}

# ── Directory Setup ──────────────────────────────────────────────────────────

create_directories() {
    header "Creating Directories"

    local dirs=(
        "$CONFIG_DIR"
        "$BIN_DIR"
        "$WALLPAPER_DIR"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            run "mkdir -p $dir"
            success "Created: $dir"
        else
            info "Exists:   $dir"
        fi
    done
}

# ── Config Copying ───────────────────────────────────────────────────────────

copy_configs() {
    header "Copying Configuration Files"

    local configs=(
        mango
        waybar
        swaylock
        swayidle
        swaync
        fuzzel
        kitty
        cava
        cmus
        fastfetch
        gtk-3.0
        gtk-4.0
        zathura
        nwg-look
        opencode
    )

    for cfg in "${configs[@]}"; do
        local src="${SCRIPT_DIR}/${cfg}"
        local dest="${CONFIG_DIR}/${cfg}"

        if [[ ! -d "$src" ]]; then
            warn "Skipping (not found): $src"
            continue
        fi

        if [[ -e "$dest" ]]; then
            local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
            warn "$dest exists — backing up to $backup"
            run "mv '$dest' '$backup'"
        fi

        run "cp -r '$src' '$dest'"
        success "Copied: $cfg -> $dest"
    done
}

copy_scripts() {
    header "Copying Scripts"

    local scripts_dir="${SCRIPT_DIR}/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        warn "Skipping (not found): $scripts_dir"
        return
    fi

    # Scripts de cor vão para ~/.local/bin/ junto com o resto (o
    # sequencia.sh chama tudo por caminho absoluto a partir dali).
    local subdirs=(colors)

    # Não só *.sh: loopdetect/loopbatch/loopgui são executáveis sem
    # extensão e um glob '*.sh' os deixaria de fora numa instalação nova.
    local targets=("$scripts_dir")
    for sub in "${subdirs[@]}"; do
        [[ -d "${scripts_dir}/${sub}" ]] && targets+=("${scripts_dir}/${sub}")
    done

    for dir in "${targets[@]}"; do
        for script in "$dir"/*; do
            [[ -f "$script" ]] || continue
            run "cp '$script' '$BIN_DIR/' && chmod +x '$BIN_DIR/$(basename "$script")'"
            success "Copied script: $(basename "$script") -> $BIN_DIR/"
        done
    done
}

copy_assets() {
    header "Copying Assets (Wallpapers & Videos)"

    local video_dir="${HOME}/Videos/wallpapers"

    if [[ -d "${SCRIPT_DIR}/wallpapers" ]]; then
        run "mkdir -p '$WALLPAPER_DIR'"
        run "cp -r '${SCRIPT_DIR}/wallpapers/.' '$WALLPAPER_DIR/'"
        success "Wallpapers -> $WALLPAPER_DIR"
    fi

    if [[ -d "${SCRIPT_DIR}/videos" ]]; then
        run "mkdir -p '$video_dir'"
        run "cp -r '${SCRIPT_DIR}/videos/.' '$video_dir/'"
        success "Videos -> $video_dir"
    fi
}

# Copia SO o template do tema. Não entra em copy_configs de propósito: lá o
# instalador faz 'mv' do diretório inteiro, o que apagaria a sessão e as
# preferências do qBittorrent do usuário.
copy_qbittorrent_theme() {
    header "Copying qBittorrent Theme"

    local src="${SCRIPT_DIR}/qbittorrent"
    # 'B' maiúsculo: é o nome real do diretório do qBittorrent (Qt usa o nome
    # da app como está) e é case-sensitive no Linux.
    local dest="${CONFIG_DIR}/qBittorrent/themes/pywal"

    if [[ ! -d "$src" ]]; then
        warn "Skipping (not found): $src"
        return
    fi

    run "mkdir -p '$dest'"
    for file in "$src"/*.tpl; do
        [[ -f "$file" ]] || continue
        run "cp '$file' '$dest/'"
        success "Copied: $(basename "$file") -> $dest"
    done

    info "Ative o tema em: qBittorrent > Tools > Preferences > Behavior > Interface"
    info "  'Use custom UI Theme' -> $dest/config.json (gerado por qbittorrent-colors.sh)"
}

# ── File Copying ─────────────────────────────────────────────────────────────

copy_files() {
    header "Copying Files"

    if [[ -f "${SCRIPT_DIR}/mimeapps.list" ]]; then
        run "cp ${SCRIPT_DIR}/mimeapps.list ${CONFIG_DIR}/mimeapps.list"
        success "Copied: mimeapps.list"
    fi

    if [[ -f "${SCRIPT_DIR}/user-dirs.dirs" ]]; then
        run "cp ${SCRIPT_DIR}/user-dirs.dirs ${CONFIG_DIR}/user-dirs.dirs"
        success "Copied: user-dirs.dirs"
    fi

    if [[ -f "${SCRIPT_DIR}/user-dirs.locale" ]]; then
        run "cp ${SCRIPT_DIR}/user-dirs.locale ${CONFIG_DIR}/user-dirs.locale"
        success "Copied: user-dirs.locale"
    fi
}

# ── Permissions ──────────────────────────────────────────────────────────────

set_permissions() {
    header "Setting Permissions"

    run "find $SCRIPT_DIR/scripts -type f -exec chmod +x {} +"
    success "All scripts set as executable."
}

# ── User Directories ──────────────────────────────────────────────────────────

setup_user_dirs() {
    header "Setting Up User Directories"

    if check_command xdg-user-dirs-update; then
        run "xdg-user-dirs-update"
        success "User directories created."
    else
        warn "xdg-user-dirs not found — skipping."
    fi
}

# ── Pre-flight Checks ────────────────────────────────────────────────────────

preflight() {
    header "Pre-flight Checks"

    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux."
        exit 1
    fi
    success "Detected Arch Linux."

    if ! check_command sudo; then
        error "sudo is required but not installed."
        exit 1
    fi
    success "sudo available."

    if ! check_command git; then
        error "git is required but not installed."
        exit 1
    fi
    success "git available."

    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        error "No internet connection."
        exit 1
    fi
    success "Internet connection OK."

    if $DRY_RUN; then
        warn "DRY-RUN mode enabled — no changes will be made."
    fi
}

# ── Post-install ─────────────────────────────────────────────────────────────

post_install() {
    header "Post-Install Notes"
    echo -e "${BOLD}Recommended next steps:${NC}"
    echo ""
    echo "  1. Log out and log back in for all changes to take effect."
    echo "  2. Set a wallpaper to trigger pywal colors:"
    echo -e "     ${CYAN}~/.local/bin/random-wallpaper.sh${NC}"
    echo "  3. Start MangoWM from your display manager or run:"
    echo -e "     ${CYAN}mango${NC}"
    echo ""
    echo -e "${BOLD}Common troubleshooting:${NC}"
    echo ""
    echo "  - Waybar not starting: check if waybar-git is installed from AUR"
    echo "  - Colors not applying: run ~/.local/bin/sequencia.sh"
    echo "  - Fonts missing: install a nerd-font package"
    echo ""
    echo -e "${GREEN}${BOLD}Enjoy your MangoWM setup!${NC}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo -e "${BOLD}${CYAN}"
    echo "  __  __    _    _   _  ____   ____  __        ___   _ "
    echo " |  \/  |  / \  | \ | |/ ___| / ___| \ \      / / | | |"
    echo " | |\/| | / _ \ |  \| | |  _ | |  _   \ \ /\ / /| | | |"
    echo " | |  | |/ ___ \| |\  | |_| || |_| |   \ V  V / | |_| |"
    echo " |_|  |_/_/   \_\_| \_|\____| \____|    \_/\_/   \___/ "
    echo -e "${NC}"
    echo -e "${BOLD}  MangoWM Dotfiles — Installer${NC}\n"

    preflight

    if $SKIP_PACKAGES; then
        warn "Skipping package installation (--skip-packages)."
    else
        if ! confirm "This will install packages and copy dotfiles. Continue?"; then
            echo -e "${YELLOW}Aborted.${NC}"
            exit 0
        fi
        install_pacman_packages
        install_yay
        install_aur_packages
    fi

    create_directories
    copy_configs
    copy_scripts
    copy_assets
    copy_qbittorrent_theme
    copy_files
    set_permissions
    setup_user_dirs
    post_install

    if ! $DRY_RUN; then
        header "Installation Complete!"
        echo -e "${GREEN}${BOLD}Your MangoWM dotfiles are ready!${NC}\n"
    fi
}

main "$@"
