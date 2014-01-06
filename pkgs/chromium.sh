#!/bin/sh -e

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

unset deb_pkgs

pkg="bison"
check_dpkg
pkg="build-essential"
check_dpkg
pkg="gperf"
check_dpkg
pkg="libcups2-dev"
check_dpkg
pkg="libgtk2.0-dev"
check_dpkg
pkg="libnss3-dev"
check_dpkg
pkg="libgconf2-dev"
check_dpkg
pkg="libgcrypt11-dev"
check_dpkg
pkg="libgnome-keyring-dev"
check_dpkg
pkg="libpci-dev"
check_dpkg
pkg="libpulse-dev"
check_dpkg
pkg="libudev-dev"
check_dpkg
pkg="pkg-config"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
fi
