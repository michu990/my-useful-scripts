#!/bin/bash

# Simple swap script
# michu990

echo "[SWAP]"

# Disabling existing swap file
echo -e "\n[1/6] Disabling swap..."
if sudo swapoff -a; then
    echo "Swap disabled."
else
    echo "Warning: Unable to disable swap (may not exist?). Continuing..."
fi

# Delete old swap file (if exist)
echo -e "\n[2/6] Deleting old swap file..."
if [ -f /swapfile ]; then
    echo "Found /swapfile."
    read -p "Are you sure you want to delete it? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Cancelled. Ending script execution."
        exit 1
    fi
    sudo rm -f /swapfile && echo "Deleted /swapfile."
else
    echo "/swapfile does not exist."
fi

# Choosing swap size
echo -e "\n[3/6] Choosing the swap file size..."
echo "Available options:"
echo "1) 2GB"
echo "2) 4GB"
echo "3) 8GB"
echo "4) 16GB"
echo "5) 32GB"
echo "6) Custom (enter manually)"

while true; do
    read -p "Choose (1-6): " option
    case $option in
        1) swap_size=2048; break;;
        2) swap_size=4096; break;;
        3) swap_size=8192; break;;
        4) swap_size=16384; break;;
        5) swap_size=32768; break;;
        6)
            while true; do
                read -p "Enter the swap file size in MB (4096 = 4GB etc.): " swap_size
                if [[ "$swap_size" =~ ^[0-9]+$ ]] && [ "$swap_size" -ge 1 ]; then
                    break 2
                else
                    echo "Error: Please enter a valid integer (minimum 1MB)!"
                fi
            done
            ;;
        *) echo "Wrong choice. Select 1-6.";;
    esac
done

# Making swap file
echo -e "\n[4/6] Creating a swap file (${swap_size}MB)..."
if sudo dd if=/dev/zero of=/swapfile bs=1M count=$swap_size status=progress; then
    echo "Swap file created."
else
    echo "Error: Failed to create swap file!" >&2
    exit 1
fi

# Setting up permissions then init
echo -e "\n[5/6] System configuration..."
sudo chmod 600 /swapfile || exit 1
sudo mkswap /swapfile || exit 1
sudo swapon /swapfile || exit 1

# End
echo -e "\n[6/6] Done! Current memory status:"
free -h

# Add to /etc/fstab (??)
echo -e "\nTo keep the swap active after a reboot, add to /etc/fstab:"
echo "/swapfile none swap sw 0 0"