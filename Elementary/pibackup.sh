#!/bin/bash

####################
# Variables
####################

# default values for vairables
PI_SD="sdx"
PI_NAME="image"
PI_IMAGE_PATH="/home/"$USER"/Documents/Raspberry/Backup/"
PI_CURR_PATH=`pwd`

####################
# Functions
####################

select_sdx () {
# print available cards
lsblk
echo

# sdx input
read -p "Please enter the name of the SD card (e.g: sdb): " PI_SD
echo
}

backup () {
# let the user chose the sd card (written into $PI_SD)
select_sdx

# image name selection
read -p "Please enter the name of the image (date will be appended): " PI_NAME
echo

# commands
echo "Use to backup (this may take a while!):"
if [ $PI_NO_PV ];
then
	echo "sudo dd bs=4M if=/dev/"$PI_SD" | gzip -c > "$PI_IMAGE_PATH$PI_NAME"`date +%y%m%d`.img.gz"
	echo
else
	echo "sudo pv -B 4M /dev/"$PI_SD" | gzip -c > "$PI_IMAGE_PATH$PI_NAME"`date +%y%m%d`.img.gz"
	echo
fi
}

restore () {
# images output
echo "Please select a file from the list"

# get data
cd $PI_IMAGE_PATH
files=$(ls *.img *.img.gz)
i=1
cd $PI_CURR_PATH

# print all available images
for j in $files
do
echo "$i. $j"
file[i]=$j
i=$(( i + 1 ))
done

# image selection
read -p "Please enter the number of the image: " input
while ! [[ $input = +([[:digit:]]) && $input -ge 1 && $input -lt $i ]]
do
	echo
	echo "Error: Wrong input. Use a number between 1 and $(( i - 1 ))"
	read -p "Please enter the number of the image: " input
done

PI_NAME=${file[$input]}
echo "You select file $PI_NAME"
echo

# let the user chose the sd card (written into $PI_SD)
select_sdx

# commands
echo "Use to restore (this may take a while!):"
if [ $PI_NO_PV ];
then
	echo "gzip -d "$PI_IMAGE_PATH$PI_NAME" | sudo dd bs=4M of=/dev/"$PI_SD
	echo
else
	echo "pv "$PI_IMAGE_PATH$PI_NAME" | gzip -d | sudo dd bs=4M of=/dev/"$PI_SD
	echo
fi

#TODO check if its gziped
#echo "Use to burn an extracted image without gzip (this may take a while!):"
#echo "sudo dd if="$PI_IMAGE_PATH$PI_NAME" bs=4M of=/dev/"$PI_SD
#echo
}

####################
# Main
####################

# welcome message
echo
echo "***Welcome to PiBackup!***"
echo

# check if pv is installed
PI_NO_PV=pv -h &>/dev/null
if [ $PI_NO_PV ];
then
	echo "Info: pv not installed. Use \"sudo apt-get install pv\" to see nice progress bars while using pibackup."
	echo
fi

#TODO pass sdx and image via parameters

# select mode
echo "Available modes:"
PS3='Please enter your choice: '
options=("Backup" "Restore/Burn Image" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Backup")
            echo "You chose Backup."
	    echo
	    backup
	    break;
            ;;
        "Restore/Burn Image")
	    echo
            echo "You chose Restore/Burn Image"
	    restore
	    break;
            ;;
        "Quit")
            echo
	    break;
            ;;
	*) echo invalid option
	    echo
	    ;;
    esac
done

echo "***Thanks for using PiBackup!***"
echo

exit 0
