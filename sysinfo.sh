#!/bin/bash

################################################################################
# Get system information
################################################################################

# Check if running on Arch linux
# TODO check if this also applies to ALARM
ARCH=`cat /etc/os-release | grep 'Arch Linux' | wc -l`

if [[ ARCH -eq 0 ]]; then
    echo "Error: No Arch Linux OS could be detected. Aborting."
    exit 1
fi

# Find out which device this script runs on
CPU_RPI=`grep -m1 -c 'BCM2708\|BCM2709\|BCM2710' /proc/cpuinfo`
CPU_ARM7=`uname -m | grep 'armv7l' | wc -l`
CPU_ARM6=`uname -m | grep 'armv6l' | wc -l`
CPU_ARM6ARM7=`uname -m | grep 'armv6l\|armv7l' | wc -l`
CPU_X64=`uname -m | grep 'x86_64' | wc -l`

# Check if running inside vm (none for normal host mode)
CPU_VM=`systemd-detect-virt | grep 'oracle' | wc -l`

# Check which RPi we are on (in case)
#TODO does not work -> pi3 recognized as pi3
RPI_1=`grep -m1 -c BCM2708 /proc/cpuinfo`
RPI_2=`grep -m1 -c BCM2709 /proc/cpuinfo`
RPI_3=`grep -m1 -c BCM2710 /proc/cpuinfo`

# Check that we have a known configuration
if [[ CPU_ARM6ARM7 -eq 1 ]]; then
    echo "Found ARM CPU"
    if [[ $CPU_RPI -eq 1 ]]; then
        if [[ $RPI_1 -eq 1 ]]; then
            echo "Found Raspberry Pi 1"
        elif [[ $RPI_2 -eq 1 ]]; then
            echo "Found Raspberry Pi 2"
        elif [[ $RPI_3 -eq 1 ]]; then
            echo "Found Raspberry Pi 3"
        else
            echo 'Error: CPU information unknown'
            exit 1
        fi
    else
        echo 'Error: CPU information unknown'
    fi
elif [[ $CPU_X64 -eq 1 ]]; then
    echo "Found x64 CPU"
else
    # No support for old 32bit CPUs which are not ARM (to use EFI)
	echo 'Error: CPU information unsupported'
	exit 1
fi
