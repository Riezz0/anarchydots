#!/bin/bash
# Patch look.lua with saved bar settings (avoids flash on theme switch)
BAR_JSON="$HOME/.config/quickshell/bar-settings.json"
LOOK_LUA="$HOME/.config/hypr/modules/look.lua"
[ -f "$BAR_JSON" ] || exit 0
[ -f "$LOOK_LUA" ] || exit 0
RADIUS=$(grep -o '"hyprlandRadius":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
BORDER=$(grep -o '"hyprlandBorderThickness":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
[ -n "$RADIUS" ] && sed -i "s/rounding\s*=\s*[0-9]\+/rounding = $RADIUS/g" "$LOOK_LUA"
[ -n "$RADIUS" ] && sed -i "s/rounding_power\s*=\s*[0-9]\+/rounding_power = $RADIUS/g" "$LOOK_LUA"
[ -n "$BORDER" ] && sed -i "s/border_size\s*=\s*[0-9]\+/border_size = $BORDER/g" "$LOOK_LUA"
