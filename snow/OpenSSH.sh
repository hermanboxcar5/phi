#!/bin/bash

# Function to configure SSH
configure_ssh() {
    sudo tee -a /etc/ssh/sshd_config <<EOL
Port 22
Protocol 2
PermitEmptyPasswords no
PermitRootLogin no
LoginGraceTime 120
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
HostbasedAuthentication no
PasswordAuthentication no
PermitUserEnvironment no
MaxAuthTries 4
AllowTcpForwarding no
X11Forwarding no
IgnoreRhosts yes
PermitTunnel no
AllowAgentForwarding no
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
EOL
    sudo chmod 600 /etc/ssh/sshd_config
    sudo systemctl restart sshd

    if [ -f /etc/ssh/ssh_config ]; then
        sudo tee -a /etc/ssh/ssh_config <<EOL
Host *
    Protocol 2
    ForwardAgent no
    ForwardX11 no
    RhostsRSAAuthentication no
    RSAAuthentication yes
    PasswordAuthentication no
    HostbasedAuthentication no
    GSSAPIAuthentication no
    GSSAPIDelegateCredentials no
    UseRoaming no
    BatchMode no
    CheckHostIP yes
    AddressFamily inet
EOL
        sudo chmod 600 /etc/ssh/ssh_config
    fi
}

sudo ufw allow ssh
# Main script execution
configure_ssh
