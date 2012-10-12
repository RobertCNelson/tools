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

if [ ! -d /lib/firmware/sdma ] ; then
	sudo mkdir -p /lib/firmware/sdma || true
fi

sudo cp sdma*.bin /lib/firmware/sdma
make clean

if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
	update-initramfs -c -k $(uname -r)
else
	update-initramfs -u -k $(uname -r)
fi

if [ -f /boot/vmlinuz-$(uname -r) ] ; then
	cp -v /boot/vmlinuz-$(uname -r) /boot/uboot/zImage
fi

if [ -f /boot/initrd.img-$(uname -r) ] ; then
	cp -v /boot/initrd.img-$(uname -r) /boot/uboot/initrd.img
fi

echo "sdma firmware installed"
echo "please reboot"

