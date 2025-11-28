#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

set -euo pipefail

ORIGINAL_DIR=$(pwd)
TMP_DIR="/tmp/yay"

require_root

info "Installing yay AUR helper..."

sudo pacman -S --needed git base-devel --noconfirm

if [[ ! -d "$TMP_DIR" ]]; then
  info "Cloning yay repository..."
else
  info "yay directory already exists, removing it..."
  rm -rf "$TMP_DIR"
fi

git clone https://aur.archlinux.org/yay.git

# TODO Add here a directory push-pop to return to the previous position
cd "$TMP_DIR"
info "building yay.... yaaaaayyyyy"
makepkg -si --noconfirm
cd "$ORIGINAL_DIR"
rm -rf "$TMP_DIR"
