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

ping -c1 www.google.com | grep ttl >/dev/null 2>&1 || network_down

check_host_pkgs () {
	unset deb_pkgs
	dpkg -l | grep dosfstools >/dev/null || deb_pkgs="${deb_pkgs}dosfstools "
	dpkg -l | grep parted >/dev/null || deb_pkgs="${deb_pkgs}parted "
	dpkg -l | grep rsync >/dev/null || deb_pkgs="${deb_pkgs}rsync "

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		apt-get update -o Acquire::Pdiffs=false
		apt-get -y install ${deb_pkgs}
	fi
}

fdisk_toggle_boot () {
	fdisk ${DISK} <<-__EOF__
	a
	1
	w
	__EOF__
	sync
}

format_boot () {
	fdisk -l ${DISK} | grep ${DISK}p1 | grep '*' || fdisk_toggle_boot

	mkfs.vfat -F 16 ${DISK}p1 -n boot
	sync
}

mount_n_check () {
	umount ${DISK}p1 || true
	umount ${DISK}p2 || true

	lsblk | grep mmcblk1p1 >/dev/null 2<&1 || repartition_emmc
	mkdir -p /tmp/boot/ || true
	if mount -t vfat ${DISK}p1 /tmp/boot/ ; then
		if [ -f /tmp/boot/MLO ] ; then
			umount ${DISK}p1 || true
			format_boot
		else
			umount ${DISK}p1 || true
			echo "use: beaglebone-black-copy-microSD-to-eMMC.sh"
		fi
	else
		echo "use: beaglebone-black-copy-microSD-to-eMMC.sh"
	fi
}

copy_boot () {
	mkdir -p /tmp/boot/ || true
	mount ${DISK}p1 /tmp/boot/
	#Make sure the BootLoader gets copied first:
	rm -f /tmp/boot/MLO || true
	cp -v /boot/uboot/MLO /tmp/boot/MLO
	sync
	rm -f /tmp/boot/u-boot.img || true
	cp -v /boot/uboot/u-boot.img /tmp/boot/u-boot.img
	sync

	rsync -aAXv /boot/uboot/ /tmp/boot/ --exclude={MLO,u-boot.img,*bak}
	sync

	unset root_uuid
	root_uuid=$(/sbin/blkid -s UUID -o value /dev/mmcblk1p2)
	if [ "${root_uuid}" ] ; then
		root_uuid="UUID=${root_uuid}"
		sed -i -e 's:/dev/mmcblk0p2:'${root_uuid}':g' /tmp/boot/uEnv.txt
	else
		root_uuid="/dev/mmcblk0p2"
	fi
	sync

	umount ${DISK}p1 || true
}

check_host_pkgs
mount_n_check
copy_boot
