#!/bin/sh

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

cd /boot/uboot
mount -o remount,rw /boot/uboot

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

MKIMAGE=$(which mkimage 2>/dev/null)
if [ "x${MKIMAGE}" != "x" ] ; then
	if [ -f /boot/uboot/uInitrd ] ; then
		mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d /boot/initrd.img-$(uname -r) /boot/uboot/uInitrd
	fi

	if [ -f /boot/uboot/uImage ] ; then
		if [ -f /boot/uboot/boot.cmd ] ; then
			mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/boot.cmd /boot/uboot/boot.scr
			cp -v /boot/uboot/boot.scr /boot/uboot/boot.ini
		fi
		if [ -f /boot/uboot/serial.cmd ] ; then
			mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Boot Script" -d /boot/uboot/serial.cmd /boot/uboot/boot.scr
		fi
		if [ -f /boot/uboot/user.cmd ] ; then
			mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Reset Nand" -d /boot/uboot/user.cmd /boot/uboot/user.scr
		fi
	fi
fi

