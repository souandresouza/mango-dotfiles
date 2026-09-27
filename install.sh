#!/usr/bin/env bash
#
# MangoWM Dotfiles — Automated Installer
# Replicates the full configuration on a fresh Arch Linux install.
#

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
BIN_DIR="${HOME}/bin"
WALLPAPER_DIR="${HOME}/Pictures/wallpapers"

# ── Package lists ─────────────────────────────────────────────────────────────
PACMAN_LIST="${SCRIPT_DIR}/lista_pacman.txt"
AUR_LIST="${SCRIPT_DIR}/lista_aur.txt"

# ── Functions ─────────────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[${NC}${BOLD}INFO${NC}${BLUE}]${NC} $*"; }
success() { echo -e "${GREEN}[${NC}${BOLD} OK ${NC}${GREEN}]${NC} $*"; }
warn()    { echo -e "${YELLOW}[${NC}${BOLD}WARN${NC}${YELLOW}]${NC} $*"; }
error()   { echo -e "${RED}[${NC}${BOLD}FAIL${NC}${RED}]${NC} $*"; }
header()  { echo -e "\n${CYAN}${BOLD}═══ $* ═══${NC}\n"; }

confirm() {
    local prompt="${1:-Are you sure?}"
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

install_pacman_packages() {
    header "Installing Official Packages"

    if [[ ! -f "$PACMAN_LIST" ]]; then
        error "Package list not found: $PACMAN_LIST"
        exit 1
    fi

    info "Installing packages from pacman..."
    sudo pacman -Syu --needed - < "$PACMAN_LIST"
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
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$tmpdir"
    success "yay installed."
}

install_aur_packages() {
    header "Installing AUR Packages"

    if [[ ! -f "$AUR_LIST" ]]; then
        warn "AUR package list not found: $AUR_LIST"
        return
    fi

    yay -Syu --needed - < "$AUR_LIST"
    success "AUR packages installed."
}

create_directories() {
    header "Creating Directories"

    local dirs=(
        "$CONFIG_DIR"
        "$BIN_DIR"
        "$WALLPAPER_DIR"
        "$CONFIG_DIR/scripts/colors"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            success "Created: $dir"
        else
            info "Exists:   $dir"
        fi
    done
}

link_configs() {
    header "Linking Configuration Files"

    # List of config directories to link into ~/.config
    local configs=(
        mango
        waybar
        swaylock
        mako
        fuzzel
        kitty
        cava
        cmus
        fastfetch
        gtk-3.0
        gtk-4.0
        zathura
        xsettingsd
        nwg-look
        scripts
        wallpapers
    )

    for cfg in "${configs[@]}"; do
        local src="${SCRIPT_DIR}/${cfg}"
        local dest="${CONFIG_DIR}/${cfg}"

        if [[ ! -d "$src" ]]; then
            warn "Skipping (not found): $src"
            continue
        fi

        if [[ -L "$dest" ]]; then
            info "Symlink exists: $dest"
        elif [[ -d "$dest" ]]; then
            warn "Directory already exists (not a symlink): $dest"
            if confirm "Replace with symlink?"; then
                rm -rf "$dest"
                ln -s "$src" "$dest"
                success "Linked: $dest -> $src"
            fi
        else
            ln -s "$src" "$dest"
            success "Linked: $dest -> $src"
        fi
    done
}

copy_files() {
    header "Copying Files"

    # mimeapps.list
    if [[ -f "${SCRIPT_DIR}/mimeapps.list" ]]; then
        cp "${SCRIPT_DIR}/mimeapps.list" "${CONFIG_DIR}/mimeapps.list"
        success "Copied: mimeapps.list"
    fi

    # user-dirs
    if [[ -f "${SCRIPT_DIR}/user-dirs.dirs" ]]; then
        cp "${SCRIPT_DIR}/user-dirs.dirs" "${CONFIG_DIR}/user-dirs.dirs"
        success "Copied: user-dirs.dirs"
    fi
    if [[ -f "${SCRIPT_DIR}/user-dirs.locale" ]]; then
        cp "${SCRIPT_DIR}/user-dirs.locale" "${CONFIG_DIR}/user-dirs.locale"
        success "Copied: user-dirs.locale"
    fi
}

set_permissions() {
    header "Setting Permissions"

    # Make all shell scripts executable
    find "${SCRIPT_DIR}" -name "*.sh" -exec chmod +x {} \;
    success "All .sh files set as executable."
}

setup_user_dirs() {
    header "Setting Up User Directories"

    if check_command xdg-user-dirs-update; then
        xdg-user-dirs-update
        success "User directories created."
    else
        warn "xdg-user-dirs not found — skipping."
    fi
}

# ── Pre-flight Checks ────────────────────────────────────────────────────────

preflight() {
    header "Pre-flight Checks"

    # Check Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux."
        exit 1
    fi
    success "Detected Arch Linux."

    # Check sudo
    if ! check_command sudo; then
        error "sudo is required but not installed."
        exit 1
    fi
    success "sudo available."

    # Check internet
    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        error "No internet connection."
        exit 1
    fi
    success "Internet connection OK."
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

    if ! confirm "This will install packages and link dotfiles. Continue?"; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 0
    fi

    install_pacman_packages
    install_yay
    install_aur_packages
    create_directories
    link_configs
    copy_files
    set_permissions
    setup_user_dirs

    header "Installation Complete!"
    echo -e "${GREEN}${BOLD}Your MangoWM dotfiles are ready!${NC}\n"
    info "Log out and log back in for all changes to take effect."
    info "Check the README.md for keybindings and manual setup notes."
    echo ""
}

main "$@"
