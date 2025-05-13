#!/usr/bin/env zsh
set -euo pipefail

# Fix My WindowServer
# by iam404
# MIT License
# Only for macOS Sequoia  

# Exit silently if not macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 1
fi

DEFAULT_BACKUP="$HOME/.local/share/windowserver_backup"

# Delete only existing items matching given patterns
remove_items() {
  for pattern in "$@"; do
    for item in $pattern(.N); do
      echo "Deleting: $item"
      sudo rm -rf -- "$item"
    done
  done
}

# Copy only existing items matching given patterns into destination
copy_items() {
  local dest="$1"; shift
  mkdir -p -- "$dest"
  for pattern in "$@"; do
    for item in $pattern(.N); do
      echo "Copying: $item → $dest/"
      cp -- "$item" "$dest/"
    done
  done
}

# Command: Remove Chrome & Keystone
cmd_rm() {
  echo "→ Removing Chromium, Chrome & Keystone files…"
  remove_items \
    "/Applications/Google Chrome.app(/)" \
    "/Library/LaunchAgents/com.google*(.)" \
    "/Library/LaunchDaemons/com.google*(.)" \
    "/Library/Application Support/Google(/)" \
    "/Library/Preferences/com.google*(.)" \
    "/Library/Caches/com.google*(.)" \
    "$HOME/Library/LaunchAgents/com.google*(.)" \
    "$HOME/Library/Application Support/Google(/)" \
    "$HOME/Library/Preferences/com.google*(.)" \
    "$HOME/Library/Caches/com.google*(.)" \
    "$HOME/Library/Google(/)" \
    "$HOME/Library/Google/Chrome(/)" \
    "$HOME/Library/Saved Application State/com.google.Chrome.savedState(/)" \
    "$HOME/Library/Logs/GoogleSoftwareUpdateAgent.log" \
    "$HOME/Library/Logs/GoogleSoftwareUpdateDaemon.log"
  echo "✓ Removal complete."
}

# Command: Backup WindowServer prefs
cmd_bkup() {
  local dir="${1:-$DEFAULT_BACKUP}"
  echo "→ Backing up WindowServer prefs to $dir…"
  copy_items "$dir" \
    "$HOME/Library/Preferences/com.apple.windowserver.*(.N)" \
    "/Library/Preferences/com.apple.windowserver.*(.N)" \
    "/Library/Preferences/SystemConfiguration/com.apple.windowserver.*(.N)"
  echo "✓ Backup complete."
}

# Command: Reset WindowServer prefs and reboot
cmd_reset() {
  echo "→ Resetting WindowServer prefs…"
  remove_items \
    "$HOME/Library/Preferences/com.apple.windowserver.*(.N)" \
    "/Library/Preferences/com.apple.windowserver.*(.N)" \
    "/Library/Preferences/SystemConfiguration/com.apple.windowserver.*(.N)"
  echo "✓ Reset done. Rebooting now."
  sudo reboot
}

# Command: Restore WindowServer prefs from backup and reboot
cmd_restore() {
  local dir="${1:-$DEFAULT_BACKUP}"
  echo "→ Restoring WindowServer prefs from $dir…"
  copy_items "$HOME/Library/Preferences"    "$dir/com.apple.windowserver.*(.N)"
  copy_items "/Library/Preferences"          "$dir/com.apple.windowserver.*(.N)"
  copy_items "/Library/Preferences/SystemConfiguration" "$dir/com.apple.windowserver.*(.N)"
  echo "✓ Restore done. Rebooting now."
  sudo reboot
}

# Command: Full fix (rm → bkup → reset)
cmd_fix() {
  local dir="${1:-$DEFAULT_BACKUP}"
  cmd_rm
  cmd_bkup "$dir"
  cmd_reset
}

# Interactive menu if no command is provided
menu() {
  echo "Fix My WindowServer"
  echo
  echo "1) rm      — Remove Chromium, Chrome & Keystone"
  echo "2) bkup    — Back up WindowServer prefs"
  echo "3) reset   — Clear prefs and reboot"
  echo "4) restore — Restore prefs and reboot"
  echo "5) fix     — rm → bkup → reset"
  echo
  echo -n "Select [1–5]: "
  read -r choice
  case $choice in
    1) CMD=rm ;;
    2) CMD=bkup ;;
    3) CMD=reset ;;
    4) CMD=restore ;;
    5) CMD=fix ;;
    *) echo "Invalid choice." && exit 1 ;;
  esac
}

# Usage/help text
usage() {
  cat <<EOF
Usage: sudo fixmywindowserver [command] [backup_dir]

Commands:
  rm        Remove Chromium, Chrome & Keystone files
  bkup      Back up WindowServer prefs to [backup_dir] (optional)
  reset     Resets WindowServer configuration/preferences + Force Restart
  restore   Restore WindowServer prefs from [backup_dir] and reboot
  fix       remove → backup → reset | 5 = 1 + 2 + 3

If no command is given, an interactive menu will start.
Default backup_dir: $DEFAULT_BACKUP
EOF
  exit 0
}

# Argument parsing
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
  usage
elif [[ -n "${1:-}" ]]; then
  CMD=$1
  [[ $CMD =~ ^(bkup|restore|fix)$ ]] && DIR=${2:-$DEFAULT_BACKUP}
else
  menu
  DIR=$DEFAULT_BACKUP
fi

# Dispatch commands
case $CMD in
  rm)      cmd_rm ;;
  bkup)    cmd_bkup "$DIR" ;;
  reset)   cmd_reset ;;
  restore) cmd_restore "$DIR" ;;
  fix)     cmd_fix "$DIR" ;;
  *)       usage ;;
esac