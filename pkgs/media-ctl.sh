#!/bin/bash

VERSION="origin/master"

sudo apt-get update
sudo apt-get -y install build-essential dh-autoreconf libudev-dev pkg-config

if [ ! -f ${HOME}/git/aptina-tools/.git/config ] ; then
	git clone git://github.com/RobertCNelson/BeagleBoard-xM.git ${HOME}/git/aptina-tools/
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

cleanup_generated_files () {
	rm -rf Makefile.in || true
	rm -rf aclocal.m4 || true
	rm -rf autom4te.cache/  || true
	rm -rf config.h.in || true
	rm -rf config/ || true
	rm -rf configure || true
	rm -rf rm -rf m4/libtool.m4 || true
	rm -rf m4/ltoptions.m4 || true
	rm -rf m4/ltsugar.m4 || true
	rm -rf m4/ltversion.m4 || true
	rm -rf m4/lt~obsolete.m4 || true
	rm -rf src/Makefile.in || true
}

cd ${HOME}/git/aptina-tools/tools/media-ctl
cleanup_generated_files

cd ${HOME}/git/aptina-tools/
git checkout master -f
git pull
git branch media-ctl-build -D || true
git checkout ${VERSION} -b media-ctl-build

echo ""
echo "Building media-ctl"
echo ""

cd ./tools/media-ctl

autoreconf --install
./configure --prefix=/usr --libdir=/usr/lib/arm-linux-${gnu}
make
sudo make install
make distclean &>/dev/null
cleanup_generated_files

