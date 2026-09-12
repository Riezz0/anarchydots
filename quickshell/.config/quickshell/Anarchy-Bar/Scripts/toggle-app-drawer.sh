#!/usr/bin/env bash

set -u

pattern='quickshell/Anarchy-Bar/Q-Apps/AppDrawer'

if pgrep -f "$pattern" >/dev/null 2>&1; then
    pkill -f "$pattern"
else
    nohup qs -p "$HOME/.config/quickshell/Anarchy-Bar/Q-Apps/AppDrawer" \
        >/tmp/anarchy-app-drawer.log 2>&1 &
fi
