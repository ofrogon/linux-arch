#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utilities/utils.sh"

set -euo pipefail

ORIGINAL_DIR="$(pwd)"
TMP_DIR="/tmp/yay"

require_root

# makepkg refuses to run as root — use the user who invoked sudo
BUILD_USER="${SUDO_USER:-}"
if [[ -z "$BUILD_USER" || "$BUILD_USER" == "root" ]]; then
  die "Lance ce script via sudo depuis un compte utilisateur normal, ex: sudo ./run.sh"
fi

info "Installing yay AUR helper..."

pacman -S --needed git base-devel --noconfirm

if [[ -d "$TMP_DIR" ]]; then
  info "yay directory already exists, removing it..."
  rm -rf "$TMP_DIR"
fi

info "Cloning yay repository..."
sudo -u "$BUILD_USER" git clone https://aur.archlinux.org/yay.git "$TMP_DIR"

cd "$TMP_DIR"
info "building yay.... yaaaaayyyyy"
sudo -u "$BUILD_USER" makepkg -si --noconfirm
cd "$ORIGINAL_DIR"
rm -rf "$TMP_DIR"
