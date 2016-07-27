#!/bin/bash

# Check for root user
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

# Check if partclone is installed
which partclone
if [[ $? -ne 0 ]]; then
  echo "Error: No partclone installation found." 2>&1
  exit 1
fi

# Create snapshot
sync
lvcreate -s -l 100%FREE -n backup /dev/mapper/arch--vg-root
sync

# Mount snapshot TODO optional with partclone?

# Backup snapshot
sudo partclone.ext4 -c -s /dev/mapper/arch--vg-backup -o /run/media/arch/32GB/root.img

# Delete snapshot
lvremove /dev/mapper/arch--vg-backup

# Do this again for the boot partition
# Backup MBR (aka first 1MiB)
# Backup lvm layout
# Export luks headers
