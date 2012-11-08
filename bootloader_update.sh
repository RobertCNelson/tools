#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

MIRROR="http://rcn-ee.net/deb"
BACKUP_MIRROR="http://rcn-ee.homeip.net:81/dl/mirrors/deb"

DRIVE="/boot/uboot"

TEMPDIR=$(mktemp -d)

rcn_ee_down_use_mirror () {
	echo "rcn-ee.net down, switching to slower backup mirror"
	echo "-----------------------------"
	MIRROR=${BACKUP_MIRROR}
	RCNEEDOWN=1
}

dl_bootloader () {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"
	bootlist="bootloader-ng"
	minimal_boot="1"
	unset disable_mirror

	mkdir -p ${TEMPDIR}/dl/${DISTARCH}

	unset RCNEEDOWN
	if [ "${disable_mirror}" ] ; then
		wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/${bootlist}
	else
		echo "attempting to use rcn-ee.net for dl files [10 second time out]..."
		wget -T 10 -t 1 --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/${bootlist}
	fi

	if [ ! -f ${TEMPDIR}/dl/${bootlist} ] ; then
		if [ "${disable_mirror}" ] ; then
			echo "error: can't connect to rcn-ee.net, retry in a few minutes (backup mirror down)"
			exit
		else
			rcn_ee_down_use_mirror
			wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MIRROR}/tools/latest/${bootlist}
		fi
	fi

	if [ "${RCNEEDOWN}" ] ; then
		sed -i -e "s/rcn-ee.net/rcn-ee.homeip.net:81/g" ${TEMPDIR}/dl/${bootlist}
		sed -i -e 's:81/deb/:81/dl/mirrors/deb/:g' ${TEMPDIR}/dl/${bootlist}
	fi

	boot_version=$(cat ${TEMPDIR}/dl/${bootlist} | grep "VERSION:" | awk -F":" '{print $2}')
	if [ "x${boot_version}" != "x${minimal_boot}" ] ; then
		echo "Error: This script is out of date and unsupported..."
		echo "Please Visit: https://github.com/RobertCNelson to find updates..."
		exit
	fi

	if [ "${USE_BETA_BOOTLOADER}" ] ; then
		ABI="ABX2"
	else
		ABI="ABI2"
	fi

	if [ "${spl_name}" ] ; then
		MLO=$(cat ${TEMPDIR}/dl/${bootlist} | grep "${ABI}:${board}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix=${TEMPDIR}/dl/ ${MLO}
		MLO=${MLO##*/}
		echo "SPL Bootloader: ${MLO}"
	else
		unset MLO
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/${bootlist} | grep "${ABI}:${board}:BOOT" | awk '{print $2}')
		wget --directory-prefix=${TEMPDIR}/dl/ ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi
}

is_omap () {
	spl_name="MLO"
	boot_name="u-boot.img"
}

omap_fatfs_boot_part () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "MLO: [${MLO}]"
	echo "u-boot.img: [${UBOOT}]"
	echo "for: [${board}]"
	echo ""
	read -p "Are you 100% sure, on selecting [${board}] (y/n)? "
	[ "${REPLY}" == "y" ] || exit
	echo "-----------------------------"
	if [ "${spl_name}" ] ; then
		if [ -f ${TEMPDIR}/dl/${MLO} ] ; then
			rm -f ${DRIVE}/${spl_name} || true
			cp -v ${TEMPDIR}/dl/${MLO} ${DRIVE}/${spl_name}
			sync
		fi
	fi

	if [ "${boot_name}" ] ; then
		if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
			rm -f ${DRIVE}/${boot_name} || true
			cp -v ${TEMPDIR}/dl/${UBOOT} ${DRIVE}/${boot_name}
			sync
		fi
	fi
	echo "-----------------------------"
	echo "Bootloader Updated"
}

is_imx () {
	unset spl_name
	boot_name="u-boot.imx"
}

dd_to_drive () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "u-boot.imx: [${UBOOT}]"
	echo "for: [${board}]"
	echo ""
	read -p "Are you 100% sure, on selecting [${board}] (y/n)? "
	[ "${REPLY}" == "y" ] || exit
	echo "-----------------------------"

	if [ "x${dd_seek}" == "x" ] ; then
		echo "dd_seek not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ "x${dd_bs}" == "x" ] ; then
		echo "dd_bs not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ "${boot_name}" ] ; then
		if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
			sudo dd if=${TEMPDIR}/dl/${UBOOT} of=/dev/mmcblk0 seek=${dd_seek} bs=${dd_bs}
			sync
		fi
	fi
	echo "-----------------------------"
	echo "Bootloader Updated"
}

got_board () {
	BOOTLOADER=${board}

	case "${bootloader_location}" in
	omap_fatfs_boot_part)
		is_omap
		dl_bootloader
		omap_fatfs_boot_part
		;;
	dd_to_drive)
		is_imx
		dl_bootloader
		dd_to_drive
		;;
	esac
}

check_soc_sh () {
	echo "Bootloader Recovery"
	if [ $(uname -m) != "armv7l" ] ; then
		echo "Warning, this is only half implemented to make it work on x86..."
		echo "mount your mmc drive to /tmp/uboot/"
		DRIVE="/tmp/uboot"
	fi

	if [ -f ${DRIVE}/SOC.sh ] ; then
		source ${DRIVE}/SOC.sh
		if [ "x${board}" != "x" ] ; then
			got_board
		else
			echo "Sorry: board undefined in [${DRIVE}/SOC.sh] can not update bootloader safely"
			exit
		fi
	else
		echo "Sorry: unable to find [${DRIVE}/SOC.sh] can not update bootloader safely"
		exit
	fi

	if [ $(uname -m) != "armv7l" ] ; then
		sync
		sync
		sudo umount ${DRIVE}/ || true
	fi
	echo "Bootloader Recovery Complete"
}

checkparm () {
	if [ "$(echo $1|grep ^'\-')" ] ; then
		echo "E: Need an argument"
	fi
}

# parse commandline options
while [ ! -z "$1" ] ; do
	case $1 in
	--use-beta-bootloader)
		USE_BETA_BOOTLOADER=1
		;;
	esac
	shift
done

check_soc_sh

