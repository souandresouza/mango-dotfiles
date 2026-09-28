#!/usr/bin/env bash
#
# MangoWM Dotfiles — Automated Installer
# Replicates the full configuration on a fresh Arch Linux install.
#
# Usage:
#   ./install.sh              Full install
#   ./install.sh --dry-run    Preview changes without executing
#   ./install.sh --skip-packages   Only link dotfiles, skip package installation
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
            echo "  --skip-packages    Skip package installation, only link dotfiles"
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
BIN_DIR="${HOME}/bin"
WALLPAPER_DIR="${HOME}/Pictures/wallpapers"

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
        "$CONFIG_DIR/scripts/colors"
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

# ── GNU Stow Linking ─────────────────────────────────────────────────────────

link_configs() {
    header "Linking Configuration Files (GNU Stow)"

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
        opencode
        scripts
        wallpapers
    )

    if ! check_command stow; then
        warn "GNU stow not found — falling back to manual symlinking."
        link_configs_manual
        return
    fi

    for cfg in "${configs[@]}"; do
        local src="${SCRIPT_DIR}/${cfg}"
        local dest="${CONFIG_DIR}"

        if [[ ! -d "$src" ]]; then
            warn "Skipping (not found): $src"
            continue
        fi

        info "Stowing: $cfg -> $dest"
        if ! $DRY_RUN; then
            # Adopt existing files to avoid conflicts, then stow
            stow --adopt --dir="$SCRIPT_DIR" --target="$dest" "$cfg" 2>/dev/null || {
                warn "Stow conflict for $cfg — trying with --force"
                stow --adopt --force --dir="$SCRIPT_DIR" --target="$dest" "$cfg" 2>/dev/null || {
                    error "Failed to stow $cfg"
                }
            }
        fi
    done
    success "All configs stowed."
}

link_configs_manual() {
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
            warn "Directory already exists: $dest"
            if confirm "Replace with symlink?"; then
                run "rm -rf $dest"
                run "ln -s $src $dest"
                success "Linked: $dest -> $src"
            fi
        else
            run "ln -s $src $dest"
            success "Linked: $dest -> $src"
        fi
    done
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

    run "find $SCRIPT_DIR -name '*.sh' -exec chmod +x {} +"
    success "All .sh files set as executable."
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
    echo -e "     ${CYAN}~/.config/scripts/random-wallpaper.sh${NC}"
    echo "  3. Start MangoWM from your display manager or run:"
    echo -e "     ${CYAN}mango${NC}"
    echo ""
    echo -e "${BOLD}Common troubleshooting:${NC}"
    echo ""
    echo "  - Waybar not starting: check if waybar-git is installed from AUR"
    echo "  - Colors not applying: run ~/.config/scripts/colors/mango-colors.sh"
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
        if ! confirm "This will install packages and link dotfiles. Continue?"; then
            echo -e "${YELLOW}Aborted.${NC}"
            exit 0
        fi
        install_pacman_packages
        install_yay
        install_aur_packages
    fi

    create_directories
    link_configs
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
