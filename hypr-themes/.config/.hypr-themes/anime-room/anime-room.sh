#!/bin/bash
set -uo pipefail

#==============================================================================#
#                                  ANIME ROOM                                  #
#==============================================================================#

#------------------------------------------------------------------------------#
# CONFIGURATION
#------------------------------------------------------------------------------#
THEME_NAME="anime-room"
THEME_DISPLAY="Anime Room"
THEME_DIR="$HOME/.config/.hypr-themes/$THEME_NAME"

WALL="$THEME_DIR/thumbnail.png"
PYWAL_ACTIVE="$HOME/.config/pywal/themes/active.json"
KVANTUM_DIR="$HOME/.config/Kvantum/pywal"

GTK_THEME="adw-gtk3-dark"
ICON_THEME="vimix_anime_room"
CURSOR_THEME="bibata_anime_room_modern"

#------------------------------------------------------------------------------#
# FUNCTIONS
#------------------------------------------------------------------------------#

prepare_directories() {
    mkdir -p \
        "$HOME/.config/vesktop/themes" \
        "$HOME/.config/gtk-3.0" \
        "$HOME/.config/gtk-4.0" \
        "$HOME/.local/share/dark" \
        "$HOME/.local/share/light" \
        "$KVANTUM_DIR"
}

apply_wallpaper() {
    awww img "$WALL" --transition-fps 144 --transition-step 255 --transition-type random
    cp "$WALL" "$HOME/.config/hypr/lock.png"
    cp "$WALL" "$HOME/.config/activebg/Wall.png"
    cp "$WALL" "/var/local/sddm-wallpaper/background.jpg" 2>/dev/null || true
}

generate_pywal() {
    cp "$THEME_DIR/pywal" "$PYWAL_ACTIVE"
    wal --theme "$PYWAL_ACTIVE"
    cat "$HOME/.cache/wal/colors.json" > "$HOME/.cache/wal/theme-colors.json"
    cp "$HOME/.cache/wal/colors.qml" "/var/local/sddm-wallpaper/PywalColors.qml" 2>/dev/null || true
}

apply_app_configs() {
    cp "$THEME_DIR/hypr-colors" "$HOME/.config/hypr/modules/colors.lua"
    bash "$HOME/.config/.hypr-themes/patch-look.sh" "$THEME_DIR/hyprlook"
    cp "$THEME_DIR/kitty" "$HOME/.config/kitty/kitty.conf"
    cp "$THEME_DIR/rofi" "$HOME/.config/rofi/launcher/colors.rasi"
    cp "$HOME/.cache/wal/colors-discord.css" "$HOME/.config/vesktop/themes/pywal-vencord.theme.css"
}

apply_gtk_and_rewaita() {
    rm -rf "$HOME/.config/gtk-4.0/"* "$HOME/.config/gtk-3.0/"*

    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    echo "$ICON_THEME" > "$HOME/.cache/current_icon_theme.txt"

    grep -vE "^(cat <<|EOF$)" "$HOME/.cache/wal/rewaita-pywal.css" > "$HOME/.local/share/dark/pywal.css"
    cp "$HOME/.local/share/dark/pywal.css" "$HOME/.local/share/light/pywal.css"

    pkill -f rewaita 2>/dev/null || true
    rewaita --theme=pywal >/dev/null 2>&1

    gtk4-update-icon-cache "$HOME/.config/gtk-4.0" 2>/dev/null || true
    gtk-update-icon-cache "$HOME/.config/gtk-3.0" 2>/dev/null || true

    # Live-reload open GTK3 and GTK4/Libadwaita apps without closing them
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
}

apply_kvantum() {
    while [ ! -f "$HOME/.cache/wal/pywal.kvconfig" ] || [ ! -f "$HOME/.cache/wal/pywal.svg" ]; do
        sleep 0.1
    done

    cp "$HOME/.cache/wal/pywal.kvconfig" "$KVANTUM_DIR/pywal.kvconfig"
    cp "$HOME/.cache/wal/pywal.svg" "$KVANTUM_DIR/pywal.svg"
}

apply_assets() {
    rm -rf "$HOME/.cache/fastfetch"
    cp "$THEME_DIR/arch-anime-room.png" "$HOME/.config/fastfetch/arch.png"
    cp "$THEME_DIR/arch-anime-room.png" "$HOME/.config/quickshell/Anarchy-Bar/Assets/arch.png"
}

refresh_session() {
    hyprctl setcursor "$CURSOR_THEME" 30
    bash "$HOME/.config/.hypr-themes/set-cursor-theme.sh" "$CURSOR_THEME"
    kill -SIGUSR1 "$(pidof kitty)" 2>/dev/null || true
    pywalfox update & disown

    cp "$THEME_DIR/$THEME_NAME.sh" "$HOME/.local/share/themes/hypr-theme-active.sh"
    notify-send -a "$THEME_DISPLAY" "Theme Loaded"
}

#------------------------------------------------------------------------------#
# MAIN EXECUTION
#------------------------------------------------------------------------------#
main() {
    prepare_directories
    apply_wallpaper
    generate_pywal
    apply_app_configs
    apply_gtk_and_rewaita
    apply_kvantum
    apply_assets
    refresh_session
}

main "$@"

