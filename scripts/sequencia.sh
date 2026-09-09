#!/bin/bash
# sequencia.sh -- executa scripts com verificação

# Função para verificar se um pacote está instalado
is_package_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

# Função para verificar se um binário existe
is_binary_installed() {
    command -v "$1" >/dev/null 2>&1
}

echo "=== Iniciando atualização de cores ==="
echo

# cava - precisa estar rodando para aplicar cores
if command -v cava >/dev/null 2>&1 && pgrep -x "cava" >/dev/null 2>&1; then
    echo "✓ Executando cava-colors.sh (cava ativo)"
    $HOME/.config/scripts/colors/cava-colors.sh
else
    echo "✗ cava não está instalado ou não está em execução. Pulando..."
fi

# kitty
if command -v kitty >/dev/null 2>&1 && pgrep -x "kitty" >/dev/null 2>&1; then
    echo "✓ Executando kitty-colors.sh (kitty ativo)"
    $HOME/.config/scripts/colors/kitty-colors.sh
else
    echo "✗ kitty não está instalado ou não está em execução. Pulando..."
fi

# wal-telegram-git - só verifica se o pacote está instalado (não fica rodando)
if pacman -Q wal-telegram-git >/dev/null 2>&1; then
    echo "✓ Executando telegram-colors.sh (wal-telegram-git instalado)"
    $HOME/.config/scripts/colors/telegram-colors.sh
else
    echo "✗ wal-telegram-git não está instalado. Pulando..."
fi

# zathura
if command -v zathura >/dev/null 2>&1 && pgrep -x "zathura" >/dev/null 2>&1; then
    echo "✓ Executando zathura-colors.sh (zathura ativo)"
    $HOME/.config/scripts/colors/zathura-colors.sh
else
    echo "✗ zathura não está instalado ou não está em execução. Pulando..."
fi

echo
echo "=== Atualização de cores concluída ==="
