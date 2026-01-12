#!/bin/bash

# Script to change Apache .htpasswd password
# michu990

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

HTPASSWD_FILE="/etc/apache2/.htpasswd"
USERNAME="piwnica"

echo "Changing password for user: $USERNAME"

if [ ! -f "$HTPASSWD_FILE" ]; then
    echo "Creating new .htpasswd file..."
    htpasswd -c "$HTPASSWD_FILE" "$USERNAME"
else
    htpasswd "$HTPASSWD_FILE" "$USERNAME"
fi

# Check if htpasswd command was successful
if [ $? -eq 0 ]; then
    # Set secure permissions
    chmod 640 "$HTPASSWD_FILE"
    chown root:www-data "$HTPASSWD_FILE"
    
    echo "Password updated successfully for user: $USERNAME"
else
    echo "Failed to update password for user: $USERNAME"
    exit 1
fi