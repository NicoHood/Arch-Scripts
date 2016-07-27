#!/bin/bash

# Check for root user
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

# Get system information
if [[ ! -e "./sysinfo.sh" ]]; then
    echo "Error: Could not find ./sysinfo.sh script."
    exit 1
fi
. ./sysinfo.sh

################################################################################
# Basic packages
################################################################################

# Basic packages
PKG_BASIC+="wget base base-devel sudo bash-completion lsb-release htop "
PKG_BASIC+="gnome-keyring unrar cfv bind-tools dosfstools rng-tools "

# Install lts kernel + headers for x64 and dkms
if [[ $CPU_X64 -eq 1 ]]; then
    PKG_BASIC+="linux-lts linux-lts-headers linux-headers "
fi

################################################################################
# XORG
################################################################################

# Install X-server
PKG_XORG+="xorg-server mesa "

# Install desktop utils + video drivers for vm
if [[ CPU_VM -eq 1 ]]; then
    echo "Installing Virtualbox drivers"
    PKG_XORG+="linux-headers linux-lts-headers "
    PKG_XORG+="virtualbox-guest-utils virtualbox-guest-dkms "
# Install video drivers for x64 PC
elif [[ $CPU_X64 -eq 1 ]]; then
    # https://wiki.archlinux.org/index.php/xorg
    # https://wiki.archlinux.org/index.php/Hardware_video_acceleration#Installing_VDPAU
    INTEL_CARD=`lspci | grep -e VGA -e 3D | grep -i Intel | wc -l`
    NVIDIA_CARD=`lspci | grep -e VGA -e 3D | grep -i Nvidia | wc -l`
    AMD_CARD=`lspci | grep -e VGA -e 3D | grep -i Amd | wc -l`
    ATI_CARD=`lspci | grep -e VGA -e 3D | grep -i Ati | wc -l`
    if [[ $INTEL_CARD -eq 1 ]]; then
        echo "Installing Intel drivers"
        # A better intel driver (xf86-video-intel) is integrated in the kernel:
        # https://www.reddit.com/r/archlinux/comments/4cojj9/it_is_probably_time_to_ditch_xf86videointel/
        # Make sure to use compton as X11 compositor to avoid vsync problems.
        PKG_XORG+="mesa-libgl libva-intel-driver libvdpau-va-gl "
    elif [[ $NVIDIA_CARD -eq 1 ]]; then
        echo "Installing Nvidia drivers"
        PKG_XORG+="xf86-video-nouveau mesa-libgl mesa-vdpau "
    elif [[ $ATI_CARD -eq 1 ]]; then
        echo "Installing ATI drivers"
        PKG_XORG+="xf86-video-ati mesa-libgl mesa-vdpau libva-mesa-driver libva-vdpau-driver "
    elif [[ $AMD_CARD -eq 1 ]]; then
        echo "Installing AMD drivers"
        PKG_XORG+="xf86-video-amdgpu mesa-libgl mesa-vdpau libva-mesa-driver libva-vdpau-driver "
    else
        echo "Warning: No graphic card found. Installing fbdev and vesa."
        echo "You might want to search your graphic card with:"
        echo "lspci | grep -e VGA -e 3D"
        echo "pacman -Ss xf86-video"
    fi
    # Fallback drivers
    PKG_XORG+="xf86-video-fbdev xf86-video-vesa mesa-libgl "

    # Gstreamer hardware acceleration
    PKG_XORG+="gstreamer-vaapi "

    # Laptop touchpad drivers
    # libinput will replace synaptics
    PKG_XORG+="xf86-input-libinput "
    #PKG_XORG+="xf86-input-synaptics "

# Install raspi video drivers
elif [[ $CPU_RPI -eq 1 ]]; then
    PKG_XORG+="xf86-video-fbturbo-git "
    #PKG_XORG+="xf86-video-fbdev"
fi
# TODO? xorg-utils xorg-server-utils

################################################################################
# Desktop environment
################################################################################

# lightdm
PKG_DESKTOP+="lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings "
PKG_DESKTOP+="accountsservice light-locker "

# xfce
PKG_DESKTOP+="exo garcon gtk-xfce-engine xfce4-panel "
PKG_DESKTOP+="xfce4-power-manager xfce4-session xfce4-settings xfconf xfdesktop "
PKG_DESKTOP+="xfwm4 xfce4-terminal compton "

# File manager
PKG_DESKTOP+="thunar thunar-volman thunar-archive-plugin thunar-media-tags-plugin "
PKG_DESKTOP+="catfish mlocate gvfs udisks udisks2 tumbler "

# Sound
PKG_DESKTOP+="xfce4-mixer gstreamer0.10-good-plugins pulseaudio paprefs pavucontrol "

# (Fallback) Themes
PKG_DESKTOP+="gnome-themes-standard gtk-engine-murrine elementary-icon-theme numix-themes "

# Network
PKG_DESKTOP+="networkmanager network-manager-applet dnsmasq "

# Install other DE related tools/plugins (also see xfce4-goodies)
PKG_DESKTOP+="dconf-editor alsa-utils xdg-user-dirs "
PKG_DESKTOP+="xfce4-notifyd nm-connection-editor file-roller "
PKG_DESKTOP+="xfce4-xkb-plugin xfce4-cpugraph-plugin "
PKG_DESKTOP+="plank "
PKG_DESKTOP+="xfce4-cpugraph-plugin xfce4-genmon-plugin "
PKG_DESKTOP+="xfce4-sensors-plugin xfce4-xkb-plugin xfce4-whiskermenu-plugin alacarte "
PKG_DESKTOP+="ffmpegthumbnailer "
PKG_DESKTOP+="freetype2 libgsf libopenraw poppler-glib xfce4-screenshooter "

################################################################################
# Applications
################################################################################

# Applications
PKG_APP+="firefox deja-dup thunderbird gnupg "
PKG_APP+="libreoffice-fresh gnome-disk-utility evince gnome-calculator pinta "
PKG_APP+="gparted gedit meld mousepad xfburn xfce4-screenshooter "
PKG_APP+="gpicview gnome-system-monitor baobab gnome-contacts "

# Editor
PKG_APP+="xfce4-notes-plugin "

# Download
PKG_APP+="uget aria2 "

# Media
PKG_APP+="udisks rhythmbox gst-libav vlc cdrdao morituri python2-pycdio "

# Chat
PKG_APP+="irssi pidgin aspell-en qtox "

# x64 only
if [[ $CPU_X64 -eq 1 ]]; then
    PKG_APP+="kodi polkit handbrake dolphin-emu "

    # Install virtual box
    PKG_APP+="virtualbox virtualbox-host-dkms virtualbox-guest-iso "
fi

# Non ARM6 only (ARM7, x64)
if [[ $CPU_ARM6 -eq 0 ]]; then
    PKG_APP+="chromium "
fi

# Raspberry Pi only
if [[ $CPU_RPI -eq 1 ]]; then
    PKG_APP+="kodi-rbp polkit wiringpi fake-hwclock"
fi

# Application alternatives
PKG_APP_ALT+="brasero gedit gnome-screenshot ristretto xfce4-taskmanager "


################################################################################
# Other
################################################################################

# Development
PKG_DEV+="git avr-gcc avrdude avr-libc libusb hidapi jdk8-openjdk jre8-openjdk "
PKG_DEV+="vim namcap subversion bzr btrfs-progs shellcheck "

# Optional
PKG_OPT+="filezilla wine keepass bless puddletag openssh ethtool "

# Pentration testing
PKG_HCK+="ettercap-gtk wireshark-gtk aircrack-ng reaver nmap pygtk "

################################################################################
# Installation
################################################################################

# Enable multilib support (for wine)
# TODO this uncomments a wrong line
#sed -i '/.multilib./{ s/^#//; n; s/^#//; }' /etc/pacman.conf

# Check for system updates before Configuring new packages to not break anything
echo "Checking for updates..."
pacman -Syyu
if [[ $? -ne 0 ]]; then
    echo "Error: Installation failed."
    exit 1
fi

PKG_ALL+="$PKG_BASIC"
PKG_ALL+="$PKG_XORG"
PKG_ALL+="$PKG_DESKTOP"
PKG_ALL+="$PKG_APP"
PKG_ALL+="$PKG_DEV"
PKG_ALL+="$PKG_OPT"
PKG_ALL+="$PKG_HCK"

echo "Installing selected packages..."
pacman -S --needed $PKG_ALL

# Raspberry Pi only
if [[ $CPU_RPI -eq 1 ]]; then
    # Install config.txt
    cp /boot/config.txt /boot/config.txt.bak
    cp Raspberry/config.txt /boot/config.txt
fi

# x64 only
if [[ $CPU_X64 -eq 1 ]]; then
  # Regenerate grub for lts kernel
  mkinitcpio -P
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# Ask for lightdm startup config
read -r -p "Do you want to enable lightdm by default? [y/N] " response
response=${response,,}
if [[ $response =~ ^(yes|y)$ ]]; then
    systemctl enable lightdm.service
fi