#!/bin/bash

# Applications to hide
APPLICATIONS_TO_HIDE=(
  "assistant" # QT Assistant
  "avahi-discover"
  "bssh"     # Avahi SSH Server Browser
  "bvnc"     # Avahi VNC Server Browser
  "designer" # QT Widget Designer
  "electron37"
  "btop"
  "htop"
  "kvantummanager"
  "linguist" # QT Linguist
  "lstopo"
  "org.gnupg.pinentry-qt"
  "org.gnupg.pinentry-qt5"
  "qv4l2"       # Qt V4L2 test Utility
  "qdbusviewer" # Qt D-Bus Viewer
  "qvidcap"     # Qt V4L2 video capture utility
  "vim"
  "nvim"
  "uuctl"
  "xgps"
  "xgpsspeed"
)

# Standard folders where can be found the .desktop
dirs=(
  "/usr/share/applications"
  "$HOME/.local/share/applications"
)

for app in "${APPLICATIONS_TO_HIDE[@]}"; do
  found=false
  for dir in "${dirs[@]}"; do
    file="$dir/$app.desktop"
    if [[ -f "$file" ]]; then
      found=true
      # Validate if NoDisplay already exist
      if grep -q "^NoDisplay=" "$file"; then
        echo "[INFO] $app.desktop already contains NoDisplay (file not modified)"
      else
        echo "[ACTION] Adding NoDisplay=true à $file"
        echo "NoDisplay=true" | sudo tee -a "$file" >/dev/null
      fi
    fi
  done
  if [[ "$found" = false ]]; then
    echo "[WARN] File .desktop can't be found for $app"
  fi
done
