#!/bin/bash

# Exit on error
set -e

echo "Starting deployment process..."

# SSH into the VPS and deploy the application
ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  set -e

  echo "Connected to VPS successfully."

  # Install Git if not installed
  if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt-get update -y
    sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
  else
    echo "Git is already installed."
  fi

  REPO_PATH="/home/ubuntu/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ubuntu/.ssh/rsa.pem"

  # Ensure SSH key permissions are correct
  chmod 600 "$SSH_KEY_PATH"

  # Add GitHub to known hosts
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "Failed to add GitHub key."; exit 1; }

  # Set custom SSH command for Git
  git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

  # Clone or pull repository
  if [ ! -d "$REPO_PATH/.git" ]; then
    echo "Cloning repository..."
    rm -rf "$REPO_PATH"
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || {
      echo "Failed to clone repository."; exit 1;
    }
  else
    echo "Repository found. Pulling latest changes..."
    cd "$REPO_PATH"
    git checkout master || { echo "Failed to checkout master branch."; exit 1; }
    git pull origin master || { echo "Failed to pull latest changes."; exit 1; }
  fi

  # Install libcrypt-compat if missing
  if ! ldconfig -p | grep -q libcrypt.so.1; then
    echo "Installing libcrypt-compat..."
    sudo apt-get install -y libxcrypt-compat || { echo "Failed to install libxcrypt-compat."; exit 1; }
  fi

  # Install Docker if not installed
  if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get update -y
    sudo apt-get install -y docker.io || { echo "Failed to install Docker."; exit 1; }
    sudo systemctl enable --now docker
  else
    echo "Docker is already installed."
  fi

  # Ensure Docker is running
  if ! systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo systemctl start docker || { echo "Failed to start Docker."; exit 1; }
  fi

  # Install docker-compose if not installed
  if ! command -v docker-compose &> /dev/null; then
    echo "Installing docker-compose..."
    sudo apt-get install -y python3-pip
    sudo pip3 install docker-compose || { echo "Failed to install docker-compose."; exit 1; }
  fi

  # Restart containers if docker-compose.yml exists
  cd "$REPO_PATH"
  if [ -f "docker-compose.yml" ]; then
    echo "Restarting containers..."
    sudo docker-compose down || { echo "Failed to stop containers."; exit 1; }
    sudo docker-compose up -d --build || { echo "Failed to restart containers."; exit 1; }
  else
    echo "No docker-compose.yml found. Skipping Docker operations."
  fi

EOF

echo "Deployment process completed successfully!"
