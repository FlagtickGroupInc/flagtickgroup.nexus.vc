#!/bin/bash

SERVER_NAME="yourdomain.com"  # Replace with your domain or IP
DEPLOY_DIR="/var/www/mywebsite"

echo "⚙️ Configuring Nginx..."

# Create Nginx config
sudo bash -c "cat > /etc/nginx/sites-available/mywebsite <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    root $DEPLOY_DIR;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF"

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/mywebsite /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

echo "✅ Nginx setup complete!"
