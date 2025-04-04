#!/bin/bash

# Function to configure Apache2
configure_apache2() {
    if systemctl is-active --quiet apache2; then
        sudo apt-get install apache2 -y
        sudo systemctl enable apache2
        sudo systemctl start apache2
        sudo tee /etc/apache2/conf-available/security.conf <<EOL
ServerTokens Prod
ServerSignature Off
TraceEnable Off
<Directory />
    AllowOverride None
    Order deny,allow
    Deny from all
    LimitRequestBody 102400
    Options -Indexes -Includes -FollowSymLinks
</Directory>
EOL
        sudo a2enconf security
        sudo systemctl restart apache2
    fi
}

sudo ufw allow apache2
# Main script execution
configure_apache2
