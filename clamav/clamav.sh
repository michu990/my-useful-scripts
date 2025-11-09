#!/bin/bash

echo "ClamAV database update"

# Stopping freshclam
echo "1. Stopping clamav-freshclam"
sudo systemctl stop clamav-freshclam

# New database
echo "2. Starting freshclam"
sudo freshclam

# Starting freshclam
echo "3. Starting clamav-freshclam"
sudo systemctl start clamav-freshclam

echo "==================================="
echo "Done"
echo ""

# Mounted disks - list
show_mounted_disks() {
    echo "Mounted disks:"
    echo "=================="
    sudo df -h | grep -E "^/dev/" | awk '{print NR ". " $1 " - " $6 " (" $2 ", " $5 " used)"}'
    echo ""
}

# Select disk to scan
scan_disk() {
    local disk_path=$1
    echo "Starting scan $disk_path"
    echo "==================================="
    sudo clamscan -r "$disk_path"
}

# Select folder to scan
choose_folder() {
    read -p "Folder path to scan: " folder_path
    if [ -d "$folder_path" ]; then
        echo "Starting scan $folder_path"
        echo "==================================="
        sudo clamscan -r "$folder_path"
    else
        echo "Error! Path '$folder_path' do not exist"
        exit 1
    fi
}

# Loopy loop
while true; do
    echo "Select:"
    echo "1. Scan mounted disks"
    echo "2. Scan folder"
    echo "3. Exit"
    read -p "Choose (1-3): " choice

    case $choice in
        1)
            show_mounted_disks
            read -p "Choose disk to scan: " disk_choice
            disk_path=$(df -h | grep -E "^/dev/" | awk -v choice="$disk_choice" 'NR==choice {print $6}')
            if [ -n "$disk_path" ]; then
                scan_disk "$disk_path"
                break
            else
                echo "Error! Disk do not exist"
            fi
            ;;
        2)
            choose_folder
            break
            ;;
        3)
            echo "Done"
            exit 0
            ;;
        *)
            echo "Bad choice!"
            ;;
    esac
    echo ""
done