#!/bin/bash

LIBDRM="2.4.38"

#package list from:
#http://anonscm.debian.org/gitweb/?p=collab-maint/xf86-video-omap.git;a=blob;f=debian/control;hb=HEAD
sudo apt-get update
sudo apt-get -y install debhelper dh-autoreconf libdrm-dev libudev-dev libxext-dev pkg-config x11proto-core-dev x11proto-fonts-dev x11proto-gl-dev x11proto-xf86dri-dev xutils-dev xserver-xorg-dev

if [ ! -f /home/${USER}/git/xf86-video-omap/.git/config ] ; then
	git clone git://anongit.freedesktop.org/xorg/driver/xf86-video-omap /home/${USER}/git/xf86-video-omap/
fi

if [ ! -f /home/${USER}/git/libdrm/.git/config ] ; then
	git clone git://anongit.freedesktop.org/mesa/drm /home/${USER}/git/libdrm/
fi

DPKG_ARCH=$(dpkg --print-architecture | grep arm)
case "${DPKG_ARCH}" in
armel)
	gnu="gnueabi"
	;;
armhf)
	gnu="gnueabihf"
	;;
esac

echo ""
echo "Building omap libdrm"
echo ""

cd /home/${USER}/git/libdrm/
make distclean &> /dev/null
git checkout master -f
git pull
git branch libdrm-build -D || true
git checkout ${LIBDRM} -b libdrm-build

./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-${gnu} \
--disable-libkms --disable-intel --disable-radeon --disable-nouveau \
--enable-omap-experimental-api

make
sudo make install

echo ""
echo "Building omap DDX"
echo ""

cd /home/${USER}/git/xf86-video-omap/
make distclean &> /dev/null
git checkout master -f
git pull
git branch omap-build -D || true
git checkout origin/HEAD -b omap-build

./autogen.sh --prefix=/usr
make
sudo make install

if [ -f /etc/X11/xorg.conf ] ; then
	sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
fi
sudo cp /boot/uboot/tools/omap/omapdrm_xorg.conf /etc/X11/xorg.conf

