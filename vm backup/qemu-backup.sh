#!/bin/bash

# VM copy/paste script
# michu990

# Colors
function draw_line()
{
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' "$1"
}

function green()
{
    echo -e "\033[1;32m$1\033[0m"
}

function red()
{
    echo -e "\033[1;31m$1\033[0m"
}

function light_blue()
{
    echo -e "\033[1;34m$1\033[0m"
}

function clear_history()
{
    clear
    draw_line "-"
    if [ "$script_mode" = "paste" ]; then
        echo -e "$(green "Copying to /var/lib/libvirt")"
    else
        echo -e "$(green "Backup /var/lib/libvirt")"
    fi
    draw_line "-"
}

# Select path
function select_path()
{
    local selected_path=""
    local current_level=0
    local current_paths=()

    # Mounted disks
    function get_mounted_disks()
    {
        echo -e "$(green "List of mounted disks:")"
        mapfile -t disks < <(sudo lsblk -o MOUNTPOINT -n -l | grep -v "^$\|^[[:space:]]*$" | sort -u)
        for i in "${!disks[@]}"; do
            free_space=$(sudo df -h "${disks[$i]}" | awk 'NR==2 {print $4}')
            echo -e "$(green "$((i+1))"). ${disks[$i]} (Free: $free_space)"
        done
        echo -e "$(green "0"). Select"
        echo -e "$(green "00"). Cancel"
        draw_line "-"
    }

    # Folder ls
    function show_folder_content()
    {
        local path="$1"
        echo -e "$(green "Content: $path")"
        mapfile -t content < <(sudo ls -1 "$path" 2>/dev/null)
        
        if [ ${#content[@]} -eq 0 ]; then
            echo -e "$(red "Folder is empty")"
        else
            for i in "${!content[@]}"; do
                if [ -d "$path/${content[$i]}" ]; then
                    echo -e "$(green "$((i+1))"). ${content[$i]}/"
                else
                    echo -e "$(light_blue "$((i+1))"). ${content[$i]}"
                fi
            done
        fi
        
        echo -e "$(green "0"). Select"
        echo -e "$(green "00"). Go back"
        draw_line "-"
    }

    # Main choice
    while true; do
        clear_history

        if [ $current_level -eq 0 ]; then
            get_mounted_disks
            read -p "Choose: " selection

            case $selection in
                0)
                    if [ -n "$selected_path" ]; then
                        if [ "$script_mode" = "paste" ]; then
                            source_path="$selected_path"
                        else
                            destination_path="$selected_path"
                        fi
                        return
                    else
                        echo -e "$(red "No path selected!")"
                        sleep 2
                    fi
                    ;;
                00)
                    echo "Operation cancelled."
                    exit 0
                    ;;
                *)
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#disks[@]} ]; then
                        current_path="${disks[$((selection-1))]}"
                        current_level=1
                        current_paths=("$current_path")
                        selected_path="$current_path"
                    else
                        echo -e "$(red "Invalid choice!")"
                        sleep 1
                    fi
                    ;;
            esac
        else
            current_path="${current_paths[$((current_level-1))]}"
            show_folder_content "$current_path"
            read -p "Choose element: " selection

            case $selection in
                0)
                    if [ "$script_mode" = "paste" ]; then
                        source_path="$current_path"
                    else
                        destination_path="$current_path"
                    fi
                    return
                    ;;
                00)
                    current_level=$((current_level-1))
                    current_paths=("${current_paths[@]:0:$current_level}")
                    selected_path="${current_paths[$((current_level-1))]}"
                    ;;
                *)
                    if [[ "$selection" =~ ^[0-9]+$ ]]; then
                        mapfile -t content < <(sudo ls -1 "$current_path" 2>/dev/null)
                        if [ "$selection" -ge 1 ] && [ "$selection" -le ${#content[@]} ]; then
                            selected_item="${content[$((selection-1))]}"
                            new_path="$current_path/$selected_item"
                            if [ -d "$new_path" ]; then
                                current_level=$((current_level+1))
                                current_paths+=("$new_path")
                                selected_path="$new_path"
                            else
                                echo -e "$(red "This is not a folder!")"
                                sleep 1
                            fi
                        else
                            echo -e "$(red "Invalid choice!")"
                            sleep 1
                        fi
                    else
                        echo -e "$(red "Invalid choice!")"
                        sleep 1
                    fi
                    ;;
            esac
        fi
    done
}

# Main script logic
if [ "$1" = "copy" ]; then
    script_mode="copy"
    
    # Calling function
    select_path

    # Check if folder exist
    if [ ! -d "/var/lib/libvirt" ]; then
        echo -e "$(red "Source folder /var/lib/libvirt does not exist.")"
        exit 1
    fi

    # Confirm
    clear_history
    echo -e "$(green "Selected destination path:") $destination_path"
    read -p "Do you want to continue copying? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo -e "$(red "Cancelled.")"
        exit 0
    fi

    # CP
    echo -e "$(green "Copying content from /var/lib/libvirt to $destination_path")"
    total_size=$(sudo du -sb /var/lib/libvirt | cut -f1)
    (
        cd /var/lib/libvirt
        sudo tar cf - . | pv -s $total_size | (cd "$destination_path" && sudo tar xf -)
    )

    # Basic cp check
    if [ $? -eq 0 ]; then
        echo -e "$(green "Copying completed successfully.")"
    else
        echo -e "$(red "An error occurred during copying.")"
        exit 1
    fi

elif [ "$1" = "paste" ]; then
    script_mode="paste"
    
    # Calling function
    select_path

    # Check if folder exist - if not make one
    if [ ! -d "/var/lib/libvirt" ]; then
        echo -e "$(red "Destination folder /var/lib/libvirt does not exist. Creating...")"
        sudo mkdir -p /var/lib/libvirt
        sudo chown root:root /var/lib/libvirt
        sudo chmod 755 /var/lib/libvirt
    fi

    # Confirm
    clear_history
    echo -e "$(green "Selected source path:") $source_path"
    echo -e "$(green "Destination folder:") /var/lib/libvirt"
    read -p "Do you want to continue copying? [Y/n] " confirm
    if [ "$confirm" =~ ^[Nn] ]; then
        echo -e "$(red "Cancelled.")"
        exit 0
    fi

    # CP
    echo -e "$(green "Copying content from $source_path to /var/lib/libvirt")"
    total_size=$(sudo du -sb "$source_path" | cut -f1)
    (
        cd "$source_path"
        sudo tar cf - . | pv -s $total_size | (cd /var/lib/libvirt && sudo tar xf -)
    )

    # Basic cp check
    if [ $? -eq 0 ]; then
        echo -e "$(green "Copying completed successfully.")"
    else
        echo -e "$(red "An error occurred during copying.")"
        exit 1
    fi

else
    echo "Usage: $0 {copy|paste}"
    echo "  copy  - Backup /var/lib/libvirt to selected destination"
    echo "  paste - Copy from selected source to /var/lib/libvirt"
    exit 1
fi

exit 0
