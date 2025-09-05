#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eE

OFROGON_PATH="$HOME/.local/share/ofrogon"
OFROGON_INSTALL="$OFROGON_PATH/install"
export PATH="$OFROGON_PATH/bin:$PATH"

# Preparation
source $OFROGON_INSTALL/preflight/show-env.sh
source $OFROGON_INSTALL/preflight/trap-errors.sh
source $OFROGON_INSTALL/preflight/guard.sh
source $OFROGON_INSTALL/preflight/chroot.sh
source $OFROGON_INSTALL/preflight/pacman.sh
source $OFROGON_INSTALL/preflight/migrations.sh
source $OFROGON_INSTALL/preflight/first-run-mode.sh

# Packaging
source $OFROGON_INSTALL/packages.sh
source $OFROGON_INSTALL/packaging/fonts.sh
source $OFROGON_INSTALL/packaging/lazyvim.sh
source $OFROGON_INSTALL/packaging/webapps.sh
source $OFROGON_INSTALL/packaging/tuis.sh

# Configuration
source $OFROGON_INSTALL/config/config.sh
source $OFROGON_INSTALL/config/theme.sh
source $OFROGON_INSTALL/config/branding.sh
source $OFROGON_INSTALL/config/git.sh
source $OFROGON_INSTALL/config/gpg.sh
source $OFROGON_INSTALL/config/timezones.sh
source $OFROGON_INSTALL/config/increase-sudo-tries.sh
source $OFROGON_INSTALL/config/increase-lockout-limit.sh
source $OFROGON_INSTALL/config/ssh-flakiness.sh
source $OFROGON_INSTALL/config/detect-keyboard-layout.sh
source $OFROGON_INSTALL/config/xcompose.sh
source $OFROGON_INSTALL/config/mise-ruby.sh
source $OFROGON_INSTALL/config/docker.sh
source $OFROGON_INSTALL/config/mimetypes.sh
source $OFROGON_INSTALL/config/localdb.sh
source $OFROGON_INSTALL/config/sudoless-asdcontrol.sh
source $OFROGON_INSTALL/config/hardware/network.sh
source $OFROGON_INSTALL/config/hardware/fix-fkeys.sh
source $OFROGON_INSTALL/config/hardware/bluetooth.sh
source $OFROGON_INSTALL/config/hardware/printer.sh
source $OFROGON_INSTALL/config/hardware/usb-autosuspend.sh
source $OFROGON_INSTALL/config/hardware/ignore-power-button.sh
source $OFROGON_INSTALL/config/hardware/nvidia.sh
source $OFROGON_INSTALL/config/hardware/fix-f13-amd-audio-input.sh

# Login
source $OFROGON_INSTALL/login/plymouth.sh
source $OFROGON_INSTALL/login/limine-snapper.sh
source $OFROGON_INSTALL/login/alt-bootloaders.sh

# Finishing
source $OFROGON_INSTALL/reboot.sh
