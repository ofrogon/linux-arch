#!/bin/bash

# Generated from https://patorjk.com/software/taag/, option "Delta Corps Priest 1"
ansi_art='                                                                       
▀████    ▐████▀  ▄██████▄  ▀█████████▄     ▄████████ ███    █▄  ▀████    ▐████▀ 
  ███▌   ████▀  ███    ███   ███    ███   ███    ███ ███    ███   ███▌   ████▀  
   ███  ▐███    ███    ███   ███    ███   ███    ███ ███    ███    ███  ▐███    
   ▀███▄███▀    ███    ███  ▄███▄▄▄██▀   ▄███▄▄▄▄██▀ ███    ███    ▀███▄███▀    
   ████▀██▄     ███    ███ ▀▀███▀▀▀██▄  ▀▀███▀▀▀▀▀   ███    ███    ████▀██▄     
  ▐███  ▀███    ███    ███   ███    ██▄ ▀███████████ ███    ███   ▐███  ▀███    
 ▄███     ███▄  ███    ███   ███    ███   ███    ███ ███    ███  ▄███     ███▄  
████       ███▄  ▀██████▀  ▄█████████▀    ███    ███ ████████▀  ████       ███▄ 
                                          ███    ███                            '

clear
echo -e "\n$ansi_art\n"

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/omarchy
OFROGON_REPO="${OFROGON_REPO:-ofrogon/linux-arch}"

echo -e "\nCloning Arch-Linux-Config from: https://github.com/${OFROGON_REPO}.git"
rm -rf ~/.local/share/ofrogon/
git clone "https://github.com/${OFROGON_REPO}.git" ~/.local/share/ofrogon >/dev/null

# Use custom branch if instructed, otherwise default to main
OFROGON_REF="${OFROGON_REF:-main}"
if [[ $OFROGON_REF != "master" ]]; then
  echo -e "\eUsing branch: $OFROGON_REF"
  cd ~/.local/share/ofrogon
  git fetch origin "${OFROGON_REF}" && git checkout "${OFROGON_REF}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/ofrogon/run.sh
