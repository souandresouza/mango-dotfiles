<div align="center">

# MangoWM Dotfiles

![Arch](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white)
![Wayland](https://img.shields.io/badge/Protocol-Wayland-ffbc42?style=flat-square&logo=wayland&logoColor=white)

</div>

## MangoWM
## > Configuração pessoal para o compositor wayland [MangoWM](https://github.com/mangowm/mango).

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

    -   Instalará os pacotes das listas `lista_pacman.txt` e `lista_aur.txt`

    -   Verificará a existência do diretório de dotfiles

    -   Se ausente, oferecerá para clonar do repositório

    -   Copiará automaticamente as configurações

    -   **Fará backup** das configurações existentes antes de sobrescrever (salvo em `~/.config/mango-dotfiles-backup-*`)

    -   Aplicará as permissões necessárias

## Dependências
As dependências estão separadas em:
- `lista_pacman.txt` - pacotes essenciais dos repositórios oficiais (comentado por categoria)
- `lista_aur.txt` - pacotes essenciais disponíveis no AUR

O `install.sh` instala automaticamente os pacotes dessas listas antes de aplicar as configurações.

> **Nota:** As listas refletem os pacotes utilizados na minha configuração pessoal. Remova ou substitua o que não fizer sentido para você.

## Componentes

- MangoWM - compositor
- waybar - barra de status
- mako - notificações
- fuzzel - launcher
- kitty - terminal
- awww (antigo swww) - wallpapers
- hypridle - gerenciamento de inatividade
- hyprlock - bloqueio de tela
- hyprpicker - seletor de cores

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
```
~/.config/
├── cava/
├── fastfetch/
├── fuzzel/
├── mango/
├── kitty/
├── music-tui/
├── scripts/
├── mako/
├── wallpapers/
├── waybar/
└── zathura/

~/mango-dotfiles/
├── assets/
│   └── user.png
└── [diretórios de configuração]
```
## Esse é o meu MangoWM. Eu gosto assim. Quer usar? Usa. Não gostou do hyprlock? Troca. Não usa Steam? Remove. Vida que segue. 😂
