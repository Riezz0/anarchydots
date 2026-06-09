#!/bin/bash

# -------------------------------
# Temperature thresholds (°C)
# -------------------------------
IDLE_MAX=35
WARM_MAX=55
MODERATE_MAX=75
HIGH_MAX=85

# -------------------------------
# Nerd Font icons
# -------------------------------
ICON_IDLE=""
ICON_WARM=""
ICON_MODERATE=""
ICON_HIGH=""
ICON_CRITICAL=""

# -------------------------------
# Get GPU temperature
# -------------------------------
TEMP=$(sensors | awk '/junction/ {
    gsub("\\+|°C","",$2);
    print int($2);
    exit
}')

if [[ -z "$TEMP" ]]; then
    echo "{\"text\":\"GPU: ?\"}"
    exit 0
fi

# -------------------------------
# Determine state
# -------------------------------
if (( TEMP <= IDLE_MAX )); then
    ICON=$ICON_IDLE
    CLASS="idle"

elif (( TEMP <= WARM_MAX )); then
    ICON=$ICON_WARM
    CLASS="warm"

elif (( TEMP <= MODERATE_MAX )); then
    ICON=$ICON_MODERATE
    CLASS="moderate"

elif (( TEMP < HIGH_MAX )); then
    ICON=$ICON_HIGH
    CLASS="high"

else
    ICON=$ICON_CRITICAL
    CLASS="critical"
fi

# -------------------------------
# Waybar output (Pango span)
# -------------------------------
TEXT="GPU:${TEMP}°C"

echo "{\"text\":\"$TEXT\",\"class\":\"$CLASS\"}"

