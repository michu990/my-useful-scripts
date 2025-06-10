#!/bin/bash

# Check if running from desktop (GUI) - if yes, launch terminal
if [ -n "$DESKTOP_SESSION" ] && [ -z "$TERMINAL_LAUNCHED" ]; then
    export TERMINAL_LAUNCHED=1
    gnome-terminal -- bash -c "$0; exec bash"
    exit 0
fi

ORPHANS=`deborphan`
if [ ! -z "$ORPHANS" ]; then
    sudo dpkg --remove $ORPHANS
fi

PURGES=`dpkg --list | grep ^rc | awk '{ print $2; }'`
if [ ! -z "$PURGES" ]; then
    sudo dpkg --purge $PURGES
fi