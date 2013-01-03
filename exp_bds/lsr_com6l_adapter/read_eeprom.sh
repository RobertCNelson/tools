#!/bin/bash

EEPROM_LOCATION=/sys/bus/i2c/devices/2-0050/eeprom

if [ ! -f $EEPROM_LOCATION ]
   then
      echo "eeprom device not present!"
      exit 1
fi

echo
echo "About to read EEPROM at $EEPROM_LOCATION"
echo "Press any key to continue, Ctrl-C to abort"
echo

read ok
hexdump $EEPROM_LOCATION
