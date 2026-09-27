#!/usr/bin/env bash

set -u

pattern='quickshell/Anarchy-Bar/Q-Apps/ThemeSwitcher'
state_file="$HOME/.cache/anarchy-theme-switcher.state"
mkdir -p "$(dirname "$state_file")"

if pgrep -f "$pattern" >/dev/null 2>&1; then
    printf 'closed\n' > "$state_file"
    pkill -f "$pattern"
else
    printf 'open\n' > "$state_file"
    nohup qs -p "$HOME/.config/quickshell/Anarchy-Bar/Q-Apps/ThemeSwitcher" \
        >/tmp/anarchy-theme-switcher.log 2>&1 &
fi
