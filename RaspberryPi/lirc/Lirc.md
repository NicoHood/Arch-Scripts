# Configure Lirc on Arch for ARM (Raspberry Pi)

```bash
# Configure pins. By default it will use GPIOs 17 (out) and 18 (in)
sudo nano /boot/config.txt
dtoverlay=lirc-rpi,gpio_out_pin=17,gpio_in_pin=18,gpio_in_pull=up

# First edit the driver setting. Otherwise the following steps will not work or crash.
sudo nano /etc/lirc/lirc_options.conf
driver          = default

# Reboot Now
sudo reboot

# Test if the driver work. You should see: pulse 564, space 589, ...
sudo mode2 -d /dev/lirc0

# List available key names, search for a specific key (see next step)
irrecord --list-namespace | grep -i search

# Create a configuration file for your remote (or download it online)
sudo irrecord
sudo mv kodi.lircd.conf /etc/lirc/lircd.conf.d/

# Start the service
sudo systemctl start lircd.service

# Test if the keys are recognized properly
irw

# Enable the service at system start
sudo systemctl enable lircd.service

# Edit the Lircmap.xml.
# You can also edit the setting for the kodi service.
# What each entry triggers can be found in /usr/share/kodi/system/keymaps/remote.xml
nano ~/.kodi/userdata/Lircmap.xml
sudo nano /var/lib/kodi/.kodi/userdata/Lircmap.xml

# Test with kodi
kodi-standalone
```
