#!/bin/bash

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

# Connection info
SFTP_HOST="x.x.x.x"
SFTP_USER="user"
SFTP_REMOTE_PATH="/path/to/folder"

DESKTOP_PATH="$HOME/Desktop"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_FOLDER_NAME="mounted_sftp_$TIMESTAMP"
TEMP_FOLDER_PATH="$DESKTOP_PATH/$TEMP_FOLDER_NAME"

# Mount function
mount_sftp()
{
    mkdir -p "$TEMP_FOLDER_PATH"
    if sshfs "$SFTP_USER@$SFTP_HOST:$SFTP_REMOTE_PATH" "$TEMP_FOLDER_PATH"; then
        echo -e "\e[32m[SUKCES]\e[0m Zdalny folder został zamontowany w \e[34m$TEMP_FOLDER_PATH\e[0m"
    else
        echo -e "\e[31m[BŁĄD]\e[0m Nie udało się zamontować zdalnego folderu!"
    fi
}

# Unmount function
unmount_sftp()
{
    if mount | grep -q "$TEMP_FOLDER_PATH"; then
        if fusermount -u "$TEMP_FOLDER_PATH" && rmdir "$TEMP_FOLDER_PATH"; then
            echo -e "\e[32m[SUKCES]\e[0m Folder został odmontowany i tymczasowy katalog usunięty"
        else
            echo -e "\e[31m[BŁĄD]\e[0m Nie udało się odmontować folderu!"
        fi
    else
        echo -e "\e[33m[INFO]\e[0m Folder nie jest obecnie zamontowany"
    fi
}

# main menu
while true; do
    echo -e "\e[32m1\e[0m. Zamontuj zdalny folder SFTP"
    echo -e "\e[32m2\e[0m. Odmontuj zdalny folder"
    echo -e "\e[32m3\e[0m. Wyjdź"
    echo ""
    read -p "Wybierz opcję (1-3): " choice

    case $choice in
        1)
            if mount | grep -q "$TEMP_FOLDER_PATH"; then
                echo -e "\e[33m[INFO]\e[0m Folder jest już zamontowany!"
            else
                mount_sftp
            fi
            ;;
        2)
            unmount_sftp
            ;;
        3)
            echo -e "\e[32m[SUKCES]\e[0m Zamykanie skryptu"
            exit 0
            ;;
        *)
            echo -e "\e[31m[BŁĄD]\e[0m Nieprawidłowy wybór, spróbuj ponownie"
            ;;
    esac
done