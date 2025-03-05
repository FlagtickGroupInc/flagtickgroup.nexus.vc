#!/bin/bash

# Variables
DEPLOY_DIR="/var/www/nexus"
GIT_REPO="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
BRANCH="master"

echo "🚀 Updating system and installing dependencies..."
sudo apt-get update -y && sudo apt-get install -y nginx git

# Clone or update the repository
if [ ! -d "$DEPLOY_DIR" ]; then
  echo "📁 Cloning repository..."
  sudo git clone -b $BRANCH $GIT_REPO $DEPLOY_DIR
else
  echo "📁 Updating existing repository..."
  cd $DEPLOY_DIR
  sudo git pull origin $BRANCH
fi

# Set correct permissions
sudo chown -R www-data:www-data $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Run Nginx setup script
echo "⚙️ Setting up Nginx..."
bash $(dirname "$0")/setup_nginx.sh

# Restart Nginx
echo "🔄 Restarting Nginx..."
sudo systemctl restart nginx

echo "✅ Deployment complete!"
