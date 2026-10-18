#!/usr/bin/env bash
# Compara duas imagens e mostra se são iguais, parecidas ou diferentes.
#
# É só uma casca em volta do image_dup.py: escolhe os dois arquivos com o
# fuzzel (que é o seletor padrão aqui) e manda o veredito para o swaync.
#
# Por que swaync e não uma janela: o veredito é uma linha ou duas. Numa
# janela de terminal ele some no instante em que o comando termina - e na
# primeira versão foi exatamente o que aconteceu, o texto mal dava tempo de
# ser lido. Notificação fica na tela até ser dispensada, e ainda aceita
# arrastar a imagem junto, que é o que resolve a dúvida de olhos: o mapa de
# diferença mostra ONDE as duas divergem.
#
# Uso:
#   imagedup_gui.sh [PASTA]
#
# Sem argumento, olha ~/Downloads. Com argumento, olha aquela pasta.
# O atalho fica em SUPER+SHIFT+D (bind.conf).

set -euo pipefail

# conf do fuzzel igual ao exit.sh: --match-mode=exact exige versão >= 1.11.
conf="--dmenu --match-mode=exact --launch-prefix=<not set>"

dir="${1:-$HOME/Downloads}"
[ -d "$dir" ] || { echo "pasta não existe: $dir" >&2; exit 1; }

imagedup="$HOME/.local/bin/imagedup"
[ -x "$imagedup" ] || imagedup="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/imagedup"
[ -f "$imagedup" ] || { echo "imagedup não encontrado" >&2; exit 1; }

# Só imagens. find em vez de glob porque o nome pode ter espaço, parênteses
# e acento (o "(3)" do Telegram quebra qualquer laço com palavra solta).
# O -name '.*' -prune tira os ocultos: senão o próprio mapa de diferença,
# se alguém deixar um ali, aparece na lista para ser comparado.
mapfile -t imagens < <(
    find "$dir" -maxdepth 1 -name '.*' -prune -o -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.tif' \
           -o -iname '*.tiff' -o -iname '*.gif' -o -iname '*.heic' \
           -o -iname '*.heif' -o -iname '*.avif' \) \
        -printf '%f\n' 2>/dev/null | sort
)

# As duas funções vêm antes do primeiro uso: em bash a definição só passa a
# existir na linha em que é executada, e o aviso de "poucas imagens" fica
# logo acima daqui - com a ordem errada ele quebrava justamente no erro.
escolher() {
    local prompt="$1"; shift
    printf '%s\n' "$@" | fuzzel $conf --lines=20 --prompt "$prompt"
}


avisar() {  # avisar TITULO CORPO [imagem]
    local img=()
    [[ -n "${3:-}" && -f "${3:-}" ]] && img=(-h "string:image-path:$3" -i "$3")
    notify-send --app-name=imagedup -u "${4:-normal}" -t "${5:-0}" \
        "${img[@]}" "$1" "$2"
}


if [[ ${#imagens[@]} -lt 2 ]]; then
    avisar "imagedup" "Preciso de pelo menos 2 imagens em $dir"
    exit 1
fi

# Primeiro arquivo: lista toda. Segundo: a mesma lista menos o já escolhido,
# para não sair comparando uma imagem com ela mesma.
a=$(escolher "Primeira imagem de $dir: " "${imagens[@]}") || exit 0
[ -n "$a" ] || exit 0

resto=()
for i in "${imagens[@]}"; do
    [[ "$i" == "$a" ]] || resto+=("$i")
done

b=$(escolher "Segunda imagem (sem $a): " "${resto[@]}") || exit 0
[ -n "$b" ] || exit 0

# O mapa de diferença vai para o cache, não para a pasta do usuário: ele não
# é uma foto que ele pediu para guardar, e dentro de ~/Downloads ele
# voltaria na lista da próxima comparação.
cache="$HOME/.cache/imagedup"
mkdir -p "$cache"
diff="$cache/diff.png"
rm -f "$diff"

# --brief imprime o veredito curto em stdout e sai com o código normal, que
# aqui não interessa: quem decide o que fazer é a pessoa.
saida=$("$imagedup" "$dir/$a" "$dir/$b" --diff "$diff" --brief) || true
[ -n "$saida" ] || exit 0

titulo=${saida%%$'\n'*}
corpo=${saida#*$'\n'}

# DND ligado engole a notificação em silêncio, e aí o atalho parece não ter
# feito nada. Nesses casos o veredito vai para o terminal, que é melhor do
# que sumir.
if swaync-client -D 2>/dev/null | grep -qi true; then
    kitty --app-id=imagedup --title="imagedup (DND ligado)" -e \
        bash -c 'printf "%s\n\n%s\n\n%s\n" "$1" "$2" "$3"
                 printf "qualquer tecla para fechar..."; read -r -n 1 -s' \
        _ "$titulo" "$corpo" "mapa de diferença: $diff"
    exit 0
fi

# timeout 0 = a notificação não some sozinha. Fica até ser dispensada, que é
# o que resolve a leitura com calma. A imagem anexada é o mapa de diferença:
# mostra de relance onde as duas divergem, coisa que o texto não transmite.
avisar "$titulo" "$corpo" "$diff"