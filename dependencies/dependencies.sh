#!/bin/bash

# Dependencies
# michu990
# Version: 2.0

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

# Succes error and info functions
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

# Apt update
print_info "Aktualizowanie listy pakietów..."
sudo apt update
if [ $? -ne 0 ]; then
    print_error "Nie udało się zaktualizować listy pakietów!"
    exit 1
fi

# Required packages
DEPENDENCIES=(
    "bash"             # bash
    "sudo"             # sudo
    "gnome-terminal"   # my terminal
    "openssh-client"   # ssh
    "sshfs"            # sshfs
    "fuse3"            # fuse
    "tigervnc-viewer"  # vncviewer
    "apt"              # package manager
    "apt-utils"        # package manager utils
    "grep"             # grep
    "coreutils"        # date, mkdir, rmdir
    "mount"            # mount
    "ncurses-bin"      # tput
    "python3"          # python
    "nmap"             # nmap
    "clamav"           # AV
    "clamav-freshclam" # AV database
    "rkhunter"         # rkhunter
    "chkrootkit"       # chkrootkit
    "lynis"            # lynis
    "net-tools"        # net-tools netstat
    "ufw"              # ufw
    "systemd"          # systemd
    "grep"             # grep
    "mawk"             # mawk
    "gawk"             # gawk
    "sed"              # sed
    "dpkg"             # dpkg
)

print_success "Instalacja zakończona. Wymagane pakiety:"
printf " - %s\n" "${DEPENDENCIES[@]}"
# Checking for fuse user
if ! groups $SUDO_USER | grep -q '\bfuse\b'; then
    print_info "Dodawanie użytkownika $SUDO_USER do grupy fuse..."
    usermod -aG fuse $SUDO_USER
    print_success "Użytkownik $SUDO_USER dodany do grupy fuse. Wymagane może być wylogowanie."
fi

# Summary
print_success "Instalacja zakończona. Wymagane pakiety:"
printf " - %s\n" "${DEPENDENCIES[@]}"

print_info "W przypadku problemów z SSHFS, upewnij się że:"
echo "1. Masz włączoną usługę SSH na zdalnym serwerze"
echo "2. Twój użytkownik należy do grupy 'fuse' (może wymagać wylogowania)"
echo "3. Masz odpowiednie uprawnienia do zdalnego folderu"

exit 0