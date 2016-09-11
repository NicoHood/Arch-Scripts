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
PKG_BASIC+="gnome-keyring unrar cfv bind-tools dosfstools rng-tools p7zip "

# Install lts kernel + headers for x64 and dkms
if [[ $CPU_X64 -eq 1 ]]; then
    PKG_BASIC+="linux-lts linux-lts-headers linux-headers "
fi

################################################################################
# Applications
################################################################################

# Internet
PKG_APP+="firefox thunderbird gnupg "

# System
PKG_APP+="gnome-system-monitor baobab gparted gnome-disk-utility gnome-calculator "

# Text Editor/Viewer
PKG_APP+="xfce4-notes-plugin atom libreoffice-fresh mousepad evince meld "

# Print and scan
PKG_APP+="cups ghostscript gsfonts system-config-printer gutenprint sane simple-scan "

# Download
PKG_APP+="uget aria2 "

# Media
PKG_APP+="udisks rhythmbox gst-libav vlc cdrdao morituri python2-pycdio "
PKG_APP+="soundconverter xfburn "

# Chat
PKG_APP+="irssi pidgin aspell-en qtox "

# Pictures
PKG_APP+="pinta gpicview xfce4-screenshooter "

# Backup TODO remove deja-dup
PKG_APP+="deja-dup snapper "

# Offline wiki
PKG_APP+="arch-wiki-docs arch-wiki-lite dialog "

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
    PKG_APP+="kodi-rbp polkit udisks lsb-release lirc wiringpi fake-hwclock"
fi

# Application alternatives
PKG_APP_ALT+="brasero gedit gnome-screenshot ristretto xfce4-taskmanager easytag "


################################################################################
# Other
################################################################################

# Development
PKG_DEV+="git avr-gcc avrdude avr-libc libusb hidapi jdk8-openjdk jre8-openjdk "
PKG_DEV+="vim namcap subversion bzr btrfs-progs shellcheck arch-install-scripts "

# Optional
PKG_OPT+="filezilla keepass bless puddletag openssh ethtool lm_sensors "

# Bluetooth with audio and phone support
PKG_OPT+="blueman pulseaudio-alsa pulseaudio-bluetooth bluez bluez-libs "
PKG_OPT+="bluez-utils bluez-firmware wammu python2-pybluez "

# Pentration testing
PKG_HCK+="ettercap-gtk wireshark-gtk aircrack-ng reaver nmap pygtk "

################################################################################
# Installation
################################################################################

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
