#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

#sudo apt-get -y install task-lxde-desktop
#Wheezy: 709 New; 449MB; 1276MB

#http://packages.debian.org/wheezy/task-lxde-desktop
#sudo apt-get -y install lightdm lxde task-desktop
#Wheezy: 1189 New, 756MB; 2135MB

sudo apt-get install lightdm lxde task-desktop

