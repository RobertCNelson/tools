#!/bin/bash

imx_sha="origin/master"
system=$(lsb_release -sd | awk '{print $1}')

sudo apt-get update
sudo apt-get -y install build-essential

if [ ! -f ${HOME}/git/sdma-firmware/.git/config ] ; then
	git clone git://git.pengutronix.de/git/imx/sdma-firmware.git ${HOME}/git/sdma-firmware/
fi

cd ${HOME}/git/sdma-firmware/

git checkout master -f
git pull
git branch ${imx_sha}-build -D || true
git checkout ${imx_sha} -b ${imx_sha}-build

make
sudo cp sdma*.bin /lib/firmware/
make clean

