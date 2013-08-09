#!/bin/bash -e

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

install_pkgs () {
	unset deb_pkgs
	pkg="build-essential"
	check_dpkg
	pkg="gstreamer-tools"
	check_dpkg
	pkg="libgstreamer0.10-dev"
	check_dpkg

	if [ "${deb_pkgs}" ] ; then
		echo ""
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
		sudo apt-get clean
		echo "--------------------"
	fi
}

git_generic () {
	echo "Building: ${project}: ${git_sha}"
	if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
		git clone ${server}/${project}.git ${HOME}/git/${project}/
	fi

	if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
		rm -rf ${HOME}/git/${project}/ || true
		echo "error: git failure, try re-runing"
		exit
	fi

	cd ${HOME}/git/${project}/
	make clean &>/dev/null

	git checkout master -f
	git pull || true
	git branch ${git_sha}-build -D || true
	git checkout ${git_sha} -b ${git_sha}-build
}

file_dsp_startup () {
	cat > "/tmp/dsp_startup" <<-__EOF__
	#!/bin/sh -e
	### BEGIN INIT INFO
	# Provides:          dsp_startup
	# Required-Start:    \$local_fs
	# Required-Stop:     \$local_fs
	# Default-Start:     2 3 4 5
	# Default-Stop:      0 1 6
	# Short-Description: Start daemon at boot time
	# Description:       Enable service provided by daemon.
	### END INIT INFO

	if [ ! -f /lib/dsp/baseimage.dof ] ; then
	        echo "tidspbridge: missing /lib/dsp/baseimage.dof"
	        exit 1
	fi

	unset driver
	if [ -f /lib/modules/\$(uname -r)/kernel/drivers/staging/tidspbridge/bridgedriver.ko ] ; then
	        driver="bridgedriver"
	fi

	#v3.4.x
	if [ -f /lib/modules/\$(uname -r)/kernel/drivers/staging/tidspbridge/tidspbridge.ko ] ; then
	        driver="tidspbridge"
	fi

	if [ ! "\${driver}" ] ; then
	        echo "tidspbridge: no tidspbridge module"
	        exit 1
	fi

	case "\$1" in
	start)
	        echo "tidspbridge: starting"
	        modprobe mailbox_mach
	        modprobe \${driver} base_img=/lib/dsp/baseimage.dof
	        ;;
	reload|force-reload|restart)
	        echo "tidspbridge: restarting"
	        rmmod \${driver} 2>/dev/null || true
	        rmmod mailbox_mach 2>/dev/null || true
	        modprobe mailbox_mach
	        modprobe \${driver} base_img=/lib/dsp/baseimage.dof
	        ;;
	stop)
	        echo "tidspbridge: stopping"
	        rmmod \${driver} 2>/dev/null || true
	        rmmod mailbox_mach 2>/dev/null || true
	        ;;
	*)
	        echo "Usage: /etc/init.d/dsp_startup {start|stop|reload|restart|force-reload}"
	        exit 1
	        ;;
	esac

	exit 0

	__EOF__
}

install_pkgs

git_sha="origin/master"
project="gst-dsp"
server="git://github.com/felipec"

git_generic

./configure
make CROSS_COMPILE= 
sudo make install

git_sha="origin/master"
project="gst-omapfb"
server="git://github.com/felipec"

git_generic

make CROSS_COMPILE= 
sudo make install

git_sha="origin/firmware"
project="dsp-tools"
server="git://github.com/felipec"

git_generic

if [ ! -d /lib/dsp/ ] ; then
	sudo mkdir -p /lib/dsp || true
fi

sudo cp -v firmware/test.dll64P /lib/dsp/

git_sha="origin/master"
project="dsp-tools"
server="git://github.com/felipec"

git_generic

make CROSS_COMPILE= 
sudo make install

file_dsp_startup

if [ -f /etc/init.d/dsp_init ] ; then
	sudo rm -f /etc/init.d/dsp_init || true
fi

sudo cp -v /tmp/dsp_startup /etc/init.d/dsp_init
sudo chmod +x /etc/init.d/dsp_init
sudo update-rc.d dsp_init defaults
