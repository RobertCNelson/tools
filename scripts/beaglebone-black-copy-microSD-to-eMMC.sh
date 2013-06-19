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

check_running_system () {
	if [ ! -f /boot/uboot/uEnv.txt ] ; then
		echo "Error: script halting, system unrecognized..."
		echo "unable to find: [/boot/uboot/uEnv.txt] is /dev/mmcblk0p1 mounted?"
		exit 1
	fi
}

check_host_pkgs () {
	unset deb_pkgs
	dpkg -l | grep dosfstools >/dev/null || deb_pkgs="${deb_pkgs}dosfstools "
	dpkg -l | grep parted >/dev/null || deb_pkgs="${deb_pkgs}parted "
	dpkg -l | grep rsync >/dev/null || deb_pkgs="${deb_pkgs}rsync "
	#ignoring Squeeze or Lucid: uboot-mkimage
	dpkg -l | grep u-boot-tools >/dev/null || deb_pkgs="${deb_pkgs}u-boot-tools"

	if [ "${deb_pkgs}" ] ; then
		ping -c1 www.google.com | grep ttl >/dev/null 2>&1 || network_down
		echo "Installing: ${deb_pkgs}"
		apt-get update -o Acquire::Pdiffs=false
		apt-get -y install ${deb_pkgs}
	fi
}

update_boot_files () {
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

	mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d /boot/initrd.img-$(uname -r) /boot/uboot/uInitrd
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
	LC_ALL=C fdisk -l ${DISK} | grep ${DISK}p1 | grep '*' || fdisk_toggle_boot

	mkfs.vfat -F 16 ${DISK}p1 -n boot
	sync
}

format_root () {
	mkfs.ext4 ${DISK}p2 -L rootfs
	sync
}

repartition_emmc_sfdisk () {
	dd if=/dev/zero of=${DISK} bs=1024 count=1024
	#64Mb
	LC_ALL=C sfdisk --DOS --sectors 63 --heads 255 --unit M "${MMC}" <<-__EOF__
		,64,0xe,*
		,,,-
	__EOF__

	sync
	format_boot
	format_root
}

repartition_emmc () {
	dd if=/dev/zero of=${DISK} bs=1024 count=1024
	parted --script ${DISK} mklabel msdos
	sync

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
	sync

	format_boot

	fdisk ${DISK} <<-__EOF__
	n
	p
	2
	 
	 
	w
	__EOF__
	sync

	format_root
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
			format_root
		else
			umount ${DISK}p1 || true
			repartition_emmc
		fi
	else
		repartition_emmc
	fi
}

copy_boot () {
	mkdir -p /tmp/boot/ || true
	mount ${DISK}p1 /tmp/boot/
	#Make sure the BootLoader gets copied first:
	cp -v /boot/uboot/MLO /tmp/boot/MLO
	sync
	cp -v /boot/uboot/u-boot.img /tmp/boot/u-boot.img
	sync

	rsync -aAXv /boot/uboot/ /tmp/boot/ --exclude={MLO,u-boot.img,*bak,flash-eMMC.txt}
	sync

	unset root_uuid
	root_uuid=$(/sbin/blkid -s UUID -o value /dev/mmcblk1p2)
	if [ "${root_uuid}" ] ; then
		root_uuid="UUID=${root_uuid}"
		device_id=$(cat /tmp/boot/uEnv.txt | grep mmcroot | grep mmcblk | awk '{print $1}' | awk -F '=' '{print $2}')
		sed -i -e 's:'${device_id}':'${root_uuid}':g' /tmp/boot/uEnv.txt
	else
		root_uuid="/dev/mmcblk0p2"
	fi
	sync

	umount ${DISK}p1 || true
}

copy_rootfs () {
	mkdir -p /tmp/rootfs/ || true
	mount ${DISK}p2 /tmp/rootfs/
	rsync -aAXv /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/boot/*,/lib/modules/*}
	mkdir -p /tmp/rootfs/boot/uboot/ || true
	mkdir -p /tmp/rootfs/lib/modules/`uname -r` || true
	rsync -aAXv /lib/modules/`uname -r`/* /tmp/rootfs/lib/modules/`uname -r`/
	sync

	unset boot_uuid
	boot_uuid=$(/sbin/blkid -s UUID -o value /dev/mmcblk1p1)
	if [ "${boot_uuid}" ] ; then
		boot_uuid="UUID=${boot_uuid}"
	else
		boot_uuid="/dev/mmcblk0p1"
	fi

	unset root_filesystem
	root_filesystem=$(mount | grep /dev/mmcblk0p2 | awk '{print $5}')
	if [ ! "${root_filesystem}" ] ; then
		root_filesystem=$(mount | grep "${root_uuid}" | awk '{print $5}')
	fi
	if [ ! "${root_filesystem}" ] ; then
		root_filesystem="auto"
	fi

	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "# Auto generated by: beaglebone-black-copy-microSD-to-eMMC.sh" >> /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ${root_filesystem}  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "${boot_uuid}  /boot/uboot  auto  defaults  0  0" >> /tmp/rootfs/etc/fstab
	sync

	umount ${DISK}p2 || true
	echo ""
	echo "This script has now completed it's task"
	echo "-----------------------------"
	echo "Note: Actually unpower the board, a reset [sudo reboot] is not enough."
	echo "-----------------------------"
}

check_running_system
check_host_pkgs
update_boot_files
mount_n_check
copy_boot
copy_rootfs
