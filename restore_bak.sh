#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

DRIVE="/boot/uboot"

echo "Kernel Recovery"
if [ $(uname -m) != "armv7l" ] ; then
	echo "Warning, this is only half implemented to make it work on x86..."
	echo "mount your mmc drive to /tmp/uboot/"
	DRIVE="/tmp/uboot"
	sudo mkdir -p ${DRIVE} || true
fi

if [ -f ${DRIVE}/uImage_bak ] ; then
	rm -rf ${DRIVE}/uImage || true
	mv -v ${DRIVE}/uImage_bak ${DRIVE}/uImage
fi

if [ -f ${DRIVE}/zImage_bak ] ; then
	rm -rf ${DRIVE}/zImage || true
	sudo mv -v ${DRIVE}/zImage_bak ${DRIVE}/zImage
fi

if [ -f ${DRIVE}/uInitrd_bak ] ; then
	rm -rf ${DRIVE}/uInitrd || true
	mv -v ${DRIVE}/uInitrd_bak ${DRIVE}/uInitrd
fi

if [ -f ${DRIVE}/initrd.bak ] ; then
	rm -rf ${DRIVE}/initrd.img || true
	mv -v ${DRIVE}/initrd.bak ${DRIVE}/initrd.img
fi

if [ -d ${DRIVE}/dtbs_bak/ ] ; then
	rm -rf ${DRIVE}/dtbs/ || true
	mv ${DRIVE}/dtbs_bak/ ${DRIVE}/dtbs/
fi

if [ $(uname -m) != "armv7l" ] ; then
	sync
	sync
	sudo umount ${DRIVE}/ || true
fi
echo "Kernel Recovery Complete"


