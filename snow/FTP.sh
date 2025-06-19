#!/bin/bash

# Function to install and configure pure-ftpd
configure_pureftpd() {
    # Install pure-ftpd
    sudo apt-get install pure-ftpd -y
    
    # Restart pure-ftpd service
    sudo systemctl restart pure-ftpd
    
    # Create self-signed certificates
    sudo mkdir -p /etc/ssl/private
    sudo openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
    
    # Set permissions for the certificate file
    sudo chmod 600 /etc/ssl/private/pure-ftpd.pem

    # Configure pure-ftpd
    sudo tee /etc/pure-ftpd/pure-ftpd.conf <<EOL
TLS 2
NoAnonymous yes
AnonymousOnly no
UnixAuthentication yes
PamAuthentication yes
ChrootEveryone yes
EOL

    # Restart pure-ftpd service
    sudo systemctl restart pure-ftpd

    # Find IP with GUI way
    sudo netstat -inpt | grep pure-ftpd | hostname -l
}

# Function to install and configure vsftpd
configure_vsftpd() {
    # Install vsftpd
    sudo apt-get install vsftpd -y
    
    # Restart vsftpd service
    sudo systemctl restart vsftpd
    
    # Create self-signed certificates
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/certs/vsftpd.crt
    
    # Configure vsftpd
    sudo tee /etc/vsftpd.conf <<EOL
ssl_enable=YES
ssl_tlsv1=NO
allow_anon_ssl=NO
ssl_tlsv1_1=NO
ssl_tlsv1_2=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/ssl/certs/vsftpd.crt
EOL

    # Restart vsftpd service
    sudo systemctl restart vsftpd
}

# Function to install and configure proftpd
configure_proftpd() {
    # Install proftpd
    sudo apt-get install proftpd -y
    
    # Create self-signed certificates
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/proftpdServerkey.pem -out /etc/ssl/private/proftpdCertificate.pem
    
    # Configure proftpd
    sudo tee /etc/proftpd/tls.conf <<EOL
TLSEngine on
TLSLog /var/log/proftpd/tls.log
TLSProtocol TLSv1.2
TLSRSACertificateFile /etc/ssl/private/proftpdCertificate.pem
TSLRSACertificateKeyFile /etc/ssl/private/proftpdServerkey.pem
TSLRequired no
EOL

    # Restart proftpd service
    sudo systemctl restart proftpd
}

sudo ufw allow ftp
# Main script execution
configure_pureftpd
configure_vsftpd
configure_proftpd
