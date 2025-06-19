#!/bin/bash

# Function to configure Seafile/Seahub if installed
configure_seafile() {
    if [ -d /opt/seafile ]; then
        echo "Configuring Seafile..."
        sudo tee /opt/seafile/conf/seahub_settings.py <<EOL
# Seahub settings
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = True
PASSWORD_MIN_LENGTH = 10
PASSWORD_STRENGTH_LEVEL = 3
EOL
        sudo chmod 700 /opt/seafile/conf/seahub_settings.py
        sudo tee -a /opt/seafile/conf/seafile.conf <<EOL
[fileserver]
enable_access_log = true
EOL
    fi
}

# Main script execution
configure_seafile
