#!/bin/bash

THEME_DIR="$HOME/.config/.hypr-themes"

printf "["

first=true

for dir in "$THEME_DIR"/*/; do
    name=$(basename "$dir")
    thumb="$dir/thumbnail.png"
    
    # First, try to find a script that matches the directory name
    script="$dir/$name.sh"
    if [ ! -f "$script" ]; then
        # If not found, try to find any other .sh file that's not a utility script
        script=$(find "$dir" -maxdepth 1 -name "*.sh" -type f | grep -v "wf-recorder-toggle.sh" | head -1)
        # If no theme-specific script found, use the first .sh file (even if it's a utility)
        if [ -z "$script" ]; then
            script=$(find "$dir" -maxdepth 1 -name "*.sh" -type f | head -1)
        fi
    fi

    if [ "$first" = true ]; then
        first=false
    else
        printf ","
    fi

    printf '\n{
      "name":"%s",
      "thumbnail":"%s",
      "script":"%s"
    }' \
    "$name" \
    "$thumb" \
    "$script"
done

printf "\n]"
