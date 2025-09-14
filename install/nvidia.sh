#!/bin/bash

# TODO : configurer /etc/mkinitcpio.conf pour editer la ligne pour qu'elle ressemble a
# MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm ...)
sudo mkinitcpio -P
