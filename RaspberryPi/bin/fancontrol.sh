#!/bin/bash

# Settings
serial=/dev/ttyUSB0
fanspeed=0
maxtemp=50000

# Open Serial
echo "Opening Serial port $serial"
exec 3<> $serial

closeSerial()
{
	# Close Serial
	echo
	echo "Closing Serial port $serial"
	exec 3>&-
}

trap 'closeSerial; exit' SIGINT

while true
do
	temp=`cat /sys/class/thermal/thermal_zone0/temp`

	# Keep temperature at a max level
	if [ $temp -gt $maxtemp ]
	then
		if [ $fanspeed -lt 9 ]
		then
		let fanspeed++
		fi
	else
		if [ $fanspeed -gt 0 ]
		then
		 let fanspeed--
		fi
	fi

	# Calculate cooling steps (0-9)
	echo -en "\rTemperature: $temp, cooling speed: $fanspeed"
	echo $fanspeed >&3

	sleep 1
done

