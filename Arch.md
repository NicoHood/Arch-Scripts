This page describes my notes when using arch linux. Those settings even work with the Raspberry Pi 3. You can get a very fancy and even fast GUI for it too. But also for x64 PCs those
settings give a very nice setup. **I am still an arch beginner. Consider this as my personal notes/settings/summary which might not be useful for you.** Most information can be found in the
Arch wiki.

### Arch Installation
TODO for live cd. Raspi has pretty straight forward instructions.

### Tipps
* To boot the live CD with more ram, at the boot menu, add the option `cow_spacesize=2G`

### Packages

```bash
# Basic tools
sudo pacman -S sudo wget htop bash-completion git base base-devel sudo alsa-utils gnome-keyring nmap unrar cfv dconf-editor bind-tools lsb-release

# Development
sudo pacman -S avr-gcc avrdude libusb hidapi jdk8-openjdk jre8-openjdk vim

# Applications (chromium is not available for rpi1)
sudo pacman -S firefox chromium qtox deja-dup rhythmbox gst-libav vlc thunderbird libreoffice-fresh gnome-disk-utility evince gnome-calculator pinta gpicview gnome-system-monitor irssi
pidgin gparted gedit meld

# Optional
sudo pacman -S filezilla wine keepass bless puddletag openssh

# Pentration testing
sudo pacman -S ettercap-gtk ettercap wireshark-gtk aircrack-ng reaver

# x64 only
sudo pacman -S kodi handbrake dolphin-emu

# Raspberry only
sudo pacman -S kodi-rbp kodi-rbp-eventclients rng-tools wiringpi

# TODO
alsa tools pavucontrol ssh cryptsetup uget notes/todo vnc brasero/xfburn etc avahi nss-mdns virtualbox virtualbox-guest-dkms linux-headers linux-lts-headers
```

Not available as official package:
* https://github.com/atom/atom
* https://github.com/arduino/Arduino
* https://github.com/hyperion-project/hyperion
* http://fritzing.org/download/
* https://www.saleae.com/downloads
* http://www.cadsoftusa.com/download-eagle/

### Configuration

```
# Use network manager
sudo systemctl start NetworkManager
sudo systemctl enable NetworkManager
#TODO disable dhcpcd
```

### Display Manager
TODO xserver, lightdm/gdm

### Desktop Environment

#### Packages
To make the DE look better I installed the following (main) packages:
* [Xfce](http://www.xfce.org/)
* [Arc Theme](https://github.com/horst3180/arc-theme)
* [Arc Icon Theme](https://github.com/horst3180/arc-icon-theme)
* [xfce4-whiskermenu-plugin](http://goodies.xfce.org/projects/panel-plugins/xfce4-whiskermenu-plugin)
* [plank](https://www.archlinux.org/packages/community/x86_64/plank/)
* [elementary-icon-theme](https://www.archlinux.org/packages/community/any/elementary-icon-theme/)
* [glacier wallpaper](https://pixabay.com/en/glacier-mountain-snow-hillside-869593/)

#### Installation
```bash

# plugins (also see xfce4-goodies)
thunar-archive-plugin thunar-media-tags-plugin xfce4-cpugraph-plugin xfce4-genmon-plugin xfce4-mpc-plugin xfce4-notifyd xfce4-sensors-plugin xfce4-xkb-plugin xfce4-whiskermenu-plugin
xfce4-mixer gstreamer0.10-good-plugins ffmpegthumbnailer freetype2 libgsf libopenraw poppler-glib

# Additional tools for the DE

# x64
xfce4-battery-plugin

# applications
mousepad xfburn xfce4-screenshooter gpicview gnome-system-monitor

# application alternatives
brasero gedit gnome-screenshot ristretto xfce4-taskmanager

# Optional theme
numix-themes

# Install other DE related tools
sudo pacman -S network-manager-applet networkmanager xfce4-notifyd nm-connection-editor file-roller thunar-archive-plugin xfce4-xkb-plugin xfce4-cpugraph-plugin xfce4-screenshooter
# plugins (also see xfce4-goodies)

# Optional DE tools
sudo pacman -S alacarte

# TODO rhythmbox plugins
gst-libav (optional) - Extra media codecs
gst-plugins-bad (optional) - Extra media codecs
gst-plugins-ugly (optional) - Extra media codecs


#TODO ssh
# add user to group users
nano /etc/ssh/sshd_config
AllowGroups   users
systemctl enable sshd.socket

```

#### Configuration

```bash
# Remove/reorder some panels and add the whiskermenu in `Settings->Panel->Items`.
# Configure whisker menu in `Appearance->PanelButton->Display` with `Icon and title` and `Behavior->Menu` with `Switch categories by hovering and `Position categories next to panel button`.
# Edit the `Action Buttons` entry in `Settings->Panel->Items`. Use `Action Buttons as `Appearance` and only check `Log Out...`
# Add `Keyboard Layouts` in `Settings->Panel->Items` and set it to `text`, `small`, `globally`.
# Add `Power Manager Plugin` in `Settings->Panel->Items`.
# Add `CPU Graph` in `Settings->Panel->Items` and pick the color of the task bar (`#2B2E37`) as `Background` and another color you like as `Color ` (I use the red color of the window closing
button `#CC575D`). In `Advanced` set `Width` to `64`, `Associated command` to `gnome-system-monitor` and only check the `show border` box.

# TODO mousepad setting
# TODO configure lightdm lock screen
# TODO lts kernel

# Set the window button layout to the left in `Settings->Window Manager->Style` under `Button layout`
# TODO command not working
xfconf-query -c xsettings -p /Gtk/DecorationLayout -s "close,minimize,maximize:"
installing gnome-tweak-tool would pull almost the entire Gnome as dependencies. I had the same problem today and I didnt want to install such a lot of unneeded stuff only to change one
little setting and spent some time researching how these things are related and it seems it is indeed possible with gconf-editor (or gconftool-2) alone.
The key in gconf-editor is /apps/metacity/general/theme. or compiz

#TODO add dns cache to network manager via dnsmasq

#TODO config.txt

# TODO test emacs org mode (as todo list)
https://www.gnu.org/software/emacs/

# TODO atom, arc AUR

#TODO optimize mirror list

#TODO elementary mouse pointer\icons

# TODO sed
# Set nano as default editor globally `echo "EDITOR=nano" | tee -a /etc/environment`.
# Enable bash history `echo '"\e[1;2A": history-search-backward' | sudo tee -a /etc/inputrc; echo '"\e[1;2B": history-search-forward' | sudo tee -a /etc/inputrc`.

# TODO check if git is installed
git config --global core.editor "nano"

#TODO setting (gb) and time

#TODO create user folders
xdg-user-dirs-update

# TODO uget enable aria2 builtin plugin

#TODO ssh
# add user to group users
nano /etc/ssh/sshd_config
AllowGroups   users
systemctl enable sshd.socket
systemctl start sshd.socket

# TODO open office path gtk

# Set the hostname
if [ -z $NEW_HOSTNAME ]
then
    hostnamectl set-hostname $NEW_HOSTNAME
fi

# TODO enable multilib (for wine)
https://wiki.archlinux.org/index.php/multilib

# TODO firefox on ram
https://wiki.archlinux.org/index.php/Firefox_on_RAM

# TODO xfce user switching
# create script is the best solution, but also patch whiskermenu
# also use dm-tool lock for locking
https://wiki.archlinux.org/index.php/LightDM#User_switching_under_Xfce4


#add avatar
https://wiki.archlinux.org/index.php/LightDM#Changing_your_avatar

#TODO fixmonitors
```


#### Optional Settings


##### Libre Office
Libre Office currently has [bad gtk3 support](https://github.com/horst3180/arc-theme/issues/569#issuecomment-224636298). To use `Arc-Darker` properly with libre office use this command to
fix it:
```bash
sudo sed -i '/export SAL_USE_VCLPLUGIN=gtk/s/^#//g' /etc/profile.d/libreoffice-fresh.sh
```

### Yaourt

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
