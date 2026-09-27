#!/bin/bash
# Script para captura de tela - usado pelo agente para ver o desktop

OUTPUT="${1:-/tmp/current-screen.png}"

# Captura a tela inteira
grim "$OUTPUT"

echo "Captura salva em: $OUTPUT"
