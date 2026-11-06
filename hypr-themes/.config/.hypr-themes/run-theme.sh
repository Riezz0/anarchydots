#!/bin/bash
# Detached theme runner
LOG="/tmp/theme-apply.log"
THEME_SCRIPT="$1"

echo "[$(date)] Starting theme: $THEME_SCRIPT" >> "$LOG"

if [ -z "$THEME_SCRIPT" ] || [ ! -f "$THEME_SCRIPT" ]; then
    echo "[$(date)] ERROR: Script not found: $THEME_SCRIPT" >> "$LOG"
    exit 1
fi

# Run theme script — it handles hyprlook copy, patching, killall, and restart
bash "$THEME_SCRIPT" >> "$LOG" 2>&1

# Reapply user-managed Hyprland values after any theme script copy, including
# future theme scripts that still copy hyprlook directly.
bash "$(dirname "$0")/patch-look.sh" --sync-all >> "$LOG" 2>&1

echo "[$(date)] Script finished" >> "$LOG"

#------------------------#
# CAELESTIA SHELL COLORS #
#------------------------#
theme_dir="$(dirname "$THEME_SCRIPT")"
theme_name="$(basename "$theme_dir")"
python3 "$HOME/anarchydots/scripts/bin/wal-to-caelestia.py" "$theme_name" >> "$LOG" 2>&1
