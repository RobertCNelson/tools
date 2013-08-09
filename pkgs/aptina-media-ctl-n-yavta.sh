#!/bin/bash -e

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

unset deb_pkgs
pkg="build-essential"
check_dpkg
pkg="dh-autoreconf"
check_dpkg
pkg="libudev-dev"
check_dpkg
pkg="pkg-config"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo ""
	echo "Installing: ${deb_pkgs}"
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
	echo "--------------------"
fi

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
