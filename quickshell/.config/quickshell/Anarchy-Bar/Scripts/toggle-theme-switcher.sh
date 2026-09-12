#!/usr/bin/env bash

set -u

pattern='quickshell/Anarchy-Bar/Q-Apps/ThemeSwitcher'

if pgrep -f "$pattern" >/dev/null 2>&1; then
    pkill -f "$pattern"
else
    nohup qs -p "$HOME/.config/quickshell/Anarchy-Bar/Q-Apps/ThemeSwitcher" \
        >/tmp/anarchy-theme-switcher.log 2>&1 &
fi
