#!/bin/bash

ti_uim_sha="origin/master"
system=$(lsb_release -sd | awk '{print $1}')

sudo apt-get update
sudo apt-get -y install build-essential bluetooth

if [ ! -f ${HOME}/git/ti-uim/.git/config ] ; then
	git clone git://github.com/RobertCNelson/ti-uim.git ${HOME}/git/ti-uim/
fi

cd ${HOME}/git/ti-uim/

git checkout master -f
git pull
git branch ${ti_uim_sha}-build -D || true
git checkout ${ti_uim_sha} -b ${ti_uim_sha}-build

make
sudo make install
make clean

if [ -f /lib/firmware/ti-connectivity/TIInit_7.6.15.bts ] ; then
	sudo rm -rf /lib/firmware/ti-connectivity/TIInit_7.6.15.bts || true
fi

#http://rcn-ee.net/firmware/ti/7.6.15_ble/WL1271L_BLE_Enabled_BTS_File/3M/TIInit_7.6.15.bts
#http://rcn-ee.net/firmware/ti/7.6.15_ble/WL1271L_BLE_Enabled_BTS_File/115K/TIInit_7.6.15.bts

sudo wget --directory-prefix=/lib/firmware/ti-connectivity http://rcn-ee.net/firmware/ti/7.6.15_ble/WL1271L_BLE_Enabled_BTS_File/115K/TIInit_7.6.15.bts

cat > /tmp/bluetooth.rules <<-__EOF__
	ACTION=="add", SUBSYSTEM=="platform", ENV{MODALIAS}=="platform:kim", RUN+="/sbin/initctl emit enable-ti-bt"

__EOF__

if [ -f /etc/udev/rules.d/bluetooth.rules ] ; then
	sudo rm -rf /etc/udev/rules.d/bluetooth.rules || true
fi
sudo mv /tmp/bluetooth.rules /etc/udev/rules.d/bluetooth.rules

if [ "x${system}" == "xUbuntu" ] ; then
	#http://bazaar.launchpad.net/~linaro-maintainers/linaro-ubuntu/ti-uim/view/head:/debian/ti-uim.upstart
	cat > /tmp/ti-uim.upstart <<-__EOF__
		# ti-uim - User Mode Init Manager for TI shared transport
		#

		description        "User Mode Init Manager for TI shared transport"

		start on enable-ti-bt
		stop on runlevel [!2345]

		pre-start script
		        modprobe -q btwilink || true
		end script

		exec /usr/sbin/uim

	__EOF__

	if [ -f /etc/init.d/ti-uim ] ; then
		sudo rm -rf /etc/init.d/ti-uim || true
	fi

	sudo mv /tmp/ti-uim.upstart /etc/init.d/ti-uim
	sudo chmod +x /etc/init.d/ti-uim
fi

