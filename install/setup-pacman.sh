#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

set -euo pipefail

ORIGINAL_DIR=$(pwd)
TMP_DIR="/tmp/yay"
PACMAN_CONF="/etc/pacman.conf"

enable_multilib() {
  info "Enabling [multilib] repository..."
  sudo sed -i '/^\s*#\[multilib\]/,/^\s*#Include/ s/^\s*#//' "$PACMAN_CONF"
}

enable_color() {
  info "Enabling color output..."
  sudo sed -i 's/^#Color/Color/' "$PACMAN_CONF"
}

enable_candy_and_bar() {
  info "Enabling Pacman loading bar and extras..."

  # Add ILoveCandy (the Pacman style loading bar) if not already present
  if ! grep -q "^[[:space:]]*ILoveCandy" "$PACMAN_CONF"; then
    sudo sed -i '/^\[options\]/a ILoveCandy' "$PACMAN_CONF"
  fi

  # Enable ParallelDownloads and VerbosePkgLists
  sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$PACMAN_CONF"
}

main() {
  require_root
  enable_multilib
  enable_color
  enable_candy_and_bar

  # Refresh cache with multilib as a source
  yay -Syu --noconfirm
}

main "$@"
