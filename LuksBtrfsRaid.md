# LuksBtrfsRaid

```bash
# rng-tools for faster /dev/random
# cryptsetup for luks en/decryption
# btrfs-progs for btrfs partition creation
sudo pacman -S rng-tools cryptsetup btrfs-progs

# Create keyfiles
# Use maximum keyfile size (8192kiB)
sudo dd bs=512 count=16384 if=/dev/random of=/root/sda.key iflag=fullblock
sudo dd bs=512 count=16384 if=/dev/random of=/root/sdb.key iflag=fullblock

# Create luks containers
# Attention: Use extra iterations for the Raspberyy Pi
# https://gitlab.com/cryptsetup/cryptsetup/wikis/FrequentlyAskedQuestionshttps://gitlab.com/cryptsetup/cryptsetup/wikis/FrequentlyAskedQuestions
sudo cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 --use-random -i 30000 /dev/sda /root/sda.key
sudo cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 --use-random -i 30000 /dev/sdb /root/sdb.key

# Add optional passphrase (use a strong random password!)
sudo cryptsetup --key-file=/root/sda.key -y luksAddKey /dev/sda
sudo cryptsetup --key-file=/root/sdb.key -y luksAddKey /dev/sdb

# Unlock luks containers
sudo cryptsetup --key-file=/root/sda.key luksOpen /dev/sda hdd1
sudo cryptsetup --key-file=/root/sdb.key luksOpen /dev/sdb hdd2

# Create btrfs filesystem (raid0 for data, raid 1 for metadata)
sudo mkfs.btrfs -L raid -d raid0 -m raid1 /dev/mapper/hdd1 /dev/mapper/hdd2

# Add permissions for other users to write to the (mounted) device
sudo mount /dev/mapper/hdd2 /mnt
sudo chmod 777 /mnt
sudo umount /mnt

# As an alternative add a volume to an existing btrfs partition
# Add new hdd, balance raid0
# sudo mkfs.btrfs /dev/mapper/hdd1
# sudo btrfs device add /dev/mapper/hdd2 /mnt
# sudo btrfs filesystem balance /mnt

# Get the UUID of all drives
SDA=$(sudo blkid /dev/sda -o value -s UUID)
SDB=$(sudo blkid /dev/sdb -o value -s UUID)
DM=$(sudo blkid /dev/mapper/hdd1 -o value -s UUID)

# Rename keyfiles with UUID
sudo mv /root/sda.key /root/${SDA}.key
sudo mv /root/sdb.key /root/${SDB}.key

# Add disks to crypttab to unlock at boot
# Use "nofail" as optional 2nd option to boot if the device is not available.
# If it becomes online it will be mounted afterwards, but kodi will not recognize it.
echo "" | sudo tee -a /etc/crypttab
echo "# Encrypted media disks" | sudo tee -a /etc/crypttab
echo "hdd1 UUID=${SDA} /root/${SDA}.key luks" | sudo tee -a /etc/crypttab
echo "hdd2 UUID=${SDB} /root/${SDB}.key luks" | sudo tee -a /etc/crypttab

# Mount at boot (you must use the UUID otherwise it will sometimes fail to mount)
echo "UUID=${DM} /run/media/raid btrfs defaults,nofail 0 0" | sudo tee -a /etc/fstab

# Reboot the system. It will take some time until all drives are decrypted and mounted
sudo reboot
```
