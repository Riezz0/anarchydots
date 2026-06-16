#!/bin/bash

# Script to automatically fix theme scripts to work out of the box
# This ensures that when new themes are added, they work without manual intervention

THEME_DIR="/home/riezzo/.config/.hypr-themes"
LOG_FILE="/tmp/fix-theme-scripts.log"

echo "[$(date)] Starting theme script fix" >> "$LOG_FILE"

# Find all theme directories
for theme_dir in "$THEME_DIR"/*/; do
    # Skip if it's a file or the parent directory
    if [ ! -d "$theme_dir" ] || [[ "$(basename "$theme_dir")" == "." || "$(basename "$theme_dir")" == ".." ]]; then
        continue
    fi
    
    theme_name=$(basename "$theme_dir")
    echo "[$(date)] Processing theme: $theme_name" >> "$LOG_FILE"
    
    # Find the script file (any .sh file in the directory)
    script_candidates=$(find "$theme_dir" -name "*.sh" -type f)
    
    if [ -n "$script_candidates" ]; then
        # Use the first script found
        script_file=$(echo "$script_candidates" | head -1)
        echo "[$(date)] Found script at: $script_file" >> "$LOG_FILE"
    else
        echo "[$(date)] WARNING: No script found for theme $theme_name" >> "$LOG_FILE"
        continue
    fi
    
    # Make script executable
    chmod +x "$script_file"
    echo "[$(date)] Made script executable: $script_file" >> "$LOG_FILE"
    
    # Fix THEME_NAME variable in script
    if grep -q "^THEME_NAME=\"" "$script_file"; then
        # Use a more robust approach with sed
        sed -i "s/^THEME_NAME=\"[^\"]*\"/THEME_NAME=\"$theme_name\"/" "$script_file"
        echo "[$(date)] Fixed THEME_NAME variable in $script_file" >> "$LOG_FILE"
    else
        echo "[$(date)] WARNING: THEME_NAME variable not found in $script_file" >> "$LOG_FILE"
    fi
    
    # Fix WALL variable if it references the wrong theme name
    if grep -q "WALL=\"\$USER_HOME/.config/.hypr-themes/" "$script_file"; then
        sed -i "s|WALL=\"\$USER_HOME/.config/.hypr-themes/.*|WALL=\"\$USER_HOME/.config/.hypr-themes/$theme_name/thumbnail.png|" "$script_file"
        echo "[$(date)] Fixed WALL variable in $script_file" >> "$LOG_FILE"
    fi
    
    # Fix THEME_DIR variable if it references the wrong theme name
    if grep -q "^THEME_DIR=\"\$USER_HOME/.config/.hypr-themes/" "$script_file"; then
        sed -i "s|^THEME_DIR=\"\$USER_HOME/.config/.hypr-themes/.*|THEME_DIR=\"\$USER_HOME/.config/.hypr-themes/$theme_name|" "$script_file"
        echo "[$(date)] Fixed THEME_DIR variable in $script_file" >> "$LOG_FILE"
    fi
    
    echo "[$(date)] Finished processing theme: $theme_name" >> "$LOG_FILE"
    echo

done

echo "[$(date)] Finished fixing all theme scripts" >> "$LOG_FILE"
echo "All theme scripts have been fixed and are ready to use!"
