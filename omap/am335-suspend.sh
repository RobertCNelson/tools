#!/bin/sh -e

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ ! -f /lib/firmware/am335x-pm-firmware.bin ] ; then
	cd /opt/source/
	git clone git://arago-project.org/git/projects/am33x-cm3.git
	cp -v /opt/source/am33x-cm3/bin/am335x-pm-firmware.bin /lib/firmware/am335x-pm-firmware.bin
fi

if [ -d /sys/devices/ocp.2/44d00000.wkup_m3/ ] ; then
	echo 1 > /sys/devices/ocp.2/44d00000.wkup_m3/firmware/am335x-pm-firmware.bin/loading
	cat /lib/firmware/am335x-pm-firmware.bin > /sys/devices/ocp.2/44d00000.wkup_m3/firmware/am335x-pm-firmware.bin/data
	echo 0 > /sys/devices/ocp.2/44d00000.wkup_m3/firmware/am335x-pm-firmware.bin/loading
fi

if [ -d /sys/devices/ocp.3/44d00000.wkup_m3/ ] ; then
	echo 1 > /sys/devices/ocp.3/44d00000.wkup_m3/firmware/am335x-pm-firmware.bin/loading
	cat /lib/firmware/am335x-pm-firmware.bin > /sys/devices/ocp.3/44d00000.wkup_m3/firmware/am335x-pm-firmware.bin/data
	echo 0 > /sys/devices/ocp.3/44d00000.wkup_m3/firmware/am335x-pm-firmware.bin/loading
fi

echo "run: echo mem > /sys/power/state"

