#!/bin/bash

## This is useful to setup multi-GPU on a Intel-Nvidia laptop

# Create the Intel one
SYMLINK_NAME="intel-igpu"
RULE_PATH="/etc/udev/rules.d/intel-igpu-dev-path.rules"
INTEL_IGPU_ID=$(lspci -d ::03xx | grep 'Intel' | cut -f1 -d' ')
UDEV_RULE="$(
  cat <<EOF
KERNEL=="card*", \
KERNELS=="0000:$INTEL_IGPU_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/$SYMLINK_NAME"
EOF
)"

echo "$UDEV_RULE" | sudo tee "$RULE_PATH"

# Create the Nvidia one
SYMLINK_NAME="nvidia-igpu"
RULE_PATH="/etc/udev/rules.d/nvidia-igpu-dev-path.rules"
NVIDIA_IGPU_ID=$(lspci -d ::03xx | grep 'NVIDIA' | cut -f1 -d' ')
UDEV_RULE="$(
  cat <<EOF
KERNEL=="card*", \
KERNELS=="0000:$NVIDIA_IGPU_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/$SYMLINK_NAME"
EOF
)"

echo "$UDEV_RULE" | sudo tee "$RULE_PATH"

# Refresh/create them
sudo udevadm control --reload
sudo udevadm trigger
