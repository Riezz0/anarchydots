# Stow Scripts

stuff to be done

sudo stow -t /usr/local scripts
sudo stow -t /usr/share bg 

stow the following packages normally (check for conflicting files):
cursors, fastfetch, gradience, gtk3, gtk4, hyprland, hypr-themes*, icons, kitty,kvantum, 
neovim, omz, pypr, pywal, qt5, qt6, quickshell, rofi, themes, wal, xkb and zsh.

#SDDM And Grub#
sudo cp -r "/home/$USER/anarchydots/sys/sddm/sddm.conf" "/etc/"
sudo cp -r "/home/$USER/anarchydots/sys/sddm/tokyo-night/" "/usr/share/sddm/themes/"

sudo cp -r "/home/$USER/anarchydots/sys/grub/grub" "/etc/default/"
sudo cp -r "/home/$USER/anarchydots/sys/grub/grub/tokyo-night" "/usr/share/grub/themes/"


#NCT6687D Driver Installation#
git clone https://github.com/Fred78290/nct6687d "/home/$USER/mydots/nct6687d/"
cd "/home/$USER/mydots/nct6687d/" && make dkms/install
sudo cp "/home/$USER/anarchydots/sys/no_nct6683.conf" /etc/modprobe.d/
sudo cp "/home/$USER/anarchydots/sys/nct6687.conf" /etc/modules-load.d/nct6687.conf

#Enable Services#
sudo modprobe nct6687
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable --now bluetooth
sudo systemctl enable --now coolercontrold.service
chsh -s "$(which zsh)"
