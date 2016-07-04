#!/bin/bash

# HDMI outputs will be set into DVI audio mode
# (to avoid blurry output of my monitors).
# No arguments will only fix the HDMI to DVI audio.
#
# Will make the monitors show up in this order.
# All not mentioned Monitors will be turned off.
# The center Monitor (left on even number) will be the primary screen.
#
# Example: fixmonitors HDMI3 HDMI2 eDP1
# Example: fixmonitors HDMI2 eDP1
# Example: fixmonitors HDMI2
#
# Additional information:
# https://wiki.archlinux.org/index.php/xrandr
#
# Note: plank intellihide will switch to the new primay screen, plank icons not.
# A workaround will kill plank and EOS will restart it automatically on the current screen.


leftmonitor() {
    # Will return the monitor on the left
    # The same monitor will be returned if its the 1st
    # An empty string will be returned if no monitor was found
    for (( i = $#; i > 1; i-- ))
    do
        if [[ ${!i} == $1 ]];
        then
            ((i--));
            echo "${!i}";
            break;
        fi
    done
}

# Get the current xrandr configuration
xrandroutput="$(xrandr)"
connectedOutputs=$(echo "$xrandroutput" | grep " connected" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")
activeOutput=$(echo "$xrandroutput" | grep -E " connected (primary )?[1-9]+" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")
primaryOutput=$(echo "$xrandroutput" | grep " connected primary" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")
newprimaryOutput=$primaryOutput
numberUsedMonitors=0
monitors=$@
me=`basename "$0"`

# Check for monitor presets
if [ $# -eq 1 ]
then
	if [ "$1" == "list" ]
	then
		echo "Connected outputs:"
		echo "$connectedOutputs"
		echo "Active outputs:"
		echo "$activeOutput"
		echo "Primary output:"
		echo "$primaryOutput"
		exit

	elif [[ "$1" == *help* ]]
	then
		echo "Display this help message: $me --help"
		echo "List available monitors: $me list"
		echo "Usage example1: $me HDMI3 HDMI2 eDP1"
		echo "Usage example2: $me HDMI3 HDMI2"
		echo "Usage example3: $me eDP1"
		echo "Preset example: $me all"
		echo "Fix DVI for all connected monitors: $me"
		exit

	# TODO write the presets into a twodimensional array
	elif [ "$1" == "all" ]
	then
		echo "Using preset all"
		monitors="HDMI3 HDMI2 eDP1"
	elif [ "$1" == "left" ]
	then
		echo "Using preset middle"
		monitors="HDMI3"
	elif [ "$1" == "middle" ]
	then
		echo "Using preset right"
		monitors="HDMI2"
	elif [ "$1" == "right" ]
	then
		echo "Using preset left"
		monitors="eDP1"
	elif [ "$1" == "laptop" ]
	then
		echo "Using preset laptop"
		monitors="eDP1"
	elif [ "$1" == "raspi" ]
    then
        echo "Using preset raspi"
        monitors="HDMI2 eDP1"
    elif [ "$1" == "monitors" ]
	then
		# TODO plank on the right monitor
		echo "Using preset monitors"
		monitors="HDMI3 HDMI2"
	fi
fi

# Go though all connected monitors and generate xrandr command
execute="xrandr"
for display in $connectedOutputs
do
	echo "Display $display"

	# Special case for no args, just fix HDMI
	if [ $# -eq 0 ]
	then
		# Force all connected HDMI monitors to DVI mode (bug of my monitors)
		if [[ "$display" == *HDMI* ]]
		then
    		echo "Only fixed HDMI"
		      # TODO ati graphics card requires first "off", then "force-dvi"
        	execute=$execute" --output $display --set audio force-dvi"
        	((numberUsedMonitors++))
        fi
	else
	    # Select the next display
		execute=$execute" --output $display"

		# Get the left monitor.
		# Will return an empty string if the monitor itself is also not inside the arguments.
	    left=$(leftmonitor $display $monitors)

		if [ -z "$left" ]
		then
			echo "Turned off"
			execute=$execute" --off"
		else
			echo "Turned on"
			execute=$execute" --auto"
			((numberUsedMonitors++))

			# Make the middle monitor (left preferred on even number) primary
			if [ "$display" == "${@:($#+1)/2:1}" ]
			then
				echo "Primary"
			    execute=$execute" --primary"
			    primaryOutput=$display
			fi

			# Check if there is a display left to it
			if [ "$left" != "$display" ]
			then
				echo "Right of $left"
			    execute=$execute" --right-of $left"

			    # Abort if the left monitor is invalid
				if [[ "$connectedOutputs" != *$left* ]]
				then
					echo "Error: $left is an invalid output"
					exit 1
				fi
		    fi

		    # Force all connected HDMI monitors to DVI mode (bug of my monitors)
			if [[ "$display" == *HDMI* ]]
			then
				echo "Fixed HDMI"
			    execute=$execute" --set audio force-dvi"
			fi
		fi
	fi
	echo ""
done

if [ "$execute" == "xrandr" ]
then
	echo "Nothing to fix."
	exit 0
fi

# Only execute command if at least one monitor is on
if [ $numberUsedMonitors -gt 0 ]
then
	echo "Executing command:"
	echo "$execute"
	$execute
else
	echo "Error: No valid monitor selected."
	exit 1
fi

# Restart plank (on Elementary OS) to switch to new primary screen
if [ $(which plank) ] && [ "$newprimaryOutput" != "$primaryOutput" ]
then
	echo ""
	echo "Restarting plank..."
	sleep 3
	killall plank
fi
