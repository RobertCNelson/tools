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

git_sha="2.4.40"
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

./autogen.sh --prefix=/usr --libdir=/usr/lib/`dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null`/ \
--disable-libkms --disable-intel --disable-radeon --disable-nouveau --disable-vmwgfx \
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

if [ ! -d /etc/X11/ ] ; then
	sudo mkdir -p /etc/X11/ || true
fi

if [ -f /etc/X11/xorg.conf ] ; then
	sudo rm -rf /etc/X11/xorg.conf.bak || true
	sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
fi

cat > /tmp/xorg.conf <<-__EOF__
	Section "Device"
	        Identifier      "omap"
	        Driver          "omap"
	EndSection

__EOF__

sudo cp -v /tmp/xorg.conf /etc/X11/xorg.conf
