#!/bin/bash

# Arch installation (encrypted efi)
#https://gist.githubusercontent.com/wuputah/4982514/raw/017cdeef4cc8ef14401092e1b4db3250e6bac0b1/archlinux-install.sh

CFG_KEYBOARD=uk
CFG_SDX=/dev/sda
CFG_BOOT_PASSWD=toor
CFG_ROOT_PASSWD=toor
CFG_TIMEZONE=Europe/Berlin
CFG_HOSTNAME=arch
CFG_USERNAME=Arch
CFG_USER_PASSWD=toor

# Boot cd NOT in EFI mode
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
echo "o\nn\np\n1\n\n+512M\na\nn\np\n2\n\n\nt\n2\n8e\np\nw" | fdisk $CFG_SDX
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
lvcreate -l 50%VG arch-vg -n backup
lvcreate -l 100%FREE arch-vg -n root
mkfs.ext4 /dev/mapper/arch--vg-root
mkfs.ext4 /dev/mapper/arch--vg-backup
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
pacstrap /mnt base base-devel sudo bash-completion net-tools
genfstab -U /mnt > /mnt/etc/fstab
arch-chroot /mnt /bin/bash -e <<EOF

sed -i '/en_US.UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=uk' > /etc/vconsole.conf
#tzselect
ln -s /usr/share/zoneinfo/$CFG_TIMEZONE /etc/localtime
hwclock --systohc --utc
echo arch > /etc/hostname

# Configuring mkinitcpio
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio_5
sed -e 's/^HOOKS=".*block/\0 keymap encrypt lvm2/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Install grub
pacman -S --needed --noconfirm -q grub os-prober intel-ucode

# Note uuid and add it to grub config efibootmgr
UUID=`blkid ${CFG_SDX}2 -o value | head -n 1`
sed -e 's/^GRUB_CMDLINE_LINUX="/\0cryptdevice=UUID=${UUID}:lvm root=/dev/mapper/arch--vg-root/g' /etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub
# TODO remove
#nano /etc/default/grub
#GRUB_CMDLINE_LINUX="... cryptdevice=UUID=<sda2-device-UUID>:lvm root=/dev/mapper/arch--vg-root ..."
#GRUB_ENABLE_CRYPTODISK=y

mkdir /run/lvm
mount --bind /hostrun/lvm /run/lvm
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=i386-pc ${CFG_SDX}

# Install sudo, if missing and add the wheel group to the sudoers
pacman -S --needed --noconfirm -q sudo
TAB=$'\t'
sed -i '/%wheel${TAB}ALL=(ALL) ALL/s/^# //g' /etc/sudoers
#EDITOR=nano
#visudo
#%wheel      ALL=(ALL) ALL

# Add a new (non root) user, make sure sudo works before you remove the root password!
useradd -m -G wheel users uucp -s /bin/bash ${CFG_USERNAME,,}
echo "${CFG_USER_PASSWD}" | passwd ${CFG_USERNAME,,} --stdin
chfn -f ${CFG_USERNAME} ${CFG_USERNAME,,}

umount /run/lvm
exit
EOF

umount /mnt -R

exit

reboot

# You have to type the password twice when booting.
# Do NOT add a 2nd keyfile to the initramfs.
# Otherwise any user can dump the initramfs and its key. This is a security risk.
# As an option you could not encrypt the boot partition and do a "normal" setup instead.



systemctl start dhcpcd
pacman -Syyu

# TODO lts kernel? -> initramfs
# TODO secure grub with a password



# TODO use reflector to rate the mirrorlist
