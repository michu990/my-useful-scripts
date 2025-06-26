#!/bin/bash

# Simple swap script
# michu990
# Version: 2.0

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

echo "[Tworzenie pliku swap]"

# Disabling existing swap file
echo -e "\n[1/6] Wyłączanie swap..."
if sudo swapoff -a; then
    echo "Swap wyłączony."
else
    echo "Uwaga: Nie udało się wyłączyć swap (może nie istnieć?). Kontynuowanie..."
fi

# Delete old swap file (if exist)
echo -e "\n[2/6] Usuwanie starego pliku swap..."
if [ -f /swapfile ]; then
    echo "Znaleziono istniejący /swapfile."
    read -p "Czy na pewno chcesz go usunąć? [T/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Anulowano. Kończenie działania skryptu."
        exit 1
    fi
    sudo rm -f /swapfile && echo "Usunięto /swapfile."
else
    echo "Brak istniejącego pliku /swapfile."
fi

# Choosing swap size
echo -e "\n[3/6] Wybór rozmiaru pliku swap..."
echo "Dostępne opcje:"
echo "1) 2GB"
echo "2) 4GB"
echo "3) 8GB"
echo "4) 16GB"
echo "5) 32GB"
echo "6) Inny rozmiar (podaj ręcznie)"

while true; do
    read -p "Wybierz opcję (1-6): " option
    case $option in
        1) swap_size=2048; break;;
        2) swap_size=4096; break;;
        3) swap_size=8192; break;;
        4) swap_size=16384; break;;
        5) swap_size=32768; break;;
        6)
            while true; do
                read -p "Podaj rozmiar pliku swap w MB (np. 4096 = 4GB): " swap_size
                if [[ "$swap_size" =~ ^[0-9]+$ ]] && [ "$swap_size" -ge 1 ]; then
                    break 2
                else
                    echo "Błąd: Podaj poprawną liczbę całkowitą (minimum 1MB)!"
                fi
            done
            ;;
        *) echo "Nieprawidłowy wybór. Wybierz 1-6.";;
    esac
done

# Making swap file
echo -e "\n[4/6] Tworzenie pliku swap (${swap_size}MB)..."
if sudo dd if=/dev/zero of=/swapfile bs=1M count=$swap_size status=progress; then
    echo "Plik swap utworzony."
else
    echo "Błąd: Nie udało się utworzyć pliku swap!" >&2
    exit 1
fi

# Setting up permissions then init
echo -e "\n[5/6] Konfiguracja systemu..."
sudo chmod 600 /swapfile || exit 1
sudo mkswap /swapfile || exit 1
sudo swapon /swapfile || exit 1

# End
echo -e "\n[6/6] Gotowe! Aktualny stan pamięci:"
free -h

# Add to /etc/fstab (??)
echo -e "\nAby swap był aktywny po restarcie, dodaj do /etc/fstab:"
echo "/swapfile none swap sw 0 0"