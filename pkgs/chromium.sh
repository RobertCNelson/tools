#!/bin/sh -e

chrome_version="31.0.1650.69"

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

unset deb_pkgs

pkg="bison"
check_dpkg
pkg="build-essential"
check_dpkg
pkg="gperf"
check_dpkg
pkg="libcups2-dev"
check_dpkg
pkg="libgtk2.0-dev"
check_dpkg
pkg="libnss3-dev"
check_dpkg
pkg="libgconf2-dev"
check_dpkg
pkg="libgcrypt11-dev"
check_dpkg
pkg="libgnome-keyring-dev"
check_dpkg
pkg="libpci-dev"
check_dpkg
pkg="libudev-dev"
check_dpkg
pkg="pkg-config"
check_dpkg

deb_distro=$(lsb_release -cs | sed 's/\//_/g')
deb_arch=$(LC_ALL=C dpkg --print-architecture)
case "${deb_distro}" in
wheezy)
	pkg="libpulse-dev"
	check_dpkg
	if [ ! -f /usr/local/bin/ninja ] ; then
		git clone git://github.com/martine/ninja.git /tmp/
		cd /tmp/ninja
		git checkout release
		./bootstrap.py
		sudo cp -v ./ninja /usr/local/bin/
	fi
	;;
jessie|sid)
	pkg="libpulse-dev:${deb_arch}"
	check_dpkg
	pkg="ninja-build"
	check_dpkg
	;;
esac

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
fi

# Disable SSE2
GYP_DEFINES=disable_sse2=1

GYP_DEFINES="${GYP_DEFINES} proprietary_codecs=1"

# disable native client (nacl)
GYP_DEFINES="${GYP_DEFINES} disable_nacl=1"

# do not use embedded third_party/gold as the linker.
GYP_DEFINES="${GYP_DEFINES} linux_use_gold_binary=0 linux_use_gold_flags=0"

# disable tcmalloc
GYP_DEFINES="${GYP_DEFINES} linux_use_tcmalloc=0"

# Use explicit library dependencies instead of dlopen.
# This makes breakages easier to detect by revdep-rebuild.
GYP_DEFINES="${GYP_DEFINES} linux_link_gsettings=1"

GYP_DEFINES="${GYP_DEFINES} sysroot=/"
GYP_DEFINES="${GYP_DEFINES} disable_nacl=1 enable_webrtc=0 use_cups=1"

if [ "x${deb_arch}" = "xarmhf" ] ; then
	GYP_DEFINES="${GYP_DEFINES} -DUSE_EABI_HARDFLOAT"
	GYP_DEFINES="${GYP_DEFINES} target_arch=arm  v8_use_arm_eabi_hardfloat=true arm_fpu=vfpv3 arm_float_abi=hard arm_thumb=1 armv7=1 arm_neon=0"
fi

if [ ! -d /opt/chrome-src/ ] ; then
	sudo mkdir /opt/chrome-src/
	sudo chown -R $USER:$USER /opt/chrome-src
fi

cd /opt/chrome-src/
wget -c http://gsdview.appspot.com/chromium-browser-official/chromium-${chrome_version}.tar.xz
if [ -d /opt/chrome-src/src/ ] ; then
	rm -rf /opt/chrome-src/src/ || true
fi
tar xf chromium-${chrome_version}.tar.xz
mv /opt/chrome-src/chromium-${chrome_version} /opt/chrome-src/src/
cd /opt/chrome-src/src/
echo "Building with: [${GYP_DEFINES}]"
export GYP_DEFINES="${GYP_DEFINES}"
./build/gyp_chromium
ninja -C out/Release chrome

#
