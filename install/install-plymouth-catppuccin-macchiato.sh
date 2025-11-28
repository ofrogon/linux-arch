#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

# Don't think the next line is usefull... maybe it create the folder if it doesn't exist...
# wget "https:/o/" -P "/usr/share/plymouth/themes/"
set -euo pipefail

TMP_DIR="/tmp/catppuccin-plymouth"
THEME_NAME="catppuccin-macchiato"
THEME_SRC="$TMP_DIR/themes/$THEME_NAME"
THEME_DEST="/usr/share/plymouth/themes/$THEME_NAME"

# Ensure root
require_root

info "Cloning Catppuccin Plymouth repo into $TMP_DIR..."
rm -rf "$TMP_DIR"
git clone --depth=1 https://github.com/catppuccin/plymouth.git "$TMP_DIR"

# Verify source exists
if [[ ! -d "$THEME_SRC" ]]; then
  err "Theme folder not found: $THEME_SRC"
  exit 1
fi

# Backup existing theme if present
if [[ -d "$THEME_DEST" ]]; then
  info "Backing up existing theme at $THEME_DEST..."
  mv "$THEME_DEST" "${THEME_DEST}.bak.$(date +%s)"
fi

info "Copying $THEME_NAME to $THEME_DEST..."
cp -r "$THEME_SRC" "$THEME_DEST"

info "Setting theme as default..."
plymouth-set-default-theme -R "$THEME_NAME"
