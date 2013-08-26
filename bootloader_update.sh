#!/bin/bash -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

MIRROR="http://rcn-ee.net/deb"
BACKUP_MIRROR="http://rcn-ee.homeip.net:81/dl/mirrors/deb"

DRIVE="/boot/uboot"

TEMPDIR=$(mktemp -d)

dl_bootloader () {
	echo ""
	echo "Downloading Device's Bootloader"
	echo "-----------------------------"
	conf_bl_listfile="bootloader-ng"
	minimal_boot="1"

	mkdir -p ${TEMPDIR}/dl/${DISTARCH}

	wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${conf_bl_http}/${conf_bl_listfile}

	if [ ! -f ${TEMPDIR}/dl/${conf_bl_listfile} ] ; then
		echo "error: can't connect to rcn-ee.net, retry in a few minutes..."
		exit
	fi

	boot_version=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "VERSION:" | awk -F":" '{print $2}')
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
		SPL=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:SPL" | awk '{print $2}')
		wget --no-verbose --directory-prefix="${TEMPDIR}/dl/" ${SPL}
		SPL=${SPL##*/}
		echo "SPL Bootloader: ${SPL}"
	else
		unset SPL
	fi

	if [ "${boot_name}" ] ; then
		UBOOT=$(cat ${TEMPDIR}/dl/${conf_bl_listfile} | grep "${ABI}:${conf_board}:BOOT" | awk '{print $2}')
		wget --directory-prefix="${TEMPDIR}/dl/" ${UBOOT}
		UBOOT=${UBOOT##*/}
		echo "UBOOT Bootloader: ${UBOOT}"
	else
		unset UBOOT
	fi
}

is_imx () {
	unset spl_name
	boot_name="u-boot.imx"
}

is_omap () {
	spl_name="MLO"
	boot_name="u-boot.img"
}

fatfs_boot () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "SPL: [${SPL}]"
	echo "u-boot.img: [${UBOOT}]"
	echo "for: [${conf_board}]"
	echo ""
	read -p "Are you 100% sure, on selecting [${conf_board}] (y/n)? "
	[ "${REPLY}" == "y" ] || exit
	echo "-----------------------------"
	if [ "${spl_name}" ] ; then
		if [ -f ${TEMPDIR}/dl/${SPL} ] ; then
			rm -f ${DRIVE}/${spl_name} || true
			cp -v ${TEMPDIR}/dl/${SPL} ${DRIVE}/${spl_name}
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

dd_uboot_boot () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "u-boot.imx: [${UBOOT}]"
	echo "for: [${conf_board}]"
	echo ""
	read -p "Are you 100% sure, on selecting [${conf_board}] (y/n)? "
	[ "${REPLY}" == "y" ] || exit
	echo "-----------------------------"

	if [ "x${dd_seek}" != "x" ] ; then
		dd_uboot_seek=${dd_seek}
	fi

	if [ "x${dd_bs}" != "x" ] ; then
		dd_uboot_bs=${dd_bs}
	fi

	if [ "x${dd_uboot_seek}" == "x" ] ; then
		echo "dd_seek/dd_uboot_seek not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ "x${dd_uboot_bs}" == "x" ] ; then
		echo "dd_bs/dd_uboot_bs not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
		sudo dd if=${TEMPDIR}/dl/${UBOOT} of=/dev/mmcblk0 seek=${dd_uboot_seek} bs=${dd_uboot_bs}
		sync
	fi
	echo "-----------------------------"
	echo "Bootloader Updated"
}

dd_spl_uboot_boot () {
	echo "-----------------------------"
	echo "Warning: this script will flash your bootloader with:"
	echo "u-boot-mmc-spl.bin: [${SPL}]"
	echo "u-boot.bin: [${UBOOT}]"
	echo "for: [${conf_board}]"
	echo ""
	read -p "Are you 100% sure, on selecting [${conf_board}] (y/n)? "
	[ "${REPLY}" == "y" ] || exit
	echo "-----------------------------"

	if [ "x${dd_spl_uboot_seek}" == "x" ] ; then
		echo "dd_spl_uboot_seek not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ "x${dd_spl_uboot_bs}" == "x" ] ; then
		echo "dd_spl_uboot_bs not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ "x${dd_uboot_seek}" == "x" ] ; then
		echo "dd_uboot_seek not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ "x${dd_uboot_bs}" == "x" ] ; then
		echo "dd_uboot_bs not found in ${DRIVE}/SOC.sh halting"
		echo "-----------------------------"
		exit
	fi

	if [ -f ${TEMPDIR}/dl/${UBOOT} ] ; then
		sudo dd if=${TEMPDIR}/dl/${SPL} of=/dev/mmcblk0 seek=${dd_spl_uboot_seek} bs=${dd_spl_uboot_bs}
		sudo dd if=${TEMPDIR}/dl/${UBOOT} of=/dev/mmcblk0 seek=${dd_uboot_seek} bs=${dd_uboot_bs}
		sync
	fi
	echo "-----------------------------"
	echo "Bootloader Updated"
}

got_board () {
	BOOTLOADER=${conf_board}

	case "${bootloader_location}" in
	omap_fatfs_boot_part|fatfs_boot)
		is_omap
		dl_bootloader
		fatfs_boot
		;;
	dd_to_drive|dd_uboot_boot)
		is_imx
		dl_bootloader
		dd_uboot_boot
		;;
	dd_spl_uboot_boot)
		dl_bootloader
		dd_spl_uboot_boot
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
			conf_board="${board}"
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

