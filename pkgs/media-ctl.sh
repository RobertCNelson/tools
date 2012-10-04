#!/bin/bash

sudo apt-get update
sudo apt-get -y install build-essential dh-autoreconf libudev-dev pkg-config

if [ ! -f ${HOME}/git/aptina-tools/.git/config ] ; then
	git clone git://github.com/RobertCNelson/BeagleBoard-xM.git ${HOME}/git/aptina-tools/
fi

echo ""
echo "Building media-ctl"
echo ""

cd ${HOME}/git/aptina-tools/tools/media-ctl

autoreconf --install
./configure
make
sudo make install
