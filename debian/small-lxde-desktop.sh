#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

#http://packages.debian.org/wheezy/task-lxde-desktop

#Wheezy: 709 pkgs, 449MB, 1276MB
#sudo apt-get -y install task-lxde-desktop

#Wheezy: 1189 pkgs, 756MB, 2135MB
#sudo apt-get -y install lightdm lxde task-desktop

#Wheezy: 402 pkgs, 159MB, 444MB
#sudo apt-get -y install lightdm lxde

#Wheezy: 281 pkgs, 94.9MB, 280MB
sudo apt-get -y install lightdm lxde-core

#We know the user/password...
if [ -f /etc/rcn-ee.conf ] ; then
	username=$(echo ${USER})
	if [ "x${username}" != "xroot" ] ; then
		sudo /usr/lib/arm-linux-gnueabihf/lightdm/lightdm-set-defaults --autologin ${username}
	fi
fi
