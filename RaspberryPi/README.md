# Raspberry Pi Tips

### Create a WLAN Access Point

Install [create_ap](https://aur.archlinux.org/packages/create_ap/) from AUR.
You do not need to configure dnsmasq, nor hostapd.
Just make sure to not use the virtual interface.
Also see [this bug report](https://github.com/oblique/create_ap/issues/185) for more information.
```bash
sudo create_ap wlan0 eth0 MyAccessPoint 12345678 -w2 --isolate-clients --no-virt
```

You can also edit the startup script to start the access point at startup.
```bash
sudo create_ap wlan0 eth0 MyAccessPoint 12345678 -w2 --isolate-clients --no-virt --mkconfig /etc/create_ap.conf
sudo nano /usr/lib/systemd/system/create_ap.service
ExecStart=/usr/bin/create_ap --config /etc/create_ap.conf
```

### Generate WLAN QR Codes

```bash
sudo pacman -S qrencode rng-tools
sudo nano /usr/local/bin/wlankeygen
sudo chmod +x /usr/local/bin/wlankeygen
sudo wlankeygen /var/lib/kodi/sudo wlankeygen /var/lib/kodi/
```

#### /usr/local/bin/wlankeygen
```bash
#!/bin/bash

# Make sure only root can run the script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Default path to save files needs to be passed by argument
if [ -z "$1" ]; then
    echo "No output path supplied"
    exit 2
fi

# Check if path exists
if [ ! -d "$1" ]; then
    echo "Output path does not exist"
    exit 3
fi

# Generate new wlan password and safe it.
# Do not use special chars as they are a) hard to read and b) cause problems with sed
WLANPSK=$(</dev/random tr -dc '[:alnum:]'| head -c 63)
WLANSSID="hackallthethings"
WLANHIDDEN="0"

# Save new setting
sed -i "s/PASSPHRASE=.*/PASSPHRASE=${WLANPSK}/" /etc/create_ap.conf
sed -i "s/SSID=.*/SSID=${WLANSSID}/" /etc/create_ap.conf
sed -i "s/HIDDEN=.*/HIDDEN=${WLANHIDDEN}/" /etc/create_ap.conf

# Restart service
systemctl restart create_ap

# Convert hidden setting into string
if [ "${WLANHIDDEN}" == "1" ]
then
    WLANHIDDEN="true"
else
    WLANHIDDEN="false"
fi

# Generate QR code pictures for Android and Windows
qrencode -t PNG -o "$1/AndroidWlan.png" -s 4 "WIFI:T:WPA;S:${WLANSSID};P:${WLANPSK};H:${WLANHIDDEN};"
qrencode -t PNG -o "$1/WindowsWlan.png" -s 4 "WIFI;T:WPA;S:${WLANSSID};P:${WLANPSK};H:${WLANHIDDEN};"

# IOS requires a hosted webpage which I do not want to host
# Use the copy to clipboard function for the password and manually connect instead.
qrencode -t PNG -o "$1/iOSWlan.png" -s 4 "${WLANPSK}"

echo "New WLAN password generated, hostapd reloaded and QR codes saved."
```

#### Timers
TODO systemd Timers
https://wiki.archlinux.org/index.php/Systemd/Timers

TODO use systemd drop in to overwrite the create_ap config
https://coreos.com/os/docs/latest/using-systemd-drop-in-units.html
