#!/bin/bash

unset deb_pkgs
dpkg -l | grep build-essential >/dev/null || deb_pkgs+="build-essential "

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

git_sha="origin/master"
project="omapconf"
server="git://github.com/omapconf"
system=$(lsb_release -sd | awk '{print $1}')

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

cd ${HOME}/git/${project}/

git checkout master -f
git pull
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

make CROSS_COMPILE= 
sudo make DESTDIR=/usr/sbin install
make clean
