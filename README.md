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

## General Settings

### Bash History
```bash
echo '"\e[1;2A": history-search-backward' | sudo tee -a /etc/inputrc
echo '"\e[1;2B": history-search-forward' | sudo tee -a /etc/inputrc
```

### Groups
* `wheel` admin
* `users` general user
* `audio` play audio in lock screen
* `uucp` use the serial ports
* `vboxusers` access to vms

### Create User Folders
```bash
xdg-user-dirs-update
```

### LTS Kernel
* Install `linux-lts linux-lts-headers` as fallback
* When booting select the non lts kernel

TODO diskfilter error:
https://askubuntu.com/questions/468466/diskfilter-writes-are-not-supported-what-triggers-this-error

```bash
sudo nano /etc/default/grub
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
```

### Lock Root
```bash
sudo passwd -l root
```

### Multilib
* Required for wine
* https://wiki.archlinux.org/index.php/multilib

### Raspi tools
To make use of tools as `tvservice` you can add `/opt/vc/bin` to your $PATH.

```bash
echo "export PATH=${PATH}:/opt/vc/bin" | sudo tee -a /etc/bash.bashrc
```

## Desktop environment Xfce

### Packages
To make the DE look better I installed the following (main) packages:
* [Xfce](http://www.xfce.org/)
* [Arc Theme](https://github.com/horst3180/arc-theme)
* [Arc Icon Theme](https://github.com/horst3180/arc-icon-theme)
* [xfce4-whiskermenu-plugin](http://goodies.xfce.org/projects/panel-plugins/xfce4-whiskermenu-plugin)
* [plank](https://www.archlinux.org/packages/community/x86_64/plank/)
* [compton](http://duncanlock.net/blog/2013/06/07/how-to-switch-to-compton-for-beautiful-tear-free-compositing-in-xfce/)
* [elementary-icon-theme](https://www.archlinux.org/packages/community/any/elementary-icon-theme/)
* [glacier wallpaper](https://pixabay.com/en/glacier-mountain-snow-hillside-869593/)

### Configuration

Not all options can be set via command line or GUI. Sometimes you have to mix.
On a clean install some commands might fail because no config file exists yet.

#### Lightdm
```bash
# Try DE
sudo systemctl start lightdm.service

# Enable DE
sudo systemctl enable lightdm.service
```

#### Panel
* Use the default panel layout when starting xfce for the first time
* Go to `Settings->Panel`
* Delete the bottom panel
* Select the top panel
* Select position `auto`
* Unlock the panel, move it to the desired monitor and lock again

##### Whiskermenu
* Go to `Settings->Panel->Items`
* Add `whiskermenu` and remove the normal ` Application menu`
* Configure whisker menu
* Set `Appearance->PanelButton->Display` to `Icon and title`
* Set `Behavior->Menu` with `Switch categories by hovering` and `Position categories next to panel button`
* Set `Commands->Lock Screen` to `light-locker-command -l`
* Set `Commands->Switch Users` to `dm-tool switch-to-greeter`
* Set `Commands->Edit Applications` to `alacarte`
* Disable `Commands->Edit Profile`

##### Panel Plugins
* Edit the `Action Buttons` entry in `Settings->Panel->Items`.
* Set `Appearance` to `Action Buttons` and only check `Log Out...`

* Add `Keyboard Layouts` in `Settings->Panel->Items` and set it to `text`, `small`, `globally`.

* Add `Power Manager Plugin` in `Settings->Panel->Items`.

* Add `CPU Graph` in `Settings->Panel->Items`
* Pick the color of the task bar (`#2B2E37`) as `Background`
* Pick the close button color (`#CC575D`) as `Color `
* In `Advanced` set `Width` to `64`
* Set `Associated command` to `gnome-system-monitor`
* Only check the `show border` box and uncheck all other options.

* Add `Notes`
* Set `Tabs position` to `Top`
* Set `Background` to `GTK+`
* Set `Font` to `Monospace 10`

#### Wallpaper
* [Download the wallpaper](https://pixabay.com/en/glacier-mountain-snow-hillside-869593/)
* Move the wallpaper to `/usr/share/backgrounds/xfce/`
* Go to `Settings->Desktop`
* Go to `Background`
* Enable the wallpaper for every display
* Go to `Icons`
* Set `Icon type` as `None`
* Also disable all desktop menus in `Settings->Desktop->Menus`

```bash
sudo cp glacier.jpg /usr/share/backgrounds/xfce/glacier.jpg
xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/xfce/glacier.jpg"
```


#### Theme
Install the Arc gtk and icon theme. Arc theme and icons have to be installed
from AUR or from git. See the official build instructions for the most up to
date installation instructions. You can use `elementary` as icon theme fallback.

* Go to `Settings->Appearance`
* Go to `Style`
* Enable the theme (Arc-Darker)
* Go to `Settings->Window Manager`
* Go to `Style`
* Enable the theme (Arc-Darker)
* Go to `Settings->Appearance`
* Go to `Icons`
* Enable the theme (Arc)
* Go to `Settings->LightDM GTK+ Greeter settings`
* Select `Arc-Dark` as `Theme`
* Select the `glacier.jpg` as `Image`
* Go to `Settings->Mouse and Touchpad`
* Go to `Theme`
* Select `elementary` as cursor
* [Set a user avatar](https://wiki.archlinux.org/index.php/LightDM#Changing_your_avatar)

```bash
xfconf-query -c xfwm4 -p /general/theme -s "Arc-Darker"
xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Darker"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Arc"
sudo nano /etc/lightdm/lightdm-gtk-greeter.conf
```

#### Plank
* Install `plank`
* Call `plank --preferences` to set the `Transparent` theme
* Go to `Settings->Session and Startup`
* Go to `Application Autostart`
* Add and entry `Plank` with the command `plank`
* Start `plank`

```bash
dconf write /net/launchpad/plank/docks/dock1/theme "'Transparent'"
mkdir -p ~/.config/autostart/
cp /usr/share/applications/plank.desktop ~/.config/autostart/
```

#### Keyboard shortcuts
* Go to `Settings->Keyboard`
* Go to `Application Shortcuts`
* Add a new shortcut for `xfce4-screenshooter --fullscreen` for the `Print` key
* Add a new shortcut for `xfce4-popup-whiskermenu` for the `Super/Windows` key
* Change the shortcut for the `light-locker-command -l` for the `Ctrl+Alt+L` key
* Remove the `Alt+F1`, `Alt+F2` and `Alt+F3` shortcuts
* Go to `Layout`
* Make sure to `Use system defaults` and set the X11 keyboard config properly

```bash
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Print -s "xfce4-screenshooter --fullscreen"
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -s "xfce4-popup-whiskermenu"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F1" -r
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F2" -r
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>F3" -r
```

#### NetworkManager
```bash
sudo systemctl disable dhcpcd
sudo systemctl stop dhcpcd
sudo systemctl start NetworkManager
sudo systemctl enable NetworkManager
```

#### Xfce Tweaks
* Go to `Settings->Window Manager Tweaks`
* Go to `Cycling`
* Enable `Cycle through windows on all workspaces`
* Disable `Draw frame around selected windows while cycling`
* Go to `Accessibility`
* Disable `Use mouse wheel on tile bar to roll up the window`
* Go to `Workspaces`
* Disable `Use the mouse wheel on the desktop to switch workspaces`
* Go to `Compositor`
* Disable `Show shadows under dock windows` to get rid of the sticky horizontal line
* Enable `Synchronize drawing to the vertical blank`
* Or disable compositing and use [compton](http://duncanlock.net/blog/2013/06/07/how-to-switch-to-compton-for-beautiful-tear-free-compositing-in-xfce/) instead.

* Set the window button layout to the left in `Settings->Window Manager->Style` under `Button layout`

* Go to `Settings->Session and Startup`
* Go to `General`
* Disable `Automatically save session on logout`
* Go to `Session`
* Hit `Clear saved session`

* Go to `Settings->Workspaces`
* Set `Number of workspaces` to `1`

```bash
xfconf-query -c xfwm4 -p /general/cycle_workspaces -s true
xfconf-query -c xfwm4 -p /general/cycle_draw_frame -s false
xfconf-query -c xfwm4 -p /general/mousewheel_rollup -s false
xfconf-query -c xfwm4 -p /general/scroll_workspaces -s false
xfconf-query -c xfwm4 -p /general/show_dock_shadow -s false

xfconf-query -c xfce4-session -p /general/AutoSave -s false
rm -f ~/.cache/sessions/xfce4-session-*

xfconf-query -c xfwm4 -p /general/workspace_count -s 1
```

### Programs

#### Thunar Filemanager
* Open Thunar
* Go to `Edit->Preferences->Side Pane`
* Set all `Icon Size` to `Very Small`
* Go to `Behavior`
* Enable `Middle Click->Open folder in new tab`

* Go to `Edit->Configure custom actions...`
* Add a search entry `Search`: `Search this folder for files using Catfish`
* Install `catfish mlocate`

| Name   | Command           | File patterns | Appears if selection contains |
|--------|-------------------|---------------|-------------------------------|
| Search | catfish --path=%f | *             | Directories                   |

```bash
echo "Configuring file manager..."
xfconf-query -c thunar -p /shortcuts-icon-size -s "THUNAR_ICON_SIZE_SMALLEST"
xfconf-query -c thunar -p /tree-icon-size -s "THUNAR_ICON_SIZE_SMALLEST"
xfconf-query -c thunar -p /misc-middle-click-in-tab -s true
```

#### Terminal
* Open a Terminal and go to `Edit->Preferences`
* Go to `Appearance`
* Set `Font` to `Monospace 11`
* Set the `Background` to `Transparent background` with `Transparency 0.95`
* Go to `Colors`
* Set `Background color` to the Arc window color (#2F343F)
* Set `Cursor color` to the Arc text color (#AAAAAA)
* Set `Tab activity color` to The Arc close button color (#FF5555)
* You can also drop the colors from the `Palette`

#### Intel driver
There is no need in installing the intel driver, as the kernel
[already supports the intel chipset even better.](https://www.reddit.com/r/archlinux/comments/4cojj9/it_is_probably_time_to_ditch_xf86videointel/)

#### Network Manager
##### Dns Caching
Install `dnsmasq` and enable it:

```bash
sudo nano /etc/NetworkManager/NetworkManager.conf
[main]
...
dns=dnsmasq

sudo systemctl restart NetworkManager.service
```

#### Kodi
##### Automount encrypted USB drives
* Install `udisks` to automount normal USB Drives
* Add a [keyfile to the luks header](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Keyfiles)
* `chmod` the USB drives root partition so that everyone (`kodi`) can read `755` the USB drive
* Add an udev rule:

```rules
# udevadm info -q all -n /dev/sdxY | grep ID_SERIAL
# sudo nano /etc/udev/rules.d/85-Seagate2TB-1.rules
# sudo udevadm test /sys/block/sda/sda1
# sudo udevadm control --reload-rules
# ls /dev/mapper
ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_SERIAL}=="ST2000DM001-9YN164_W1E0JWNZ", \
RUN+="/usr/bin/cryptsetup --key-file /root/Seagate2TB-1.key luksOpen $env{DEVNAME} Seagate2TB-1"
```

http://michael.stapelberg.de/Artikel/automount_cryptsetup_udev
https://wiki.archlinux.de/title/Udev
http://tech.cbjck.de/2014/03/27/luks-automount/

#### SSH
```
nano /etc/ssh/sshd_config
AllowGroups  wheel
AllowUsers   <username>

systemctl enable sshd.socket
systemctl start sshd.socket
```

#### Pidgin
##### Fix browser error
Go to preferences and set the correct browser.

##### Minimize to tray
Go to preferences and enable the system tray.

##### Spell correction
Install `aspell-en`

#### Git

```bash
git config --global core.editor "nano"
```

#### Libre Office
##### Fix Arc GTK theme
```bash
sudo sed -i '/export SAL_USE_VCLPLUGIN=gtk$/s/^#//g' /etc/profile.d/libreoffice-fresh.sh
git config --global user.email "$USER@users.noreply.github.com"
git config --global user.name "$USER"
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
rip cd rip --offset 6
```

#### Kodi

##### No shutdown buttons
Install `polkit`

##### Video does not start properly
Sometimes it happens that a video starts and hangs as the very first seconds.
The menu is still visible and sometimes the audio starts to play but no video.
If you switch to a list view instead of a poster view in the movie library
all video should be playable again. This seems to be a kodi bug. It does not
apply to all videos, just some and sometimes.

##### Right Click Menu Key
If the key does not work you can try holding enter longer.
This will also give you the context menu.

##### Disable Pulse-Eight CEC Adapter
Go to System -> Input -> Peripherals -> Pulse-Eight CEC Adapter

##### Blackborder Are Transparent
https://github.com/archlinuxarm/PKGBUILDs/pull/1379

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
