#!/bin/bash
git clone https://gitlab.com/Riezz01/mydots.git /home/$USER/dots/
chmod +x /home/$USER/dots/.assets/install.sh
cd /home/$USER/dots/ 
bash /home/$USER/dots/.assets/install.sh
