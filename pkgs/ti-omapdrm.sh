#!/bin/bash

#package list from:
#http://anonscm.debian.org/gitweb/?p=collab-maint/xf86-video-omap.git;a=blob;f=debian/control;hb=HEAD
sudo apt-get update

#libdrm Installs: (wheezy)
#dh-autoreconf libpciaccess-dev libpciaccess0 libpthread-stubs0
#libpthread-stubs0-dev libx11-dev libxau-dev libxcb1-dev libxdmcp-dev pkg-config
#x11proto-core-dev x11proto-input-dev x11proto-kb-dev xorg-sgml-doctools xtrans-dev
sudo apt-get -y build-dep libdrm

#for: xf86-video-omap
sudo apt-get -y install xutils-dev

#need to review:
sudo apt-get -y install debhelper libudev-dev x11proto-core-dev libxext-dev x11proto-fonts-dev x11proto-gl-dev x11proto-xf86dri-dev x11proto-xf86dri-dev xserver-xorg-dev

DPKG_ARCH=$(dpkg --print-architecture | grep arm)
case "${DPKG_ARCH}" in
armel)
	gnu="gnueabi"
	;;
armhf)
	gnu="gnueabihf"
	;;
esac

git_sha="2.4.39"
project="libdrm"
server="git://anongit.freedesktop.org/mesa/drm"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server} ${HOME}/git/${project}/ || true
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

echo ""
echo "Building ${project}"
echo ""

cd ${HOME}/git/${project}/

make distclean &> /dev/null
git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-${gnu} \
--disable-libkms --disable-intel --disable-radeon --disable-nouveau \
--enable-omap-experimental-api

make
sudo make install
make distclean &> /dev/null

git_sha="origin/master"
project="xf86-video-omap"
server="git://anongit.freedesktop.org/xorg/driver"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/ || true
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

echo ""
echo "Building ${project}"
echo ""

cd ${HOME}/git/${project}/

make distclean &> /dev/null
git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

./autogen.sh --prefix=/usr
make
sudo make install

#if [ ! -d /etc/X11/ ] ; then
#	sudo mkdir -p /etc/X11/ || true
#fi

#if [ -f /etc/X11/xorg.conf ] ; then
#	sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
#fi
#sudo cp /boot/uboot/tools/omap/omapdrm_xorg.conf /etc/X11/xorg.conf

