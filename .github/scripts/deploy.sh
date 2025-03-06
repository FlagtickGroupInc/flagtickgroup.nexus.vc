#!/bin/bash

# Exit on any error
set -e

echo "Starting deployment process..."

# SSH into the VPS and deploy the application
ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  set -e

  echo "Connected to VPS successfully."

  REPO_PATH="/home/ec2-user/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/rsa.pem"

  # Install Git if missing
  if ! command -v git &> /dev/null; then
    sudo yum install -y git || sudo dnf install -y git || sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
  fi

  # Ensure proper SSH authentication for GitHub
  chmod 600 "$SSH_KEY_PATH"
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "Failed to add GitHub key to known_hosts."; exit 1; }
  git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

  # Ensure the repository directory exists
  if [ ! -d "$REPO_PATH" ]; then
    echo "Repository not found. Cloning..."
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || { echo "Failed to clone repository."; exit 1; }
  fi

  # Move into the repository directory
  cd "$REPO_PATH" || { echo "Failed to navigate to repository directory."; exit 1; }

  # Ensure it's a valid Git repository, otherwise re-clone
  if [ ! -d ".git" ]; then
    echo "Corrupted repository detected. Re-cloning..."
    cd ..
    rm -rf "$REPO_PATH"
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || { echo "Failed to re-clone repository."; exit 1; }
    cd "$REPO_PATH"
  fi

  # Checkout master and pull the latest code
  git checkout master || { echo "Failed to checkout master branch."; exit 1; }
  git pull origin master || { echo "Failed to pull latest changes from master."; exit 1; }

  # Ensure Docker is installed and running
  if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum install -y docker || sudo dnf install -y docker || sudo apt-get install -y docker.io || { echo "Failed to install Docker."; exit 1; }
  fi

  # Start Docker service if not running
  if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker || { echo "Failed to start Docker service."; exit 1; }
  fi

  # Fix requests package issue
  if python3 -c "import requests" &> /dev/null; then
    if rpm -q python3-requests &> /dev/null; then
      echo "Removing system-installed requests package..."
      sudo yum remove -y python3-requests || sudo dnf remove -y python3-requests || sudo apt-get remove -y python3-requests || { echo "Failed to remove system requests package."; exit 1; }
    fi
  fi

  # **Fix pip upgrade issue**
  echo "Removing system-installed python3-pip..."
  sudo yum remove -y python3-pip || sudo dnf remove -y python3-pip || sudo apt-get remove -y python3-pip || { echo "Failed to remove system-installed pip."; exit 1; }

  echo "Installing pip from source..."
  curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3 || { echo "Failed to install pip."; exit 1; }

  # Verify pip installation
  pip3 --version || { echo "pip installation failed."; exit 1; }

  # Install wheel before upgrading docker-compose
  sudo pip3 install --upgrade wheel

  # Ensure docker-compose and dependencies are installed and updated
  if ! command -v docker-compose &> /dev/null; then
    echo "Installing docker-compose..."
    sudo pip3 install --upgrade docker-compose docker || { echo "Failed to install docker-compose."; exit 1; }
  else
    echo "Updating docker-compose and dependencies..."
    sudo pip3 install --ignore-installed requests --upgrade docker-compose docker || { echo "Failed to update docker-compose."; exit 1; }
  fi

  # Stop and remove old containers if they exist
  for container in nexus nginx; do
    if sudo docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
      echo "Stopping and removing existing $container container..."
      sudo docker stop $container && sudo docker rm $container || { echo "Failed to remove existing $container container."; exit 1; }
    fi
  done

  # Deploy using docker-compose
  if [ -f "docker-compose.yml" ]; then
    echo "Rebuilding and restarting containers..."
    sudo docker-compose down || { echo "Failed to stop containers."; exit 1; }
    sudo docker-compose up -d --build || { echo "Failed to rebuild and restart containers."; exit 1; }
  else
    echo "No docker-compose.yml found. Skipping Docker operations."
  fi

EOF

echo "Deployment process completed successfully!"
