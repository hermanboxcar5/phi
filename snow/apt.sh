#!/bin/bash

# Function to configure unattended-upgrades
configure_unattended_upgrades() {
    sudo apt-get install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
}

# Function to check for suspicious files in /etc/apt
check_apt_directory() {
    echo "Checking for suspicious files in /etc/apt..."
    for file in $(ls /etc/apt); do
        if [[ "$file" != "sources.list" && "$file" != "trusted.gpg" && "$file" != "trusted.gpg.d" ]]; then
            echo "Suspicious file found: $file"
        fi
    done
}

# Main script execution
configure_unattended_upgrades
check_apt_directory
