#!/bin/bash


# Install NGINX
sudo apt-get install nginx -y
sudo ufw allow nginx

# Ensure NGINX runs as a non-root user
sudo sed -i 's/^user .*/user www-data;/' /etc/nginx/nginx.conf

# Configure HTTPS and obtain SSL certificates using Certbot
sudo apt-get install certbot python3-certbot-nginx -y
sudo certbot --nginx

# Enable HTTP/2
sudo sed -i 's/listen 443 ssl;/listen 443 ssl http2;/' /etc/nginx/sites-available/default

# Disable server tokens to hide NGINX version
sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

# Enable Gzip compression
sudo tee /etc/nginx/conf.d/gzip.conf <<EOL
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
EOL

# Enable security headers
sudo tee /etc/nginx/conf.d/security_headers.conf <<EOL
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options "SAMEORIGIN";
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "no-referrer-when-downgrade";
add_header Content-Security-Policy "default-src 'self'; script-src 'self' https:; style-src 'self' https:;";
EOL

# Set up a basic firewall using UFW
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Limit the rate of requests to prevent DoS attacks
sudo tee /etc/nginx/conf.d/limit_req.conf <<EOL
limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=1r/s;
EOL

sudo tee /etc/nginx/sites-available/default <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        limit_req zone=mylimit burst=10 nodelay;
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Enable logging
sudo tee /etc/nginx/conf.d/logging.conf <<EOL
log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                  '\$status \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for"';

access_log /var/log/nginx/access.log main;
error_log /var/log/nginx/error.log warn;
EOL

# Restart NGINX to apply changes
sudo systemctl restart nginx

echo "NGINX has been hardened and secured."
