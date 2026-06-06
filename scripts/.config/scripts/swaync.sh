#!/bin/bash

PROCESS_NAME="swaync"

echo "Attempting to aggressively kill and verify '$PROCESS_NAME'..."

while pgrep "$PROCESS_NAME" > /dev/null; do
    echo "Killing '$PROCESS_NAME'..."
    # Use pkill for efficiency, and -9 for SIGKILL (forceful termination)
    pkill -9 "$PROCESS_NAME"
    # Wait a very short period to allow the kernel to clean up
    sleep 0.1
done

swaync-client -rs

echo "'$PROCESS_NAME' process not found. It has been successfully killed."
