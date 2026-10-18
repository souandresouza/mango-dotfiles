#!/usr/bin/env bash
# backup.sh - backup do /home e do /etc num disco externo via restic.
#
#   backup.sh              roda um backup (sem argumentos = manual)
#   backup.sh --check      só verifica a integridade do repositório
#   backup.sh --restore <caminho> [destino]
#   backup.sh --snapshots  lista os pontos de restauração
#   backup.sh --latest     imprime o snapshot mais recente (para backup.sh --restore latest)
#
# O script recusa rodar se o disco externo não estiver montado. Sem essa
# checagem, um backing off do USB deixaria o restic gravar o backup no
# próprio disco local, e só se descobre quando o externo volta.
set -uo pipefail

MOUNT_POINT="${BACKUP_MOUNT:-/mnt/backup}"
REPO="${BACKUP_REPO:-$MOUNT_POINT/restic-repo}"
KEYFILE="${BACKUP_KEYFILE:-$HOME/.config/restic/key}"
LOG="${BACKUP_LOG:-$HOME/.local/state/restic/backup.log}"
STATE="$HOME/.local/state/restic"
LOCK="$STATE/backup.lock"

# O que entra no backup é a home, não o ponto de montagem.
# Cada padrão precisa do prefixo --exclude=: sem isso o restic lê o caminho
# como mais um diretório-fonte e copia justamente o que se queria excluir.
H="${BACKUP_HOME:-$HOME}"
EXCLUDES=(
    "--exclude=$H/.cache"
    "--exclude=$H/.wine"
    "--exclude=$H/.cargo"
    "--exclude=$H/.local/share/Trash"
    "--exclude=$H/.local/share/flatpak/exports"
    "--exclude=**/node_modules"
    # Tudo daqui pra baixo é conteúdo único do disco local, não duplicata:
    # ao excluir, o espaço sai de verdade do repo. (Duplicata byte-idêntica -
    # mesmo arquivo em duas pastas - já é deduplicada pelo restic por hash, e
    # excluí-la não liberaria nada.)
    #
    # venv: reinstala com um pip install a partir do requirements.
    "--exclude=$H/.local/share/loopdetect/venv"
    # Perfil do Firefox: storage e sqlite reconstruem sozinhos; extensions e
    # widevinecdm sao baixados de novo na hora. Os .sqlite ainda podem estar
    # abertos durante o backup, o que gera estado inconsistente no restore.
    #
    # O caminho e ~/.config/mozilla, nao ~/.mozilla - nesta maquina ~/.mozilla
    # nao existe. Havia um "--exclude=$H/.mozilla/**/cache2" aqui desde o
    # inicio que nunca pegou nada, alem de cache2 nao ser mais o nome do
    # cache no Firefox atual: agora e startupCache, coberto pelo padrao
    # abaixo. O que fica fora do perfil e so cache e plugin - places.sqlite,
    # favicons, security_state e sessionstore continuam no backup, porque
    # nao voltam.
    "--exclude=$H/.config/mozilla/firefox/*/startupCache"
    "--exclude=$H/.config/mozilla/firefox/*/storage"
    "--exclude=$H/.config/mozilla/firefox/*/extensions"
    "--exclude=$H/.config/mozilla/firefox/*/gmp-widevinecdm"
    # GeoDB do qBittorrent: base de geolocalizacao, o app refaz o download.
    "--exclude=$H/.local/share/qBittorrent/GeoDB"
    # WAL do SQLite: e um arquivo temporario, transico entre checkpoints.
    # O .db em si fica - tem historico que nao volta.
    "--exclude=$H/.local/share/opencode/opencode.db-wal"
    # .git dos repos que tem remoto: o mesmo historico ja existe la, entao
    # levar o .git e guardar o mesmo dado duas vezes.
    #
    # A lista e explicita, nao "**/.git". O padrao largo pegava tambem
    # repos que so existem aqui - e um --exclude desses e definitivo, nao ha
    # como reverter depois que o backup rodar. Todos os 10 .git da home tem
    # remoto hoje, mas isso pode mudar, e o backup de amanha nao deve
    # depender disso.
    "--exclude=$H/mango-dotfiles/.git"
    "--exclude=$H/cadrocfile/.git"
    "--exclude=$H/ruwall/.git"
    # O .git do cache do yay nao entra mesmo, porque o $H/.cache acima ja
    # exclui a pasta inteira.
)
# /etc tem arquivos root-only (shadow, sudoers, chaves privadas). Um backup
# não roda como root, então eles não são legíveis - e o restic devolve o
# código 3 (avisos) por causa disso. Backups de /etc só são bons com sudo;
# sem ele, levamos o que der e registramos o resto como pendente.
ETC_EXCLUDES=(
    "--exclude=/etc/shadow"
    "--exclude=/etc/shadow-"
    "--exclude=/etc/gshadow"
    "--exclude=/etc/gshadow-"
    "--exclude=/etc/sudoers"
    "--exclude=/etc/sudoers.d"
    "--exclude=/etc/ssl/private"
    "--exclude=/etc/pacman.d/gnupg"
    "--exclude=/etc/polkit-1/rules.d"
    "--exclude=/etc/ppp"
    "--exclude=/etc/ufw"
    "--exclude=/etc/samba"
    "--exclude=/etc/ceph"
    "--exclude=/etc/docker"
    "--exclude=/etc/netplan"
)
# política de retenção
KEEP_HOURLY=6
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=6

mkdir -p "$STATE"
[[ -f "$KEYFILE" ]] || { echo "sem chave em $KEYFILE - rode: openssl rand -base64 32 > $KEYFILE" >&2; exit 1; }

# --password-file: sem ele o backup agendado para esperando alguém
# digitar senha. A chave e um openssl rand, gerada uma vez só.
# --repository-file não serve aqui: ele já traz a localização do
# repositório e conflita com -r.
#
# Duas esperas distintas, porque espera longa faz sentido numa coisa e
# não na outra. O backup precisa do retry longo: ele roda às 23h sem
# ninguém olhando, e um lock passageiro de outro processo não deve
# reprovar o backup inteiro. O check é o contrario - é rodado na mão,
# na frente de alguém, e esperar 5 minutos por um lock orfao parece
# travamento. Lock orfao é comum depois de um processo interrompido no
# meio, que nao consegue soltar o lock; nesses casos o certo e avisar
# rapido e deixar a pessoa rodar o unlock.
R() { restic -r "$REPO" --password-file "$KEYFILE" --retry-lock=5m "$@"; }
C() { restic -r "$REPO" --password-file "$KEYFILE" --retry-lock=20s "$@"; }

log() {
    local msg="$1"
    printf '%s  %s\n' "$(date '+%F %T')" "$msg" >>"$LOG"
    printf '%s  %s\n' "$(date '+%F %T')" "$msg"
}

notify() {
    command -v notify-send >/dev/null && \
        notify-send -a "restic" -u "$2" "Backup" "$1" 2>/dev/null
}

# Trava: dois backups simultâneos no mesmo disco USB não dá certo.
exec 9>"$LOCK" || exit 1
flock -n 9 || { log "outro backup já está rodando"; exit 0; }

# --- o disco precisa estar montado ---------------------------------------
if ! mountpoint -q "$MOUNT_POINT"; then
    # Com o timer diário isso é o caso normal: o disco externo não fica
    # plugado o tempo todo. Não é falha, e notificar aqui seria spam.
    log "disco externo ausente em $MOUNT_POINT - pulando (sem alarde)"
    exit 0
fi
command -v restic >/dev/null || { log "ERRO: restic não instalado"; exit 1; }

case "${1:-}" in
--check)
    log "verificando a integridade do repositório..."
    C check --read-data-subset=5% && log "repositório íntegro" && exit 0
    log "ERRO: repositório com problema (se a causa for lock, rode: restic -r $REPO --password-file $KEYFILE unlock)"
    exit 1
    ;;
--snapshots)
    R snapshots; exit 0
    ;;
--restore)
    snap="${2:?informe o snapshot (ou 'latest')}"
    dest="${3:-$PWD}"
    # --verify relê os dados do repo e confere o checksum de cada arquivo.
    # Sem isto é só uma cópia que ninguém olhou.
    R restore "$snap" --target "$dest" --verify
    # o /etc vem com modos como r-xr-xr-x e fica impossível de apagar
    # depois sem chmod; o alvo é temporário, então destrava.
    chmod -R u+w "$dest" 2>/dev/null
    log "restaurado $snap -> $dest"
    exit 0
    ;;
--latest)
    R snapshots --json | python3 -c 'import json,sys; s=json.load(sys.stdin); print(s[-1]["short_id"] if s else "")'
    exit 0
    ;;
esac

# --- o backup em si ------------------------------------------------------
log "iniciando backup para $REPO"
# Código 0 = tudo certo, 3 = parte ilegível. O 3 é esperado em /etc sem root,
# então não é tratado como falha.
R backup "$H" "${EXCLUDES[@]}" /etc "${ETC_EXCLUDES[@]}" \
      --tag home --tag sistema --exclude-caches \
      --exclude "*.iso" --exclude "*.tar.zst"
rc=$?
case $rc in
0)  ;;
3)  log "aviso: alguns arquivos não foram lidos (esperado em /etc sem root)" ;;
*)  log "ERRO: o backup falhou (código $rc)"
    notify "O backup falhou; veja $LOG" critical
    exit 1 ;;
esac

R forget --prune \
    --keep-hourly "$KEEP_HOURLY" --keep-daily "$KEEP_DAILY" \
    --keep-weekly "$KEEP_WEEKLY" --keep-monthly "$KEEP_MONTHLY"

# O check precisa de retorno proprio: uma vez ele falhou por trava obsoleta e
# o script ainda anunciou "backup ok", que e exatamente o que nao deve
# acontecer - backup nao verificado nao e backup.
if ! C check --read-data-subset=2%; then
    log "ERRO: o repositorio nao passou no check - o backup existe mas nao e confiavel"
    notify "Check do repositorio falhou; veja $LOG" critical
    exit 1
fi
size=$(R stats --mode raw-data 2>/dev/null | grep -i "total size" | tail -1)
log "backup ok - ${size:-tamanho desconhecido}"
notify "Backup ok (${size:-concluido})" normal
