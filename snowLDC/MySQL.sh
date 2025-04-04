#!/bin/bash

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

# Main script execution
configure_mysql
create_mysql_user "limited_user" "user_password"
setup_log_rotation
enable_audit_logging

# Allow MySQL service through the firewall
sudo ufw allow mysql

echo "MySQL configuration applied successfully."
