#!/bin/bash -e

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl &> /dev/null || network_down

unset deb_pkgs
dpkg -l | grep build-essential >/dev/null || deb_pkgs+="build-essential "

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

sudo gcc spidev_test.c -o spitest

echo ""
echo "spidev_test.c should output"
echo ""
echo "spi mode: 0"
echo "bits per word: 8"
echo "max speed: 500000 Hz (500 KHz)"
echo ""
echo "FF FF FF FF FF FF"
echo "40 00 00 00 00 95"
echo "FF FF FF FF FF FF"
echo "FF FF FF FF FF FF"
echo "FF FF FF FF FF FF"
echo "DE AD BE EF BA AD"
echo "F0 0D "
echo ""

echo "Beagle"
echo "sudo ./spitest -D /dev/spidev3.0"
