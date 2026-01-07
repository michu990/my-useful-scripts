#!/bin/bash

# Simple swap script
# michu990

echo "[SWAP]"

# Disabling existing swap file
echo -e "\n[1/7] Disabling swap..."
if sudo swapoff -a; then
    echo "Swap disabled."
else
    echo "Warning: Unable to disable swap (may not exist?). Continuing..."
fi

# Delete old swap file (if exist)
echo -e "\n[2/7] Deleting old swap file..."
if [ -f /swapfile ]; then
    echo "Found /swapfile."
    read -p "Are you sure you want to delete it? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Cancelled. Ending script execution."
        exit 1
    fi
    sudo rm -f /swapfile && echo "Deleted /swapfile."
    
    # Also remove from fstab if it exists there
    if grep -q "/swapfile" /etc/fstab; then
        echo "Removing old /swapfile entry from /etc/fstab..."
        sudo sed -i '\|^/swapfile |d' /etc/fstab
        sudo sed -i '\|^/swapfile$|d' /etc/fstab
    fi
else
    echo "/swapfile does not exist."
fi

# Choosing swap size
echo -e "\n[3/7] Choosing the swap file size..."
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
echo -e "\n[4/7] Creating a swap file (${swap_size}MB)..."
if sudo dd if=/dev/zero of=/swapfile bs=1M count=$swap_size status=progress; then
    echo "Swap file created."
else
    echo "Error: Failed to create swap file!" >&2
    exit 1
fi

# Setting up permissions then init
echo -e "\n[5/7] System configuration..."
sudo chmod 600 /swapfile || exit 1
sudo mkswap /swapfile || exit 1
sudo swapon /swapfile || exit 1

# Add to fstab
echo -e "\n[6/7] Adding to /etc/fstab for persistence after reboot..."
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "Added to /etc/fstab."
else
    echo "/swapfile already exists in /etc/fstab (checking if valid)..."
    # Check if the existing entry is correct
    if grep -q "^/swapfile\s\+none\s\+swap\s\+sw\s\+0\s\+0" /etc/fstab; then
        echo "Valid entry found in /etc/fstab."
    else
        echo "Warning: /swapfile entry exists but may be incorrect."
        echo "Please check /etc/fstab manually."
    fi
fi

# Verify swappiness if desired
echo -e "\n[7/7] Optional: Adjust swappiness value?"
echo "Swappiness controls how often system uses swap (0-100)."
echo "Current value: $(cat /proc/sys/vm/swappiness)"
read -p "Change swappiness? [y/N] " change_swappiness
if [[ "$change_swappiness" =~ ^[Yy]$ ]]; then
    read -p "Enter new swappiness value (0-100, default 60): " new_swappiness
    if [[ "$new_swappiness" =~ ^[0-9]+$ ]] && [ "$new_swappiness" -ge 0 ] && [ "$new_swappiness" -le 100 ]; then
        echo "vm.swappiness=$new_swappiness" | sudo tee /etc/sysctl.d/99-swappiness.conf
        sudo sysctl -w vm.swappiness=$new_swappiness
        echo "Swappiness set to $new_swappiness (will persist after reboot)."
    else
        echo "Invalid value. Keeping current swappiness."
    fi
fi

# End
echo -e "\nDone! Current memory status:"
free -h
echo -e "\nSwap will persist after reboot."
echo "To verify: check that '/swapfile none swap sw 0 0' exists in /etc/fstab"
