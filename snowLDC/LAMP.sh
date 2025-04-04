#!/bin/bash

# Function to configure Apache2
configure_apache2() {
    sudo apt-get update
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
    sudo ufw allow 'Apache Full'
    echo "Apache2 configuration applied successfully."
}

# Function to configure MySQL
configure_mysql() {
    sudo apt-get update
    sudo apt-get install mysql-server -y
    sudo systemctl enable mysql
    sudo systemctl start mysql

    sudo mysql_secure_installation <<EOF

y
secret_password
secret_password
y
y
y
y
EOF

    # Bind MySQL to localhost
    sudo sed -i 's/^bind-address.*/bind-address = 127.0.0.1/' /etc/mysql/mysql.conf.d/mysqld.cnf

    # Set secure file permissions
    sudo chown mysql:mysql /etc/mysql/my.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo chmod 640 /etc/mysql/my.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

    # Restart MySQL service to apply changes
    sudo systemctl restart mysql
    sudo ufw allow mysql
    echo "MySQL configuration applied successfully."
}

# Function to create a MySQL user with limited privileges
create_mysql_user() {
    local username=$1
    local password=$2
    sudo mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
    sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO '$username'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
}

# Function to set up log rotation for MySQL logs
setup_log_rotation() {
    sudo tee /etc/logrotate.d/mysql <<EOL
/var/log/mysql/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 mysql adm
    sharedscripts
    postrotate
        test -x /usr/bin/mysqladmin || exit 0
        if [ -f /var/run/mysqld/mysqld.pid ]; then
            /usr/bin/mysqladmin flush-logs
        fi
    endscript
}
EOL
}

# Function to enable MySQL audit logging
enable_audit_logging() {
    sudo tee /etc/mysql/mysql.conf.d/audit.cnf <<EOL
[mysqld]
plugin-load-add=audit_log.so
audit_log_format=JSON
audit_log_file=/var/log/mysql/audit.log
audit_log_rotate_on_size=10M
audit_log_rotations=10
EOL
    sudo systemctl restart mysql
}

# Function to install and configure PHP
configure_php() {
    sudo apt-get update
    sudo apt-get install php libapache2-mod-php php-mysql -y
    sudo systemctl restart apache2
    echo "PHP configuration applied successfully."
}

# Main script execution
configure_apache2
configure_mysql
create_mysql_user "limited_user" "user_password"
setup_log_rotation
enable_audit_logging
configure_php

echo "LAMP stack configuration applied successfully."
