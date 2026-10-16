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

install_cadrocfile() {
    header "Installing cadrocfile from GitHub"

    if check_command cadrocfile; then
        success "cadrocfile already installed."
        return
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"
    run "git clone https://github.com/souandresouza/cadrocfile.git '$tmpdir/cadrocfile'"

    if ! $DRY_RUN; then
        cd "$tmpdir/cadrocfile" || return
        local built=0

        if [[ -f Cargo.toml ]]; then
            info "Detected Rust project, building with cargo..."
            if cargo build --release 2>/dev/null; then
                sudo cp target/release/cadrocfile /usr/local/bin/
                built=1
            fi
        elif [[ -f Makefile ]]; then
            info "Detected Makefile, building with make..."
            if make 2>/dev/null; then
                sudo cp cadrocfile /usr/local/bin/ 2>/dev/null || sudo cp target/release/cadrocfile /usr/local/bin/ 2>/dev/null
                built=1
            fi
        elif [[ -f meson.build ]]; then
            info "Detected Meson project..."
            if meson setup builddir 2>/dev/null && ninja -C builddir 2>/dev/null; then
                sudo cp builddir/cadrocfile /usr/local/bin/ 2>/dev/null
                built=1
            fi
        fi

        if [[ $built -eq 0 ]]; then
            warn "Could not automatically build cadrocfile."
            info "Build manually in $tmpdir/cadrocfile and copy the binary to /usr/local/bin/ (or your PATH)."
        fi

        cd "$SCRIPT_DIR"
    fi

    run "rm -rf '$tmpdir'"
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
        cadrocfile
        matugen
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

    # O matugen substituiu os scripts de cor: cada bloco [templates.*] do
    # matugen/config.toml escreve um arquivo de saida e recarrega o app pelo
    # post_hook. Os scripts em scripts/colors/ ficaram sem uso e nao sao mais
    # chamados pelo sequencia.sh — o subdirso continua na lista para não
    # quebrar quem ainda os tenha no ~/.local/bin.
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
        # --force garante que os diretórios padrão sejam (re)criados mesmo
        # que o arquivo user-dirs.dirs já exista (comum em instalações recentes).
        run "xdg-user-dirs-update --force"
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

    # O snapper só tem backend para btrfs e XFS. Em ext4 ele não cria
    # configuração nenhuma e o snapper-timeline.timer fica sem efeito, então
    # avisar aqui evita a surpresa de instalar o pacote e nada funcionar.
    #
    # A criptografia é detectada pelo SOURCE, não pelo FSTYPE: num sistema
    # LUKS+btrfs o findmnt ainda devolve "btrfs" na raiz, porque o btrfs fica
    # em cima do mapper. Testar FSTYPE=="crypt" nunca dispararia.
    local root_fs root_src
    root_fs="$(findmnt -no FSTYPE / 2>/dev/null || echo desconhecido)"
    root_src="$(findmnt -no SOURCE / 2>/dev/null || echo desconhecido)"
    case "$root_fs" in
        btrfs)
            success "Root filesystem is btrfs — snapper will work."
            ;;
        xfs)
            warn "Root is XFS. Snapper works, but the dotfiles assume btrfs subvolumes."
            ;;
        *)
            warn "Root filesystem is '$root_fs', not btrfs."
            info "Snapper cannot create snapshots here (btrfs or XFS required)."
            info "The snapper package will install but stay inert. This is expected"
            info "on an ext4 root; ignore it unless you are planning to reinstall."
            ;;
    esac

    # cryptsetup é o que destrava volumes LUKS. Ele não vem no grupo base e
    # nenhum pacote do Arch o declara como dependência, então precisa estar
    # explícito na lista — sem ele, uma raiz criptografada não destrava.
    if [[ "$root_src" == /dev/mapper/* ]]; then
        if check_command cryptsetup; then
            success "Encrypted root detected ($root_src) and cryptsetup available."
        else
            error "Root is LUKS-encrypted ($root_src) but cryptsetup is not installed."
            error "The system will prompt for the passphrase and fail to unlock."
        fi
    elif check_command cryptsetup; then
        info "Root is not encrypted ($root_src); cryptsetup available for other volumes."
    else
        warn "cryptsetup is not installed (only needed if you use LUKS)."
    fi

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
    echo "  2. Set a wallpaper to generate the theme with matugen:"
    echo -e "     ${CYAN}~/.local/bin/random-wallpaper.sh${NC}"
    echo "     (or just ${CYAN}~/.local/bin/sequencia.sh${NC} to re-apply the current one)"
    echo "  3. Start MangoWM from your display manager or run:"
    echo -e "     ${CYAN}mango${NC}"
    echo ""
    echo -e "${BOLD}Common troubleshooting:${NC}"
    echo ""
    echo "  - Waybar not starting: check if waybar-git is installed from AUR"
    echo "  - Colors not applying: run ~/.local/bin/sequencia.sh"
    echo "  - Editing a theme: the files under ~/.config are generated by matugen."
    echo "    Edit ~/.config/matugen/config.toml and the templates instead, then"
    echo "    re-run sequencia.sh — editing the output directly gets overwritten."
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
        install_cadrocfile
    fi

    create_directories
    copy_configs
    copy_scripts
    copy_assets
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
