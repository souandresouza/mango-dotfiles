#!/usr/bin/env bash

set -euo pipefail

# Bloqueio de tela: delega ao lock.sh, que já faz debounce, DND via swaync
# e tem fallback para fundo preto. Não precisa de imagem/params aqui.
lock_cmd="$HOME/.local/bin/lock.sh"


 # Define config options
   # conf="--dmenu --no-fuzzy --launch-prefix=<not set>" # for version < 1.11
  conf="--dmenu --match-mode=exact --launch-prefix=<not set>" # for version >= 1.11.0-1
  # colors="-b 173f4fee -t 21a4dfd9 -s 35b9abd9 -S ddfffdd9"

  # Define the menu options
  options=("🔒\tBloquear\n""⏸\tSuspender\n""⏏\tSair\n""🔄\tReiniciar\n""⏻\tDesligar")

  # Show the menu and get the user's choice
  # sel_option=$(echo -e "${options[@]}" | fuzzel $conf $colors --lines=5 --prompt "Seleciona uma opção:  ")
  sel_option=$(echo -e "${options[@]}" | fuzzel $conf --lines=5 --prompt "Seleciona uma opção:  ")


  # Check if the user selected an option
  if [[ -n $sel_option ]]; then
      # Extract the action part without the glyph
      action=$(echo "$sel_option" | awk '{print $NF}')

      # Ask for confirmation
      #	confirm=$(echo -e "Não - cancelar\nSim - confirmar" | fuzzel $conf $colors --lines=2 --prompt "Confirmar $action ?  " | awk '{print $1}')
    confirm=$(echo -e "Não - cancelar\nSim - confirmar" | fuzzel $conf --lines=2 --prompt "Confirmar $action ?  " | awk '{print $1}')

    # If the user confirmed, execute the selected option
    if [[ $confirm == "Sim" ]]; then
          case $action in
              "Bloquear")
                  "$lock_cmd"
                  ;;
              "Suspender")
                  systemctl suspend
                  ;;
              "Sair")
                  # Encerra o MangoWM. SIGINT/SIGTERM são tratados por
                  # handle_quit_signal() -> quit() -> wl_display_terminate()
                  # (src/main.c). Use -TERM explicitamente; SIGHUP NÃO é
                  # tratado e encerra o compositor de forma abrupta.
                  pkill -x -TERM mango
                  ;;
              "Reiniciar")
                  systemctl reboot
                  ;;
              "Desligar")
                  systemctl poweroff
                  ;;
          esac
    fi
  fi
  # Exit the script
  exit 0
