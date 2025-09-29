#!/bin/bash
set -euo pipefail

ts() { date +"%Y%m%d-%H%M%S"; }

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Run this as root. Aborting." >&2
    exit 1
  fi
}

have_cmd() { command -v "$1" &>/dev/null; }

backup() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  cp -a "$f" "${f}.bak.$(ts)"
}

ensure_pkg() {
  local pkg="$1"
  if ! pacman -Qi "$pkg" &>/dev/null; then
    echo "Installing $pkg..."
    pacman --noconfirm -Syu "$pkg"
  else
    echo "$pkg already installed."
  fi
}

# Rebuild HOOKS to ensure:
# - 'plymouth' exists
# - 'systemd' (if present) is before 'plymouth'
# - 'plymouth' is before 'encrypt' or 'sd-encrypt' (if present)
fix_mkinitcpio_hooks() {
  local file="/etc/mkinitcpio.conf"
  [[ -f "$file" ]] || {
    echo "$file not found"
    exit 1
  }

  backup "$file"

  # extract hooks payload between parentheses
  local payload
  payload=$(sed -n 's/^[[:space:]]*HOOKS=(\(.*\))[[:space:]]*$/\1/p' "$file" | tail -n1)

  if [[ -z "$payload" ]]; then
    echo "Could not parse HOOKS=() from $file"
    exit 1
  fi

  # read into array (split on whitespace)
  # shellcheck disable=SC2206
  local hooks=($payload)

  # remove any existing 'plymouth'
  local cleaned=()
  for h in "${hooks[@]}"; do
    [[ "$h" == "plymouth" ]] && continue
    cleaned+=("$h")
  done
  hooks=("${cleaned[@]}")

  local inserted=0
  local result=()

  for h in "${hooks[@]}"; do
    if [[ "$h" == "systemd" ]]; then
      # keep systemd, then insert plymouth right after it (once)
      result+=("$h")
      if [[ $inserted -eq 0 ]]; then
        result+=("plymouth")
        inserted=1
      fi
      continue
    fi

    if [[ "$h" == "encrypt" || "$h" == "sd-encrypt" ]]; then
      # ensure plymouth is before encrypt hooks
      if [[ $inserted -eq 0 ]]; then
        result+=("plymouth")
        inserted=1
      fi
      result+=("$h")
      continue
    fi

    result+=("$h")
  done

  if [[ $inserted -eq 0 ]]; then
    # no systemd/encrypt encountered; just append at the end
    result+=("plymouth")
  fi

  local new_line="HOOKS=(${result[*]})"
  echo "Updating HOOKS -> $new_line"
  # Replace only the HOOKS line (the last matching line wins)
  # Use a temp file to avoid sed -i portability quirks
  local tmp
  tmp="$(mktemp)"
  awk -v repl="$new_line" '
    BEGIN{done=0}
    /^\s*HOOKS=\(/ { last=NR }
    { lines[NR]=$0 }
    END{
      for(i=1;i<=NR;i++){
        if(i==last){ print repl } else { print lines[i] }
      }
    }' "$file" >"$tmp"
  mv "$tmp" "$file"
}

ensure_kernel_arg_splash_grub() {
  local f="/etc/default/grub"
  [[ -f "$f" ]] || return 1
  backup "$f"

  # read current line or set default
  local line
  line=$(grep -E '^GRUB_CMDLINE_LINUX=' "$f" || true)
  if [[ -z "$line" ]]; then
    echo 'GRUB_CMDLINE_LINUX="splash"' >>"$f"
  else
    if grep -E '^GRUB_CMDLINE_LINUX=.*\bsplash\b' "$f" >/dev/null; then
      :
    else
      # insert 'splash' before closing quote
      sed -i 's/^\(GRUB_CMDLINE_LINUX="[^"]*\)"/\1 splash"/' "$f"
    fi
  fi

  echo "Regenerating GRUB config..."
  if have_cmd grub-mkconfig; then
    grub-mkconfig -o /boot/grub/grub.cfg
  elif have_cmd grub2-mkconfig; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
  else
    echo "grub-mkconfig not found. You must regenerate GRUB config manually." >&2
  fi
  return 0
}

ensure_kernel_arg_splash_systemdboot() {
  shopt -s nullglob
  local changed=0
  for entry in /boot/loader/entries/*.conf; do
    backup "$entry"
    if grep -E '^options ' "$entry" | grep -qw splash; then
      continue
    fi
    # Append splash to the options line
    sed -i 's/^\(options .*\)$/\1 splash/' "$entry"
    echo "Updated: $entry"
    changed=1
  done
  if [[ $changed -eq 0 ]]; then
    return 1
  fi
  return 0
}

ensure_kernel_arg_splash() {
  echo "Ensuring kernel cmdline has 'splash'..."
  if ensure_kernel_arg_splash_grub; then
    echo "GRUB: 'splash' ensured."
    return
  fi
  if ensure_kernel_arg_splash_systemdboot; then
    echo "systemd-boot: 'splash' ensured."
    return
  fi
  echo "Could not detect GRUB or systemd-boot entries. Add 'splash' to your kernel cmdline manually." >&2
}

rebuild_initramfs() {
  echo "Regenerating initramfs with mkinitcpio -P ..."
  mkinitcpio -P
}

main() {
  need_root
  ensure_pkg plymouth
  fix_mkinitcpio_hooks
  set_theme_if_requested
  rebuild_initramfs
  ensure_kernel_arg_splash

  echo
  echo "All set. Reboot to test Plymouth."
  echo "Tip: For a quieter boot, add 'quiet loglevel=3' to your kernel cmdline too."
}

main "$@"
