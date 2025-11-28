#!/bin/bash

# Function to check if a package is installed
is_installed() {
  pacman -Qi "$1" &>/dev/null
}

# Function to check if a package is installed
is_group_installed() {
  pacman -Qg "$1" &>/dev/null
}

# Function to install a single package if not already installed
install_package() {
  if ! is_installed "$1" && ! is_group_installed "$1"; then
    yay -S --noconfirm $1
  fi
}

# Function to install packages if not already installed
install_packages() {
  local packages=("$@")
  local to_install=()

  for pkg in "${packages[@]}"; do
    if ! is_installed "$pkg" && ! is_group_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -ne 0 ]; then
    info "Installing: ${to_install[*]}"
    yay -S --noconfirm "${to_install[@]}"
  fi
}

# Require the user to be root
require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (sudo)." >&2
    exit 1
  fi
}

have_cmd() {
  command -v "$1" &>/dev/null
}

# Create a backup copy of a file
backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    cp -a "$file" "$file.bak-${ts}"
    echo "Backed up $file to $file.bak-${ts}"
  fi
}

# Restore the backup version of a file
# TODO Work on this and complete the
restore_backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # Test if a backup file exist and take the latest
    # rm "$file"
    # mv "$old_file" "$file"
    echo "Restored up ${file} from ${old_file}"
  fi
}

# ---------- Console log helpers ----------
err() {
  printf "\e[31m[error]\e[0m %s\n" "$*" >&2
}

warn() {
  printf "\e[33m[warning]\e[0m %s\n" "$*" >&2
}

ok() {
  printf "\e[32m[ok]\e[0m %s\n" "$*"
}

info() {
  printf "\e[34m[info]\e[0m %s\n" "$*"
}
