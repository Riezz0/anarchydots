#!/bin/bash

#========================#
#       TOKYO NIGHT      #
#========================#

#------------------------#
# VARIABLES
#------------------------#
USER_HOME="$HOME"
THEME_NAME="tokyo-night"
THEME_DISPLAY="Tokyo Night Theme"
THEME_DIR="$USER_HOME/.config/.hypr-themes/$THEME_NAME"

# Wallpaper
WALL_DIR="$USER_HOME/.config/wallpapers"
WALL="$WALL_DIR/Wall.png"

# Pywal
PYWAL="$USER_HOME/.config/pywal/themes/active.json"

# GTK and Icons
GTK_THEME="adw-gtk3-dark"
ICON_THEME="oomox-tokyo-night"

# Kvantum
KVANTUM_DIR="$USER_HOME/.config/Kvantum/pywal"
#------------------------#

#------------------------#
# SET WALLPAPER
#------------------------#
mkdir -p "$WALL_DIR"
cp "$WALL_DIR/tokyo-night.png" "$WALL"   # copy from wallpapers folder
chmod 644 "$WALL"
sync

# Set wallpaper with swww
swww img "$WALL" --transition-fps 144 --transition-step 255 --transition-type random

#------------------------#
# SET COLOR SCHEME
#------------------------#
cp -r "$THEME_DIR/pywal" "$PYWAL"
wal --theme "$PYWAL"  # synchronous to ensure cache files exist

#------------------------#
# COPY CONFIG FILES
#------------------------#
cp -r "$THEME_DIR/hypr-colors" "$USER_HOME/.config/hypr/colors.conf"
cp -r "$THEME_DIR/hyprlook" "$USER_HOME/.config/hypr/look.conf"
cp -r "$THEME_DIR/kitty" "$USER_HOME/.config/kitty/kitty.conf"
cp -r "$THEME_DIR/main-bar" "$USER_HOME/.config/waybar/main-bar/bar-style.css"
cp -r "$THEME_DIR/game-bar" "$USER_HOME/.config/waybar/game-bar/game-bar-style.css"
cp -r "$THEME_DIR/power-bar" "$USER_HOME/.config/waybar/power-bar/power-bar-style.css"
cp -r "$THEME_DIR/theme-bar" "$USER_HOME/.config/waybar/power-bar/theme-bar-style.css"
cp -r "$THEME_DIR/rofi" "$USER_HOME/.config/rofi/launcher/colors.rasi"
cp -r "$THEME_DIR/wf-recorder-toggle.sh" "$USER_HOME/.config/scripts/wf-recorder-toggle.sh"
cp -f "${HOME}"/.cache/wal/pywal.json "${HOME}"/.config/presets/user/pywal.json

#------------------------#
# SET GTK AND ICON THEME
#------------------------#
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
wait
gradience-cli apply -p ~/.config/presets/user/pywal.json --gtk both  
gradience-cli flatpak-overrides -e both 

#----------#
# SET FONT
#----------#
gsettings set org.gnome.desktop.interface document-font-name "MesloLGL Nerd Font 12"
gsettings set org.gnome.desktop.interface monospace-font-name "MesloLGL Mono Nerd Font 12"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "MesloLGL Mono Nerd Font 12"

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
# REFRESH INTERFACES
#------------------------#
hyprctl reload
kill -SIGUSR1 $(pidof kitty)

#------------------------#
# NOTIFICATION
#------------------------#
notify-send "$THEME_DISPLAY Loaded" & disown

