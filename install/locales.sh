#!/bin/bash

GEN=/etc/locale.gen
LOCALES=("en_GB.UTF-8 UTF-8  " "en_US.UTF-8 UTF-8  ")

source ../utilities/utils.sh

require_root

# Validate that the lines are present and not commented
for loc in "${LOCALES[@]}"; do
  # If the line exist, we uncomment it
  if grep -Eq "^[#[:space:]]*$(printf '%s' "$loc" | sed 's/[.[\*^$(){}+?|\\/]/\\&/g')$" "$GEN"; then
    sudo sed -i -E "s|^[#[:space:]]*($(printf '%s' "$loc" | sed 's/[.[\*^$(){}+?|\\/]/\\&/g'))$|\1|" "$GEN"
  else
    # Else we add it
    echo "$loc" >>"$GEN"
  fi
done

# Render the locales
sudo locale-gen

info "Locales activated: ${LOCALES[*]}"
info "Validating..."
# TODO Make this check more flexible, we want to check for the values in LOCALES not hard codded values
locale -a | grep -E 'en_(GB|US)\.utf8' || true
