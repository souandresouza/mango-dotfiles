# 🥭 MangoWM Dotfiles

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Wayland](https://img.shields.io/badge/Wayland-0077FF?style=flat-square&logo=wayland&logoColor=white)](https://wayland.freedesktop.org)
[![MangoWM](https://img.shields.io/badge/MangoWM-WM-FF6B6B?style=flat-square)](https://github.com/DreamMaoMao/mango)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

> Dotfiles for my personal **MangoWM** (Wayland compositor) setup on Arch Linux.

---

## 📸 Preview

| Component | Description |
|-----------|-------------|
| **WM** | [MangoWM](https://github.com/DreamMaoMao/mango) — tiling Wayland compositor |
| **Bar** | [Waybar](https://github.com/Alexays/Waybar) with custom modules |
| **Notifications** | [Mako](https://github.com/emersion/mako) |
| **Launcher** | [Fuzzel](https://codeberg.org/dnkl/fuzzel) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| **Lock** | [Swaylock-effects](https://github.com/mortie/swaylock-effects) |
| **Shell** | Bash + custom scripts |
| **Music** | [cmus](https://cmus.github.io/) |
| **Visualizer** | [Cava](https://github.com/karlstav/cava) |

---

## 📁 Repository Structure

```
mango-dotfiles/
├── mango/                  # MangoWM core configuration
│   ├── config.conf          # Main compositor config
│   ├── bind.conf           # Keybindings
│   ├── rule.conf           # Window rules
│   ├── theme.conf          # Theme/appearance
│   ├── env.conf            # Environment variables
│   └── scripts/            # WM-specific scripts
├── waybar/                  # Status bar config & styles
├── swaylock/                # Lock screen config
├── mako/                    # Notification daemon config
├── fuzzel/                  # App launcher config
├── kitty/                   # Terminal config
├── cava/                    # Audio visualizer + shaders
├── cmus/                    # Music player config & playlists
├── fastfetch/               # System info tool config
├── gtk-3.0/                 # GTK3 settings & bookmarks
├── gtk-4.0/                 # GTK4 settings & CSS
├── zathura/                 # PDF viewer config
├── xsettingsd/              # X11 settings daemon
├── nwg-look/                # GTK theme utility
├── scripts/                 # Custom shell scripts
│   ├── colors/              # Pywal color integration
│   ├── dashboard.sh         # System dashboard
│   ├── clipboard.sh         # Clipboard manager
│   └── ...                  # Various utilities
├── wallpapers/              # Wallpaper collection
├── opencode/                # OpenCode service config
├── lista_pacman.txt         # Official repo packages
├── lista_aur.txt            # AUR packages
└── install.sh              # Automated install script
```

---

## 🚀 Quick Start

### Prerequisites

- **Arch Linux** (or Arch-based distro)
- **sudo** privileges
- **Internet** connection

### One-line Install

```bash
curl -fsSL https://raw.githubusercontent.com/souandresouza/mango-dotfiles/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/souandresouza/mango-dotfiles.git
cd mango-dotfiles
chmod +x install.sh
./install.sh
```

---

## 📦 What `install.sh` Does

1. **Installs packages** from official repos (`lista_pacman.txt`)
2. **Installs AUR helper** (yay) and AUR packages (`lista_aur.txt`)
3. **Creates necessary directories** (`~/.config`, `~/bin`, etc.)
4. **Symlinks/copies dotfiles** to their proper locations
5. **Sets executable permissions** on scripts
6. **Configures user directories** (XDG)

---

## ⌨️ Keybindings

> Full list in `mango/bind.conf` — view interactively with <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>/</kbd>

| Binding | Action |
|---------|--------|
| <kbd>Super</kbd> + <kbd>Enter` | Open terminal |
| <kbd>Super</kbd> + <kbd>D` | App launcher (fuzzel) |
| <kbd>Super</kbd> + <kbd>Q` | Close window |
| <kbd>Super</kbd> + <kbd>1-9` | Switch tag |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1-9</kbd> | Move window to tag |
| <kbd>Super</kbd> + <kbd>H/J/K/L` | Focus direction |
| <kbd>Super</kbd> + <kbd>Space` | Cycle layout |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Space` | Toggle floating |
| <kbd>Super</kbd> + <kbd>F` | Fullscreen |
| <kbd>Super</kbd> + <kbd>S</kbd> | Screenshot |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E` | Exit menu |

---

## 🎨 Themes & Colors

Colors are managed via [Pywal](https://github.com/dylanaraps/pywal) — set a wallpaper and the entire system palette updates automatically:

```bash
# Colors are extracted from your wallpaper
~/.config/scripts/colors/mango-colors.sh
```

Each app has its own color script in `scripts/colors/`.

---

## 📋 Package Lists

| File | Description |
|------|-------------|
| `lista_pacman.txt` | Official Arch repository packages |
| `lista_aur.txt` | AUR packages (installed via yay) |

To export your current package list:
```bash
pacman -Qqe | grep -v "$(pacman -Qqm)" > lista_pacman.txt
pacman -Qqm > lista_aur.txt
```

---

## 🛠️ Manual Setup (Without install.sh)

If you prefer to set things up manually:

```bash
# 1. Install packages
sudo pacman -S --needed - < lista_pacman.txt
yay -S --needed - < lista_aur.txt

# 2. Link configs
mkdir -p ~/.config
stow -d ~/mango-dotfiles -t ~/.config mango waybar swaylock mako fuzzel kitty cava cmus fastfetch gtk-3.0 gtk-4.0 zathura xsettingsd nwg-look

# 3. Copy wallpapers & scripts
cp -r wallpapers ~/Pictures/
cp -r scripts ~/.config/

# 4. Set user directories
cp user-dirs.dirs user-dirs.locale ~/.config/
```

---

## 📝 Notes

- **MangoWM** is a relatively new and experimental Wayland compositor — expect some rough edges.
- Some configs assume a **Brazilian Portuguese** locale (`pt_BR.UTF-8`).
- Monitor configuration in `mango/config.conf` is specific to my setup (eDP-1 + HDMI-A-1) — adjust accordingly.
- The `cmus/cache` and `cmus/lib.pl` contain your personal music library paths.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [MangoWM](https://github.com/DreamMaoMao/mango) by DreamMaoMao
- The Arch Linux community
- All the open-source projects that make this setup possible
