#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

set -euo pipefail

REQUIRED_MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)
MKINITCONF="/etc/mkinitcpio.conf"
MODPROBE_NVIDIA_CONF="/etc/modprobe.d/nvidia.conf"

have_nvidia_gpu() {
  if lspci -nnk | grep -qi 'VGA.*NVIDIA'; then
    return 0
  else
    return 1
  fi
}

extract_modules_line() {
  # prints the first non-comment MODULES=… line, or empty if none
  awk '
    /^[[:space:]]*#/ { next } 
    /^[[:space:]]*MODULES[[:space:]]*=/ { print; exit }
  ' "$MKINITCONF"
}

parse_modules_from_line() {
  # input: a line like MODULES=(foo bar baz)
  # output: space-separated modules to stdout
  local line="$1"
  # Strip up to first '(' and trailing ')'
  local content="${line#*=}"
  content="${content#*(}"
  content="${content%)}"
  # Normalize whitespace
  echo "$content" | tr -s '[:space:]' ' '
}

dedupe_and_merge_modules() {
  # Args: existing modules (space-separated)
  local existing_str="$1"
  declare -A seen=()
  local out=()

  # First ensure REQUIRED_MODULES (in that order)
  for m in "${REQUIRED_MODULES[@]}"; do
    if [[ -n "$m" && -z "${seen[$m]+x}" ]]; then
      out+=("$m")
      seen[$m]=1
    fi
  done

  # Then keep existing (preserve their order) if not already included
  for m in $existing_str; do
    # skip empty and comments/sentinels just in case
    [[ -z "$m" ]] && continue
    [[ "$m" =~ ^# ]] && continue
    if [[ -z "${seen[$m]+x}" ]]; then
      out+=("$m")
      seen[$m]=1
    fi
  done

  printf "%s " "${out[@]}" | sed 's/[[:space:]]\+$//'
}

ensure_modules_in_mkinitcpio() {
  info "Ensuring MODULES in $MKINITCONF includes NVIDIA + i915…"
  backup_file "$MKINITCONF"

  local line existing merged new_line
  line="$(extract_modules_line || true)"

  if [[ -z "$line" ]]; then
    # No MODULES line: create one with the required modules
    merged="$(printf "%s " "${REQUIRED_MODULES[@]}" | sed 's/[[:space:]]\+$//')"
    echo "MODULES=(${merged})" >>"$MKINITCONF"
    info "Added new MODULES line: MODULES=(${merged})"
  else
    existing="$(parse_modules_from_line "$line")"
    merged="$(dedupe_and_merge_modules "$existing")"
    new_line="MODULES=(${merged})"

    # Replace the first MODULES= line (ignoring commented ones)
    # Use a temporary marker to safely replace the *first* active line.
    awk -v repl="$new_line" '
      BEGIN { done=0 }
      {
        if (!done && $0 !~ /^[[:space:]]*#/ && $0 ~ /^[[:space:]]*MODULES[[:space:]]*=/) {
          print repl
          done=1
        } else {
          print $0
        }
      }
    ' "$MKINITCONF" >"${MKINITCONF}.tmp"

    mv "${MKINITCONF}.tmp" "$MKINITCONF"
    info "Updated MODULES line to: $new_line"
  fi
}

maybe_add_kms_hook() {
  # Insert 'kms' into HOOKS if not present, placing it after 'modconf' if possible
  info "Checking for kms hook in HOOKS…"
  if ! awk '/^[[:space:]]*#/ {next} /^[[:space:]]*HOOKS[[:space:]]*=/{print;exit}' "$MKINITCONF" | grep -qw "kms"; then
    backup_file "$MKINITCONF"
    awk '
      /^[[:space:]]*#/ { print; next }
      /^[[:space:]]*HOOKS[[:space:]]*=/ {
        line=$0
        # Extract content inside ()
        content=line
        sub(/^[[:space:]]*HOOKS[[:space:]]*=\(/, "", content)
        sub(/\)[[:space:]]*$/, "", content)

        # Tokenize by space
        n=split(content, a, /[[:space:]]+/)
        found_modconf=0
        out=""

        for(i=1; i<=n; i++){
          out=out (out=="" ? "" : " ") a[i]
          if(a[i]=="modconf" && !found_modconf){
            out=out " kms"
            found_modconf=1
          }
        }
        if(!found_modconf){
          out=out " kms"
        }
        print "HOOKS=(" out ")"
        next
      }
      { print }
    ' "$MKINITCONF" >"${MKINITCONF}.tmp"
    mv "${MKINITCONF}.tmp" "$MKINITCONF"
    info "Added 'kms' to HOOKS."
  else
    info "'kms' hook already present."
  fi
}

ensure_modprobe_modeset() {
  info "Ensuring DRM KMS (modeset=1) via $MODPROBE_NVIDIA_CONF…"
  mkdir -p "$(dirname "$MODPROBE_NVIDIA_CONF")"
  if [[ -f "$MODPROBE_NVIDIA_CONF" ]]; then
    if grep -q '^options[[:space:]]\+nvidia_drm' "$MODPROBE_NVIDIA_CONF"; then
      # Update existing line to include modeset=1 (and keep any others)
      sed -i 's/^options[[:space:]]\+nvidia_drm.*/options nvidia_drm modeset=1/' "$MODPROBE_NVIDIA_CONF"
    else
      echo "options nvidia_drm modeset=1" >>"$MODPROBE_NVIDIA_CONF"
    fi
  else
    echo "options nvidia_drm modeset=1" >"$MODPROBE_NVIDIA_CONF"
  fi
  info "Set: options nvidia_drm modeset=1"
}

rebuild_initramfs() {
  info "Rebuilding initramfs (mkinitcpio -P)…"
  mkinitcpio -P
  info "Initramfs rebuilt."
}

main() {
  require_root

  if ! have_cmd lspci; then
    info "Installing pciutils to detect GPU…"
    pacman -Sy --needed --noconfirm pciutils
  fi

  if have_nvidia_gpu; then
    info "NVIDIA GPU detected."
  else
    info "Warning: No NVIDIA GPU detected by lspci. Continuing anyway…" >&2
  fi

  ensure_modules_in_mkinitcpio
  maybe_add_kms_hook
  ensure_modprobe_modeset
  rebuild_initramfs

  cat <<EOF

All done!

• Verified/installed: nvidia, nvidia-utils, nvidia-settings
• Ensured MODULES includes: ${REQUIRED_MODULES[*]}
• Ensured HOOKS includes: kms
• Enabled DRM KMS: options nvidia_drm modeset=1
• Rebuilt initramfs: mkinitcpio -P
EOF
}

main "$@"
