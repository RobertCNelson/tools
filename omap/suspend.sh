#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

echo mem > /sys/power/state

