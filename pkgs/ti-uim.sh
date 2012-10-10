#!/bin/bash

ti_uim_sha="origin/master"

sudo apt-get update
sudo apt-get -y install build-essential bluetooth

if [ ! -f ${HOME}/git/ti-uim/.git/config ] ; then
	git clone git://github.com/RobertCNelson/ti-uim.git ${HOME}/git/ti-uim/
fi

cd ${HOME}/git/ti-uim/

git checkout master -f
git pull
git branch ${ti_uim_sha}-build -D || true
git checkout ${ti_uim_sha} -b ${ti_uim_sha}-build

make
sudo make install
make clean

