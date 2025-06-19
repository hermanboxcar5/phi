#!/bin/bash

# Function to configure IPv4 settings according to CIS Benchmark
configure_ipv4() {
    echo "Configuring IPv4 settings..."
    
    # Ensure IP forwarding is disabled
    sudo sysctl -w net.ipv4.ip_forward=0
    sudo sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward = 0/' /etc/sysctl.conf
    
    # Ensure packet redirect sending is disabled
    sudo sysctl -w net.ipv4.conf.all.send_redirects=0
    sudo sysctl -w net.ipv4.conf.default.send_redirects=0
    sudo sed -i 's/^net.ipv4.conf.all.send_redirects.*/net.ipv4.conf.all.send_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.send_redirects.*/net.ipv4.conf.default.send_redirects = 0/' /etc/sysctl.conf
    
    # Ensure source routed packets are not accepted
    sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
    sudo sysctl -w net.ipv4.conf.default.accept_source_route=0
    sudo sed -i 's/^net.ipv4.conf.all.accept_source_route.*/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.accept_source_route.*/net.ipv4.conf.default.accept_source_route = 0/' /etc/sysctl.conf
    
    # Ensure ICMP redirects are not accepted
    sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
    sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
    sudo sed -i 's/^net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.accept_redirects.*/net.ipv4.conf.default.accept_redirects = 0/' /etc/sysctl.conf
    
    # Ensure secure ICMP redirects are not accepted
    sudo sysctl -w net.ipv4.conf.all.secure_redirects=0
    sudo sysctl -w net.ipv4.conf.default.secure_redirects=0
    sudo sed -i 's/^net.ipv4.conf.all.secure_redirects.*/net.ipv4.conf.all.secure_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.secure_redirects.*/net.ipv4.conf.default.secure_redirects = 0/' /etc/sysctl.conf
    
    # Ensure suspicious packets are logged
    sudo sysctl -w net.ipv4.conf.all.log_martians=1
    sudo sysctl -w net.ipv4.conf.default.log_martians=1
    sudo sed -i 's/^net.ipv4.conf.all.log_martians.*/net.ipv4.conf.all.log_martians = 1/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.log_martians.*/net.ipv4.conf.default.log_martians = 1/' /etc/sysctl.conf
    
    # Ensure broadcast ICMP requests are ignored
    sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
    sudo sed -i 's/^net.ipv4.icmp_echo_ignore_broadcasts.*/net.ipv4.icmp_echo_ignore_broadcasts = 1/' /etc/sysctl.conf
    
    # Ensure bogus ICMP responses are ignored
    sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
    sudo sed -i 's/^net.ipv4.icmp_ignore_bogus_error_responses.*/net.ipv4.icmp_ignore_bogus_error_responses = 1/' /etc/sysctl.conf
    
    # Ensure Reverse Path Filtering is enabled
    sudo sysctl -w net.ipv4.conf.all.rp_filter=1
    sudo sysctl -w net.ipv4.conf.default.rp_filter=1
    sudo sed -i 's/^net.ipv4.conf.all.rp_filter.*/net.ipv4.conf.all.rp_filter = 1/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.rp_filter.*/net.ipv4.conf.default.rp_filter = 1/' /etc/sysctl.conf
    
    # Ensure TCP SYN Cookies is enabled
    sudo sysctl -w net.ipv4.tcp_syncookies=1
    sudo sed -i 's/^net.ipv4.tcp_syncookies.*/net.ipv4.tcp_syncookies = 1/' /etc/sysctl.conf
}

# Function to configure IPv6 settings according to CIS Benchmark
configure_ipv6() {
    echo "Configuring IPv6 settings..."
    
    # Ensure IPv6 router advertisements are not accepted
    sudo sysctl -w net.ipv6.conf.all.accept_ra=0
    sudo sysctl -w net.ipv6.conf.default.accept_ra=0
    sudo sed -i 's/^net.ipv6.conf.all.accept_ra.*/net.ipv6.conf.all.accept_ra = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv6.conf.default.accept_ra.*/net.ipv6.conf.default.accept_ra = 0/' /etc/sysctl.conf
    
    # Ensure IPv6 redirects are not accepted
    sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
    sudo sysctl -w net.ipv6.conf.default.accept_redirects=0
    sudo sed -i 's/^net.ipv6.conf.all.accept_redirects.*/net.ipv6.conf.all.accept_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv6.conf.default.accept_redirects.*/net.ipv6.conf.default.accept_redirects = 0/' /etc/sysctl.conf
    
    # Ensure IPv6 is disabled if not required
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sed -i 's/^net.ipv6.conf.all.disable_ipv6.*/net.ipv6.conf.all.disable_ipv6 = 1/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv6.conf.default.disable_ipv6.*/net.ipv6.conf.default.disable_ipv6 = 1/' /etc/sysctl.conf
}

# Main script execution
configure_ipv4
configure_ipv6

echo "Network configuration applied."
