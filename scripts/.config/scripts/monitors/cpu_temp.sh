#!/bin/bash

# -------------------------------
# Temperature thresholds (°C)
# Adjusted for Ryzen 3600X
# -------------------------------
IDLE_MAX=40
WARM_MAX=60
MODERATE_MAX=75
HIGH_MAX=85

# -------------------------------
# Nerd Font icons (same as GPU)
# -------------------------------
ICON_IDLE=""        # snowflake
ICON_WARM=""        # thermometer low
ICON_MODERATE=""    # thermometer half
ICON_HIGH=""        # thermometer high
ICON_CRITICAL=""    # fire

# -------------------------------
# Get CPU temperature from Tctl
# -------------------------------
TEMP=$(sensors | awk '/Tctl/ { gsub("\\+|°C","",$2); print int($2); exit }')

if [[ -z "$TEMP" ]]; then
    echo "{\"text\":\"CPU: ?\"}"
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
TEXT="CPU:${TEMP}°C"
echo "{\"text\":\"$TEXT\",\"class\":\"$CLASS\"}"

