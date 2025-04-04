#!/bin/bash

# Function to configure Samba
configure_samba() {
    if systemctl is-active --quiet smbd; then
        sudo apt-get install samba -y
        sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
        sudo tee /etc/samba/smb.conf <<EOL
[global]
   workgroup = WORKGROUP
   server string = Samba Server %v
   security = user
   map to guest = bad user
   dns proxy = no

[Public]
   path = /samba/public
   writable = no
   guest ok = yes
   read only = yes
   force user = nobody

[sambashare]
   comment = Samba on Ubuntu
   path = /mnt/sambashare
   read only = no
   browseable = yes
EOL
        sudo mkdir -p /samba/public
        sudo chmod -R 0755 /samba/public
        sudo chown -R nobody:nogroup /samba/public
        sudo mkdir -p /mnt/sambashare
        sudo chmod -R 0755 /mnt/sambashare
        sudo chown -R nobody:nogroup /mnt/sambashare
        sudo systemctl restart smbd
    fi
}

sudo ufw allow samba
# Main script execution
configure_samba
