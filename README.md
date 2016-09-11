# Arch-Scripts
This is a personal collection of my Arch Linux settings I made.
This is not a recommendation, just a personal documentation.
Consider this just as a probably helpful information, but not as guideline.

## Arch Installation
### Download
* [x86_64](https://www.archlinux.org/download/)
* [ARM](https://archlinuxarm.org/platforms)

Make sure to also set the keyboard layout and the time.

### Live CD
#### Bigger initramfs
* To boot the live CD with more ram, at the boot menu, add the option `cow_spacesize=2G`

### Lock Root
```bash
sudo passwd -l root
```

## General Settings

### LTS Kernel
* Install `linux-lts linux-lts-headers` as fallback
* When booting select the non lts kernel

TODO diskfilter error:
https://askubuntu.com/questions/468466/diskfilter-writes-are-not-supported-what-triggers-this-error

```bash
sudo nano /etc/default/grub
# Only works on non lvm/btrfs
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true

# Alternative to use the non lts kernel
GRUB_DEFAULT='Advanced options for Arch Linux>Arch Linux, with Linux linux'
```

TODO
https://bbs.archlinux.org/viewtopic.php?id=166131
sudo grub-editenv create





### Copy whole filesystem with rsync
Make sure to remove the slash after `/mnt` and set it after the `source`
```bash
sudo rsync -axAXH --info=progress2 --numeric-ids /source/ /mnt
```

### Raspi packages
```bash
# Useful tools
pacman -S --needed base-devel sudo bash-completion wget rng-tools fake-hwclock

# Raspi installed tools
pacman -S git htop kodi-rbp lirc lsb-release polkit pulseaudio pulseaudio-alsa \
qrencode snapper udisks wiringpi

# Not required
rsync dosfstools btrfs-progs arch-install-scripts bluez bluez-firmware \
bluez-utils pulseaudio-bluetooth

# AUR
create_ap snap-pac hyperion
```



#### Atom
* [Tabs to Spaces](https://atom.io/packages/tabs-to-spaces)

#### Firefox
#### Cache in Ram
* https://wiki.archlinux.org/index.php/Firefox_on_RAM

#### Plugins
* TODO

#### Morituri
My offset is 6.
```
# Rip a new CD
rip cd rip --offset 6 --track-template="%R/%A/%d/%t. %n" --disc-template="%R/%A/%d/%A - %d"

# For an unknown CD:
rip cd rip --offset 6 --track-template="%R/%A/%d/%t. %n" --disc-template="%R/%A/%d/%A - %d" -U
```

#### Kodi

##### No shutdown buttons
Install `polkit`

##### Video does not start properly
Sometimes it happens that a video starts and hangs at the very first seconds.
The menu is still visible and sometimes the audio starts to play without video.
If you switch to a list view instead of a poster view in the movie library
all videos should be playable again. This seems to be a kodi bug. It does not
apply to all videos, just some and sometimes. This likely happens more often if
you have larger video files and slower discs.

##### Right Click Menu Key
If the key does not work you can try holding enter longer.
This will also give you the context menu.

##### Disable Pulse-Eight CEC Adapter
Go to System -> Input -> Peripherals -> Pulse-Eight CEC Adapter

##### Blackborders Are Transparent
https://github.com/archlinuxarm/PKGBUILDs/pull/1379

##### Use USB Soundcard

```bash
# Install pulseaudio
sudo pacman -S pulseaudio pulseaudio-alsa

# Add user to audio group
sudo usermod -a -G audio alarm

# Autostart pulseaudio (without gui)
sudo nano /etc/pulse/client.conf
sudo reboot

# Set the USB audio card as default output
pacmd list-sinks
pacmd set-default-sink "alsa_output.usb-M-AUDIO_M-Track_Hub-00.analog-stereo"
```

#### Steam
Fix startup crash
```bash
# Add multilib repository
sudo nano /etc/pacman.conf

sudo pacman -Syyu
sudo pacman -S steam lib32-alsa-plugins lib32-curl ttf-liberation

find ~/.steam/root/ \( -name "libgcc_s.so*" -o -name "libstdc++.so*" -o -name "libxcb.so*" -o -name "libgpg-error.so*" \) -print -delete
```

#### Printer
Use `CMYK` as color model and 2 sided printing. Make sure to add the user to the `sys` group.

#### Snapper
```bash
sudo pacman -S snapper snap-pac

# Setup configurations
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo mount -a
sudo chmod 750 /.snapshots
sudo chown :wheel /.snapshots
sudo chown :users /home/.snapshots
sudo usermod -a -G users ${USER}

# Start snapper timers
sudo systemctl enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer
sudo systemctl enable snapper-boot.timer
sudo systemctl start snapper-timeline.timer
sudo systemctl start snapper-cleanup.timer
```

#### Yaourt

```bash
# Install yaourt from a non root user!
sudo pacman -Syy
sudo pacman -S git base-devel
mkdir yaourt && cd yaourt
git clone https://aur.archlinux.org/package-query.git
git clone https://aur.archlinux.org/yaourt.git
cd package-query
makepkg -sri
cd ..
cd yaourt
makepkg -sri
cd ../..
rm yaourt -rf
```
