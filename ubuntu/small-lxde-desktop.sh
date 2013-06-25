#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

#Ubuntu Raring: 240 pkgs, 62.2 MB dl, 183 MB of space
sudo apt-get -y install lxde-core slim xserver-xorg-video-modesetting xserver-xorg x11-xserver-utils
sudo apt-get clean

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

#Ubuntu Raring: 244 pkgs, 61.6 MB dl, 183 MB of space
#sudo apt-get -y install lxde-core lxdm xserver-xorg-video-modesetting xserver-xorg x11-xserver-utils
#sudo apt-get clean
##lxdm
#sudo sed -i -e 's:# session=/usr/bin/startlxde:session=/usr/bin/startlxde:g' /etc/lxdm/lxdm.conf
#if [ "x${USER}" != "xroot" ] ; then
#	username=$(echo ${USER})
#	sudo sed -i -e 's:# autologin=dgod:autologin='${username}':g' /etc/lxdm/lxdm.conf
#else
#	echo "To enable autologin:"
#	echo "change: [# autologin=dgod] in /etc/lxdm/lxdm.conf to [autologin=username]"
#fi

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

sudo cp -v /tmp/xorg.conf /etc/X11/xorg.conf

echo "Please Reboot"
