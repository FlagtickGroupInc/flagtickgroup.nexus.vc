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
    echo "Git not found, installing Git..."
    sudo yum install -y git || sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
  fi

  if [ ! -d "$REPO_PATH" ]; then
    echo "Project directory not found. Cloning repository..."
    
    chmod 600 "$SSH_KEY_PATH"
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "Failed to add GitHub key to known_hosts."; exit 1; }
    git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || {
      echo "Failed to clone repository."
      exit 1
    }
  else
    echo "Project directory already exists."
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

  # Ensure we're on the correct branch (master)
  git checkout master || { echo "Failed to checkout master branch."; exit 1; }
  git pull origin master || { echo "Failed to pull latest changes from master."; exit 1; }

  # Ensure Docker is installed
  if ! command -v docker &> /dev/null; then
    echo "Docker not found, installing Docker..."
    sudo yum install -y docker || sudo apt-get install -y docker.io || { echo "Failed to install Docker."; exit 1; }
  fi

  # Ensure the user has permission to use Docker
  if ! groups | grep -q '\bdocker\b'; then
    echo "Adding user to Docker group..."
    sudo usermod -aG docker $(whoami) || { echo "Failed to add user to Docker group."; exit 1; }
    echo "Please log out and log back in or restart the server for changes to take effect."
    exit 1
  fi

  # Ensure Docker is running
  if ! systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo systemctl start docker || { echo "Failed to start Docker."; exit 1; }
  fi

  # Ensure Python3 and pip are installed
  if ! command -v python3 &> /dev/null; then
    echo "Installing Python3..."
    sudo yum install -y python3 || sudo apt-get install -y python3 || { echo "Failed to install Python3."; exit 1; }
  fi
  if ! command -v pip3 &> /dev/null; then
    echo "Installing pip3..."
    sudo yum install -y python3-pip || sudo apt-get install -y python3-pip || { echo "Failed to install pip3."; exit 1; }
  fi

  # Ensure docker-compose is installed
  if ! command -v docker-compose &> /dev/null; then
    echo "Installing docker-compose..."
    pip3 install --user docker-compose || { echo "Failed to install docker-compose."; exit 1; }

    # Add ~/.local/bin to PATH
    export PATH=\$HOME/.local/bin:\$PATH
    echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.bashrc
    source ~/.bashrc
  fi

  # Verify docker-compose installation
  if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose still not found. Exiting."
    exit 1
  fi

  # Stop and remove existing containers
  echo "Stopping existing Docker services..."
  sudo docker-compose down || { echo "Failed to stop containers."; exit 1; }

  # Start Docker services without scaling missing ones
  echo "Starting Docker services..."
  sudo docker-compose up -d --build || { echo "Failed to start containers."; exit 1; }

  echo "Waiting for Nexus to be ready..."
  until curl --output /dev/null --silent --head --fail http://localhost:8081; do
    echo "Waiting for Nexus..."
    sleep 10
  done
  echo "Nexus is up!"

EOF

echo "Deployment process completed successfully!"
