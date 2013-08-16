#!/bin/sh -e

board=$(cat /proc/cpuinfo | grep "^Hardware" | awk '{print $4}')

sudo apt-get update
sudo apt-get -y upgrade

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

unset deb_pkgs
pkg="lxde-core"
check_dpkg
pkg="slim"
check_dpkg
if [ "x${board}" = "xAM33XX" ] ; then
	pkg="xserver-xorg-video-modesetting"
	check_dpkg
fi
pkg="xserver-xorg"
check_dpkg
pkg="x11-xserver-utils"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo ""
	echo "Installing: ${deb_pkgs}"
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
	echo "--------------------"
fi

#slim
if [ "x${USER}" != "xroot" ] ; then
	echo "#!/bin/sh" > ${HOME}/.xinitrc
	echo "" >> ${HOME}/.xinitrc
	echo "exec startlxde" >> ${HOME}/.xinitrc

	chmod +x ${HOME}/.xinitrc

	#/etc/slim.conf modfications:
	sudo sed -i -e 's:default,start:startlxde,default,start:g' /etc/slim.conf
	echo "default_user	${USER}" | sudo tee -a /etc/slim.conf >/dev/null
	echo "auto_login	yes" | sudo tee -a /etc/slim.conf >/dev/null
fi

cat > /tmp/xorg.conf <<-__EOF__
	Section "Monitor"
	        Identifier      "Builtin Default Monitor"
	EndSection

	Section "Device"
	        Identifier      "Builtin Default fbdev Device 0"
	        Driver          "modesetting"
	EndSection

	Section "Screen"
	        Identifier      "Builtin Default fbdev Screen 0"
	        Device          "Builtin Default fbdev Device 0"
	        Monitor         "Builtin Default Monitor"
	        DefaultDepth    16
	EndSection

	Section "ServerLayout"
	        Identifier      "Builtin Default Layout"
	        Screen          "Builtin Default fbdev Screen 0"
	EndSection
__EOF__

if [ "x${board}" = "xAM33XX" ] ; then
	sudo cp -v /tmp/xorg.conf /etc/X11/xorg.conf
fi

echo "Please Reboot"
