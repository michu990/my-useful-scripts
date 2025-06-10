#!/bin/bash

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

# succes error and info functions
print_success()
{
    echo -e "\033[0;32m[SUKCES]\033[0m $1"
}

print_error()
{
    echo -e "\033[0;31m[BŁĄD]\033[0m $1"
}

print_info()
{
    echo -e "\033[1;36m[INFO]\033[0m $1"
}

# apt update
print_info "Aktualizowanie listy pakietów..."
sudo apt update
if [ $? -ne 0 ]; then
    print_error "Nie udało się zaktualizować listy pakietów!"
    exit 1
fi

# required packages
DEPENDENCIES=(
    "bash"
    "gnome-terminal"
    "openssh-client"   # ssh
    "sshfs"
    "fuse3"
    "tigervnc-viewer"  # vncviewer
    "apt"
    "apt-utils"
    "grep"
    "coreutils"        # date, mkdir, rmdir
    "mount"
    "ncurses-bin"      # tput
)

# installation
print_info "Rozpoczynanie instalacji wymaganych pakietów..."
for pkg in "${DEPENDENCIES[@]}"; do
    print_info "Instalowanie pakietu: $pkg"
    sudo apt install "$pkg"
    if [ $? -eq 0 ]; then
        print_success "Pomyślnie zainstalowano: $pkg"
    else
        print_error "Nie udało się zainstalować: $pkg"
    fi
done

# checking for fuse user
if ! groups $SUDO_USER | grep -q '\bfuse\b'; then
    print_info "Dodawanie użytkownika $SUDO_USER do grupy fuse..."
    usermod -aG fuse $SUDO_USER
    print_success "Użytkownik $SUDO_USER dodany do grupy fuse. Wymagane może być wylogowanie."
fi

# summary
print_success "Instalacja zakończona. Wymagane pakiety:"
printf " - %s\n" "${DEPENDENCIES[@]}"

print_info "W przypadku problemów z SSHFS, upewnij się że:"
echo "1. Masz włączoną usługę SSH na zdalnym serwerze"
echo "2. Twój użytkownik należy do grupy 'fuse' (może wymagać wylogowania)"
echo "3. Masz odpowiednie uprawnienia do zdalnego folderu"

exit 0