#!/bin/bash

# Function to configure display managers
configure_display_managers() {
    if [ -f /etc/gdm3/custom.conf ]; then
        sudo tee /etc/gdm3/custom.conf <<EOL
[security]
DisallowTCP=true
AllowRoot=false
AllowRemoteRoot=false
AllowRemoteAutoLogin=false

[xdmcp]
Enable=false

[greeter]
IncludeAll=true
Browser=true
EOL
    fi
}

# Function to configure sysctl for security
configure_sysctl() {
    sudo wget https://rentry.co/klaveritsysctl/raw -O /etc/sysctl.conf
    sudo sysctl -p
}

# Main script execution
configure_display_managers
configure_sysctl
