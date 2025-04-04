#!/bin/bash

# Function to ensure only necessary services are enabled
ensure_necessary_services() {
    echo "Ensuring only necessary services are enabled..."
    # Disable unnecessary services (example: avahi-daemon)
    sudo systemctl disable avahi-daemon
    sudo systemctl stop avahi-daemon
}

# Function to ensure services do not run as root unless necessary
ensure_services_not_root() {
    echo "Ensuring services do not run as root unless necessary..."
    # Example: Ensure nginx runs as www-data
    sudo sed -i 's/^user .*/user www-data;/' /etc/nginx/nginx.conf
    sudo systemctl restart nginx
}

# Function to ensure only necessary client services are enabled
ensure_necessary_client_services() {
    echo "Ensuring only necessary client services are enabled..."
    # Disable unnecessary client services (example: cups)
    sudo systemctl disable cups
    sudo systemctl stop cups
}

# Function to ensure client services are configured with least privilege
configure_client_services_least_privilege() {
    echo "Configuring client services with least privilege..."
    # Example: Ensure NetworkManager runs with least privilege
    sudo sed -i 's/^#dns=dnsmasq/dns=dnsmasq/' /etc/NetworkManager/NetworkManager.conf
    sudo systemctl restart NetworkManager
}

# Function to ensure client services do not run as root unless necessary
ensure_client_services_not_root() {
    echo "Ensuring client services do not run as root unless necessary..."
    # Example: Ensure cron runs as a non-root user
    sudo sed -i 's/^#user .*/user cronuser;/' /etc/cron.d
    sudo systemctl restart cron
}

# Function to ensure time synchronization is in use
ensure_time_synchronization() {
    echo "Ensuring time synchronization is in use..."
    timedatectl set-ntp true
}

# Function to ensure systemd-timesyncd is configured
configure_systemd_timesyncd() {
    echo "Configuring systemd-timesyncd..."
    sudo apt-get install -y systemd-timesyncd
    sudo systemctl enable systemd-timesyncd
    sudo systemctl start systemd-timesyncd
}

# Function to ensure chrony is configured
configure_chrony() {
    echo "Configuring chrony..."
    sudo apt-get install -y chrony
    sudo systemctl enable chrony
    sudo systemctl start chrony
    # Add common chrony configurations
    echo "server 0.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server 1.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server 2.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server 3.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "driftfile /var/lib/chrony/chrony.drift" | sudo tee -a /etc/chrony/chrony.conf
    echo "makestep 1.0 3" | sudo tee -a /etc/chrony/chrony.conf
}

# Function to ensure ntp is configured
configure_ntp() {
    echo "Configuring ntp..."
    sudo apt-get install -y ntp
    sudo systemctl enable ntp
    sudo systemctl start ntp
    # Add common ntp configurations
    echo "server 0.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "server 1.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "server 2.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "server 3.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "driftfile /var/lib/ntp/ntp.drift" | sudo tee -a /etc/ntp.conf
}

# Function to disable autofs service
disable_autofs() {
    echo "Disabling autofs service..."
    sudo systemctl disable autofs
    sudo systemctl stop autofs
}

# Function to disable dhcp service
disable_dhcp() {
    echo "Disabling dhcp service..."
    sudo systemctl disable isc-dhcp-server
    sudo systemctl stop isc-dhcp-server
}

# Function to disable dnsmasq service
disable_dnsmasq() {
    echo "Disabling dnsmasq service..."
    sudo systemctl disable dnsmasq
    sudo systemctl stop dnsmasq
}

# Function to disable iscsid service
disable_iscsid() {
    echo "Disabling iscsid service..."
    sudo systemctl disable iscsid
    sudo systemctl stop iscsid
}

# Function to disable print server service
disable_print_server() {
    echo "Disabling print server service..."
    sudo systemctl disable cups
    sudo systemctl stop cups
}

# Function to disable rpcbind service
disable_rpcbind() {
    echo "Disabling rpcbind service..."
    sudo systemctl disable rpcbind
    sudo systemctl stop rpcbind
}

# Function to disable rsync service
disable_rsync() {
    echo "Disabling rsync service..."
    sudo systemctl disable rsync
    sudo systemctl stop rsync
}

# Function to disable xinetd service
disable_xinetd() {
    echo "Disabling xinetd service..."
    sudo systemctl disable xinetd
    sudo systemctl stop xinetd
}

# Function to disable X Window System
disable_x_window() {
    echo "Disabling X Window System..."
    sudo systemctl disable lightdm
    sudo systemctl stop lightdm
}

# Main script execution
ensure_necessary_services 
ensure_services_not_root
ensure_necessary_client_services
configure_client_services_least_privilege
ensure_client_services_not_root
ensure_time_synchronization
configure_systemd_timesyncd
configure_chrony
configure_ntp
disable_autofs
disable_dhcp
disable_dnsmasq
disable_iscsid
disable_print_server
disable_rpcbind
disable_rsync
disable_xinetd
disable_x_window
