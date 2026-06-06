#!/bin/bash

# Simple status checker for wf-recorder
if pgrep -x "wf-recorder" > /dev/null; then
    # Recording is active
    echo '{"text": "󰓛", "tooltip": "Screen Recording Active", "class": "recording", "alt": "recording"}'
else
    # Not recording
    echo '{"text": "󰑊", "tooltip": "Screen Recorder Idle", "class": "idle", "alt": "idle"}'
fi
