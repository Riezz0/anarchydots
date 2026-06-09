#!/usr/bin/env bash

#AUR Packages#
packages=(
    python-yapsy swww qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects 
    hypridle hyprlock hyprpicker tree qt5ct qt6ct qt5-styleplugins 
    wl-clipboard firefox code vlc nwg-look gnome-disk-utility 
    nwg-displays zsh ttf-meslo-nerd ttf-font-awesome 
    ttf-font-awesome-4 ttf-font-awesome-5 waybar-git rust cargo 
    fastfetch cmatrix pulsemixer net-tools python-pip python-psutil 
    python-virtualenv python-requests python-hijri-converter 
    python-pytz python-gobject xfce4-settings xfce-polkit exa 
    libreoffice-fresh rofi-wayland neovim goverlay-git flatpak 
    python-pywal16 python-pywalfox make cmake linux-firmware 
    dkms automake kvantum-qt5 chromium nautilus steam scdoc bats 
    xdg-terminal-exec swaync feh vlc-plugins-all wf-recorder 
    python-wxpython gradience adw-gtk-theme mesa-utils vkbasalt bluez 
    bluez-utils blueman swappy lutris bottles solaar liquidctl openrgb
    vencord xdg-desktop-portal-gtk xdg-desktop-portal-kde 
    xdg-desktop-portal-wlr xdg-desktop-portal-xapp nodejs-nativefier 
    gum stow nemo nemo-fileroller firewalld freedownloadmanager qdirstat
    pyprland nautilus-open-any-terminal arch-update 
)

#Stow Packages#
stow_packs=(fastfetch gradience gtk3 gtk4 hypr-themes hyprland 
  icons kitty kvantum neovim pywal qt5 qt6 rofi swaync themes
  vesktop wal waybar zsh)


missing_pkgs=()

#Welcome
cat << "EOF"

  /$$$$$$                      /$$                  /$$$$$$   /$$$$$$        /$$   /$$       /$$   /$$                               /$$                           /$$
 /$$__  $$                    | $$                 /$$__  $$ /$$__  $$      | $$  / $$      | $$  | $$                              | $$                          | $$
| $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$  /$$   /$$| $$  \ $$| $$  \__/      |  $$/ $$/      | $$  | $$ /$$   /$$  /$$$$$$   /$$$$$$ | $$  /$$$$$$  /$$$$$$$   /$$$$$$$
| $$       |____  $$ /$$_____/| $$__  $$| $$  | $$| $$  | $$|  $$$$$$        \  $$$$/       | $$$$$$$$| $$  | $$ /$$__  $$ /$$__  $$| $$ |____  $$| $$__  $$ /$$__  $$
| $$        /$$$$$$$| $$      | $$  \ $$| $$  | $$| $$  | $$ \____  $$        >$$  $$       | $$__  $$| $$  | $$| $$  \ $$| $$  \__/| $$  /$$$$$$$| $$  \ $$| $$  | $$
| $$    $$ /$$__  $$| $$      | $$  | $$| $$  | $$| $$  | $$ /$$  \ $$       /$$/\  $$      | $$  | $$| $$  | $$| $$  | $$| $$      | $$ /$$__  $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$/|  $$$$$$/      | $$  \ $$      | $$  | $$|  $$$$$$$| $$$$$$$/| $$      | $$|  $$$$$$$| $$  | $$|  $$$$$$$
 \______/  \_______/ \_______/|__/  |__/ \____  $$ \______/  \______/       |__/  |__/      |__/  |__/ \____  $$| $$____/ |__/      |__/ \_______/|__/  |__/ \_______/
                                         /$$  | $$                                                     /$$  | $$| $$                                                  
                                        |  $$$$$$/                                                    |  $$$$$$/| $$                                                  
                                         \______/                                                      \______/ |__/        


EOF

echo "🙏 Welcome To The CachyOS X Hyprland Setup, $USER 🙏"

echo "⚠️   NOTE!! NOTE!! NOTE!! NOTE!! NOTE!! NOTE!!   ⚠️"
sleep 3
echo "⚠️ Sudo Access Will Be Required For This Script  ⚠️"
sleep 3

#Directories#
echo "Preparing Directories"
sleep 3
mkdir -p /home/$USER/git/
mkdir -p /home/$USER/venv/
mkdir -p /home/$USER/mydots/tmp/
mkdir -p /home/$USER/.local/share/fonts
sudo mkdir -p /etc/modules-load.d/
echo "Done"
sleep 3

#System Update#
echo "🔁 Running System Update 🔁"
sleep 2
paru -Syyu
echo "Done"
sleep 3

#AUR Package Installation#
echo "-------------------------------------------"
echo "Checking If Required Packages Are Installed"
echo "-------------------------------------------"
sleep 3
for pkg in "${packages[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        echo "✅ $pkg is installed."
    else
        echo "❌ $pkg is NOT installed."
        missing_pkgs+=("$pkg")
    fi
done

echo "-------------------------------------------"
if [ ${#missing_pkgs[@]} -eq 0 ]; then
    echo "      All packages are installed!      "
echo "-------------------------------------------"
else
echo "----------------------------------------"
    echo "Missing packages: ${missing_pkgs[*]}"
echo "----------------------------------------"

    read -p "Would you like to install the missing packages using paru? (y/n) " choice
    if [[ "$choice" == "y" ]]; then
        paru -S "${missing_pkgs[@]}"
    fi
fi

#Flatpak Installation#
echo "Installing Flatpaks"
sleep 3
flatpak install flathub org.localsend.localsend_app
flatpak install flathub com.github.tchx84.Flatseal
flatpak install flathub net.rpcs3.RPCS3
flatpak install flathub org.libretro.RetroArch
flatpak install flathub io.github.plrigaux.sysd-manager
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark
echo "Done"
sleep 3

#Fonts Installation
while true; do
    echo "Would You Like To Install Arabic Fonts Y/N?"
    read -r choice
case $choice in
    Y|y) cp -r /home/$USER/mydots/fonts/* /home/$USER/.local/share/fonts/ 
    break ;;
    N|n) echo "Skipping Arabic Fonts Installation" 
    break ;;
    *) echo "Invalid Input. Please Answer Y or N."
esac
done
echo "Done"
sleep 3

#OhMyZsh Installation
echo "Installing Oh My Zsh"
sleep 3
git clone "https://github.com/zsh-users/zsh-autosuggestions.git" "/home/$USER/mydots/tmp/zsh-autosuggestions/"
git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "/home/$USER/mydots/tmp/zsh-syntax-highlighting/"
git clone "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "/home/$USER/mydots/tmp/fast-syntax-highlighting/"
git clone --depth 1 "https://github.com/marlonrichert/zsh-autocomplete.git" "/home/$USER/mydots/tmp/zsh-autocomplete/"
git clone "https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git" "/home/$USER/mydots/tmp/autoswitch_virtualenv/"

RUNZSH=no sh -c "$(curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh")" "" --unattended

cp -r /home/$USER/mydots/tmp/zsh-autosuggestions/ /home/$USER/.oh-my-zsh/custom/plugins/
cp -r /home/$USER/mydots/tmp/zsh-syntax-highlighting/ /home/$USER/.oh-my-zsh/custom/plugins/
cp -r /home/$USER/mydots/tmp/fast-syntax-highlighting/ /home/$USER/.oh-my-zsh/custom/plugins/
cp -r /home/$USER/mydots/tmp/zsh-autocomplete/ /home/$USER/.oh-my-zsh/custom/plugins/
cp -r /home/$USER/mydots/tmp/autoswitch_virtualenv/ /home/$USER/.oh-my-zsh/custom/plugins/
echo "Done"
sleep 3

#Remove Conflicting Files And Directories#
echo "Removing Conflicting Files And Directories"
sleep 3
sudo rm /etc/sddm.conf
sudo rm /etc/default/grub
sudo rm /usr/share/icons/default
rm ~/.zshrc
rm /home/$USER/.config/hypr/
rm /home/$USER/.config/kitty/
echo "Done"
sleep 3

#Stow Dotfiles#
echo "Stowing Dotfiles"
sleep 3
cd /home/$USER/mydots/
stow $stow_packs
echo "Done"
sleep 3

#Load Theme#
echo "Loading Theme"
sleep 3
bash /home/$USER/mydots/.assets/tokyo-night.sh
echo "Done"
sleep 3

#Cursor SDDM And Grub#
echo "Setting up Cursors, SDDM, & GRUB"
sleep 3
sudp cp -r "/home/$USER/mydots/sys/cursors/default/" "/usr/share/icons/"
sudp cp -r "/home/$USER/mydots/sys/cursors/oreo_white_cursors/" "/usr/share/icons/"
gsettings set org.gnome.desktop.interface cursor-theme "oreo_white_cursors"

sudo cp -r "/home/$USER/sys/sddm/sddm.conf" "/etc/"
sudo cp -r "/home/$USER/sys/sddm/tokyo-night/" "/usr/share/sddm/themes/"

sudo cp -r "/home/$USER/sys/grub/grub" "/etc/default/"
sudo cp -r "/home/$USER/sys/grub/grub/tokyo-night" "/usr/share/grub/themes/"

echo "Done"
sleep 3

#NCT6687D Driver Installation#
read -rp "Install NCT6687D Driver? (y/n): WARNING -- Only Install If You Know What You Are Doing" drv_ans
if [[ "$drv_ans" =~ ^[Yy] ]]; then
    git clone https://github.com/Fred78290/nct6687d "/home/$USER/mydots/nct6687d/"
    cd "/home/$USER/mydots/nct6687d/" && make dkms/install
    sudo cp "/home/$USER/mydots/sys/no_nct6683.conf" /etc/modprobe.d/
    sudo cp "/home/$USER/mydots/sys/nct6687.conf" /etc/modules-load.d/nct6687.conf
    echo "Done"
    sleep 3
fi

#Enable Services#
echo "Enabling Services"
sleep 3
sudo modprobe nct6687
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable --now bluetooth
sudo systemctl enable --now coolercontrold.service
sudo systemctl enable --now firewalld
chsh -s "$(which zsh)"
echo "Done"
sleep 3

#Display Setup#
echo "Please Set Up Your Monitors"
sleep 3
nwg-displays

#System Cleanup
echo "Performing System Cleanup"
sleep 3
rm -rf /home/$USER/mydots/tmp/
echo -e "✔ Installation Finished!"

#Reboot#
bash "/home/$USER/mydots/.assets/reboot.sh"

