#!/bin/bash

wget "https:/o/" -P "/usr/share/plymouth/themes/"
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="/tmp/catppuccin-plymouth"
THEME_NAME="catppuccin-macchiato"
THEME_SRC="$TMP_DIR/themes/$THEME_NAME"
THEME_DEST="/usr/share/plymouth/themes/$THEME_NAME"

# Ensure root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (e.g. sudo $0)"
  exit 1
fi

echo "Cloning Catppuccin Plymouth repo into $TMP_DIR..."
rm -rf "$TMP_DIR"
git clone --depth=1 https://github.com/catppuccin/plymouth.git "$TMP_DIR"

# Verify source exists
if [[ ! -d "$THEME_SRC" ]]; then
  echo "Theme folder not found: $THEME_SRC"
  exit 1
fi

# Backup existing theme if present
if [[ -d "$THEME_DEST" ]]; then
  echo "Backing up existing theme at $THEME_DEST..."
  mv "$THEME_DEST" "${THEME_DEST}.bak.$(date +%s)"
fi

echo "Copying $THEME_NAME to $THEME_DEST..."
cp -r "$THEME_SRC" "$THEME_DEST"

echo "Setting theme as default..."
plymouth-set-default-theme -R "$THEME_NAME"
