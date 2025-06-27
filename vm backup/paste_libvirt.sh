#!/bin/bash

# VM copy-paste script
# michu990
# Version: 1.0

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

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
    echo -e "$(green "Kopiowanie do /var/lib/libvirt")"
    draw_line "-"
}

# Select path
function select_source()
{
    local selected_path=""
    local current_level=0
    local current_paths=()

    # Mounted disks
    function get_mounted_disks()
    {
        echo -e "$(green "Lista zamontowanych dysków:")"
        mapfile -t disks < <(sudo lsblk -o MOUNTPOINT -n -l | grep -v "^$\|^[[:space:]]*$" | sort -u)
        for i in "${!disks[@]}"; do
            echo -e "$(green "$((i+1))"). ${disks[$i]}"
        done
        echo -e "$(green "0"). Wybierz"
        echo -e "$(green "00"). Anuluj"
        draw_line "-"
    }

    # Folder ls
    function show_folder_content()
    {
        local path="$1"
        echo -e "$(green "Zawartość: $path")"
        mapfile -t content < <(sudo ls -1 "$path" 2>/dev/null)
        
        if [ ${#content[@]} -eq 0 ]; then
            echo -e "$(red "Folder jest pusty")"
        else
            for i in "${!content[@]}"; do
                if [ -d "$path/${content[$i]}" ]; then
                    echo -e "$(green "$((i+1))"). ${content[$i]}/"
                else
                    echo -e "$(light_blue "$((i+1))"). ${content[$i]}"
                fi
            done
        fi
        
        echo -e "$(green "0"). Wybierz"
        echo -e "$(green "00"). Wróć"
        draw_line "-"
    }

    # Main choice
    while true; do
        clear_history

        if [ $current_level -eq 0 ]; then
            get_mounted_disks
            read -p "Wybierz: " selection

            case $selection in
                0)
                    if [ -n "$selected_path" ]; then
                        source_path="$selected_path"
                        return
                    else
                        echo -e "$(red "Nie wybrano żadnej ścieżki!")"
                        sleep 2
                    fi
                    ;;
                00)
                    echo "Anulowano operację."
                    exit 0
                    ;;
                *)
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#disks[@]} ]; then
                        current_path="${disks[$((selection-1))]}"
                        current_level=1
                        current_paths=("$current_path")
                        selected_path="$current_path"
                    else
                        echo -e "$(red "Nieprawidłowy wybór!")"
                        sleep 1
                    fi
                    ;;
            esac
        else
            current_path="${current_paths[$((current_level-1))]}"
            show_folder_content "$current_path"
            read -p "Wybierz element: " selection

            case $selection in
                0)
                    source_path="$current_path"
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
                                echo -e "$(red "To nie jest folder!")"
                                sleep 1
                            fi
                        else
                            echo -e "$(red "Nieprawidłowy wybór!")"
                            sleep 1
                        fi
                    else
                        echo -e "$(red "Nieprawidłowy wybór!")"
                        sleep 1
                    fi
                    ;;
            esac
        fi
    done
}

# Calling function
select_source

# Check if folder exist - if not make one
if [ ! -d "/var/lib/libvirt" ]; then
    echo -e "$(red "Folder docelowy /var/lib/libvirt nie istnieje. Tworzenie...")"
    sudo mkdir -p /var/lib/libvirt
    sudo chown root:root /var/lib/libvirt
    sudo chmod 755 /var/lib/libvirt
fi

# Confirm
clear_history
echo -e "$(green "Wybrana ścieżka źródłowa:") $source_path"
echo -e "$(green "Folder docelowy:") /var/lib/libvirt"
read -p "Czy chcesz kontynuować kopiowanie? [Y/n] " confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
    echo -e "$(red "Anulowano.")"
    exit 0
fi

# CP
echo -e "$(green "Kopiowanie zawartości $source_path do /var/lib/libvirt")"
total_size=$(sudo du -sb "$source_path" | cut -f1)
(
    cd "$source_path"
    sudo tar cf - . | pv -s $total_size | (cd /var/lib/libvirt && sudo tar xf -)
)

# Idk if needed
#sudo chown -R root:root /var/lib/libvirt
#sudo chmod -R 755 /var/lib/libvirt

# Basic cp check
if [ $? -eq 0 ]; then
    echo -e "$(green "Kopiowanie zakończone pomyślnie.")"
else
    echo -e "$(red "Wystąpił błąd podczas kopiowania.")"
    exit 1
fi

exit 0