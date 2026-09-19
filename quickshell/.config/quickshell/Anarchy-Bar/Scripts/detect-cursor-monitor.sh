#!/bin/sh

POS=$(hyprctl cursorpos 2>/dev/null || true)
X=$(printf '%s' "$POS" | awk -F', ' '{print $1}')
Y=$(printf '%s' "$POS" | awk -F', ' '{print $2}')

# Prefer the monitor under the cursor, but always return a usable output.
if printf '%s' "$X" | grep -Eq '^-?[0-9]+$' && printf '%s' "$Y" | grep -Eq '^-?[0-9]+$'; then
    monitor=$(hyprctl monitors -j 2>/dev/null | jq -r --argjson x "$X" --argjson y "$Y" \
        '[.[] | select($x >= .x and $x < .x + .width and $y >= .y and $y < .y + .height)] | .[0].name // empty' 2>/dev/null)
    if [ -n "$monitor" ]; then
        printf '%s\n' "$monitor"
        exit 0
    fi
fi

hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.focused == true)][0].name // .[0].name // empty' 2>/dev/null
