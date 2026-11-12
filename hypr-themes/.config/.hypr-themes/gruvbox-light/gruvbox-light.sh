#!/bin/bash

#========================#
#     GRUVBOX_LIGHT      #
#========================#

#------------------------#
# VARIABLES
#------------------------#
USER_HOME="$HOME"
THEME_NAME="gruvbox-light"
THEME_DISPLAY="Gruvbox Light"
THEME_DIR="$USER_HOME/.config/.hypr-themes/$THEME_NAME"

# Wallpaper
WALL="$USER_HOME/.config/.hypr-themes/$THEME_NAME/thumbnail.png"

# Pywal
PYWAL="$USER_HOME/.config/pywal/themes/active.json"

# GTK, Icons and Cursors
GTK_THEME="graphite-anarchy-gruvbox-dark"
ICON_THEME="vimix_gruvbox_light"
CURSOR_THEME="bibata_gruvbox_light_modern"

# Kvantum
KVANTUM_DIR="$USER_HOME/.config/Kvantum/pywal"
#------------------------#

#------------------------#
# SET WALLPAPER
#------------------------#
awww img "$WALL" --transition-fps 144 --transition-step 255 --transition-type random
cp -r "$WALL" "/home/$USER/.config/hypr/lock.png"
cp -r "$WALL" "/home/$USER/.config/activebg/Wall.png"
cp "$WALL" "/var/local/sddm-wallpaper/background.jpg" 2>/dev/null || true

#------------------------#
# SET COLOR SCHEME
#------------------------#
cp -r "$THEME_DIR/pywal" "$PYWAL"
wal --theme "$PYWAL"  # synchronous to ensure cache files exist
cat "$HOME/.cache/wal/colors.json" > "$HOME/.cache/wal/theme-colors.json"
cp ~/.cache/wal/colors.qml /var/local/sddm-wallpaper/PywalColors.qml 2>/dev/null || true


#------------------------#
# MAKE DIRECTORIES
#------------------------#
mkdir -p /home/$USER/.config/vesktop/themes/

#------------------------#
# COPY CONFIG FILES
#------------------------#
cp -r "$THEME_DIR/hypr-colors" "$USER_HOME/.config/hypr/modules/colors.lua"
# bash ~/.config/.hypr-themes/patch-look.sh "$THEME_DIR/hyprlook"
bash ~/.config/.hypr-themes/patch-look.sh "$THEME_DIR/hyprlook"
cp -r "$THEME_DIR/kitty" "$USER_HOME/.config/kitty/kitty.conf"
cp -r "$THEME_DIR/rofi" "$USER_HOME/.config/rofi/launcher/colors.rasi"
cp -r $HOME/.cache/wal/colors-discord.css $HOME/.config/vesktop/themes/pywal-vencord.theme.css
#--------------------------#
# REMOVE CONFLICTING FILES
#--------------------------#
rm -rf /home/$USER/.config/gtk-4.0/*
rm -rf /home/$USER/.config/gtk-3.0/*

#------------------------#
# SET ICON & REWAITA THEME
#------------------------#
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
echo "$ICON_THEME" > "$HOME/.cache/current_icon_theme.txt"

grep -vE "^(cat <<|EOF$)" "$HOME/.cache/wal/rewaita-pywal.css" > "$HOME/.local/share/dark/pywal.css"
cp "$HOME/.local/share/dark/pywal.css" "$HOME/.local/share/light/pywal.css"

pkill -f rewaita 2>/dev/null || true
rewaita --theme=pywal >/dev/null 2>&1

gtk4-update-icon-cache "$HOME/.config/gtk-4.0" 2>/dev/null || true
gtk-update-icon-cache "$HOME/.config/gtk-3.0" 2>/dev/null || true

if [[ "$GTK_THEME" == *"dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.1
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.1
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
fi
#------------------------#
# SET KVANTUM THEME
#------------------------#
mkdir -p "$KVANTUM_DIR"

# Wait until Pywal cache files exist
while [ ! -f "$HOME/.cache/wal/pywal.kvconfig" ] || [ ! -f "$HOME/.cache/wal/pywal.svg" ]; do
    sleep 0.1
done

cp "$HOME/.cache/wal/pywal.kvconfig" "$KVANTUM_DIR/pywal.kvconfig"
cp "$HOME/.cache/wal/pywal.svg" "$KVANTUM_DIR/pywal.svg"

#------------------------#
# FASTFETCH
#------------------------#
rm -rf ~/.cache/fastfetch 
cp -r "$THEME_DIR/arch-gruvbox-light.png" "/home/$USER/.config/fastfetch/arch.png"

#------------------------#
# REFRESH INTERFACES
#------------------------#
hyprctl setcursor "$CURSOR_THEME" 30
bash ~/.config/.hypr-themes/set-cursor-theme.sh "$CURSOR_THEME"
# Quickshell applies the Pywal colors without reloading the compositor.
kill -SIGUSR1 $(pidof kitty)
pywalfox update & disown 
#swaync-client -rs
#bash /home/$USER/.config/scripts/waybar.sh
# REMOVED: killall quickshell
# REMOVED: bash /usr/local/bin/qbarmain.sh
wait

#------------------------#
# COPY THEME
#------------------------#
cp "$THEME_DIR/$THEME_NAME.sh" "/home/$USER/.local/share/themes/hypr-theme-active.sh"

#------------------------#
# NOTIFICATION
#------------------------#
notify-send -a "$THEME_DISPLAY" "Theme Loaded"

