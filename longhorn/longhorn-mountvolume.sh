# 1. Create partition using fdisk
echo -e "g\nn\n\n\n\nw" | sudo fdisk /dev/sdd

# Explanation of commands:
# g = create GPT partition table
# n = new partition
# (defaults for partition number, first sector, last sector)
# w = write changes

# 2. Format as ext4
sudo mkfs.ext4 -F -L longhorn-data /dev/sdd1

# 3. Get the UUID
DISK_UUID=$(sudo blkid -s UUID -o value /dev/sdd1)
echo "Disk UUID: $DISK_UUID"

# 4. Create mount point
sudo mkdir -p /var/lib/longhorn-storage

# 5. Add to /etc/fstab
echo "# Longhorn storage disk - added $(date +%Y-%m-%d)" | sudo tee -a /etc/fstab
echo "UUID=$DISK_UUID  /var/lib/longhorn-storage  ext4  defaults,noatime,nodiratime,discard  0  2" | sudo tee -a /etc/fstab

# 6. Mount it
sudo mount -a

# 7. Verify
df -h /var/lib/longhorn-storage

# 8. Set permissions
sudo chmod 755 /var/lib/longhorn-storage