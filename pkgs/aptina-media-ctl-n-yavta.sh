#!/bin/bash

sudo apt-get update
sudo apt-get -y install build-essential dh-autoreconf libudev-dev pkg-config

DPKG_ARCH=$(dpkg --print-architecture | grep arm)
case "${DPKG_ARCH}" in
armel)
	gnu="gnueabi"
	;;
armhf)
	gnu="gnueabihf"
	;;
esac

git_sha="origin/master"
project="media-ctl"
server="git://github.com/RobertCNelson"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

cleanup_generated_files () {
	rm -rf Makefile.in || true
	rm -rf aclocal.m4 || true
	rm -rf autom4te.cache/  || true
	rm -rf config.h.in || true
	rm -rf config/ || true
	rm -rf configure || true
	rm -rf m4/libtool.m4 || true
	rm -rf m4/ltoptions.m4 || true
	rm -rf m4/ltsugar.m4 || true
	rm -rf m4/ltversion.m4 || true
	rm -rf m4/lt~obsolete.m4 || true
	rm -rf src/Makefile.in || true
}

cd ${HOME}/git/${project}/
cleanup_generated_files

git checkout master -f
git pull
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

echo ""
echo "Building ${project}"
echo ""

autoreconf --install
./configure --prefix=/usr --libdir=/usr/lib/arm-linux-${gnu}
make
sudo make install
make distclean &>/dev/null
cleanup_generated_files

git_sha="origin/master"
project="yavta"
server="git://github.com/RobertCNelson"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

cd ${HOME}/git/${project}/

git checkout master -f
git pull
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

echo ""
echo "Building ${project}"
echo ""

make
sudo install yavta /usr/sbin/
make clean &>/dev/null
