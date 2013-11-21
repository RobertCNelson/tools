#!/bin/bash

sudo apt-get install nodejs

if [ ! -f /usr/bin/node ] ; then
	sudo ln -s /usr/bin/nodejs /usr/bin/node
fi
if [ ! -d /usr/lib/node ] ; then
	sudo mkdir -p /usr/lib/node
fi

curl https://npmjs.org/install.sh | sudo sh

git clone https://github.com/ajaxorg/cloud9.git

