#!/bin/bash -e

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl &> /dev/null || network_down

unset deb_pkgs
dpkg -l | grep build-essential >/dev/null || deb_pkgs+="build-essential "
dpkg -l | grep gstreamer-tools >/dev/null || deb_pkgs+="gstreamer-tools "

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

