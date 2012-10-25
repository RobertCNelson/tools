tools
=====
small collection of scripts that end up on the ARM images...

update:
=====
	cd /boot/uboot/tools/
	sudo ./update.sh

Generic Tools:
==============

update boot files:
------------------
	cd /boot/uboot/tools/
	sudo ./update_boot_files.sh

lxde minimal desktop:
---------------------
	cd /boot/uboot/tools/
	./ubuntu/minimal_lxde_desktop.sh

Packages:
==============

omapdrm kms userspace:
---------------------
	cd /boot/uboot/tools/pkgs/
	./ti-omapdrm.sh

omapconf (TI OMAP4+): https://github.com/omapconf/omapconf
---------------------
	cd /boot/uboot/tools/pkgs/
	./ti-omapconf.sh

uim (TI uim Bluetooth wl12xx):
---------------------
	cd /boot/uboot/tools/pkgs/
	./ti-uim.sh

sdma-firmware (imx sdma firmware): http://git.pengutronix.de/?p=imx/sdma-firmware.git;a=summary
---------------------
	cd /boot/uboot/tools/pkgs/
	./imx-sdma-firmware.sh

TI/OMAP Tools:
==============

suspend testing:
----------------
	cd /boot/uboot/tools/
	./omap/suspend_mount_debug.sh
	./omap/suspend.sh
