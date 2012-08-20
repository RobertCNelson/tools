tools
=====
small collection of scripts that end up on the ARM images...

update:
=====
	cd /boot/uboot/tools/
	git pull

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

TI/OMAP Tools:
==============

omapdrm kms userspace:
---------------------
	cd /boot/uboot/tools/
	./omap/build_omapdrm.sh

suspend testing:
----------------
	cd /boot/uboot/tools/
	./omap/suspend_mount_debug.sh
	./omap/suspend.sh
