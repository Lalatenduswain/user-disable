#!/usr/bin/env bash
# user-disable.sh - Interactive disable/enable user account automation
# Run: sudo /usr/local/bin/user-disable.sh

set -o errexit
set -o pipefail
set -o nounset

LOGFILE="/var/log/user-disable.log"
OUTDIR="/opt/scan-report"
BACKUP_BASE="/root/user-disable-backups"
TIMESTAMP="$(date +%F_%H%M%S)"

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo)." >&2
  exit 1
fi

prompt_yesno() {
  # prompt_yesno "Question?" default_yes/no (y/n)
  local question="${1:-Proceed?}"
  local default="${2:-n}"
  local yn
  if [[ "$default" = "y" ]]; then
    read -rp "$question [Y/n]: " yn
    yn=${yn:-y}
  else
    read -rp "$question [y/N]: " yn
    yn=${yn:-n}
  fi
  case "$yn" in
    [Yy]*) return 0 ;;
    *)      return 1 ;;
  esac
}

read -rp "Action (disable / enable): " ACTION
ACTION="${ACTION,,}"   # lowercase

if [[ "$ACTION" != "disable" && "$ACTION" != "enable" ]]; then
  echo "Invalid action. Choose 'disable' or 'enable'." >&2
  exit 2
fi

read -rp "Username: " USER
if [[ -z "$USER" ]]; then
  echo "Username cannot be empty." >&2
  exit 3
fi

if ! id "$USER" &>/dev/null; then
  echo "User '$USER' does not exist." >&2
  exit 4
fi

# Confirm
if ! prompt_yesno "You chose: $ACTION user '$USER'. Continue?" "n"; then
  echo "Cancelled by user."
  exit 0
fi

mkdir -p "$OUTDIR" "$BACKUP_BASE" || true
mkdir -p "$(dirname "$LOGFILE")" || true
REPORT="${OUTDIR}/user-disable-${USER}-${TIMESTAMP}.txt"
backup_path="${BACKUP_BASE}/${USER}-${TIMESTAMP}"
mkdir -p "$backup_path"

log() {
  echo "[$(date +'%F %T')] $*" | tee -a "$LOGFILE" >> "$REPORT"
}

# detect current shell for possible restore info
current_shell="$(getent passwd "$USER" | awk -F: '{print $7}')"
user_home="$(eval echo "~${USER}")"

if [[ "$ACTION" == "disable" ]]; then
  {
    echo "User disable report for: $USER"
    echo "Timestamp: $TIMESTAMP"
    echo "Current shell: $current_shell"
    echo ""
  } > "$REPORT"

  log "START disable $USER"

  # SSH keys
  auth_keys="${user_home}/.ssh/authorized_keys"
  if [ -f "$auth_keys" ]; then
    mkdir -p "$backup_path/ssh"
    cp -a "$auth_keys" "$backup_path/ssh/authorized_keys.${TIMESTAMP}" && log "Backed up $auth_keys"
    if prompt_yesno "Disable SSH key login by chmod 000 $auth_keys?" "y"; then
      chmod 000 "$auth_keys" && log "Disabled $auth_keys (chmod 000)"
    else
      log "Skipped disabling authorized_keys"
    fi
  else
    log "No authorized_keys at $auth_keys"
  fi

  # Crontab
  if crontab -u "$USER" -l &>/dev/null; then
    mkdir -p "$backup_path/cron"
    crontab -u "$USER" -l > "$backup_path/cron/crontab.${TIMESTAMP}" || true
    if prompt_yesno "Remove crontab for $USER (backup saved)?" "n"; then
      crontab -u "$USER" -r && log "Removed crontab for $USER"
    else
      log "Kept crontab (backup present at $backup_path/cron/)"
    fi
  else
    log "No crontab for $USER"
  fi

  # Remove from privileged groups
  for g in sudo adm wheel docker admin; do
    if getent group "$g" &>/dev/null && id -nG "$USER" | grep -qw "$g"; then
      deluser "$USER" "$g" 2>/dev/null || gpasswd -d "$USER" "$g" 2>/dev/null || true
      log "Removed $USER from group $g"
    fi
  done

  # Lock + expire
  usermod -L "$USER" || true
  usermod -e 1 "$USER" || true
  log "Locked and expired account"

  # change shell to nologin
  if [ -x /usr/sbin/nologin ]; then
    usermod -s /usr/sbin/nologin "$USER" || true
    log "Shell set to /usr/sbin/nologin"
  else
    usermod -s /usr/sbin/false "$USER" || true
    log "Shell set to /usr/sbin/false"
  fi

  # Kill processes
  pkill -u "$USER" 2>/dev/null || true
  sleep 1
  if pgrep -u "$USER" >/dev/null; then
    pkill -9 -u "$USER" 2>/dev/null || true
    log "Forced SIGKILL to remaining processes"
  fi
  log "Killed user processes (if any)"

  # Home backup (tar.gz) - only if home exists and writable space likely present
  if [ -d "$user_home" ]; then
    tar -czf "$backup_path/home.${TIMESTAMP}.tar.gz" -C "$(dirname "$user_home")" "$(basename "$user_home")" 2>/dev/null || true
    du -sh "$user_home" 2>/dev/null | awk '{print "Home size: "$1}' >> "$REPORT" || true
    log "Attempted home backup to $backup_path"
  fi

  echo "" >> "$REPORT"
  echo "Backups saved to: $backup_path" >> "$REPORT"
  log "COMPLETE disable $USER"
  cp -a "$REPORT" "$OUTDIR/" 2>/dev/null || true
  echo "DISABLE complete. Report: $REPORT"
  exit 0

elif [[ "$ACTION" == "enable" ]]; then
  log "START enable $USER"

  # Unlock + remove expiry
  usermod -U "$USER" || true
  usermod -e "" "$USER" || true
  log "Unlocked account and removed expiry"

  # restore shell to /bin/bash (safe default)
  usermod -s /bin/bash "$USER" || true
  log "Set shell to /bin/bash (adjust manually if needed)"

  # attempt to restore most recent backup for authorized_keys & crontab
  latest_backup="$(ls -1d ${BACKUP_BASE}/${USER}-* 2>/dev/null | sort -r | head -n1 || true)"
  if [[ -n "$latest_backup" ]]; then
    if [[ -f "$latest_backup/ssh/authorized_keys."* ]]; then
      mkdir -p "$user_home/.ssh"
      cp -a "$latest_backup/ssh/authorized_keys."* "$user_home/.ssh/authorized_keys" 2>/dev/null || true
      chown "$USER":"$(id -gn $USER)" "$user_home/.ssh/authorized_keys" 2>/dev/null || true
      chmod 600 "$user_home/.ssh/authorized_keys" 2>/dev/null || true
      log "Restored authorized_keys from backup $latest_backup"
    else
      log "No authorized_keys backup found in $latest_backup"
    fi

    if [[ -f "$latest_backup/cron/crontab."* ]]; then
      crontab -u "$USER" "$latest_backup/cron/crontab."* 2>/dev/null || true
      log "Restored crontab for $USER from backup"
    else
      log "No crontab backup to restore in $latest_backup"
    fi
  else
    log "No backups found for $USER in $BACKUP_BASE"
  fi

  echo "" >> "$REPORT"
  log "COMPLETE enable $USER"
  cp -a "$REPORT" "$OUTDIR/" 2>/dev/null || true
  echo "ENABLE complete. Check $LOGFILE and $REPORT"
  exit 0
fi
