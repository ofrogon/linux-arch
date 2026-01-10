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

# Restore the latest backup version of a file
restore_backup_file() {
  local file="$1"
  # Find the latest backup file (sorted by timestamp in filename)
  local latest_backup
  latest_backup=$(ls -1 "${file}.bak-"* 2>/dev/null | sort -r | head -n1)

  if [[ -n "$latest_backup" && -f "$latest_backup" ]]; then
    cp -a "$latest_backup" "$file"
    echo "Restored $file from $latest_backup"
  else
    echo "No backup found for $file" >&2
    return 1
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

# Exit with error message
die() {
  err "$*"
  exit 1
}

# Ensure directory exists
ensure_dir() {
  mkdir -p "$@"
}

# Add or update a marked block in a file
# Usage: add_or_update_block <file> <block_start> <block_end> <content>
add_or_update_block() {
  local file="$1" block_start="$2" block_end="$3" content="$4"
  [[ -f "$file" ]] || touch "$file"
  if grep -qF "$block_start" "$file"; then
    awk -v start="$block_start" -v end="$block_end" '
      BEGIN{skip=0}
      index($0,start){skip=1; next}
      index($0,end){skip=0; next}
      skip==0{print}
    ' "$file" >"$file.tmp"
    mv "$file.tmp" "$file"
  fi
  printf "\n%s\n" "$content" >>"$file"
}

# Prompt user for input
# Usage: prompt_var <variable_name> <prompt_message>
prompt_var() {
  local var_name="$1" prompt="$2"
  read -rp "$prompt" "$var_name"
}
