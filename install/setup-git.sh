#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

set -euo pipefail

require_root

install_package git
install_package git-lfs

# Validate that GIT_EMAIL variable is set
if [ -z "${GIT_EMAIL+x}" ]; then
  echo "What is your Git email address (format: john.doe@email.com)?"
  read -r GIT_EMAIL
fi

# Validate that GIT_USERNAME variable is set
if [ -z "${GIT_USERNAME+x}" ]; then
  echo "What is your Git name (format: John Doe)?"
  read -r GIT_USERNAME
fi

# Set Git
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.editor "nvim"
git config --global init.defaultBranch "main"

# Set Git LFS
git lfs install
