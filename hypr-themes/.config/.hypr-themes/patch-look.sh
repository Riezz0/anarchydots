#!/bin/bash
# Patch look.lua with saved bar settings (atomic: avoids flash on theme switch)
#
# Usage:
#   patch-look.sh                  — patch existing look.lua in-place (legacy)
#   patch-look.sh <source_hyprlook> — copy source, patch, then mv to look.lua (atomic)

BAR_JSON="$HOME/.config/quickshell/bar-settings.json"
LOOK_LUA="$HOME/.config/hypr/modules/look.lua"
[ -f "$BAR_JSON" ] || exit 0
[ -f "$LOOK_LUA" ] || exit 0

RADIUS=$(grep -o '"hyprlandRadius":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
BORDER=$(grep -o '"hyprlandBorderThickness":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
GAPIN=$(grep -o '"hyprlandGapIn":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
GAPOUT=$(grep -o '"hyprlandGapOut":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
OPACITY=$(grep -o '"hyprlandWindowOpacity":[[:space:]]*[0-9.]*' "$BAR_JSON" | grep -o '[0-9.]*$')
BLUREN=$(grep -o '"hyprlandBlurEnabled":[[:space:]]*\(true\|false\)' "$BAR_JSON" | grep -o 'true\|false')
BLURSIZE=$(grep -o '"hyprlandBlurSize":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
BLURPASSES=$(grep -o '"hyprlandBlurPasses":[[:space:]]*[0-9]*' "$BAR_JSON" | grep -o '[0-9]*$')
BLURVIB=$(grep -o '"hyprlandBlurVibrancy":[[:space:]]*[0-9.]*' "$BAR_JSON" | grep -o '[0-9.]*$')

# If a source hyprlook was provided, copy it to a temp file so we can
# patch there and then mv atomically — Hyprland never sees the unpatched version.
if [ -n "$1" ] && [ -f "$1" ]; then
    TMPFILE=$(mktemp "${LOOK_LUA}.XXXXXX")
    cp "$1" "$TMPFILE"
    TARGET="$TMPFILE"
else
    TARGET="$LOOK_LUA"
fi

[ -n "$RADIUS" ]   && sed -i "s/rounding\s*=\s*[0-9]\+/rounding = $RADIUS/g" "$TARGET"
[ -n "$RADIUS" ]   && sed -i "s/rounding_power\s*=\s*[0-9]\+/rounding_power = $RADIUS/g" "$TARGET"
[ -n "$BORDER" ]   && sed -i "s/border_size\s*=\s*[0-9]\+/border_size = $BORDER/g" "$TARGET"
[ -n "$GAPIN" ]    && sed -i "s/gaps_in\s*=\s*[0-9]\+/gaps_in  = $GAPIN/g" "$TARGET"
[ -n "$GAPOUT" ]   && sed -i "s/gaps_out\s*=\s*[0-9]\+/gaps_out = $GAPOUT/g" "$TARGET"
[ -n "$OPACITY" ]  && sed -i "s/active_opacity\s*=\s*[0-9.]\+/active_opacity    = $OPACITY/g" "$TARGET"
[ -n "$OPACITY" ]  && sed -i "s/inactive_opacity\s*=\s*[0-9.]\+/inactive_opacity  = $OPACITY/g" "$TARGET"
[ -n "$BLUREN" ]   && sed -i "s/\\benabled\\s*=\\s*true\\|\\benabled\\s*=\\s*false/enabled   = $BLUREN/g" "$TARGET"
[ -n "$BLURSIZE" ] && sed -i "s/\\bsize\\s*=\\s*[0-9]\\+/size      = $BLURSIZE/g" "$TARGET"
[ -n "$BLURPASSES" ] && sed -i "s/\\bpasses\\s*=\\s*[0-9]\\+/passes    = $BLURPASSES/g" "$TARGET"
[ -n "$BLURVIB" ]  && sed -i "s/\\bvibrancy\\s*=\\s*[0-9.]\\+/vibrancy  = $BLURVIB/g" "$TARGET"

# Atomic swap — Hyprland only sees the fully-patched file
if [ "$TARGET" != "$LOOK_LUA" ]; then
    mv "$TARGET" "$LOOK_LUA"
fi
