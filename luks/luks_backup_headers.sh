#!/bin/bash

# Simple LUKS header backup script
BACKUP_DIR="/home/michu990/Desktop/luks"
DATE=$(date +%Y%m%d)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Finding mounted LUKS devices..."

# Check all block devices for LUKS
for device in $(sudo lsblk -o NAME,TYPE,MOUNTPOINT | grep -E "crypt|part" | awk '{print $1}' | sed 's/[^a-zA-Z0-9]//g'); do
    full_device="/dev/$device"
    
    # Check if device exists and is LUKS
    if [ -b "$full_device" ] && sudo cryptsetup isLuks "$full_device" 2>/dev/null; then
        echo "Backing up LUKS header for $full_device..."

        # Tmp root save 
        sudo cryptsetup luksHeaderBackup "$full_device" --header-backup-file "/tmp/${device}_header_${DATE}.img"
        
        if [ $? -eq 0 ]; then
            # Changing permissions
            sudo chown michu990:michu990 "/tmp/${device}_header_${DATE}.img"
            
            # Move to folder
            mv "/tmp/${device}_header_${DATE}.img" "$BACKUP_DIR/${device}_header_${DATE}.img"
            
            echo "Backup successful: ${device}_header_${DATE}.img"
        else
            echo "Backup failed for $device"

        fi
    fi
done

echo ""
echo "LUKS header backup complete. Files stored in: $BACKUP_DIR"
ls -lh "$BACKUP_DIR/"