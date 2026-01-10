#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

# Set global theme (GTK)
info "Setting GTK theme..."
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru-blue"

# Set links for Nautilus action icons
info "Setting up Nautilus icon links..."
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg
sudo gtk-update-icon-cache /usr/share/icons/Yaru

ok "Theme configured"

# Set mouse cursor
## This is set using the package "catppuccin-cursors-macchiato" in DESKTOP_REQUIREMENT.conf and the environement variable
## section named "Cursors" of the file [...]/dotfiles/.config/hypr/configs/env.conf
