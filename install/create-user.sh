#!/bin/bash

# Source utility functions
source ../utilities/utils.sh

if [ ! -z ${USER_NAME+x} ]; then
  echo "What is the username?"
  read USER_NAME
fi

# Install sudo
install_package sudo

useradd --create-home USER_NAME
echo "${USER_NAME} ALL=(ALL) ALL" >>"/etc/sudoers.d/90-${USER_NAME}"
