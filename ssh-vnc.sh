#!/bin/bash

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

main_menu() {
    # Original code with additional exit option
    echo "Wybierz połączenie:"
    echo "1. SSH"
    echo "2. VNC"
    echo "00. Wyjdź"
    read -p "Wybór (0-2): " connection_mode

    # Handle exit option
    if [[ $connection_mode == "00" ]]; then
        echo "Wychodzę..."
        exit 0
    fi

    #######################################################################
    # SSH section
    #######################################################################

    if [[ $connection_mode -eq 1 ]]; then
        #SSH
        #Server list
        servers=(
            "example1@192.168.1.1 -p 22:example1"
            "example2@192.168.1.2 -p 22:example2"
            "example3@192.168.1.3 -p 22:example3"
            "example4@192.168.1.4 -p 22:example4"  
        )

        #Server list function
        show_menu()
        {
            echo "Lista serwerów SSH:"
            for i in "${!servers[@]}";
            do
                IFS=':' read -ra parts <<< "${servers[$i]}"
                echo "$((i+1)). ${parts[1]} (${parts[0]})"
            done
            echo "$(( ${#servers[@]} + 1 )). Otwórz wszystkie serwery"
            echo "0. Powrót do menu głównego"
            echo "00. Wyjdź"
        }

        #Server connection function
        connect_to_server()
        {
            local index=$1
            IFS=':' read -ra parts <<< "${servers[$index]}"
            gnome-terminal --window --title="${parts[1]}" -- bash -c "ssh ${parts[0]}; exec bash"
        }

        #Open all function
        open_all_servers()
        {
        #Next in line
            for entry in "${servers[@]:0}"; 
            do
                IFS=':' read -ra parts <<< "$entry"
                gnome-terminal --tab --title="${parts[1]}" -- bash -c "ssh ${parts[0]}; exec bash"
                sleep 0.1
            done
        }

        #Main program loop
        while true; 
        do
            show_menu
            read -p "Wybierz: " choice

            if [[ $choice == "00" ]];
            then
                echo "Wychodzę..."
                exit 0
            elif [[ $choice -eq 0 ]];
            then
                main_menu
                return
            elif [[ $choice -eq $(( ${#servers[@]} + 1 )) ]];
            then
                echo "Otwieram wszystkie serwery..."
                open_all_servers
                break
            elif [[ $choice -ge 1 && $choice -le ${#servers[@]} ]];
            then
                echo "Łączę z serwerem $choice..."
                connect_to_server $((choice-1))
            else
                echo "Nieprawidłowy wybór. Spróbuj ponownie."
            fi
        done

    #######################################################################
    # VNC section
    #######################################################################

    elif [[ $connection_mode -eq 2 ]]; then
        #VNC
        #VNC server list
        vnc_servers=(
            "192.168.1.1:1:example1"
            "192.168.1.2:1:example2"
            "192.168.1.3:1:example3"
        )

        #VNC list function
        show_vnc_menu()
        {
            echo "Lista serwerów VNC:"
            for i in "${!vnc_servers[@]}";
            do
                IFS=':' read -ra parts <<< "${vnc_servers[$i]}"
                echo "$((i+1)). ${parts[2]} (${parts[0]}:${parts[1]})"
            done
            echo "$(( ${#vnc_servers[@]} + 1 )). Otwórz wszystkie połączenia VNC"
            echo "0. Powrót do menu głównego"
            echo "00. Wyjdź"
        }

        #VNC connection function
        connect_to_vnc()
        {
            local index=$1
            IFS=':' read -ra parts <<< "${vnc_servers[$index]}"
            gnome-terminal --window --title="VNC:${parts[2]}" -- bash -c "vncviewer ${parts[0]}::${parts[1]}; exec bash"
        }

        #Open all VNC function
        open_all_vnc()
        {
            for entry in "${vnc_servers[@]:0}"; 
            do
                IFS=':' read -ra parts <<< "$entry"
                gnome-terminal --tab --title="VNC:${parts[2]}" -- bash -c "vncviewer ${parts[0]}::${parts[1]}; exec bash"
                sleep 0.1
            done
        }

        #Main VNC program loop
        while true;
        do
            show_vnc_menu
            read -p "Wybierz: " choice

            if [[ $choice == "00" ]];
            then
                echo "Wychodzę..."
                exit 0
            elif [[ $choice -eq 0 ]];
            then
                main_menu
                return
            elif [[ $choice -eq $(( ${#vnc_servers[@]} + 1 )) ]];
            then
                echo "Otwieram wszystkie połączenia VNC..."
                open_all_vnc
                break
            elif [[ $choice -ge 1 && $choice -le ${#vnc_servers[@]} ]];
            then
                echo "Łączę z VNC serwera $choice..."
                connect_to_vnc $((choice-1))
            else
                echo "Nieprawidłowy wybór z listy. Spróbuj ponownie."
            fi
        done
    else
        echo "Nieprawidłowy wybór połączenia. Kończę działanie."
        exit 1
    fi
}

# Start the main menu
main_menu