#!/bin/bash

# Command center
# michu990
# Version: 2.0

# Style functions
print_text()
{
    local text="$1"
    echo -e "$text"
}
# Line funtion
draw_line()
{
    local line_char="${1:-=}"
    local cols=$(tput cols)
    printf "%${cols}s\n" | tr " " "$line_char"
}
# Menu header function
print_menu_header()
{
    local title="$1"
    draw_line "-"
    echo -e "$title"
    draw_line "-"
}

# Color functions
green()
{
    echo -e "\033[0;32m$1\033[0m"
}

light_blue()
{
    echo -e "\033[1;36m$1\033[0m"
}

red()
{
    echo -e "\033[0;31m$1\033[0m"
}

# Function to clear terminal history
clear_history()
{
    # For bash
    history -c
    history -w
    # For zsh - not tested
    [ -n "$ZSH_VERSION" ] && history -p
    clear
}

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

# Function to show result of operations
show_result()
{
    if [ $? -eq 0 ]; then
        echo -e "$(green "Operacja zakończona sukcesem!")"
    else
        echo -e "$(red "Operacja zakończona niepowodzeniem!")"
    fi
}

# Deborphan functionality
deborphan_func()
{
    ORPHANS=`deborphan`
    if [ ! -z "$ORPHANS" ]; then
        sudo dpkg --remove $ORPHANS
        show_result
    else
        echo -e "$(green "Brak osieroconych pakietów do usunięcia.")"
    fi

    PURGES=`dpkg --list | grep ^rc | awk '{ print $2; }'`
    if [ ! -z "$PURGES" ]; then
        sudo dpkg --purge $PURGES
        show_result
    else
        echo -e "$(green "Brak pakietów do wyczyszczenia.")"
    fi
}

# SSH-VNC functionality
ssh_vnc_menu()
{
    clear_history
    
    print_menu_header "Wybierz połączenie:"
    echo -e "$(green "1"). SSH"
    echo -e "$(green "2"). VNC"
    echo -e "$(green "0"). Cofnij"
    echo -e "$(green "00"). Wyjdź"
    draw_line "-"
    read -p "Wybierz: " connection_mode

    if [[ $connection_mode == "00" ]]; then
        echo
        echo "Wychodzę..."
        draw_line "-"
        exit 0
    fi

    if [[ $connection_mode == "0" ]]; then
        return
    fi

##############################################################################################################################################################################
#                                                                                                                                                                            #
#                                                                                   ADD SERVERS                                                                              #
#                                                                                                                                                                            #
##############################################################################################################################################################################

    if [[ $connection_mode -eq 1 ]]; then
        servers=(
            "example1@192.168.1.1 -p 22:example1"
            "example2@192.168.1.2 -p 22:example2"
            "example3@192.168.1.3 -p 22:example3"
            "example4@192.168.1.4 -p 22:example4"
        )
        # SSH menu
        show_menu()
        {
            clear_history
            print_menu_header "Lista serwerów SSH:"
            for i in "${!servers[@]}"; do
                IFS=':' read -ra parts <<< "${servers[$i]}"
                echo -e "$(green "$((i+1))"). ${parts[1]} (${parts[0]})"
            done
            draw_line "-"
            echo -e "$(green "$(( ${#servers[@]} + 1 ))"). Otwórz wszystkie serwery"
            echo -e "$(green "0"). Cofnij"
            echo -e "$(green "00"). Wyjdź"
            echo
            echo -e "$(light_blue "Aby wybrać kilka serwerów, wprowadź numery oddzielone spacjami (np. 1 3 5)")"
            draw_line "-"
        }
        # Connecting to server
        connect_to_server()
        {
            local index=$1
            IFS=':' read -ra parts <<< "${servers[$index]}"
            gnome-terminal --window --title="${parts[1]}" -- bash -c "ssh ${parts[0]}; exec bash"
        }
        # Opening selecter servers - then connecting
        open_selected_servers()
        {
            local choices=($1)
            for choice in "${choices[@]}"; do
                if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#servers[@]} ]]; then
                    echo "Łączę z serwerem $choice..."
                    connect_to_server $((choice-1))
                    sleep 0.1
                elif [[ $choice == "00" ]]; then
                    echo "Wychodzę..."
                    draw_line "-"
                    exit 0
                elif [[ $choice == "0" ]]; then
                    return 1
                else
                    echo "Nieprawidłowy wybór: $choice. Pomijam."
                fi
            done
        }
        # Opening all servers
        open_all_servers()
        {
            for entry in "${servers[@]:0}"; do
                IFS=':' read -ra parts <<< "$entry"
                gnome-terminal --tab --title="${parts[1]}" -- bash -c "ssh ${parts[0]}; exec bash"
                sleep 0.1
            done
        }
        # Same but in cli
        while true; do
            show_menu
            read -p "Wybierz: " input

            if [[ $input == "00" ]]; then
                echo "Wychodzę..."
                draw_line "-"
                exit 0
            elif [[ $input == "0" ]]; then
                ssh_vnc_menu
                return
            elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -ge 1 && $input -le ${#servers[@]} ]]; then
                echo "Łączę z serwerem SSH $input..."
                connect_to_server $((input-1))
            else
                echo "Nieprawidłowy wybór. Spróbuj ponownie."
            fi
        done

##############################################################################################################################################################################
#                                                                                                                                                                            #
#                                                                                   ADD SERVERS                                                                              #
#                                                                                                                                                                            #
##############################################################################################################################################################################

    elif [[ $connection_mode -eq 2 ]]; then
        vnc_servers=(
            "192.168.1.1:1:example1"
            "192.168.1.2:1:example2"
            "192.168.1.3:1:example3"
        )
        # VNC menu
        show_vnc_menu()
        {
            clear_history
            print_menu_header "Lista serwerów VNC:"
            for i in "${!vnc_servers[@]}"; do
                IFS=':' read -ra parts <<< "${vnc_servers[$i]}"
                echo -e "$(green "$((i+1))"). ${parts[2]} (${parts[0]}:${parts[1]})"
            done
            draw_line "-"
            echo -e "$(green "$(( ${#vnc_servers[@]} + 1 ))"). Otwórz wszystkie połączenia VNC"
            echo -e "$(green "0"). Cofnij"
            echo -e "$(green "00"). Wyjdź"
            echo
            echo -e "$(light_blue "Aby wybrać kilka serwerów, wprowadź numery oddzielone spacjami (np. 1 3 5)")"
            draw_line "-"
        }
        # Connecting to VNC server
        connect_to_vnc()
        {
            local index=$1
            IFS=':' read -ra parts <<< "${vnc_servers[$index]}"
            gnome-terminal --window --title="VNC:${parts[2]}" -- bash -c "vncviewer ${parts[0]}::${parts[1]}; exec bash"
        }
        # Opening selected VNC servers
        open_selected_vnc()
        {
            local choices=($1)
            for choice in "${choices[@]}"; do
                if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#vnc_servers[@]} ]]; then
                    echo "Łączę z serwerem VNC $choice..."
                    connect_to_vnc $((choice-1))
                    sleep 0.1
                elif [[ $choice == "00" ]]; then
                    echo "Wychodzę..."
                    draw_line "-"
                    exit 0
                elif [[ $choice == "0" ]]; then
                    return 1
                else
                    echo "Nieprawidłowy wybór: $choice. Pomijam."
                fi
            done
        }
        # Opening all VNC servers
        open_all_vnc()
        {
            for entry in "${vnc_servers[@]:0}"; do
                IFS=':' read -ra parts <<< "$entry"
                gnome-terminal --tab --title="VNC:${parts[2]}" -- bash -c "vncviewer ${parts[0]}::${parts[1]}; exec bash"
                sleep 0.1
            done
        }
        # Same but in cli
        while true; do
            show_vnc_menu
            read -p "Wybierz: " input

            if [[ $input == "00" ]]; then
                echo "Wychodzę..."
                draw_line "-"
                exit 0
            elif [[ $input == "0" ]]; then
                ssh_vnc_menu
                return
            elif [[ $input == $(( ${#vnc_servers[@]} + 1 )) ]]; then
                echo "Otwieram wszystkie połączenia VNC..."
                open_all_vnc
                break
            else
                if [[ $input =~ [[:space:]] || $input =~ , ]]; then
                    echo "Otwieram wybrane połączenia VNC..."
                    open_selected_vnc "$input"
                    if [ $? -eq 1 ]; then
                        continue
                    fi
                elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -ge 1 && $input -le ${#vnc_servers[@]} ]]; then
                    echo "Łączę z VNC serwera $input..."
                    connect_to_vnc $((input-1))
                else
                    echo "Nieprawidłowy wybór z listy. Spróbuj ponownie."
                fi
            fi
        done
    else
        echo "Nieprawidłowy wybór połączenia. Spróbuj ponownie."
    fi
}

# APT functionality
apt_menu()
{
    # Function to perform all updates
    perform_all_updates()
    {
        echo -e "\n$(green "=== Rozpoczynanie pełnej aktualizacji systemu ===")"
        
        # Update
        echo -e "\n$(green "[1/4] Update systemu (apt update)...")"
        sudo apt update
        show_result
        
        # Upgrade
        echo -e "\n$(green "[2/4] Upgrade systemu (apt upgrade)...")"
        sudo apt upgrade -y
        show_result
        
        # Autoremove
        echo -e "\n$(green "[3/4] Usuwanie niepotrzebnych pakietów (apt autoremove)...")"
        sudo apt autoremove -y
        show_result
        
        # Autoclean
        echo -e "\n$(green "[4/4] Czyszczenie cache (apt-get autoclean)...")"
        sudo apt-get autoclean
        show_result
        
        echo -e "\n$(green "=== Wszystkie operacje zakończone ===")"
    }
    # Menu choices
    while true; do
        clear_history
        print_menu_header "Zarządzanie pakietami APT:"
        echo -e "$(green "1"). Update systemu (apt update)"
        echo -e "$(green "2"). Upgrade systemu (apt upgrade)"
        echo -e "$(green "3"). Usuń niepotrzebne pakiety (apt autoremove)"
        echo -e "$(green "4"). Wyczyść cache (apt-get autoclean)"
        echo -e "$(green "5"). Wykonaj WSZYSTKIE powyższe operacje (1-4)"
        echo -e "$(green "6"). Usuń osierocone pakiety (deborphan)"
        echo -e "$(green "0"). Cofnij"
        echo -e "$(green "00"). Wyjdź"
        draw_line "-"
        read -p "Wybierz: " choice
        # Choices
        case $choice in
            1)
                echo "Rozpoczynanie update'u systemu..."
                sudo apt update
                show_result
                ;;
            2)
                echo "Rozpoczynanie upgrade'u systemu..."
                sudo apt upgrade
                show_result
                ;;
            3)
                echo "Usuwanie niepotrzebnych pakietów..."
                sudo apt autoremove
                show_result
                ;;
            4)
                echo "Czyszczenie cache..."
                sudo apt-get autoclean
                show_result
                ;;
            5)
                perform_all_updates
                ;;
            6)
                deborphan_func
                ;;
            0)
                return
                ;;
            00)
                echo "Wychodzę..."
                draw_line "-"
                exit 0
                ;;
            *)
                echo -e "$(red "Nieprawidłowy wybór. Wybierz liczbę od 1 do 6.")"
                ;;
        esac

        read -p "Naciśnij Enter, aby kontynuować..."
    done
}

##############################################################################################################################################################################
#                                                                                                                                                                            #
#                                                                                   ADD SERVER                                                                               #
#                                                                                                                                                                            #
##############################################################################################################################################################################

# SSHFS functionality
sshfs_menu()
{
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
            echo -e "$(green "[SUKCES]") Zdalny folder został zamontowany w $(light_blue "$TEMP_FOLDER_PATH")"
        else
            echo -e "$(red "[BŁĄD]") Nie udało się zamontować zdalnego folderu!"
        fi
    }

    # Unmount function
    unmount_sftp()
    {
        if mount | grep -q "$TEMP_FOLDER_PATH"; then
            if fusermount -u "$TEMP_FOLDER_PATH" && rmdir "$TEMP_FOLDER_PATH"; then
                echo -e "$(green "[SUKCES]") Folder został odmontowany i tymczasowy katalog usunięty"
            else
                echo -e "$(red "[BŁĄD]") Nie udało się odmontować folderu!"
            fi
        else
            echo -e "$(light_blue "[INFO]") Folder nie jest obecnie zamontowany"
        fi
    }
    # Menu
    while true; do
        clear_history
        print_menu_header "Zarządzanie połączeniami SSHFS:"
        echo -e "$(green "1"). Zamontuj zdalny folder SFTP"
        echo -e "$(green "2"). Odmontuj zdalny folder"
        echo -e "$(green "0"). Cofnij"
        echo -e "$(green "00"). Wyjdź"
        draw_line "-"
        read -p "Wybierz: " choice
        # Choices
        case $choice in
            1)
                if mount | grep -q "$TEMP_FOLDER_PATH"; then
                    echo -e "$(light_blue "[INFO]") Folder jest już zamontowany!"
                else
                    mount_sftp
                fi
                ;;
            2)
                unmount_sftp
                ;;
            0)
                return
                ;;
            00)
                echo -e "$(green "[SUKCES]") Zamykanie skryptu"
                exit 0
                ;;
            *)
                echo -e "$(red "[BŁĄD]") Nieprawidłowy wybór, spróbuj ponownie"
                ;;
        esac
        
        read -p "Naciśnij Enter, aby kontynuować..."
    done
}

# Network Scanner functionality
network_scanner_menu()
{
    clear_history
    
    # Get the directory where .sh is located
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    SCAN_PY_PATH="$SCRIPT_DIR/scan.py"
    OUTPUT_JSON="$SCRIPT_DIR/network_devices.json"
    
    # Menu
    print_menu_header "Skaner sieci:"
    echo -e "$(green "1"). Skanuj sieć w poszukiwaniu urządzeń"
    echo -e "$(green "2"). Pokaż ostatni wynik skanowania"
    echo -e "$(green "0"). Cofnij"
    echo -e "$(green "00"). Wyjdź"
    draw_line "-"
    read -p "Wybierz: " choice

    # Choices
    case $choice in
        1)
            echo "Rozpoczynanie skanowania sieci..."
            if [ -f "$SCAN_PY_PATH" ]; then
                # Exec scan.py with hardcoded path
                sudo python3 "$SCAN_PY_PATH" --output "$OUTPUT_JSON"
                show_result
            else
                echo -e "$(red "Błąd: Nie znaleziono pliku scan.py w ścieżce: $SCAN_PY_PATH")"
            fi
            ;;
        2)
            if [ -f "$OUTPUT_JSON" ]; then
                echo "Ostatni wynik skanowania:"
                sudo python3 -c "import json; data=json.load(open('$OUTPUT_JSON')); print(json.dumps(data, indent=4, ensure_ascii=False))"
            else
                echo -e "$(red "Brak pliku z wynikiem skanowania. Najpierw wykonaj skanowanie.")"
            fi
            ;;
        0)
            return
            ;;
        00)
            echo "Wychodzę..."
            draw_line "-"
            exit 0
            ;;
        *)
            echo -e "$(red "Nieprawidłowy wybór. Spróbuj ponownie.")"
            ;;
    esac
    
    read -p "Naciśnij Enter, aby kontynuować..."
}

# Security functionality
security_main_menu()
{
    clear_history
    
    print_menu_header "Narzędzia bezpieczeństwa systemu:"
    echo -e "$(green "1"). Skanowanie antywirusowe (ClamAV)"
    echo -e "$(green "2"). Skanowanie rootkitów (rkhunter)"
    echo -e "$(green "3"). Skanowanie rootkitów (chkrootkit)"
    echo -e "$(green "4"). Audyt bezpieczeństwa (Lynis)"
    echo -e "$(green "5"). Narzędzia systemowe"
    echo -e "$(green "0"). Cofnij"
    echo -e "$(green "00"). Wyjdź"
    draw_line "-"
    read -p "Wybierz: " choice
    #Menu
    case $choice in
        1) clamav_menu ;;
        2) run_rkhunter ;;
        3) run_chkrootkit ;;
        4) run_lynis ;;
        5) system_tools_menu ;;
        0) return ;;
        00)
            echo "Wychodzę..."
            draw_line "-"
            exit 0
            ;;
        *) 
            echo -e "$(red "Nieprawidłowy wybór!")"
            sleep 1
            ;;
    esac
    
    security_main_menu
}

# ClamAV menu
clamav_menu()
{
    clear_history
    
    print_menu_header "Skanowanie antywirusowe ClamAV:"
    echo -e "$(green "1"). Skanuj określony folder"
    echo -e "$(green "2"). Skanuj cały system"
    echo -e "$(green "3"). Skanuj bieżącą lokalizację"
    echo -e "$(green "4"). Skanuj nowe/zmodyfikowane pliki"
    echo -e "$(green "5"). Aktualizuj sygnatury wirusów"
    echo -e "$(green "0"). Cofnij"
    echo -e "$(green "00"). Wyjdź"
    draw_line "-"
    read -p "Wybierz: " choice

    case $choice in
        1)
            read -p "Podaj ścieżkę folderu: " folder
            if [ -d "$folder" ]; then
                sudo clamscan -r --bell "$folder"
                show_result
            else
                echo -e "$(red "Folder nie istnieje!")"
            fi
            ;;
        2)
            echo "Rozpoczynanie skanowania całego systemu..."
            sudo clamscan -r --bell /
            show_result
            ;;
        3)
            echo "Rozpoczynanie skanowania bieżącej lokalizacji..."
            sudo clamscan -r --bell .
            show_result
            ;;
        4)
            echo "Skanowanie nowych/zmodyfikowanych plików..."
            sudo find / -type f -mtime -7 -exec clamscan -r --bell {} +
            show_result
            ;;
        5)
            echo "Aktualizowanie sygnatur wirusów..."
            sudo freshclam
            show_result
            ;;
        0)
            return
            ;;
        00)
            echo "Wychodzę..."
            draw_line "-"
            exit 0
            ;;
        *)
            echo -e "$(red "Nieprawidłowy wybór!")"
            sleep 1
            ;;
    esac
    
    read -p "Naciśnij Enter, aby kontynuować..."
    clamav_menu
}

# rkhunter menu
run_rkhunter()
{
    echo "Aktualizowanie bazy rkhunter..."
    sudo rkhunter --update
    show_result
    
    echo "Rozpoczynanie skanowania..."
    sudo rkhunter --check --sk
    show_result
    
    read -p "Naciśnij Enter, aby kontynuować..."
}

# chrootkit menu
run_chkrootkit()
{
    echo "Rozpoczynanie skanowania chkrootkit..."
    sudo chkrootkit
    show_result
    
    read -p "Naciśnij Enter, aby kontynuować..."
}

# Lynis menu
run_lynis()
{
    echo "Rozpoczynanie audytu Lynis..."
    sudo lynis audit system
    show_result
    
    read -p "Naciśnij Enter, aby kontynuować..."
}

# system tools menu
system_tools_menu()
{
    clear_history
    
    print_menu_header "Narzędzia systemowe:"
    echo -e "$(green "1"). Sprawdź otwarte połączenia"
    echo -e "$(green "2"). Sprawdź firewall (ufw)"
    echo -e "$(green "3"). Sprawdź usługi systemd"
    echo -e "$(green "0"). Cofnij"
    echo -e "$(green "00"). Wyjdź"
    draw_line "-"
    read -p "Wybierz: " choice

    case $choice in
        1)
            echo "Sprawdzanie otwartych połączeń..."
            sudo netstat -tulnp
            ;;
        2)
            echo "Sprawdzanie statusu firewalla..."
            sudo ufw status verbose
            ;;
        3)
            echo "Lista usług systemd:"
            echo -e "$(green "Usługi aktywne:")"
            sudo systemctl list-units --type=service --state=active
            echo -e "$(green "Usługi nieaktywne:")"
            sudo systemctl list-units --type=service --state=inactive
            ;;
        0)
            return
            ;;
        00)
            echo "Wychodzę..."
            draw_line "-"
            exit 0
            ;;
        *)
            echo -e "$(red "Nieprawidłowy wybór!")"
            sleep 1
            ;;
    esac
    
    read -p "Naciśnij Enter, aby kontynuować..."
    system_tools_menu
}

# Main menu
main_menu()
{
    while true; do
        clear_history
        print_menu_header "Menu główne:"
        echo -e "$(green "1"). Zarządzanie połączeniami SSH/VNC"
        echo -e "$(green "2"). Zarządzanie pakietami APT"
        echo -e "$(green "3"). Zarządzanie połączeniami SSHFS"
        echo -e "$(green "4"). Skaner sieci"
        echo -e "$(green "5"). Narzędzia bezpieczeństwa"
        echo -e "$(green "00"). Wyjdź"
        draw_line "-"
        read -p "Wybierz: " choice

        case $choice in
            1) ssh_vnc_menu ;;
            2) apt_menu ;;
            3) sshfs_menu ;;
            4) network_scanner_menu ;;
            5) security_main_menu ;;
            00) exit 0 ;;
            *) echo "Nieprawidłowy wybór!"; sleep 1 ;;
        esac
    done
}

# Start
main_menu