#!/bin/bash
set -uo pipefail

#========================#
#         MASJID         #
#========================#

#------------------------#
# VARIABLES
#------------------------#
THEME_NAME="masjid"
THEME_DISPLAY="Masjid"
THEME_DIR="$HOME/.config/.hypr-themes/$THEME_NAME"

WALL="$THEME_DIR/thumbnail.png"
PYWAL="$HOME/.config/pywal/themes/active.json"

GTK_THEME="adw-gtk3-dark"
ICON_THEME="vimix_masjid"
CURSOR_THEME="bibata_masjid_modern"

KVANTUM_DIR="$HOME/.config/Kvantum/pywal"

#------------------------#
# SET WALLPAPER
#------------------------#
awww img "$WALL" --transition-fps 144 --transition-step 255 --transition-type random
cp "$WALL" "$HOME/.config/hypr/lock.png"
cp "$WALL" "$HOME/.config/activebg/Wall.png"
cp "$WALL" "/var/local/sddm-wallpaper/background.jpg" 2>/dev/null || true

#------------------------#
# SET COLOR SCHEME
#------------------------#
cp "$THEME_DIR/pywal" "$PYWAL"
wal --theme "$PYWAL"
cat "$HOME/.cache/wal/colors.json" > "$HOME/.cache/wal/theme-colors.json"
cp ~/.cache/wal/colors.qml /var/local/sddm-wallpaper/PywalColors.qml 2>/dev/null || true

#------------------------#
# MAKE DIRECTORIES
#------------------------#
mkdir -p "$HOME/.config/vesktop/themes/" "$HOME/.config/gtk-3.0/" "$HOME/.config/gtk-4.0/" "$HOME/.local/share/dark" "$HOME/.local/share/light"

#------------------------#
# COPY CONFIG FILES
#------------------------#
cp "$THEME_DIR/hypr-colors" "$HOME/.config/hypr/modules/colors.lua"
# bash ~/.config/.hypr-themes/patch-look.sh "$THEME_DIR/hyprlook"
bash ~/.config/.hypr-themes/patch-look.sh "$THEME_DIR/hyprlook"
cp "$THEME_DIR/kitty" "$HOME/.config/kitty/kitty.conf"
cp "$THEME_DIR/rofi" "$HOME/.config/rofi/launcher/colors.rasi"
cp "$HOME/.cache/wal/colors-discord.css" "$HOME/.config/vesktop/themes/pywal-vencord.theme.css"

#------------------------#
# REMOVE CONFLICTING FILES
#------------------------#
rm -rf "$HOME/.config/gtk-4.0/"*
rm -rf "$HOME/.config/gtk-3.0/"*

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

while [ ! -f "$HOME/.cache/wal/pywal.kvconfig" ] || [ ! -f "$HOME/.cache/wal/pywal.svg" ]; do
    sleep 0.1
done

cp "$HOME/.cache/wal/pywal.kvconfig" "$KVANTUM_DIR/pywal.kvconfig"
cp "$HOME/.cache/wal/pywal.svg" "$KVANTUM_DIR/pywal.svg"

#------------------------#
# FASTFETCH
#------------------------#
rm -rf "$HOME/.cache/fastfetch"
cp "$THEME_DIR/masjid.png" "$HOME/.config/fastfetch/arch.png"

#------------------------#
# BAR ICON
#------------------------#
# cp "$THEME_DIR/masjid.png" "$HOME/.config/waybar/icons/arch.png"
cp "$THEME_DIR/masjid.png" "$HOME/.config/quickshell/Anarchy-Bar/Assets/arch.png"

#------------------------#
# REFRESH INTERFACES
#------------------------#
hyprctl setcursor "$CURSOR_THEME" 30
bash ~/.config/.hypr-themes/set-cursor-theme.sh "$CURSOR_THEME"
# Quickshell applies the Pywal colors without reloading the compositor.
kill -SIGUSR1 "$(pidof kitty)" 2>/dev/null || true
pywalfox update & disown
# REMOVED: killall quickshell
# REMOVED: bash /usr/local/bin/qbarmain.sh

#------------------------#
# COPY THEME
#------------------------#
cp "$THEME_DIR/$THEME_NAME.sh" "/home/$USER/.local/share/themes/hypr-theme-active.sh"

#------------------------#
# NOTIFICATION
#------------------------#

notify-send -a "$THEME_DISPLAY" "Theme Loaded"

