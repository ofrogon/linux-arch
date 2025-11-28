#!/bin/bash
#
# Source utility functions
source ../utilities/utils.sh

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/ofrogon/dotfiles"
REPO_NAME="dotfiles"

require_root

install_package stow

cd ~

# Check if the repository already exists
if [ -d "$REPO_NAME" ]; then
  info "Repository '$REPO_NAME' already exists. Skipping clone"
else
  git clone "$REPO_URL"
fi

# Check if the clone was successful
if [ $? -eq 0 ]; then
  cd "$REPO_NAME"
  stow . --adopt
  git reset --hard
  cd "$ORIGINAL_DIR"
else
  err "Failed to clone the repository."
  cd "$ORIGINAL_DIR"
fi
