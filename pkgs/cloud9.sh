#!/bin/bash

release=`lsb_release -sc`

if [ "x$release" = "xwheezy" ] ; then
	sudo sh -c "echo 'deb http://ftp.debian.org/debian wheezy-backports main contrib non-free' >> /etc/apt/sources.list"
	sudo apt-get update
	sudo apt-get -y -t wheezy-backports install nodejs
else
	sudo apt-get -y install nodejs
fi

if [ ! -f /usr/bin/node ] ; then
	sudo ln -s /usr/bin/nodejs /usr/bin/node
fi
if [ ! -d /usr/lib/node ] ; then
	sudo mkdir -p /usr/lib/node
fi

curl https://npmjs.org/install.sh | sudo sh

git clone https://github.com/ajaxorg/cloud9.git

