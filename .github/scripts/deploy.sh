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

  # Install Git if missing
  if ! command -v git &> /dev/null; then
    sudo yum install -y git || sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
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
    sudo yum install -y docker || sudo apt-get install -y docker.io || { echo "Failed to install Docker."; exit 1; }
  fi

  # Start Docker service if not running
  if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker || { echo "Failed to start Docker service."; exit 1; }
  fi

  # Ensure docker-compose and dependencies are installed and updated
  if ! command -v docker-compose &> /dev/null; then
    echo "Installing docker-compose..."
    sudo yum install -y python3-pip || sudo apt-get install -y python3-pip
    sudo pip3 install --upgrade docker-compose docker || { echo "Failed to install or update docker-compose."; exit 1; }
  else
    echo "Updating docker-compose and dependencies..."
    sudo pip3 install --upgrade docker-compose docker || { echo "Failed to update docker-compose."; exit 1; }
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
