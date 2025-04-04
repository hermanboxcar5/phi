#!/bin/bash

# Function to configure AppArmor
configure_apparmor() {
    sudo apt-get install apparmor apparmor-utils -y
    sudo systemctl enable apparmor
    sudo systemctl start apparmor

    # Load AppArmor profiles
    sudo aa-enforce /etc/apparmor.d/*
    
    # Enable AppArmor in the kernel boot parameters
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&apparmor=1 security=apparmor /' /etc/default/grub
    sudo update-grub

    # Ensure AppArmor is running
    if sudo apparmor_status | grep -q "apparmor module is loaded"; then
        echo "AppArmor is active and running."
    else
        echo "AppArmor is not running. Please check the configuration."
    fi
}

# Function to configure AppArmor profiles based on CIS Benchmark
configure_apparmor_profiles() {
    # Ensure all AppArmor profiles are in enforce mode
    sudo aa-enforce /etc/apparmor.d/*
    
    # Example of enforcing specific profiles (add more profiles as needed)
    sudo aa-enforce /etc/apparmor.d/usr.sbin.cupsd
    sudo aa-enforce /etc/apparmor.d/usr.sbin.dhcpd
    sudo aa-enforce /etc/apparmor.d/usr.sbin.mysqld
}
# Main script execution
configure_apparmor
configure_apparmor_profiles

echo "AppArmor configuration applied successfully."
