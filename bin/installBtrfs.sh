#!/bin/bash

# Check for root user
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

set -x
CFG_KEYBOARD=uk
CFG_SDX=/dev/sda
CFG_ROOT_PASSWD=root
CFG_TIMEZONE=Europe/Berlin
CFG_HOSTNAME=arch
CFG_USERNAME=Arch
CFG_USER_PASSWD=toor
set +x
echo "Press enter to continue installation with those settings."
read

# Boot CD in EFI mode
echo "Checking for EFI system (error is expected for bios boot)."
ls /sys/firmware/efi/efivars
if [[ $? -ne 0 ]]; then
    echo "Error: Not running in EFI mode."
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

# Partition disk:
# GPT
# +1M bios boot partition
# +512M EFI partition
# root partition
echo "Formating disk..."
echo -e "g\nn\n\n\n+1M\nt\n4\nn\n\n\n+512M\nt\n\n1\nn\n\n\n\np\nw\n" | fdisk $CFG_SDX
echo ""

# Stop on errors
set -e

# Create cryptodisk and mount btrfs
echo -n "$CFG_ROOT_PASSWD" | cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 --use-random ${CFG_SDX}3
echo -n "$CFG_ROOT_PASSWD" | cryptsetup luksOpen ${CFG_SDX}3 cryptroot

# Mount btrfs and create subvolumes
mkfs.btrfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Remount with proper subvolumes
mount -o subvol=@ /dev/mapper/cryptroot /mnt
mkdir /mnt/home
mkdir /mnt/.snapshots
mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots

# Create some other subvolumes which should get excluded from backups
mkdir -p /mnt/var/cache/pacman
btrfs subvolume create /mnt/var/cache/pacman/pkg
btrfs subvolume create /mnt/var/abs
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/var/log
btrfs subvolume create /mnt/srv

# Mount efi partition
mkdir -p /mnt/boot/efi
mkfs.fat -F32 ${CFG_SDX}2
mount ${CFG_SDX}2 /mnt/boot/efi

# I had to wipe sda1 as it was recognized as btrfs for some reasons
# Afterwards os-prober will give some infos about not existing filesystems but thats okay
wipefs ${CFG_SDX}1 -a

# Install basic system and chroot
pacstrap /mnt base base-devel sudo bash-completion btrfs-progs
genfstab -U /mnt > /mnt/etc/fstab
UUID=`blkid ${CFG_SDX}3 -o value -s UUID`

arch-chroot /mnt /bin/bash <<EOF

# Stop on errors
set -e
set -x

# Set basic settings
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=uk' > /etc/vconsole.conf
# To change on a running system later:
#localectl set-locale LANG=en_US.UTF-8
#localectl set-keymap uk
#localectl set-x11-keymap gb,us,de pc105 ,, grp:alt_shift_toggle

#tzselect
ln -s /usr/share/zoneinfo/$CFG_TIMEZONE /etc/localtime
hwclock --systohc --utc
echo ${CFG_HOSTNAME} > /etc/hostname

# Add "keymap, encrypt" hooks and "/usr/bin/btrfs" to binaries
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio_5
sed -i 's/^HOOKS=".*block/\0 keymap encrypt/g' /etc/mkinitcpio.conf
sed -i "s#^BINARIES=\"#\0/usr/bin/btrfs#g" /etc/mkinitcpio.conf
mkinitcpio -P

# Install and configure grub
pacman -S --needed --noconfirm -q grub os-prober efibootmgr intel-ucode
sed -i "s#^GRUB_CMDLINE_LINUX=\"#\0cryptdevice=UUID=${UUID}:cryptroot#g" /etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Install grub for efi and bios. Efi installation will only work if you booted with efi.
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-install --target=i386-pc ${CFG_SDX}

# Install sudo, if missing and add the wheel group to the sudoers
pacman -S --needed --noconfirm -q sudo
sed -i '/%wheel.ALL=(ALL) ALL/s/^# //g' /etc/sudoers

# Add a new (non root) user, make sure sudo works before you remove the root password!
useradd -m -G wheel,users,uucp -s /bin/bash ${CFG_USERNAME,,}
echo "${CFG_USERNAME,,}:${CFG_USER_PASSWD}" | chpasswd
chfn -f ${CFG_USERNAME} ${CFG_USERNAME,,}

# Disable root
passwd -l root

exit
EOF

echo "Press enter to unmount /mnt now and reboot."
read
umount /mnt -R
reboot

# Changes
mkdir /mnt/boot
mkdir /mnt/root
crypsetup luksOpen /dev/sda1 boot
crypsetup luksOpen /dev/sda2 root
mount /dev/mapper/arch--vg-root /mnt/root
mount /dev/mapper/boot /mnt/boot
cp -a /mnt/boot /mnt/root
mkdir /mnt/root/hostrun
mount --bind /run /mnt/root/hostrun
arch-chroot /mnt/root

nano /etc/crypttab
nano /etc/fstab
mkdir /run/lvm
mount --bind /hostrun/lvm /run/lvm
grub-install --target=i386-pc /dev/sda
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
exit

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
