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
    "--exclude=$H/.mozilla/**/cache2"
    "--exclude=$H/.local/share/flatpak/exports"
    "--exclude=**/node_modules"
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
R() { restic -r "$REPO" --password-file "$KEYFILE" --retry-lock=5m "$@"; }

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
    log "ERRO: $MOUNT_POINT não está montado - backup cancelado"
    notify "$MOUNT_POINT não está montado; nada foi salvo" critical
    exit 1
fi
command -v restic >/dev/null || { log "ERRO: restic não instalado"; exit 1; }

case "${1:-}" in
--check)
    log "verificando a integridade do repositório..."
    R check --read-data-subset=5% && log "repositório íntegro" && exit 0
    log "ERRO: repositório com problema"; exit 1
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
if ! R check --read-data-subset=2%; then
    log "ERRO: o repositorio nao passou no check - o backup existe mas nao e confiavel"
    notify "Check do repositorio falhou; veja $LOG" critical
    exit 1
fi
size=$(R stats --mode raw-data 2>/dev/null | grep -i "total size" | tail -1)
log "backup ok - ${size:-tamanho desconhecido}"
notify "Backup ok (${size:-concluido})" normal
