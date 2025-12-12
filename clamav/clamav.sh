#!/bin/bash

# AV menu script
# michu990

echo "ClamAV database update"

# New database
echo "2. Starting freshclam"
sudo freshclam

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

# Function to navigate and select folders
navigate_and_select_folders() {
    current_dir="/"
    selected_folders=()
    
    while true; do
        clear
        echo "Current directory: $current_dir"
        echo "========================================="
        echo "0. Select current directory"
        echo "1. Go to parent directory"
        echo "========================================="
        
        # List directories
        echo "Available directories:"
        echo "----------------------"
        count=2
        declare -a dir_array
        
        # List only directories
        while IFS= read -r dir; do
            if [ -d "$current_dir/$dir" ]; then
                echo "$count. $dir/"
                dir_array[$count]="$dir"
                ((count++))
            fi
        done < <(sudo ls -1 "$current_dir" 2>/dev/null)
        
        # List selected folders if any
        if [ ${#selected_folders[@]} -gt 0 ]; then
            echo ""
            echo "========================================="
            echo "Selected folders:"
            for ((i=0; i<${#selected_folders[@]}; i++)); do
                echo "  ${selected_folders[$i]}"
            done
            echo "========================================="
        fi
        
        echo ""
        echo "Options:"
        echo "s - Start scanning selected folders"
        echo "c - Clear all selected folders"
        echo "q - Cancel and exit"
        echo ""
        read -p "Choose directory or option (0-$((count-1)) or s/c/q): " choice
        
        case $choice in
            0)
                # Select current directory
                selected_folders+=("$current_dir")
                echo "Added: $current_dir"
                sleep 1
                ;;
            1)
                # Go to parent directory
                if [ "$current_dir" != "/" ]; then
                    current_dir=$(dirname "$current_dir")
                fi
                ;;
            s)
                # Start scanning
                if [ ${#selected_folders[@]} -eq 0 ]; then
                    echo "No folders selected!"
                    sleep 1
                    continue
                fi
                
                echo ""
                echo "Starting scan of ${#selected_folders[@]} folder(s)..."
                echo "========================================="
                
                for folder in "${selected_folders[@]}"; do
                    echo ""
                    echo "==================================="
                    echo "Scanning: $folder"
                    echo "==================================="
                    sudo clamscan -r "$folder"
                    echo ""
                done
                
                read -p "Press Enter to continue..."
                return 0
                ;;
            c)
                # Clear selection
                selected_folders=()
                echo "Selection cleared"
                sleep 1
                ;;
            q)
                # Cancel
                echo "Cancelled"
                return 1
                ;;
            [0-9]*)
                # Check if it's a valid number choice
                if [ "$choice" -ge 2 ] && [ "$choice" -lt "$count" ]; then
                    selected_dir="${dir_array[$choice]}"
                    if [ -n "$selected_dir" ]; then
                        if [ "$current_dir" = "/" ]; then
                            current_dir="/$selected_dir"
                        else
                            current_dir="$current_dir/$selected_dir"
                        fi
                    fi
                else
                    echo "Invalid choice!"
                    sleep 1
                fi
                ;;
            *)
                echo "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# Loopy loop
while true; do
    echo "Select:"
    echo "1. Scan mounted disks"
    echo "2. Scan folder(s) - Interactive selection"
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
            navigate_and_select_folders
            # Don't break here, allow returning to main menu after scanning
            echo ""
            read -p "Press Enter to return to main menu..."
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