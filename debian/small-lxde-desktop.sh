#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get -y install lightdm lxde-core x11-xserver-utils

if [ "x${USER}" != "xroot" ] ; then
	sudo /usr/lib/arm-linux-gnueabihf/lightdm/lightdm-set-defaults --autologin ${USER}
else
	echo "To enable autologin:"
	echo "sudo /usr/lib/arm-linux-gnueabihf/lightdm/lightdm-set-defaults --autologin username"
fi
