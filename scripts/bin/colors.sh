#!/bin/bash
# Re-derive the pywal palette from a wallpaper and refresh every consumer.
#
# Usage: colors.sh [wallpaper]
#   With no argument, uses the currently active wallpaper.

set -u

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "$SELF")/../.." && pwd -P)"

WALL="${1:-}"
if [ -z "$WALL" ]; then
    for candidate in "$HOME/.config/activebg/Wall.png" "$HOME/.config/hypr/lock.png"; do
        if [ -f "$candidate" ]; then
            WALL="$candidate"
            break
        fi
    done
fi

if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    echo "colors.sh: no wallpaper found; pass one explicitly: colors.sh /path/to/image" >&2
    exit 1
fi

wal -i "$WALL" --cols16 || exit 1

# Terminal: kitty includes ~/.cache/wal/colors-kitty.conf directly, but keep
# the stowed colors.conf in sync for tools that read it.
mkdir -p "$HOME/.config/kitty"
cp -f "$HOME/.cache/wal/colors-kitty.conf" "$HOME/.config/kitty/colors.conf"

# Hyprland / Waybar (when present).
if [ -d "$HOME/.config/hypr" ] || [ -f "$HOME/.cache/wal/colors-hyprland.conf" ]; then
    mkdir -p "$HOME/.config/hypr"
    [ -f "$HOME/.cache/wal/colors-hyprland.conf" ] && \
        cp -f "$HOME/.cache/wal/colors-hyprland.conf" "$HOME/.config/hypr/colors.conf"
fi
if [ -d "$HOME/.config/waybar" ] || [ -f "$HOME/.cache/wal/colors-waybar.css" ]; then
    mkdir -p "$HOME/.config/waybar"
    [ -f "$HOME/.cache/wal/colors-waybar.css" ] && \
        cp -f "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/waybar/colors.css"
fi

# Anarchy-Shell / Caelestia scheme. Prefer the installed helper, then the
# checkout this script came from, so a fresh VM works without extra setup.
SYNC="$HOME/.local/bin/shell-theme-sync"
[ -x "$SYNC" ] || SYNC="/usr/local/bin/shell-theme-sync"
[ -x "$SYNC" ] || SYNC="$(command -v shell-theme-sync 2>/dev/null || true)"

if [ -n "$SYNC" ]; then
    "$SYNC" >/dev/null 2>&1 || true
else
    BRIDGE="$HOME/.local/bin/wal-to-caelestia"
    [ -x "$BRIDGE" ] || BRIDGE="$REPO_ROOT/local-bin/bin/wal-to-caelestia"
    [ -f "$BRIDGE" ] && python3 "$BRIDGE" pywal >/dev/null 2>&1
fi

# Reload running consumers. Kitty reloads its config on SIGUSR1.
pkill -SIGUSR1 -x kitty 2>/dev/null || true
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -x waybar 2>/dev/null || true
    waybar >/dev/null 2>&1 &
fi

pywalfox update >/dev/null 2>&1 || true
