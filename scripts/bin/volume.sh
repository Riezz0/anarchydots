#!/usr/bin/env bash

# Config
STEP=5
SINK="@DEFAULT_AUDIO_SINK@"
ICON_LOW="audio-volume-low"
ICON_MED="audio-volume-medium"
ICON_HIGH="audio-volume-high"
ICON_MUTED="audio-volume-muted"

# Get current volume (integer)
get_volume() {
  wpctl get-volume "$SINK" | awk '{print int($2 * 100)}'
}

# Get mute status
is_muted() {
  wpctl get-volume "$SINK" | grep -q MUTED
}

# Choose icon based on volume
get_icon() {
  local vol=$1
  if is_muted; then
    echo "$ICON_MUTED"
  elif [ "$vol" -lt 30 ]; then
    echo "$ICON_LOW"
  elif [ "$vol" -lt 70 ]; then
    echo "$ICON_MED"
  else
    echo "$ICON_HIGH"
  fi
}

case "$1" in
  up)
    wpctl set-volume "$SINK" "${STEP}%+"
    notify
    ;;
  down)
    wpctl set-volume "$SINK" "${STEP}%-"
    notify
    ;;
  mute)
    wpctl set-mute "$SINK" toggle
    notify
    ;;
  *)
    echo "Usage: $0 {up|down|mute}"
    exit 1
    ;;
esac

