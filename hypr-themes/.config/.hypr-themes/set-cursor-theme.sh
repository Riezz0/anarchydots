#!/usr/bin/env bash
set -euo pipefail

CURSOR_THEME="${1:-}"
ICON_THEME_FILE="/usr/share/icons/default/index.theme"
SDDM_CURSOR_FILE="$HOME/.config/.hypr-themes/cursor-theme.txt"
SDDM_CONF="/etc/sddm.conf"

if [[ -z "$CURSOR_THEME" ]]; then
    echo "Usage: $0 <cursor-theme-name>" >&2
    exit 1
fi

if [[ ! "$CURSOR_THEME" =~ ^[[:alnum:]_.-]+$ ]]; then
    echo "Invalid cursor theme name: $CURSOR_THEME" >&2
    exit 1
fi

# Keep the selected cursor in the Hypr themes config directory, then use that
# file to update the greeter's explicit CursorTheme setting.
mkdir -p "$(dirname "$SDDM_CURSOR_FILE")"
printf '%s\n' "$CURSOR_THEME" > "$SDDM_CURSOR_FILE"

# Updating the system cursor and SDDM settings requires root privileges.
sudo -v

sudo install -d -m 755 "$(dirname "$ICON_THEME_FILE")"
if sudo test -f "$ICON_THEME_FILE"; then
    if sudo grep -qE '^[[:space:]]*Inherits=' "$ICON_THEME_FILE"; then
        sudo sed -i -E "s/^[[:space:]]*Inherits=.*/Inherits=$CURSOR_THEME/" "$ICON_THEME_FILE"
    else
        printf 'Inherits=%s\n' "$CURSOR_THEME" | sudo tee -a "$ICON_THEME_FILE" >/dev/null
    fi
else
    printf '[Icon Theme]\nInherits=%s\n' "$CURSOR_THEME" | sudo tee "$ICON_THEME_FILE" >/dev/null
fi

if ! sudo test -f "$SDDM_CONF"; then
    echo "Cannot update SDDM cursor theme: $SDDM_CONF does not exist" >&2
    exit 1
fi

SDDM_CURSOR_THEME="$(cat "$SDDM_CURSOR_FILE")"
CONFIG_TMP="$(mktemp)"
trap 'rm -f "$CONFIG_TMP"' EXIT

sudo cat "$SDDM_CONF" | awk -v cursor="$SDDM_CURSOR_THEME" '
    function write_cursor() {
        if (!cursor_written) {
            print "CursorTheme=" cursor
            cursor_written = 1
        }
    }

    /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
        if (in_theme) write_cursor()
        in_theme = ($0 ~ /^[[:space:]]*\[Theme\][[:space:]]*$/)
        if (in_theme) theme_found = 1
        print
        next
    }

    in_theme && /^[[:space:]]*CursorTheme[[:space:]]*=/ {
        write_cursor()
        next
    }

    { print }

    END {
        if (in_theme) write_cursor()
        if (!theme_found) {
            print ""
            print "[Theme]"
            print "CursorTheme=" cursor
        }
    }
' > "$CONFIG_TMP"

sudo install -o root -g root -m 644 "$CONFIG_TMP" "$SDDM_CONF"
