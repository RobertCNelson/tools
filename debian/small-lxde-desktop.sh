#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

#Debian Wheezy: 288pkg, 100Mb dl, 289Mb of space
sudo apt-get -y install lightdm lxde-core x11-xserver-utils xserver-xorg-video-modesetting
sudo apt-get clean

if [ "x${USER}" != "xroot" ] ; then
	sudo /usr/lib/arm-linux-gnueabihf/lightdm/lightdm-set-defaults --autologin ${USER}
else
	echo "To enable autologin:"
	echo "sudo /usr/lib/arm-linux-gnueabihf/lightdm/lightdm-set-defaults --autologin username"
fi

cat > /tmp/xorg.conf <<-__EOF__
	Section "Module"
	        Load            "extmod"
	        Load            "dbe"
	        Load            "glx"
	        Load            "freetype"
	        Load            "type1"
	        Load            "record"
	        Load            "dri"
	EndSection

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

sudo cp -v /tmp/xorg.conf /etc/X11/xorg.conf

echo "Please Reboot"
