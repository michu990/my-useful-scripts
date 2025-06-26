#!/bin/bash

# VM shared memory script
# michu990
# Version: 1.0

MOUNT_SOURCE="shared"
MOUNT_POINT="/mnt/shared"
DESKTOP_LINK="$HOME/Desktop/shared_folder"  # Dla XFCE

function check_mount_status()
{
    if mountpoint -q "$MOUNT_POINT"; then
        return 0  # zamontowane
    else
        return 1  # niezamontowane
    fi
}

function create_desktop_link()
{
    if [ -L "$DESKTOP_LINK" ]; then
        echo "Symboliczny link już istnieje."
        return 0
    fi
    
    echo "Tworzę symboliczny link na pulpicie..."
    ln -s "$MOUNT_POINT" "$DESKTOP_LINK" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        chmod 755 "$DESKTOP_LINK"
        echo "Utworzono link: $DESKTOP_LINK"
        return 0
    else
        echo "Błąd: Nie udało się utworzyć linku!"
        return 1
    fi
}

function remove_desktop_link()
{
    if [ -L "$DESKTOP_LINK" ]; then
        echo "Usuwam symboliczny link z pulpitu..."
        rm -f "$DESKTOP_LINK"
        [ ! -L "$DESKTOP_LINK" ] && echo "Link usunięty pomyślnie."
    else
        echo "Link nie istnieje."
    fi
}

function mount_folder()
{
    if check_mount_status; then
        echo "Folder jest już podłączony."
        create_desktop_link
        return
    fi
    
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Tworzę punkt montowania $MOUNT_POINT..."
        sudo mkdir -p "$MOUNT_POINT" ||
        {
            echo "Błąd: Nie udało się utworzyć katalogu!"
            return 1
        }
    fi
    
    echo "Podłączam folder..."
    sudo mount -t virtiofs "$MOUNT_SOURCE" "$MOUNT_POINT"
    
    if check_mount_status; then
        echo "Folder został pomyślnie podłączony."
        create_desktop_link
    else
        echo "Błąd: Nie udało się podłączyć folderu."
    fi
}

function unmount_folder()
{
    if ! check_mount_status; then
        echo "Folder nie jest podłączony."
        remove_desktop_link
        return
    fi
    
    echo "Odłączam folder..."
    sudo umount "$MOUNT_POINT"
    
    if ! check_mount_status; then
        echo "Folder został pomyślnie odłączony."
        remove_desktop_link
    else
        echo "Błąd: Nie udało się odłączyć folderu."
    fi
}

function show_status()
{
    echo "===== STATUS ====="
    if check_mount_status; then
        echo -e "Montowanie: \e[32mPODŁĄCZONY\e[0m"
    else
        echo -e "Montowanie: \e[31mODŁĄCZONY\e[0m"
    fi
    
    if [ -L "$DESKTOP_LINK" ]; then
        echo -e "Link na pulpicie: \e[32mISTNIEJE\e[0m"
        echo "Ścieżka linku: $DESKTOP_LINK"
        echo "Wskazuje na: $(readlink -f "$DESKTOP_LINK")"
    else
        echo -e "Link na pulpicie: \e[31mBRAK\e[0m"
    fi
    echo "=================="
}

while true; do
    clear
    echo "==========================================="
    echo " MENU ZARZĄDZANIA FOLDEREM WSPÓLNYM"
    echo "==========================================="
    show_status
    echo "-------------------------------------------"
    echo "1. Podłącz folder (ze stworzeniem linku)"
    echo "2. Odłącz folder (z usunięciem linku)"
    echo "3. Tylko stwórz link na pulpicie"
    echo "4. Tylko usuń link z pulpitu"
    echo "5. Sprawdź status"
    echo "6. Wyjście"
    echo "-------------------------------------------"
    read -p "Wybierz: " choice
    
    case $choice in
        1) mount_folder ;;
        2) unmount_folder ;;
        3) create_desktop_link ;;
        4) remove_desktop_link ;;
        5) show_status ;;
        6) echo "Zamykanie skryptu..."; exit 0 ;;
        *) echo "Nieprawidłowy wybór. Wybierz 1-6." ;;
    esac
    
    read -p "Naciśnij Enter, aby kontynuować..." _
done