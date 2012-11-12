#!/bin/bash -e

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl &> /dev/null || network_down

unset deb_pkgs
dpkg -l | grep build-essential >/dev/null || deb_pkgs+="build-essential "

echo "Installing: ${deb_pkgs}dh-autoreconf libudev-dev pkg-config"
sudo apt-get update
sudo apt-get -y install ${deb_pkgs}dh-autoreconf libudev-dev pkg-config

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

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/
cleanup_generated_files

git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

echo ""
echo "Building ${project}"
echo ""

autoreconf --install
./configure --prefix=/usr --libdir=/usr/lib/`dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null`/
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

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/

git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

echo ""
echo "Building ${project}"
echo ""

make
sudo install yavta /usr/sbin/
make clean &>/dev/null
