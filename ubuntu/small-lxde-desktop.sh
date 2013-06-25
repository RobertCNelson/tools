#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

#Wheezy: 281 pkgs, 94.9MB, 280MB
#sudo apt-get -y install lightdm lxde-core

#Ubuntu Raring:
sudo apt-get -y install lxde-core slim xserver-xorg-video-modesetting xserver-xorg x11-xserver-utils dmz-cursor-theme
sudo apt-get clean

#Fixme: doesnt stay active...
#sudo update-alternatives --config x-cursor-theme <<-__EOF__
#1
#__EOF__

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
