#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade
#sudo apt-get -y install task-lxde-desktop
#http://packages.debian.org/wheezy/task-lxde-desktop
sudo apt-get -y install lightdm lxde task-desktop
