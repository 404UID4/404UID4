#!/usr/bin/env zsh
set -euo pipefail

# macOS Sequoia (15.x) Fix WindowServer + Chrome Keystone Removal Utility
# I'm new to this. It has flat backups, verbose output, and MIT License

trap 'echo "Interrupted. Exiting."; exit 1' INT TERM

###############
# Environment #
###############

# 1) Confirm running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: This script only supports macOS. Exiting." >&2
  exit 1
fi

# 2) Confirm macOS Sequoia (15.x)
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=${OS_VERSION%%.*}
if [[ "$OS_MAJOR" -ne 15 ]]; then
  echo "Error: This script only supports macOS Sequoia (15.x). Detected $OS_VERSION. Exiting." >&2
  exit 1
fi

# 3) Require root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run with sudo or as root." >&2
  exit 1
fi

# 4) Determine real user home for backups
if [[ -n "${SUDO_USER:-}" ]]; then
  USER_HOME=$(eval echo "~$SUDO_USER")
else
  USER_HOME="$HOME"
fi

DEFAULT_BACKUP="${USER_HOME}/.local/share/windowserver_backup"

# 5) Verify required commands
for cmd in ditto rm reboot; do
  if ! command -v $cmd &>/dev/null; then
    echo "Error: Required command '$cmd' not found. Exiting." >&2
    exit 1
  fi
done

####################
# Path Definitions #
####################

# Chrome & Keystone artifacts (explicit, no wildcards)
chrome_items=(
  "/Applications/Google Chrome.app"
  "/Library/LaunchAgents/com.google.keystone.agent.plist"
  "/Library/LaunchDaemons/com.google.keystone.daemon.plist"
  "/Library/Application Support/Google"
  "/Library/Preferences/com.google.Chrome.plist"
  "/Library/Caches/com.google.Chrome"
  "${USER_HOME}/Library/LaunchAgents/com.google.keystone.agent.plist"
  "${USER_HOME}/Library/Application Support/Google"
  "${USER_HOME}/Library/Preferences/com.google.Chrome.plist"
  "${USER_HOME}/Library/Caches/com.google.Chrome"
  "${USER_HOME}/Library/Google"
  "${USER_HOME}/Library/Saved Application State/com.google.Chrome.savedState"
  "${USER_HOME}/Library/Logs/GoogleSoftwareUpdateAgent.log"
  "${USER_HOME}/Library/Logs/GoogleSoftwareUpdateDaemon.log"
)

# WindowServer preference files
ws_prefs=(
  "${USER_HOME}/Library/Preferences/com.apple.windowserver.plist"
  "/Library/Preferences/com.apple.windowserver.plist"
  "/Library/Preferences/SystemConfiguration/com.apple.windowserver.plist"
)

####################
# Core Subroutines #
####################

remove_items() {
  for item in "$@"; do
    if [[ -e "$item" ]]; then
      echo "Removing: $item"
      rm -rf -- "$item" || echo "Warning: Failed to remove $item" >&2
    else
      echo "Skipped (not found): $item"
    fi
  done
}

backup_items() {
  local dest="$1"; shift
  echo "Creating backup directory: $dest"
  mkdir -p -- "$dest"
  for item in "$@"; do
    if [[ -e "$item" ]]; then
      echo "Backing up: $item → $dest/"
      ditto "$item" "$dest/" || echo "Warning: Backup failed for $item" >&2
    else
      echo "Skipped (not found): $item"
    fi
  done
}

confirm_reboot() {
  echo -n "Reboot required. Reboot now? (y/n): "
  read -r confirm
  if [[ "$confirm" =~ ^[yY]$ ]]; then
    reboot
  else
    echo "Reboot cancelled. Please reboot manually later."
  fi
}

################
# Command Wrap #
################

cmd_rm() {
  echo "→ Removing Chrome & Keystone files..."
  remove_items "${chrome_items[@]}"
  echo "✓ Chrome removal complete."
}

cmd_bkup() {
  local dir="${1:-$DEFAULT_BACKUP}"
  echo "→ Backing up WindowServer preferences to $dir..."
  backup_items "$dir" "${ws_prefs[@]}"
  echo "✓ Backup complete."
}

cmd_reset() {
  echo "→ Resetting WindowServer preferences..."
  remove_items "${ws_prefs[@]}"
  echo "✓ Preferences reset."
  confirm_reboot
}

cmd_restore() {
  local dir="${1:-$DEFAULT_BACKUP}"
  echo "→ Restoring WindowServer preferences from $dir..."
  for item in "${ws_prefs[@]}"; do
    local filename=$(basename "$item")
    local backup_file="$dir/$filename"
    if [[ -e "$backup_file" ]]; then
      echo "Restoring: $backup_file → $(dirname "$item")/"
      ditto "$backup_file" "$(dirname "$item")/" || echo "Error: Restore failed for $backup_file" >&2
    else
      echo "Skipped (not found): $backup_file"
    fi
  done
  echo "✓ Restore complete."
  confirm_reboot
}

cmd_fix() {
  echo "→ Performing full fix: Remove → Backup → Reset"
  cmd_rm
  cmd_bkup "${1:-$DEFAULT_BACKUP}"
  cmd_reset
}

###############
# Usage & Menu #
###############

usage() {
  cat <<EOF
Usage: sudo $(basename "$0") [command] [backup_dir]

Commands:
  rm        Remove Chrome & Keystone files.
  bkup      Backup WindowServer prefs (default: $DEFAULT_BACKUP).
  reset     Reset WindowServer prefs (prompts reboot).
  restore   Restore prefs from backup (prompts reboot).
  fix       Full fix: rm → bkup → reset.

EOF
  exit 0
}

if [[ $# -eq 0 ]]; then
  usage
fi

case "$1" in
  -h|--help) usage ;;
  rm|bkup|reset|restore|fix) CMD="$1" ;;
  *) echo "Error: Unknown command '$1'."; usage ;;
esac

# Pass backup dir for bkup/restore/fix
if [[ "$CMD" == "bkup" || "$CMD" == "restore" || "$CMD" == "fix" ]]; then
  DIR="${2:-$DEFAULT_BACKUP}"
fi

# Dispatch
case "$CMD" in
  rm)      cmd_rm ;;
  bkup)    cmd_bkup "$DIR" ;;
  reset)   cmd_reset ;;
  restore) cmd_restore "$DIR" ;;
  fix)     cmd_fix "$DIR" ;;
esac
