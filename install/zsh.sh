#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

# Install and configure Oh-My-ZSH
info "Installing Oh-My-ZSH..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --keep-zshrc
ok "Oh-My-ZSH installed"
