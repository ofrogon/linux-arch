#!/bin/bash

cat <<"EOF"
▀████    ▐████▀  ▄██████▄  ▀█████████▄     ▄████████ ███    █▄  ▀████    ▐████▀ 
  ███▌   ████▀  ███    ███   ███    ███   ███    ███ ███    ███   ███▌   ████▀  
   ███  ▐███    ███    ███   ███    ███   ███    ███ ███    ███    ███  ▐███    
   ▀███▄███▀    ███    ███  ▄███▄▄▄██▀   ▄███▄▄▄▄██▀ ███    ███    ▀███▄███▀    
   ████▀██▄     ███    ███ ▀▀███▀▀▀██▄  ▀▀███▀▀▀▀▀   ███    ███    ████▀██▄     
  ▐███  ▀███    ███    ███   ███    ██▄ ▀███████████ ███    ███   ▐███  ▀███    
 ▄███     ███▄  ███    ███   ███    ███   ███    ███ ███    ███  ▄███     ███▄  
████       ███▄  ▀██████▀  ▄█████████▀    ███    ███ ████████▀  ████       ███▄ 
                                          ███    ███                            
EOF

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to ofrogon/linux-arch
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
cd ~/.local/share/ofrogon/
source ~/.local/share/ofrogon/run.sh
