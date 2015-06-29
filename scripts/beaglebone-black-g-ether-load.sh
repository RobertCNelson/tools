#!/bin/sh

#Based off:
#https://github.com/beagleboard/meta-beagleboard/blob/master/meta-beagleboard-extras/recipes-support/usb-gadget/gadget-init/g-ether-load.sh

SERIAL_NUMBER="0123456789"
ISBLACK=""
PRODUCT="am335x_evm"
manufacturer="Circuitco"

eeprom="/sys/bus/i2c/devices/0-0050/eeprom"
if [ -f ${eeprom} ] ; then
	SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -s 14 -n 2)-$(hexdump -e '8/1 "%c"' ${eeprom} -s 16 -n 12)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -s 8 -n 4)

	PRODUCT="BeagleBone"
	if [ "x${ISBLACK}" = "xBBBK" ] || [ "x${ISBLACK}" = "xBNLT" ] ; then
		PRODUCT="BeagleBoneBlack"
	fi
fi

eeprom="/sys/class/nvmem/at24-0/nvmem"
if [ -f ${eeprom} ] ; then
	SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' ${eeprom} -n 16 | cut -b 15-16)-$(hexdump -e '8/1 "%c"' ${eeprom} -n 24 | cut -b 13-24)
	ISBLACK=$(hexdump -e '8/1 "%c"' ${eeprom} -n 12 | cut -b 9-12)
	PRODUCT="BeagleBone"
	if [ "x${ISBLACK}" = "xBBBK" ] || [ "x${ISBLACK}" = "xBNLT" ] ; then
		PRODUCT="BeagleBoneBlack"
	fi
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100200/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_0_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
else
	#todo: generate random mac... (this is a development tre board in the lab...)
	cpsw_0_mac="1c:ba:8c:a2:ed:68"
fi

mac_address="/proc/device-tree/ocp/ethernet@4a100000/slave@4a100300/mac-address"
if [ -f ${mac_address} ] ; then
	cpsw_1_mac=$(hexdump -v -e '1/1 "%02X" ":"' ${mac_address} | sed 's/.$//')
else
	#todo: generate random mac...
	cpsw_1_mac="1c:ba:8c:a2:ed:69"
fi

#The other option is to xor cpsw_0/cpsw_1, but this should be faster...
cpsw_0_last=$(echo ${cpsw_0_mac} | awk -F ':' '{print $6}' | cut -c 2)
cpsw_1_last=$(echo ${cpsw_1_mac} | awk -F ':' '{print $6}' | cut -c 2)
mac_prefix=$(echo ${cpsw_0_mac} | cut -c 1-16)
if [ ! "x${cpsw_0_last}" = "x0" ] && [ ! "x${cpsw_1_last}" = "x0" ]; then
	dev_mac="${mac_prefix}0"
elif  [ ! "x${cpsw_0_last}" = "x1" ] && [ ! "x${cpsw_1_last}" = "x1" ]; then
	dev_mac="${mac_prefix}1"
else
	dev_mac="${mac_prefix}2"
fi

if [ -f /usr/sbin/udhcpd ] || [ -f /usr/sbin/dnsmasq ] ; then
	#Make sure (# CONFIG_USB_ETH_EEM is not set), otherwise this shows up as "usb0" instead of ethX on host pc..
	modprobe g_ether iSerialNumber=${SERIAL_NUMBER} iManufacturer=${manufacturer} iProduct=${PRODUCT} host_addr=${cpsw_1_mac} dev_addr=${dev_mac} || true
else
	#serial:
	modprobe g_serial || true
fi

sleep 3

if [ -f /etc/default/udhcpd ] ; then
	unset udhcp_disabled
	udhcp_disabled=$(grep \#DHCPD_ENABLED /etc/default/udhcpd || true)
	if [ "x${udhcp_disabled}" = "x" ] ; then
		sed -i -e 's:DHCPD_ENABLED="no":#DHCPD_ENABLED="no":g' /etc/default/udhcpd
	fi
fi

if [ -f /etc/udhcpd.conf ] ; then
	#Distro default...
	unset deb_udhcpd
	deb_udhcpd=$(grep Sample /etc/udhcpd.conf || true)
	if [ ! "x${deb_udhcpd}" = "x" ] ; then
		mv /etc/udhcpd.conf /etc/udhcpd.conf.bak

		echo "start      192.168.7.1" > /etc/udhcpd.conf
		echo "end        192.168.7.1" >> /etc/udhcpd.conf
		echo "interface  usb0" >> /etc/udhcpd.conf
		echo "max_leases 1" >> /etc/udhcpd.conf
		echo "option subnet 255.255.255.252" >> /etc/udhcpd.conf
	fi
	/etc/init.d/udhcpd restart

	/sbin/ifconfig usb0 192.168.7.2 netmask 255.255.255.252
	/usr/sbin/udhcpd -S /etc/udhcpd.conf
fi
