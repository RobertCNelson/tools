#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

EEPROM_LOCATION=/sys/bus/i2c/devices/2-0050/eeprom
#MKEEPROM=./mkeeprom
EEPROM_DATA=eeprom_data

#if [ $# -eq 0 ]
#then
#	echo "no args"
#	$MKEEPROM
#else
#	echo "args: $1"
#	$MKEEPROM < $1
#fi

if [ ! -f $EEPROM_LOCATION ]
   then
      echo "eeprom device not present!"
      exit 1
fi

if [ ! -f $EEPROM_DATA ]
   then
      echo "eeprom_data does not exist!!"
      exit 1
fi

echo
echo "About to write EEPROM at $EEPROM_LOCATION"
echo "Press any key to continue, Ctrl-C to abort"
echo

read ok
dd if=$EEPROM_DATA of=$EEPROM_LOCATION bs=64
echo "Done"
