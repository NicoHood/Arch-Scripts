#!/bin/bash

# Check for root user
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

set -x
CFG_KEYBOARD=uk
CFG_SDX=/dev/sda
CFG_BOOT_PASSWD=toor
CFG_ROOT_PASSWD=toor
CFG_TIMEZONE=Europe/Berlin
CFG_HOSTNAME=arch
CFG_USERNAME=Arch
CFG_USER_PASSWD=toor
set +x
echo "Press enter to continue installation with those settings."
read

# Boot cd NOT in EFI mode
echo "Checking for EFI system (error is expected for bios boot)."
ls /sys/firmware/efi/efivars
if [[ $? -eq 0 ]]; then
    echo "Error: Running in EFI mode."
    exit 1
fi

ls $CFG_SDX
if [[ $? -ne 0 ]]; then
    lsblk
    echo "Error: Disk $CFG_SDX not found."
    exit 1
fi

# Set keyboard temporary
loadkeys $CFG_KEYBOARD
ping archlinux.org -c 4
if [[ $? -ne 0 ]]; then
    echo "Error: No network connection."
    exit 1
fi

# Set time
timedatectl set-ntp true

# Partitioning
# https://wiki.archlinux.org/index.php/beginners'_guide#Prepare_the_storage_devices
# /boot   512MiB
# LVM     100%FREE
# swap    4GiB
# /backup 50%VG
# /       100%FREE
#fdisk /dev/sda
#o
#n p 1 [Enter] +512M
#a
#n p 2 [Enter] [Enter]
#t 2 8e
#w
echo "Formating disk..."
echo -e "o\nn\np\n1\n\n+512M\na\nn\np\n2\n\n\nt\n2\n8e\np\nw" | fdisk $CFG_SDX
echo ""

# Stop on errors
set -e

# Preparing the logical volumes
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Preparing_the_logical_volumes
# Create luks
echo "Creating root luks + lvm partitions..."
echo -n "$CFG_ROOT_PASSWD" | cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 --use-random ${CFG_SDX}2
echo -n "$CFG_ROOT_PASSWD" | cryptsetup open --type luks ${CFG_SDX}2 lvm
pvcreate /dev/mapper/lvm
vgcreate arch-vg /dev/mapper/lvm
lvcreate -L 4G arch-vg -n swap
# Reserve 5% for snapshots
lvcreate -l 5%VG arch-vg -n reserve
lvcreate -l 100%FREE arch-vg -n root
lvremove -f /dev/mapper/arch--vg-reserve
mkfs.ext4 /dev/mapper/arch--vg-root
mount /dev/mapper/arch--vg-root /mnt
mkswap /dev/mapper/arch--vg-swap
swapon /dev/mapper/arch--vg-swap

# Preparing the boot partition
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Preparing_the_boot_partition_5
echo "Creating boot luks..."
echo -n "$CFG_BOOT_PASSWD" | cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 --use-random ${CFG_SDX}1
echo -n "$CFG_BOOT_PASSWD" | cryptsetup open --type luks ${CFG_SDX}1 cryptboot
mkfs.ext4 /dev/mapper/cryptboot
mkdir /mnt/boot
mount /dev/mapper/cryptboot /mnt/boot

# Map hosts /run:
# https://unix.stackexchange.com/questions/105389/arch-grub-asking-for-run-lvm-lvmetad-socket-on-a-non-lvm-disk
mkdir /mnt/hostrun
mount --bind /run /mnt/hostrun

# Install the base packages, fstab and chroot
# https://wiki.archlinux.org/index.php/beginners'_guide#Install_the_base_packages
pacstrap /mnt base base-devel sudo bash-completion
genfstab -U /mnt > /mnt/etc/fstab
UUID1=`blkid ${CFG_SDX}1 -o value | head -n 1`
UUID2=`blkid ${CFG_SDX}2 -o value | head -n 1`

arch-chroot /mnt /bin/bash <<EOF

# Stop on errors
set -e
set -x

echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=uk' > /etc/vconsole.conf
#tzselect
ln -s /usr/share/zoneinfo/$CFG_TIMEZONE /etc/localtime
hwclock --systohc --utc
echo arch > /etc/hostname
#TODO Add the same hostname to /etc/hosts

# Configuring mkinitcpio
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio_5
sed -i 's/^HOOKS=".*block/\0 keymap encrypt lvm2/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Install grub
pacman -S --needed --noconfirm -q grub os-prober intel-ucode

# Note uuid and add it to grub config efibootmgr
sed -i "s#^GRUB_CMDLINE_LINUX=\"#\0cryptdevice=UUID=${UUID2}:lvm root=/dev/mapper/arch--vg-root#g" /etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub

mkdir /run/lvm
mount --bind /hostrun/lvm /run/lvm
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=i386-pc ${CFG_SDX}

# Configuring fstab and crypttab
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Configuring_fstab_and_crypttab_2
echo "cryptboot UUID=${UUID1} none luks" >> /etc/crypttab

# Install sudo, if missing and add the wheel group to the sudoers
pacman -S --needed --noconfirm -q sudo
sed -i '/%wheel.ALL=(ALL) ALL/s/^# //g' /etc/sudoers

# Add a new (non root) user, make sure sudo works before you remove the root password!
useradd -m -G wheel,users,uucp -s /bin/bash ${CFG_USERNAME,,}
echo "${CFG_USERNAME,,}:${CFG_USER_PASSWD}" | chpasswd
chfn -f ${CFG_USERNAME} ${CFG_USERNAME,,}

# Disable root
passwd -l root

umount /run/lvm
exit
EOF

echo "Press enter to unmount /mnt now and reboot."
read
umount /mnt -R
reboot

# You have to type the password twice when booting.
# Do NOT add a 2nd keyfile to the initramfs.
# Otherwise any user can dump the initramfs and its key. This is a security risk.
# As an option you could not encrypt the boot partition and do a "normal" setup instead.
# If the keyboard does not work when booting try to run the fallback initramfs.
# Then once the system is booted run `mkinitcpio -p linux`.
# Change the default passwords after reboot!
# Make sure to use `sudo` on the new system for administrative commands.

sudo systemctl start dhcpcd
sudo pacman -Syyu

# TODO lts kernel? -> initramfs
# TODO secure grub with a password

# Arch installation (encrypted efi)
#https://gist.githubusercontent.com/wuputah/4982514/raw/017cdeef4cc8ef14401092e1b4db3250e6bac0b1/archlinux-install.sh


# TODO use reflector to rate the mirrorlist
