#!/bin/bash

set -e

PACMAN_CONF="/etc/pacman.conf"

# Require script to be run as root
require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script as root."
    exit 1
  fi
}

# Enable multilib repository
enable_multilib() {
  echo "Enabling [multilib] repository..."
  sed -i '/^\s*#\[multilib\]/,/^\s*#Include/ s/^\s*#//' "$PACMAN_CONF"
}

# Enable color
enable_color() {
  echo "Enabling color output..."
  sed -i 's/^#Color/Color/' "$PACMAN_CONF"
}

# Enable pacman loading bar (ILoveCandy), progress bar, verbose pkg list
enable_candy_and_bar() {
  echo "Enabling Pacman loading bar and extras..."

  # Add ILoveCandy if not already present
  if ! grep -q "^[[:space:]]*ILoveCandy" "$PACMAN_CONF"; then
    sed -i '/^\[options\]/a ILoveCandy' "$PACMAN_CONF"
  fi

  # Enable ParallelDownloads and VerbosePkgLists
  sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$PACMAN_CONF"
}

main() {
  # require_root
  enable_multilib
  enable_color
  enable_candy_and_bar

  # Refresh cache with multilib as a source
  yay -Syu --noconfirm

  echo "Tip: run 'sudo pacman -Syy' to refresh your package databases."
}

main "$@"
