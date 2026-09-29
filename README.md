# 🥭 MangoWM Dotfiles

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Wayland](https://img.shields.io/badge/Wayland-0077FF?style=flat-square&logo=wayland&logoColor=white)](https://wayland.freedesktop.org)
[![MangoWM](https://img.shields.io/badge/MangoWM-WM-FF6B6B?style=flat-square)](https://github.com/DreamMaoMao/mango)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

> Dotfiles for my personal **MangoWM** (Wayland compositor) setup on Arch Linux.

---

## 📸 Preview

![Waybar](screenshots/waybar.png)

> *Waybar with custom modules: workspaces, layout, music player, clock, network, volume, bluetooth, and battery*

### Layout Switching Demo

![MangoWM layout switching demo](videos/mango-layout-switch.gif)

> *Switching between layouts with cava, cmatrix, tty-clock, and lavat running*

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
├── opencode/                # OpenCode config
├── lista_pacman.txt         # Official repo packages
├── lista_aur.txt            # AUR packages
├── install.sh              # Automated install script
├── LICENSE                 # MIT License
└── README.md               # This file
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

### Install Options

| Option | Description |
|--------|-------------|
| `./install.sh` | Full install (packages + dotfiles) |
| `./install.sh --dry-run` | Preview changes without executing |
| `./install.sh --skip-packages` | Only link dotfiles, skip package installation |

---

## 📦 What `install.sh` Does

1. **Pre-flight checks** — verifies Arch Linux, sudo, git, and internet
2. **Installs packages** from official repos (`lista_pacman.txt`)
3. **Installs AUR helper** (yay) and AUR packages (`lista_aur.txt`)
4. **Creates necessary directories** (`~/.config`, `~/bin`, etc.)
5. **Links dotfiles** using GNU Stow (with manual fallback)
6. **Copies misc files** (mimeapps.list, user-dirs)
7. **Sets executable permissions** on scripts
8. **Configures user directories** (XDG)

---

## ⌨️ Keybindings

> Full list in `mango/bind.conf` — view interactively with <kbd>Super</kbd> + <kbd>A</kbd> (mango-keys)

### Apps & Launchers

| Binding | Action |
|---------|--------|
| <kbd>Super</kbd> + <kbd>Enter</kbd> | Open terminal (kitty) |
| <kbd>Super</kbd> + <kbd>Space</kbd> | App launcher (fuzzel) |
| <kbd>Super</kbd> + <kbd>E</kbd> | File manager ([cadrocfile](https://github.com/souandresouza/cadrocfile)) |
| <kbd>Super</kbd> + <kbd>F</kbd> | Browser (firefox) |
| <kbd>Super</kbd> + <kbd>S</kbd> | Music player (cmus) |
| <kbd>Super</kbd> + <kbd>T</kbd> | Telegram |
| <kbd>Super</kbd> + <kbd>W</kbd> | System monitor (btop) |
| <kbd>Super</kbd> + <kbd>N</kbd> | Network manager (nmtui) |
| <kbd>Super</kbd> + <kbd>O</kbd> | TTY clock |
| <kbd>Super</kbd> + <kbd>D</kbd> | Bluetooth (bluetui) |
| <kbd>Super</kbd> + <kbd>Y</kbd> | File explorer (yazi) |
| <kbd>Super</kbd> + <kbd>X</kbd> | Emoji picker |

### Scripts & Tools

| Binding | Action |
|---------|--------|
| <kbd>Super</kbd> + <kbd>M</kbd> | **Exit menu** |
| <kbd>Super</kbd> + <kbd>V</kbd> | Dashboard toggle |
| <kbd>Super</kbd> + <kbd>B</kbd> | Clipboard toggle |
| <kbd>Super</kbd> + <kbd>H</kbd> | Random wallpaper |
| <kbd>Super</kbd> + <kbd>C</kbd> | Color picker (hyprpicker) |
| <kbd>Super</kbd> + <kbd>I</kbd> | Image converter |
| <kbd>Super</kbd> + <kbd>J</kbd> | Extract video frames |
| <kbd>Super</kbd> + <kbd>G</kbd> | Sequência |
| <kbd>Super</kbd> + <kbd>P</kbd> | Reload waybar |
| <kbd>Super</kbd> + <kbd>R</kbd> | Reload MangoWM config |
| <kbd>Super</kbd> + <kbd>L</kbd> | Lock screen (swaylock) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | Screen recorder |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>A</kbd> | Scrcpy mirror |

### Window Management

| Binding | Action |
|---------|--------|
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close window |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | Toggle overview |
| <kbd>Alt</kbd> + <kbd>\\</kbd> | Toggle floating |
| <kbd>Alt</kbd> + <kbd>A</kbd> | Maximize |
| <kbd>Alt</kbd> + <kbd>F</kbd> | Fullscreen |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Fake fullscreen |
| <kbd>Alt</kbd> + <kbd>I</kbd> | Minimize |
| <kbd>Alt</kbd> + <kbd>O</kbd> | Toggle overlay |
| <kbd>Alt</kbd> + <kbd>Z</kbd> | Toggle scratchpad |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Switch layout |
| <kbd>Alt</kbd> + <kbd>←/→/↑/↓</kbd> | Focus direction |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>←/→/↑/↓</kbd> | Swap window |

### Tags (Workspaces)

| Binding | Action |
|---------|--------|
| <kbd>Super</kbd> + <kbd>1-9</kbd> | Switch to tag |
| <kbd>Alt</kbd> + <kbd>1-9</kbd> | View tag |
| <kbd>Super</kbd> + <kbd>←/→</kbd> | Previous/next tag |

### Screenshots

| Binding | Action |
|---------|--------|
| <kbd>PrtSc</kbd> | Screenshot all |
| <kbd>Alt</kbd> + <kbd>PrtSc</kbd> | Screenshot monitor |
| <kbd>Ctrl</kbd> + <kbd>PrtSc</kbd> | Screenshot region |
| <kbd>Shift</kbd> + <kbd>PrtSc</kbd> | Take screenshot |

### Mouse

| Binding | Action |
|---------|--------|
| <kbd>Super</kbd> + <kbd>Left click</kbd> | Move window |
| <kbd>Alt</kbd> + <kbd>Right click</kbd> | Resize window |
| <kbd>Shift</kbd> + <kbd>Middle click</kbd> | Maximize toggle |

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

# 2. Link configs with stow
mkdir -p ~/.config
stow -d ~/mango-dotfiles -t ~/.config mango waybar swaylock mako fuzzel kitty cava cmus fastfetch gtk-3.0 gtk-4.0 zathura xsettingsd nwg-look

# 3. Copy wallpapers & scripts
cp -r wallpapers ~/Pictures/
cp -r scripts ~/.config/

# 4. Set user directories
cp user-dirs.dirs user-dirs.locale ~/.config/
```

---

## 🔧 Post-Install

After running `install.sh`, complete these steps:

1. **Log out and log back in** for all changes to take effect
2. **Set a wallpaper** to trigger pywal colors:
   ```bash
   ~/.config/scripts/random-wallpaper.sh
   ```
3. **Start MangoWM** from your display manager or run:
   ```bash
   mango
   ```

### Enabling Services

```bash
# Bluetooth
sudo systemctl enable --now bluemask

# Power management
sudo systemctl enable --now power-profiles-daemon

# Network
sudo systemctl enable --now NetworkManager
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Waybar not starting | Ensure `waybar-git` is installed from AUR |
| Colors not applying | Run `~/.config/scripts/colors/mango-colors.sh` |
| Fonts missing | Install a nerd-font package: `sudo pacman -S ttf-nerd-fonts-symbols` |
| Stow conflicts | Run `stow --adopt --force -d ~/mango-dotfiles -t ~/.config <package>` |
| MangoWM not found | Ensure `mangowm-git` is installed from AUR |
| Notifications not showing | Check if `mako` is running: `pgrep mako` |

---

## 🤝 Contributing

Contributions are welcome! Here's how to help:

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Guidelines

- Keep scripts POSIX-compliant where possible
- Test `install.sh` with `--dry-run` before submitting
- Update README.md if you add new components
- Add new packages to the appropriate list (`lista_pacman.txt` or `lista_aur.txt`)

---

## 📝 Notes

- **MangoWM** is a relatively new and experimental Wayland compositor — expect some rough edges.
- Some configs assume a **Brazilian Portuguese** locale (`pt_BR.UTF-8`).
- Monitor configuration in `mango/config.conf` is specific to my setup (eDP-1 + HDMI-A-1) — adjust accordingly.
- The `cmus/cache` and `cmus/lib.pl` contain your personal music library paths (gitignored).

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [MangoWM](https://github.com/DreamMaoMao/mango) by DreamMaoMao
- [cadrocfile](https://github.com/souandresouza/cadrocfile) — file manager used in this setup
- The Arch Linux community
- All the open-source projects that make this setup possible
