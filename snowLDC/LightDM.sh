#!/bin/bash

# Function to configure display managers
configure_display_managers() {
    if [ -f /etc/lightdm/lightdm.conf ]; then
        sudo tee /etc/lightdm/lightdm.conf <<EOL
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=default
greeter-hide-users=true
allow-guest=false
autologin-guest=false
autologin-user=none
xserver-command=X -core
EOL
    fi
}

# Main script execution
configure_display_managers
