#!/bin/bash

source ./utilities/logo.sh

# Parse command line arguments
WSL_ONLY=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --wsl-only)
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

# TODO Add a step to ask for username, email and git name
echo "What is your username (format: john)"
read -r USERNAME

echo "What is your Git email address (format: john.doe@email.com)?"
read -r GIT_EMAIL

echo "What is your Git name (format: John Doe)?"
read -r GIT_USERNAME

echo "Do you have an Nvidia system? (y/N)"
read -r SET_NVIDIA
SET_NVIDIA=${SET_NVIDIA:-N}

echo "Do you want to configure Steam (NVidia only for now)? (y/N)"
read -r SET_STEAM
SET_STEAM=${SET_STEAM:-N}

# Source the package lists
PACKAGES_LIST=(
  DESKTOP_REQUIREMENT
  DEVELOPMENT
  DOTNET
  FONTS
  HYPRLAND
  NVIDIA
  RAZER_BLADE
  STEAM
  SYSTEM_UTILS
  TERMINAL_TOOLS
)

for package in "${PACKAGES_LIST[@]}"; do
  if [ ! -f "packages/${package}.conf" ]; then
    echo "Error: ${package}.conf not found!"
    exit 1
  fi

  source packages/${package}.conf
done

if [[ "$WSL_ONLY" == true ]]; then
  echo "Starting wsl-only setup..."
else
  echo "Starting full system setup..."
fi

# Update the system first
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Install yay AUR helper if not present
if ! have_cmd yay; then
  ./install/install-yay.sh
else
  info "yay is already installed"
fi

# Install packages by category
if [[ "$WSL_ONLY" == true ]]; then
  echo "Configuring Locales..."
  #. install/locales.sh

  echo "Configuring local account"
  #. install/create-user.sh

  # Only install packages that can be used in WSL
  echo "Installing development tools..."
  #install_packages "${DEVELOPMENT[@]}"
  #install_packages "${DEVELOPMENT_DESKTOP[@]}"

  echo "Installing dotnet tools..."
  #install_packages "${DOTNET[@]}"

  echo "Installing system utilities..."
  #install_packages "${SYSTEM_UTILS[@]}"

  echo "Installing terminal tools..."
  #install_packages "${TERMINAL_TOOLS[@]}"

  echo "Configuring dotfiles..."
  . install/setup-dotfiles.sh

  echo "Configuring ZSH..."
  #. install/zsh.sh

  echo "####################################"
  echo "# Now you can configure Windows, do this on a Windows terminal"
  echo "#"
  echo "# To set your username as defaut for your new WSL distro:"
  echo "#     wsl --manage archlinux --set-default-user $USERNAME "
  echo "#"
  echo "# To set Arch as the default WSL distro"
  echo "#     wsl --set-default archlinux"

else
  echo "Configuring Locales..."
  . install/locales.sh

  # Configure Rust default toolchain if rustup is available
  if have_cmd rustup; then
    rustup default stable
  fi

  echo "Configure Pacman"
  . install/setup-pacman.sh

  # Install all packages
  echo "Installing desktop requirements..."
  install_packages "${DESKTOP_REQUIREMENT[@]}"

  echo "Installing development tools..."
  install_packages "${DEVELOPMENT[@]}"

  echo "Installing dotnet tools..."
  install_packages "${DOTNET[@]}"

  echo "Installing Hyprland..."
  install_packages "${HYPRLAND[@]}"

  if [[ "$SET_NVIDIA" == "Y" || "$SET_NVIDIA" == "y" ]]; then
    echo "Installing graphic drivers..."
    install_packages "${NVIDIA[@]}"

    echo "Configuring Nvidia..."
    #. install/nvidia.sh
    . install/setup-cards-symlink.sh
  fi

  if [[ "$SET_STEAM" == "Y" || "$SET_STEAM" == "y" ]]; then
    echo "Installing graphic drivers..."
    install_packages "${STEAM[@]}"
  fi

  # TODO: Make this configurable as an option
  install_packages "${RAZER_BLADE[@]}"

  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"

  echo "Installing terminal tools..."
  install_packages "${TERMINAL_TOOLS[@]}"

  echo "Installing fonts..."
  install_packages "${FONTS[@]}"

  echo "Configuring Plymouth..."
  #. install/plymouth.sh
  echo "Configuring dotfiles..."
  . install/setup-dotfiles.sh
  echo "Configuring ZSH..."
  #. install/zsh.sh
  echo "Configure Git"
  . install/setup-git.sh
  echo "Configure theme"
  . install/theme.sh
  echo "Hide some applications"
  . install/setup-hidden-applications.sh
  echo "Create the WPAs"
  . install/setup-wpa.sh
  echo "Setup Network services"
  . install/setup-networks.sh
  echo "Setup Plymouth (boot screen theme)"
  . install/install-plymouth-catppuccin-macchiato.sh
  . install/setup-plymouth.sh
  echo "Setup default applications"
  . install/setup-default-app.sh
  echo "Setup Firefox"
  . install/setup-firefox.sh
fi

echo "Setup complete! You may want to reboot your system."
