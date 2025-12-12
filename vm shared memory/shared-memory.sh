#!/bin/bash

# VM shared memory script
# michu990

MOUNT_SOURCE="shared"
MOUNT_POINT="/mnt/shared"
DESKTOP_LINK="$HOME/Desktop/shared_folder"

function check_mount_status()
{
    if mountpoint -q "$MOUNT_POINT"; then
        return 0  # mounted
    else
        return 1  # unmounted
    fi
}

function create_desktop_link()
{
    if [ -L "$DESKTOP_LINK" ]; then
        echo "Symbolic link exists."
        return 0
    fi
    
    echo "Creating symbolic link on desktop..."
    ln -s "$MOUNT_POINT" "$DESKTOP_LINK" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        chmod 755 "$DESKTOP_LINK"
        echo "Link created: $DESKTOP_LINK"
        return 0
    else
        echo "Error: The link could not be created!"
        return 1
    fi
}

function remove_desktop_link()
{
    if [ -L "$DESKTOP_LINK" ]; then
        echo "Removing the symbolic link from the desktop...."
        rm -f "$DESKTOP_LINK"
        [ ! -L "$DESKTOP_LINK" ] && echo "Link successfully removed."
    else
        echo "The link does not exist."
    fi
}

function mount_folder()
{
    if check_mount_status; then
        echo "Folder is already mounted."
        create_desktop_link
        return
    fi
    
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Creating mount point $MOUNT_POINT..."
        sudo mkdir -p "$MOUNT_POINT" ||
        {
            echo "Error: Failed to create directory!"
            return 1
        }
    fi
    
    echo "Mounting folder..."
    sudo mount -t virtiofs "$MOUNT_SOURCE" "$MOUNT_POINT"
    
    if check_mount_status; then
        echo "Folder has been mounted."
        create_desktop_link
    else
        echo "Error: Failed to mount folder."
    fi
}

function unmount_folder()
{
    if ! check_mount_status; then
        echo "Folder is not mounted."
        remove_desktop_link
        return
    fi
    
    echo "Unmounting folder..."
    sudo umount "$MOUNT_POINT"
    
    if ! check_mount_status; then
        echo "Folder unmounted successfully."
        remove_desktop_link
    else
        echo "Error: Failed to unmount folder."
    fi
}

function show_status()
{
    echo "===== STATUS ====="
    if check_mount_status; then
        echo -e "Mounting: \e[32mMOUNTED\e[0m"
    else
        echo -e "Mounting: \e[31mUNMOUNTED\e[0m"
    fi
    
    if [ -L "$DESKTOP_LINK" ]; then
        echo -e "Desktop link: \e[32mEXIST\e[0m"
        echo "Link path: $DESKTOP_LINK"
        echo "Shows: $(readlink -f "$DESKTOP_LINK")"
    else
        echo -e "Desktop link: \e[31mNULL\e[0m"
    fi
    echo "=================="
}

while true; do
    clear
    echo "==========================================="
    echo " Shared Folder"
    echo "==========================================="
    show_status
    echo "-------------------------------------------"
    echo "1. Connect folder (with link creation)"
    echo "2. Disconnect folder (with link removal)"
    echo "3. Only create link on desktop"
    echo "4. Only remove link from desktop"
    echo "5. Check status"
    echo "6. Exit"
    echo "-------------------------------------------"
    read -p "Choose: " choice
    
    case $choice in
        1) mount_folder ;;
        2) unmount_folder ;;
        3) create_desktop_link ;;
        4) remove_desktop_link ;;
        5) show_status ;;
        6) echo "Exiting..."; exit 0 ;;
        *) echo "Wrong choice. Select 1-6." ;;
    esac
    
    read -p "Press Enter to continue..." _
done