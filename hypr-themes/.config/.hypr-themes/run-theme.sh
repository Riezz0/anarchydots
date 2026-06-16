#!/bin/bash
# Detached theme runner
LOG="/tmp/theme-apply.log"
THEME_SCRIPT="$1"

echo "[$(date)] Starting theme: $THEME_SCRIPT" >> "$LOG"

if [ -z "$THEME_SCRIPT" ] || [ ! -f "$THEME_SCRIPT" ]; then
    echo "[$(date)] ERROR: Script not found: $THEME_SCRIPT" >> "$LOG"
    exit 1
fi

bash "$THEME_SCRIPT" >> "$LOG" 2>&1
EXIT_CODE=$?

echo "[$(date)] Script finished with exit code: $EXIT_CODE" >> "$LOG"

# Check if quickshell is running, restart if not
if ! pgrep -x quickshell > /dev/null 2>&1; then
    echo "[$(date)] Quickshell not running, restarting via qbarmain.sh" >> "$LOG"
    bash /usr/local/bin/qbarmain.sh >> "$LOG" 2>&1
else
    echo "[$(date)] Quickshell is running" >> "$LOG"
fi
