#!/bin/bash -e
#
# Copyright (c) 2013 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

DISK=/dev/mmcblk1

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl &> /dev/null || network_down

check_host_pkgs () {
	unset deb_pkgs
	dpkg -l | grep parted >/dev/null || deb_pkgs+="parted "
	dpkg -l | grep dosfstools >/dev/null || deb_pkgs+="dosfstools "

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		apt-get update
		apt-get -y install ${deb_pkgs}
	fi
}

reformat_emmc () {
	dd if=/dev/zero of=${DISK} bs=1024 count=1024
	parted --script ${DISK} mklabel msdos

	fdisk ${DISK} <<-__EOF__
	n
	p
	1
	 
	+64M
	t
	e
	p
	w
	__EOF__

	parted --script ${DISK} set 1 boot on

	mkfs.vfat -F 16 ${DISK}p1 -n boot

	fdisk ${DISK} <<-__EOF__
	n
	p
	2
	 
	 
	w
	__EOF__

	mkfs.ext4 ${DISK}p2 -L rootfs
}

setup_boot () {
	mkdir /tmp/boot/
	mount ${DISK}p1 /tmp/boot/
	#cp these first:
	cp -v /boot/uboot/MLO /tmp/boot/MLO
	cp -v /boot/uboot/u-boot.img /tmp/boot/u-boot.img
}

check_host_pkgs
reformat_emmc
setup_boot
