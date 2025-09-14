#!/bin/bash

# Print the logo
print_logo() {
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
}

# Parse command line arguments
WSL_ONLY=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --dev-only)
    WSL_ONLY=true
    shift
    ;;
  *)
    echo "Unknown parameter: $1"
    exit 1
    ;;
  esac
done

# Clear screen and show logo
clear
print_logo

# Exit on any error
set -e

# Source utility functions
source utilities/utils.sh

# Source the package list
if [ ! -f "packages.conf" ]; then
  echo "Error: packages.conf not found!"
  exit 1
fi

source packages.conf

if [[ "$WSL_ONLY" == true ]]; then
  echo "Starting wsl-only setup..."
else
  echo "Starting full system setup..."
fi

# Update the system first
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Install yay AUR helper if not present
if ! command -v yay &>/dev/null; then
  ./install/install-yay.sh
else
  echo "yay is already installed"
fi

# Install packages by category
if [[ "$WSL_ONLY" == true ]]; then
  # Only install packages that can be used in WSL
  echo "Installing development tools..."
  install_packages "${DEVELOPMENT[@]}"
  install_packages "${DEVELOPMENT_DESKTOP[@]}"

  echo "Installing dotnet tools..."
  install_packages "${DOTNET[@]}"

  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"

  echo "Installing terminal tools..."
  install_packages "${TERMINAL_TOOLS[@]}"
else
  echo "Configuring Languages..."
  . install/languages.sh

  # Install all packages
  echo "Installing desktop requirements..."
  install_packages "${DESKTOP_REQUIREMENT[@]}"

  echo "Installing development tools..."
  install_packages "${DEVELOPMENT[@]}"

  echo "Installing dotnet tools..."
  install_packages "${DOTNET[@]}"

  echo "Installing Hyprland..."
  install_packages "${HYPRLAND[@]}"

  echo "Installing graphic drivers..."
  install_packages "${NVIDIA[@]}"

  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"

  echo "Installing terminal tools..."
  install_packages "${TERMINAL_TOOLS[@]}"

  echo "Installing fonts..."
  install_packages "${FONTS[@]}"

  # Install gnome specific things to make it like a tiling WM
  echo "Configuring Nvidia..."
  . install/nvidia.sh
  echo "Configuring Plymouth..."
  . install/plymouth.sh
  echo "Configuring ..."
  . install/cursor.sh
  echo ""

  # Some programs just run better as flatpaks. Like discord/spotify
  echo "Installing flatpaks (like discord and spotify)"
  . install-flatpaks.sh
fi

echo "Setup complete! You may want to reboot your system."
