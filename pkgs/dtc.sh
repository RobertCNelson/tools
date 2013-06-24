#!/bin/sh -e

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl > /dev/null 2>&1 || network_down

unset deb_pkgs
dpkg -l | grep bison >/dev/null || deb_pkgs="${deb_pkgs}bison "
dpkg -l | grep build-essential >/dev/null || deb_pkgs="${deb_pkgs}build-essential "
dpkg -l | grep flex >/dev/null || deb_pkgs="${deb_pkgs}flex "
dpkg -l | grep git-core >/dev/null || deb_pkgs="${deb_pkgs}git-core "

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

#git_sha="origin/master"
#git_sha="27cdc1b16f86f970c3c049795d4e71ad531cca3d"
git_sha="fdc7387845420168ee5dd479fbe4391ff93bddab"
project="dtc"
server="git://git.jdl.com/software"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/
make clean
git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build
git pull git://github.com/RobertCNelson/dtc.git dtc-fixup-fdc7387

make clean
make PREFIX=/usr/local/ CC=gcc CROSS_COMPILE= all
echo "Installing into: /usr/local/bin/"
sudo make PREFIX=/usr/local/ install
