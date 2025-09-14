#!/bin/bash

# Some application need the "en_GB.UTF-8 UTF-8" and "en_US.UTF-8 UTF-8" languages to be configured
sudo echo "en_GB.UTF-8 UTF-8  " >>/etc/locale.gen
sudo echo "en_US.UTF-8 UTF-8  " >>/etc/locale.gen
sudo locale-gen
