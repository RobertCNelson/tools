#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

mkdir -p /debug
mount -t debugfs debugfs /debug

