#!/bin/bash

is_git_installed() {
  pacman -Qi "git" &>/dev/null
}

if ! is_git_installed; then
  echo "Install git first"
fi

# Validate that GIT_EMAIL variable is set
if [ ! -z ${GIT_EMAIL+x} ]; then
  echo "What is your Git email address (format: john.doe@email.com)?"
  read GIT_EMAIL
fi

# Validate that GIT_USERNAME variable is set
if [ ! -z ${GIT_USERNAME+x} ]; then
  echo "What is your Git name (format: John Doe)?"
  read GIT_USERNAME
fi

# Set Git
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.editor "nvim"
