#!/bin/bash

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

# Color definitions
GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[0;31m'

# Function to display success/failure
show_result()
{
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Operacja zakończona sukcesem!${NC}"
    else
        echo -e "${RED}Operacja zakończona niepowodzeniem!${NC}"
    fi
}

# Function to perform all updates
perform_all_updates()
{
    echo -e "\n${GREEN}=== Rozpoczynanie pełnej aktualizacji systemu ===${NC}"
    
    # 1. Update
    echo -e "\n${GREEN}[1/4] Update systemu (apt update)...${NC}"
    sudo apt update
    show_result
    
    # 2. Upgrade
    echo -e "\n${GREEN}[2/4] Upgrade systemu (apt upgrade)...${NC}"
    sudo apt upgrade -y
    show_result
    
    # 3. Autoremove
    echo -e "\n${GREEN}[3/4] Usuwanie niepotrzebnych pakietów (apt autoremove)...${NC}"
    sudo apt autoremove -y
    show_result
    
    # 4. Autoclean
    echo -e "\n${GREEN}[4/4] Czyszczenie cache (apt-get autoclean)...${NC}"
    sudo apt-get autoclean
    show_result
    
    echo -e "\n${GREEN}=== Wszystkie operacje zakończone ===${NC}"
}

# Menu function
show_menu() 
{
    clear
    echo "Wybierz opcję:"
    echo -e "${GREEN}1${NC}. Update systemu (apt update)"
    echo -e "${GREEN}2${NC}. Upgrade systemu (apt upgrade)"
    echo -e "${GREEN}3${NC}. Usuń niepotrzebne pakiety (apt autoremove)"
    echo -e "${GREEN}4${NC}. Wyczyść cache (apt-get autoclean)"
    echo -e "${GREEN}5${NC}. Wykonaj WSZYSTKIE powyższe operacje (1-4)"
    echo -e "${GREEN}6${NC}. Wyjdź"
}

# Main loop
while true; do
    show_menu
    read -p "Wybór (1-6): " choice

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
            echo "Zamykanie skryptu."
            exit 0
            ;;
        *)
            echo -e "${RED}Nieprawidłowy wybór. Wybierz liczbę od 1 do 6.${NC}"
            sleep 1
            ;;
    esac

    # Wait for user to press Enter
    read -p "Naciśnij Enter, aby kontynuować..."
done