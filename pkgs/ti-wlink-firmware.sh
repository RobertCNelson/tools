#!/bin/bash -e

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl &> /dev/null || network_down

git_sha="origin/master"
project="linux-firmware"
server="git://git.kernel.org/pub/scm/linux/kernel/git/firmware"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/


sudo mkdir -p /lib/firmware/ti-connectivity
sudo cp -v ${HOME}/git/${project}/LICENCE.ti-connectivity /lib/firmware/ti-connectivity
sudo cp -v ${HOME}/git/${project}/ti-connectivity/* /lib/firmware/ti-connectivity

#should only do with Panda ES
if [ -f /lib/firmware/ti-connectivity/TIInit_7.6.15.bts ] ; then
	sudo rm -rf /lib/firmware/ti-connectivity/TIInit_7.6.15.bts || true
fi
sudo wget --directory-prefix=/lib/firmware/ti-connectivity http://rcn-ee.net/firmware/ti/7.6.15_ble/WL1271L_BLE_Enabled_BTS_File/115K/TIInit_7.6.15.bts

echo "wlink firmware installed"
echo "please reboot"