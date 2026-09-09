<div align="center">

# MangoWM Dotfiles

![Arch](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white)
![Wayland](https://img.shields.io/badge/Protocol-Wayland-ffbc42?style=flat-square&logo=wayland&logoColor=white)

</div>

## MangoWM
> Configuração pessoal para o compositor wayland [MangoWM](https://github.com/mangowm/mango).

## Instalação
```bash
git clone https://github.com/souandresouza/mango-dotfiles.git
cd mango-dotfiles
chmod +x install.sh
./install.sh
```
**Siga as instruções interativas**

    -   O script verificará as dependências

    -   Se necessário, perguntará se deseja instalar o yay

    -   Verificará a existência do diretório de dotfiles

    -   Se ausente, oferecerá para clonar do repositório

    -   Copiará automaticamente as configurações

    -   Aplicará as permissões necessárias

## 🔒 Permissões Configuradas

O script automaticamente torna executáveis:

-   `~/.config/scripts/*.sh`

-   `~/.config/scripts/colors/*.sh`

-   `~/.config/mango/scripts/*.sh`

-   `~/.config/waybar/scripts/*.sh`

-   `~/.config/waybar/scripts/*.py`

### Erro: "You're not on an Arch-based distro"

**Solução**: O script só funciona em distribuições baseadas em Arch. Use um sistema Arch Linux ou derivado.

### Erro: Permissão negada

**Solução**: Certifique-se de ter privilégios sudo e permissão para executar o script.

### Erro: Diretório não encontrado

**Solução**: Verifique se o diretório `~/mango-dotfiles` existe ou se você tem acesso à internet para cloná-lo.

## Estrutura
<!-- TREE_START -->
```
.
├── assets
│   └── user.png
├── cava
│   ├── shaders
│   │   ├── bar_spectrum.frag
│   │   ├── eye_of_phi.frag
│   │   ├── northern_lights.frag
│   │   ├── pass_through.vert
│   │   ├── spectrogram.frag
│   │   └── winamp_line_style_spectrum.frag
│   ├── themes
│   │   ├── colors
│   │   ├── solarized_dark
│   │   └── tricolor
│   └── config
├── fastfetch
│   ├── ascii.txt
│   └── config.jsonc
├── fuzzel
│   ├── colors-fuzzel.ini
│   └── fuzzel.ini
├── kitty
│   ├── colors-kitty.conf
│   └── kitty.conf
├── mako
│   └── config
├── mango
│   ├── scripts
│   │   └── mango-keys.sh
│   ├── bind.conf
│   ├── config.conf
│   ├── emoji-list.txt
│   ├── env.conf
│   ├── rule.conf
│   └── theme.conf
├── music-tui
│   └── config.toml
├── scripts
│   ├── colors
│   │   ├── cava-colors.sh
│   │   ├── colors.wt-constants
│   │   ├── fuzzel-colors.sh
│   │   ├── kitty-colors.sh
│   │   ├── mako-colors.sh
│   │   ├── mango-colors.sh
│   │   ├── telegram-colors.sh
│   │   ├── waybar-colors.sh
│   │   └── zathura-colors.sh
│   ├── album_art.sh
│   ├── auto_detect_terminal.sh
│   ├── battery-status.sh
│   ├── battery_tracker.sh
│   ├── calendar.sh
│   ├── clipboard.sh
│   ├── clipboard_toggle.sh
│   ├── contador_pacotes.sh
│   ├── converter_imagens.sh
│   ├── dashboard.sh
│   ├── dashboard_toggle.sh
│   ├── exit-menu.sh
│   ├── extract_frames.sh
│   ├── hyprpicker.sh
│   ├── music-progress.sh
│   ├── powermenu.sh
│   ├── qr.sh
│   ├── random-wallpaper.sh
│   ├── refreshWaybar.sh
│   ├── screen_recorder.sh
│   ├── screenshot.sh
│   ├── sequencia.sh
│   ├── take-screenshot.sh
│   ├── wlsunset.sh
│   └── year-progress.sh
├── wallpapers
│   ├── 9088f95a-6f39-4565-ad55-8ee3ea373cc6_0.png
│   ├── 9ee753d2-06b6-4795-a81e-bc3f729a62b7_0.png
│   ├── leaves.png
│   ├── vintage-ascent.png
│   ├── wall-13.png
│   └── wallpaper_5.png
├── waybar
│   ├── scripts
│   │   ├── scrolling-mpris.py
│   │   └── weather.sh
│   ├── colors-waybar.css
│   ├── config.jsonc
│   └── style.css
├── zathura
│   └── zathurarc
├── install.sh
├── LICENSE
├── lista_aur.txt
├── lista_pacman.txt
├── README.md
└── structure_update.py
```
<!-- TREE_END -->
