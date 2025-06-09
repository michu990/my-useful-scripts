#!/bin/bash

# Style functions
print_text()
{
    local text="$1"
    echo -e "$text"
}

draw_line()
{
    local line_char="${1:-=}"
    local cols=$(tput cols)
    printf "%${cols}s\n" | tr " " "$line_char"
}

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

main_menu()
{
    clear_history
    
    print_menu_header "Select connection:"
    echo -e "$(green "1"). SSH"
    echo -e "$(green "2"). VNC"
    echo -e "$(green "00"). Exit"
    draw_line "-"
    read -p "Select: " connection_mode

    if [[ $connection_mode == "00" ]]; then
        echo
        echo "Exiting..."
        draw_line "-"
        exit 0
    fi

    if [[ $connection_mode -eq 1 ]]; then
        servers=(
            "example1@192.168.1.1 -p 22:example1"
            "example2@192.168.1.2 -p 22:example2"
            "example3@192.168.1.3 -p 22:example3"
            "example4@192.168.1.4 -p 22:example4"  
        )

        show_menu()
        {
            clear_history
            print_menu_header "SSH server list:"
            for i in "${!servers[@]}"; do
                IFS=':' read -ra parts <<< "${servers[$i]}"
                echo -e "$(green "$((i+1))"). ${parts[1]} (${parts[0]})"
            done
            draw_line "-"
            echo -e "$(green "$(( ${#servers[@]} + 1 ))"). Open all servers"
            echo -e "$(green "0"). Return to main menu"
            echo -e "$(green "00"). Exit"
            echo
            echo -e "$(light_blue "To select multiple servers, enter numbers separated by spaces (e.g. 1 3 5)")"
            draw_line "-"
        }

        connect_to_server()
        {
            local index=$1
            IFS=':' read -ra parts <<< "${servers[$index]}"
            gnome-terminal --window --title="${parts[1]}" -- bash -c "ssh ${parts[0]}; exec bash"
        }

        open_selected_servers()
        {
            local choices=($1)
            for choice in "${choices[@]}"; do
                if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#servers[@]} ]]; then
                    echo "Connecting $choice..."
                    connect_to_server $((choice-1))
                    sleep 0.1
                elif [[ $choice == "00" ]]; then
                    echo "Exiting..."
                    draw_line "-"
                    exit 0
                elif [[ $choice == "0" ]]; then
                    main_menu
                    return
                else
                    echo "Wrong choice: $choice. Skipping."
                fi
            done
        }

        open_all_servers()
        {
            for entry in "${servers[@]:0}"; do
                IFS=':' read -ra parts <<< "$entry"
                gnome-terminal --tab --title="${parts[1]}" -- bash -c "ssh ${parts[0]}; exec bash"
                sleep 0.1
            done
        }

        while true; do
            show_menu
            read -p "Select: " input

            if [[ $input == "00" ]]; then
                echo "Leaving..."
                draw_line "-"
                exit 0
            elif [[ $input == "0" ]]; then
                main_menu
                return
            elif [[ $input == $(( ${#servers[@]} + 1 )) ]]; then
                echo "Opening all servers..."
                open_all_servers
                break
            else
                if [[ $input =~ [[:space:]] || $input =~ , ]]; then
                    echo "Opening selected servers..."
                    open_selected_servers "$input"
                elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -ge 1 && $input -le ${#servers[@]} ]]; then
                    echo "Connecting to SSH server $input..."
                    connect_to_server $((input-1))
                else
                    echo "Wrong choice. Try again."
                fi
            fi
        done

    elif [[ $connection_mode -eq 2 ]]; then
        vnc_servers=(
            "192.168.1.1:1:example1"
            "192.168.1.2:1:example2"
            "192.168.1.3:1:example3"
        )

        show_vnc_menu()
        {
            clear_history
            print_menu_header "VNC server list:"
            for i in "${!vnc_servers[@]}"; do
                IFS=':' read -ra parts <<< "${vnc_servers[$i]}"
                echo -e "$(green "$((i+1))"). ${parts[2]} (${parts[0]}:${parts[1]})"
            done
            draw_line "-"
            echo -e "$(green "$(( ${#vnc_servers[@]} + 1 ))"). Open all VNC connections"
            echo -e "$(green "0"). Return to main menu"
            echo -e "$(green "00"). Exit"
            echo
            echo -e "$(light_blue "To select multiple servers, enter numbers separated by spaces (e.g. 1 3 5)")"
            draw_line "-"
        }

        connect_to_vnc()
        {
            local index=$1
            IFS=':' read -ra parts <<< "${vnc_servers[$index]}"
            gnome-terminal --window --title="VNC:${parts[2]}" -- bash -c "vncviewer ${parts[0]}::${parts[1]}; exec bash"
        }

        open_selected_vnc()
        {
            local choices=($1)
            for choice in "${choices[@]}"; do
                if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#vnc_servers[@]} ]]; then
                    echo "Connecting to VNC server $choice..."
                    connect_to_vnc $((choice-1))
                    sleep 0.1
                elif [[ $choice == "00" ]]; then
                    echo "Exiting..."
                    draw_line "-"
                    exit 0
                elif [[ $choice == "0" ]]; then
                    main_menu
                    return
                else
                    echo "Wrong choice: $choice. Skipping."
                fi
            done
        }

        open_all_vnc()
        {
            for entry in "${vnc_servers[@]:0}"; do
                IFS=':' read -ra parts <<< "$entry"
                gnome-terminal --tab --title="VNC:${parts[2]}" -- bash -c "vncviewer ${parts[0]}::${parts[1]}; exec bash"
                sleep 0.1
            done
        }

        while true; do
            show_vnc_menu
            read -p "Select: " input

            if [[ $input == "00" ]]; then
                echo "Exiting..."
                draw_line "-"
                exit 0
            elif [[ $input == "0" ]]; then
                main_menu
                return
            elif [[ $input == $(( ${#vnc_servers[@]} + 1 )) ]]; then
                echo "Opening all VNC connections..."
                open_all_vnc
                break
            else
                if [[ $input =~ [[:space:]] || $input =~ , ]]; then
                    echo "Opening selected VNC connections..."
                    open_selected_vnc "$input"
                elif [[ $input =~ ^[0-9]+$ ]] && [[ $input -ge 1 && $input -le ${#vnc_servers[@]} ]]; then
                    echo "Connecting to VNC server $input..."
                    connect_to_vnc $((input-1))
                else
                    echo "Wrong choice. Try again."
                fi
            fi
        done
    else
        echo "Incorrect choice of connection. Exiting."
        draw_line "-"
        exit 1
    fi
}

main_menu