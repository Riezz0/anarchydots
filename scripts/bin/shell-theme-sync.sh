#!/usr/bin/env bash
# Keeps Anarchy-Shell colours + wallpaper in sync with pywal, no matter how
# the user switches themes (run-theme.sh, direct script, manual `wal`, etc).
# Idempotent: does nothing unless ~/.cache/wal/colors.json (or the theme
# wallpaper target) is newer than the last synced state.

set -u

HOME_DIR="${HOME:-/home/$USER}"
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "$SELF")/../.." && pwd -P)"
ACTIVE="$HOME_DIR/.local/share/themes/hypr-theme-active.sh"
WAL_COLORS="$HOME_DIR/.cache/wal/colors.json"
SCHEME="$HOME_DIR/.local/state/caelestia/scheme.json"
PATH_TXT="$HOME_DIR/.local/state/caelestia/wallpaper/path.txt"

# Prefer the installed bridge, then the checkout this script came from.
BRIDGE="$HOME_DIR/.local/bin/wal-to-caelestia"
[ -x "$BRIDGE" ] || BRIDGE="/usr/local/bin/wal-to-caelestia"
[ -x "$BRIDGE" ] || BRIDGE="$(command -v wal-to-caelestia 2>/dev/null || true)"
[ -x "$BRIDGE" ] || BRIDGE="$REPO_ROOT/scripts/bin/wal-to-caelestia.py"

[ -f "$WAL_COLORS" ] || exit 0
[ -x "$BRIDGE" ] || exit 0

# Resolve the active theme + wallpaper target the same way the bridge does:
# THEME_NAME= and WALL= lines from hypr-theme-active.sh (expand $vars).
THEME="$(sed -n 's/^THEME_NAME="\(.*\)"/\1/p' "$ACTIVE" 2>/dev/null)"
WALL_LINE="$(grep -m1 '^WALL=' "$ACTIVE" 2>/dev/null | cut -d= -f2- | tr -d '"')"
# literal variable substitution only (no eval — $THEME_NAME is not exported)
WALL="$(sed -e "s|\$USER_HOME|$HOME_DIR|g" -e "s|\$THEME_NAME|$THEME|g" -e "s|\$HOME|$HOME_DIR|g" <<<"$WALL_LINE")"
[ -n "$WALL" ] && { [ -f "$WALL" ] || WALL=""; } || true

synced=0

# 1) colours: resync when pywal palette is newer than the scheme
if [ "$WAL_COLORS" -nt "$SCHEME" ]; then
    "$BRIDGE" "${THEME:-pywal}" >/dev/null 2>&1
    synced=1
# 2) wallpaper: resync (also refreshes colours) when the registered wall
#    differs from the active theme's wallpaper target
elif [ -n "$WALL" ] && [ "$(cat "$PATH_TXT" 2>/dev/null)" != "$WALL" ]; then
    "$BRIDGE" "${THEME:-pywal}" >/dev/null 2>&1
    synced=1
fi

echo "shell-theme-sync: resynced colours=$synced"
