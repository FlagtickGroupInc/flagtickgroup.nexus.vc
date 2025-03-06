#!/bin/bash

# Exit on error
set -e

echo "Starting deployment process..."

# SSH into the VPS and deploy the application
ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  set -e

  echo "Connected to VPS successfully."

  REPO_PATH="/home/ec2-user/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/rsa.pem"

  # Ensure Git is installed
  if ! command -v git &> /dev/null; then
    sudo yum install -y git || sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
  fi

  if [ ! -d "$REPO_PATH" ]; then
    
    chmod 600 "$SSH_KEY_PATH"
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "Failed to add GitHub key to known_hosts."; exit 1; }
    git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || {
      exit 1
    }
  else
    git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"
  fi

  cd "$REPO_PATH" || { echo "Failed to navigate to project directory."; exit 1; }

  if [ ! -d ".git" ]; then
    echo "Directory is not a Git repository. Re-cloning..."
    cd ..
    rm -rf "$REPO_PATH"
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || { echo "Failed to re-clone repository."; exit 1; }
    cd "$REPO_PATH"
  fi

  git checkout master || { echo "Failed to checkout master branch."; exit 1; }
  git pull origin master || { echo "Failed to pull latest changes from master."; exit 1; }

  if ! ldconfig -p | grep -q libcrypt.so.1; then
    echo "libcrypt.so.1 not found, installing it..."
    
    if [ -f /etc/os-release ] && grep -q "Amazon Linux" /etc/os-release; then
      sudo yum install -y libxcrypt-compat || { echo "Failed to install libxcrypt-compat."; exit 1; }
    else
      sudo apt-get install -y libxcrypt-compat || { echo "Failed to install libxcrypt-compat."; exit 1; }
    fi
  else
    echo "libcrypt.so.1 is already installed."
  fi
  
  if ! command -v docker &> /dev/null; then
    if [ -f /etc/os-release ] && grep -q "Amazon Linux" /etc/os-release; then
      sudo yum update -y
      sudo yum install -y docker || { echo "Failed to install Docker."; exit 1; }
    else
      sudo apt-get update
      sudo apt-get install -y docker.io || { echo "Failed to install Docker."; exit 1; }
    fi
  else
    echo "Docker is already installed."
  fi
  
  if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker || { echo "Failed to start Docker service."; exit 1; }
  else
    echo "Docker service is already running."
  fi
  
  # Check if docker-compose is installed, and install if missing
  if ! command -v docker-compose &> /dev/null; then
    if [ -f /etc/os-release ] && grep -q "Amazon Linux" /etc/os-release; then
      sudo yum install -y python3-pip
      sudo pip3 install docker-compose || { echo "Failed to install docker-compose."; exit 1; }
    else
      sudo apt-get install -y python3-pip
      sudo pip3 install docker-compose || { echo "Failed to install docker-compose."; exit 1; }
    fi
  else
    echo "docker-compose is already installed."
  fi
    
  if sudo docker ps -a --format '{{.Names}}' | grep -q "^nexus$"; then
    sudo docker stop nexus && sudo docker rm nexus || { echo "Failed to remove existing nexus container."; exit 1; }
  fi
  
  if sudo docker ps -a --format '{{.Names}}' | grep -q "^nginx"; then
    sudo docker stop nginx && sudo docker rm nginx || { echo "Failed to remove existing nginx container."; exit 1; }
  fi

  if [ -f "docker-compose.yml" ]; then
    sudo docker-compose down || { echo "Failed to stop containers."; exit 1; }
    sudo docker-compose up -d --build || { echo "Failed to rebuild and restart containers."; exit 1; }
  else
    echo "No docker-compose.yml found. Skipping Docker operations."
  fi

EOF

echo "Deployment process completed successfully!"
