#!/bin/bash

# TODO ask password
# TODO check root: do not run as root!

# TODO check if packages are installed/service/file exists and only use sudo if they are not installed.
# TODO a pkgbuild might be better than a script?

function installPackages {
    # Pacman for Arch Linux
    PACKAGES=$@
    pacman -Q $PACKAGES >/dev/null 1>&2
    if [[ $? -ne 0 ]]; then
        # TODO is this echo really required?
        echo "Installing packages $PACKAGES"
        sudo pacman -S --needed --noconfirm -q $PACKAGES
        if [[ $? -ne 0 ]]; then
            echo "Error: Installation failed."
            exit 1
        fi
    fi
}


################################################################################
# Settings
################################################################################

USERNAME=alarm # TODO
BUILD_DIR=~/hackallthethings # TODO

# Disable components
ENV_VARS=1
XORG=1
LIGHTDM=1
XFCE=1
ARC_THEME=1
ARC_ICON_THEME=1
PLANK=1
KEYBOARD_SHORTCUTS=1
DESKTOP=1
XFCE_TWEAKS=1
FILE_MANAGER=1
TERMINAL=1

# Add new user if it does not exist yet
# TODO

# Switch to this user
# TODO this does not work
#su - $USERNAME
# TODO exit afterwards and reboot


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


################################################################################
# General
################################################################################

# Check for system updates before installing new packages to not break anything
echo "Checking for updates..."
checkupdates
if [[ $? -ne 0 ]];then
    sudo pacman -Syyu
    if [[ $? -ne 0 ]]; then
        echo "Error: Installation failed."
        exit 1
    fi
else
    echo "Already up to date."
fi

# Install base-devel group if not installed in any case
pacman -Qg base-devel >/dev/null
if [[ $? -ne 0 ]]; then
    sudo pacman -S --needed --noconfirm -q base-devel
    if [[ $? -ne 0 ]]; then
        echo "Error: Installation failed."
        exit 1
    fi
fi

# Create build irectory if it does not exist
mkdir -p $BUILD_DIR

# Add /opt/vc tools to path
# TODO locally?
if [[ ENV_VARS -eq 1 ]];then
    echo "Installing environment variables..."
    if [[ $CPU_RPI -eq 1 ]]; then
        grep "^export PATH=.*:/opt/vc/bin" /etc/bash.bashrc
        if [[ $? -ne 0 ]]; then
            echo "Adding /opt/vc/bin to global path."
            echo "export PATH=${PATH}:/opt/vc/bin" | sudo tee -a /etc/bash.bashrc
        fi
    fi
fi


################################################################################
# Desktop environment installation
################################################################################

if [[ XORG -eq 1 ]];then
    echo "Installing X-Org..."

    # Install X-server
    installPackages xorg-server mesa

    # Install kernel headers for x64 and dkms
    if [[ $CPU_X64 -eq 1 ]]; then
        installPackages linux-lts-headers linux-headers
    fi

    # Install desktop utils + video drivers for vm
    if [[ CPU_VM -eq 1 ]]; then
        installPackages virtualbox-guest-utils virtualbox-guest-dkms
    # Install video drivers for x64 PC
    elif [[ $CPU_X64 -eq 1 ]]; then
        INTEL_CARD=`lspci | grep -e VGA -e 3D | grep -i Intel | wc -l`
        NVIDIA_CARD=`lspci | grep -e VGA -e 3D | grep -i Nvidia | wc -l`
        AMD_CARD=`lspci | grep -e VGA -e 3D | grep -i Amd | wc -l`
        ATI_CARD=`lspci | grep -e VGA -e 3D | grep -i Ati | wc -l`
        if [[ $INTEL_CARD -eq 1 ]]; then
            installPackages xf86-video-intel
        elif [[ $NVIDIA_CARD -eq 1 ]]; then
            installPackages xf86-video-nouveau
        elif [[ $ATI_CARD -eq 1 ]]; then
            installPackages xf86-video-ati
        elif [[ $AMD_CARD -eq 1 ]]; then
            installPackages xf86-video-amdgpu
        else
            echo "Warning: No graphic card found. Installing fbdev and vesa. You might want to search yours with:"
            echo "lspci | grep -e VGA -e 3D"
            echo "pacman -Ss xf86-video"
            installPackages xf86-video-fbdev xf86-video-vesa
        fi
    # TODO raspi drivers
    fi
    # TODO? xorg-utils xorg-server-utils
fi

if [[ LIGHTDM -eq 1 ]];then
    # Install display manager and greeter and enable it
    echo "Installing lightdm..."
    installPackages lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
                accountsservice light-locker
    systemctl is-active lightdm.service
    if [[ $? -ne 0 ]]; then
        echo "Enabling lightdm service..."
        # TODO ask for enabling
        sudo systemctl enable lightdm.service
    fi

    # TODO this requires arc theme and background as dependency
    # TODO gui config messes up settings
    LIGHTDM_GREETER_CFG=/etc/lightdm/lightdm-gtk-greeter.conf
    #if [[ ! -e "$TERMINAL_CFG" ]]; then
    #    echo "[Configuration]" > $TERMINAL_CFG
    #fi
    #sed -i '/^FontName=.*/d' $TERMINAL_CFG
    #echo "FontName=Monospace 11" >> $TERMINAL_CFG
fi

if [[ XFCE -eq 1 ]];then
    # xfce4 basic packages (xfce4 without thunar, terminal, xfce4-appfinder and xfwm4-themes)
    echo "Installing xfce..."
    installPackages exo garcon gtk-xfce-engine tumbler xfce4-mixer xfce4-panel \
                xfce4-power-manager xfce4-session xfce4-settings xfconf \
                xfdesktop xfwm4
fi


################################################################################
# Arc theme
################################################################################

if [[ ARC_THEME -eq 1 ]];then
    # Install Arc theme dependencies
    echo "Installing/updating Arc theme..."
    installPackages gnome-themes-standard gtk-engine-murrine \
                    elementary-icon-theme autoconf automake git

    # Arc theme and icons have to be installed from AUR or from git
    # See the official build instructions for the most up to date installation instructions
    cd $BUILD_DIR
    if [[ ! -d "arc-theme" ]]; then
        # Control will enter here if $DIRECTORY doesn't exist.
        git clone https://github.com/horst3180/arc-theme --depth 1
        cd arc-theme
    else
        # Check if new data was pulled. If not do not recompile
        cd arc-theme
        git pull
        if [[ $? -eq 0 ]]; then
            ARC_THEME=0
        fi
    fi

    if [[ ARC_THEME -eq 1 ]];then
        # Build and install
        ./autogen.sh --prefix=/usr
        sudo make install

        # Go to `Settings->Appearance`
        # Go to `Style`
        # Enable the theme (Arc-Darker)
        # Go to `Settings->Window Manager`
        # Go to `Style`
        # Enable the theme (Arc-Darker)
        xfconf-query -c xfwm4 -p /general/theme -s "Arc-Darker"
        xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Darker"
    fi
fi


################################################################################
# Arc icon theme
################################################################################

if [[ ARC_ICON_THEME -eq 1 ]];then
    # Arc theme and icons have to be installed from AUR or from git
    # See the official build instructions for the most up to date installation instructions
    echo "Installing/updating Arc icon theme..."
    cd $BUILD_DIR
    if [[ ! -d "arc-icon-theme" ]]; then
        # Control will enter here if $DIRECTORY doesn't exist.
        git clone https://github.com/horst3180/arc-icon-theme --depth 1
        cd arc-icon-theme
    else
        # Check if new data was pulled. If not do not recompile
        cd arc-icon-theme
        git pull
        if [[ $? -eq 0 ]]; then
            ARC_ICON_THEME=0
        fi
    fi

    if [[ ARC_ICON_THEME -eq 1 ]];then
        # Before you compile add elementary as fallback icon theme
        sed -ie "s/Inherits=.*/Inherits=elementary,Adwaita,gnome,hicolor/" Arc/index.theme

        # Build and install
        ./autogen.sh --prefix=/usr
        sudo make install

        # Go to `Settings->Appearance`
        # Go to `Icons`
        # Enable the theme (Arc)
        xfconf-query -c xsettings -p /Net/IconThemeName -s "Arc"

        # Update/generate Arc icon cache:
        sudo gtk-update-icon-cache /usr/share/icons/Arc/
    fi
fi


################################################################################
# Configure plank
################################################################################

if [[ PLANK -eq 1 ]];then
    # Install `plank`
    # Call `plank --preferences` to set the `Transparent` theme
    # Go to `Settings->Session and Startup`
    # Go to `Application Autostart`
    # Add and entry `Plank` with the command `plank`
    # Start `plank`
    echo "Installing plank..."
    installPackages plank
    dconf write /net/launchpad/plank/docks/dock1/theme "'Transparent'"
    cp /usr/share/applications/plank.desktop ~/.config/autostart/
fi


################################################################################
# Keyboard shortcuts
################################################################################

if [[ KEYBOARD_SHORTCUTS -eq 1 ]];then
    # Go to `Settings->Keyboard->Application Shortcuts`
    # Add a new shortcut for `xfce4-screenshooter --fullscreen` for the `Print` key
    # Add a new shortcut for `xfce4-popup-whiskermenu` for the `Super/Windows` key
    # Remove the `Alt+F1`, `Alt+F2` and `Alt+F3` shortcuts
    echo "Installing keyboard shortcuts..."
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Print -s "xfce4-screenshooter --fullscreen"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -s "xfce4-popup-whiskermenu"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F1" -r
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F2" -r
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F3" -r
fi


################################################################################
# Desktop setup
################################################################################

if [[ DESKTOP -eq 1 ]];then
    # Download wallpaper from `https://pixabay.com/en/glacier-mountain-snow-hillside-869593/`
    # Move the wallpaper to `/usr/share/backgrounds/xfce/`
    # Go to `Settings->Desktop`
    # Go to `Background`
    # Enable the wallpaper
    # Go to `Icons`
    # Set `Icon type` as `None`
    # Also disable all desktop menus in `Settings->Desktop->Menus`
    echo "Installing desktop..."
    # Check if wallpaper exists. If not show website link
    if [[ ! -e /usr/share/backgrounds/xfce/glacier.jpg ]]; then
        if [[ ! -e glacier.jpg ]]; then
            echo "Error: No desktop background found."
            echo "Please download it from: https://pixabay.com/en/glacier-mountain-snow-hillside-869593/"
            echo "Place it into this folder as 'glacier.jpg' and rerun this script."
            exit 1
        fi
        sudo cp glacier.jpg /usr/share/backgrounds/xfce/glacier.jpg
    fi
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/xfce/glacier.jpg"
fi


################################################################################
# Xfce tweaks
################################################################################

if [[ XFCE_TWEAKS -eq 1 ]];then
    # Install several Xfce related tweaks/fixes
    echo "Installing Xfce tweaks..."

    # Go to `Settings->Window Manager Tweaks`
    # Go to `Cycling`
    # Enable `Cycle through windows on all workspaces`
    # Disable `Draw frame around selected windows while cycling`
    # Go to `Accessibility`
    # Disable `Use mouse wheel on tile bar to roll up the window`
    # Go to `Workspaces`
    # Disable `Use the mouse wheel on the desktop to switch workspaces`
    # Go to `Compositor`
    # Disable `Show shadows under dock windows` to get rid of the sticky horizontal line
    xfconf-query -c xfwm4 -p /general/cycle_workspaces -s true
    xfconf-query -c xfwm4 -p /general/cycle_draw_frame -s false
    xfconf-query -c xfwm4 -p /general/mousewheel_rollup -s false
    xfconf-query -c xfwm4 -p /general/scroll_workspaces -s false
    xfconf-query -c xfwm4 -p /general/show_dock_shadow -s false


    # Go to `Settings->Session and Startup`
    # Go to `General`
    # Disable `Automatically save session on logout`
    # Go to `Session`
    # Hit `Clear saved session`
    xfconf-query -c xfce4-session -p /general/AutoSave -s false
    rm -f ~/.cache/sessions/xfce4-session-*


    # Go to `Settings->Workspaces`
    # Set `Number of workspaces` to `1`
    xfconf-query -c xfwm4 -p /general/workspace_count -s 1
fi


################################################################################
# File Manager
################################################################################

if [[ FILE_MANAGER -eq 1 ]];then
    # Go to `Settings->File Manager`
    # Go to `Side Pane`
    # Set all `Icon Size` to `Very Small`
    # Go to `Behavior`
    # Enable `Middle Click->Open folder in new tab`
    echo "Installing file manager..."
    installPackages thunar thunar-volman
    xfconf-query -c thunar -p /shortcuts-icon-size -s "THUNAR_ICON_SIZE_SMALLEST"
    xfconf-query -c thunar -p /tree-icon-size -s "THUNAR_ICON_SIZE_SMALLEST"
    xfconf-query -c thunar -p /misc-middle-click-in-tab -s true
fi


################################################################################
# Terminal
################################################################################

if [[ TERMINAL -eq 1 ]];then
    # Open a Terminal and go to `Edit->Preferences`
    # Go to `Appearance`
    # Set `Font` to `Monospace 11`
    # Set the `Background` to `Transparent background` with `Transparency 0.95`
    # Go to `Colors`
    # Set `Background color` to the Arc window color (#2F343F)
    # Set `Cursor color` to the Arc text color (#AAAAAA)
    # Set `Tab activity color` to The Arc close button color (#FF5555)
    # You can also drop the colors from the `Palette`
    echo "Installing terminal..."
    installPackages xfce4-terminal
    TERMINAL_CFG=~/.config/xfce4/terminal/terminalrc
    if [[ ! -e "$TERMINAL_CFG" ]]; then
        echo "[Configuration]" > $TERMINAL_CFG
    fi
    sed -i '/^FontName=.*/d' $TERMINAL_CFG
    echo "FontName=Monospace 11" >> $TERMINAL_CFG
    sed -i '/^BackgroundDarkness=.*/d' $TERMINAL_CFG
    echo "BackgroundDarkness=0.950000" >> $TERMINAL_CFG
    sed -i '/^BackgroundMode=/d' $TERMINAL_CFG
    echo "BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT" >> $TERMINAL_CFG
    sed -i '/^ColorBackground=.*/d' $TERMINAL_CFG
    echo "ColorBackground=#2f2f34343f3f" >> $TERMINAL_CFG
    sed -i '/^ColorCursor=.*/d' $TERMINAL_CFG
    echo "ColorCursor=#aaaaaaaaaaaa" >> $TERMINAL_CFG
    sed -i '/^TabActivityColor=.*/d' $TERMINAL_CFG
    echo "TabActivityColor=#ffff55555555" >> $TERMINAL_CFG
fi


################################################################################
# End
################################################################################

echo "All settings applied. You might need to logout/restart to take effect the changes."
