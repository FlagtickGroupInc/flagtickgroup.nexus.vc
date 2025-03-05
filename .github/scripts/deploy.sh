#!/bin/bash

# Exit on error
set -e

echo "Starting deployment process..."

# SSH into the VPS and deploy the application
ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  set -e

  echo "Connected to VPS successfully."

  # Install Git if not already installed (Amazon Linux uses yum)
  if ! command -v git &> /dev/null; then
    echo "Git not found, installing Git..."
    
    if [ -f /etc/os-release ] && grep -q "Amazon Linux" /etc/os-release; then
      sudo yum update -y
      sudo yum install -y git || { echo "Failed to install Git."; exit 1; }
    else
      sudo apt-get update
      sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
    fi
  else
    echo "Git is already installed."
  fi

  REPO_PATH="/home/ec2-user/flagtickgroup.suite.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/rsa.pem"

  if [ ! -d "$REPO_PATH" ]; then
    echo "Project directory not found. Cloning repository..."

    chmod 600 "$SSH_KEY_PATH"
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "Failed to add GitHub key to known_hosts."; exit 1; }
    git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

    git clone git@github.com:FlagtickGroupInc/flagtickgroup.suite.vc.git "$REPO_PATH" || {
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
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.suite.vc.git "$REPO_PATH" || { echo "Failed to re-clone repository."; exit 1; }
    cd "$REPO_PATH"
  fi

  # Ensure we're on the correct branch (master)
  git checkout master || { echo "Failed to checkout master branch."; exit 1; }
  git pull origin master || { echo "Failed to pull latest changes from master."; exit 1; }

  # Process Git submodules
  if [ -f ".gitmodules" ]; then
    echo "Updating submodules..."
    git submodule update --init --recursive || { echo "Failed to initialize submodules."; exit 1; }
    git submodule foreach git pull origin master || { echo "Failed to pull latest changes for submodules."; exit 1; }
  else
    echo "No submodules to process."
  fi

  # Install libcrypt if missing (fix for Python error)
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

  # Check if Docker is installed, and install if missing
  if ! command -v docker &> /dev/null; then
    echo "Docker not found, installing Docker..."

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

  # Start Docker service if it's not running
  if ! systemctl is-active --quiet docker; then
    echo "Docker service is not running. Starting Docker service..."
    sudo systemctl start docker || { echo "Failed to start Docker service."; exit 1; }
  else
    echo "Docker service is already running."
  fi

  # Check if docker-compose is installed, and install if missing
  if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose not found, installing docker-compose..."

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
  
  # Skip and add 'docker-compose.yml' to .gitignore
  if [ -f "tools/libraries/docker-compose.yml" ]; then
    cp -f tools/libraries/docker-compose.yml docker-compose.yml || { echo "Failed to copy 'docker-compose.yml' to the root directory."; exit 1; }
  fi

  # Stop and remove any running containers
  if [ -f "docker-compose.yml" ]; then
    sudo docker-compose down || { echo "Failed to stop containers."; exit 1; }
    sudo docker-compose up -d --build --scale composer=0 --scale artisan=0 --scale terraform=0 --scale artillery=0 --scale sonar-scanner=0 || { echo "Failed to rebuild and restart containers."; exit 1; }
  else
    echo "No docker-compose.yml found. Skipping Docker operations."
  fi
  
  # Skip and add 'sonar-project.properties' to .gitignore
  if [ -f "tools/libraries/sonar-project.properties" ]; then
    cp -f tools/libraries/sonar-project.properties vc.flagtickgroup/sonar-project.properties || { echo "Failed to move 'sonar-project.properties' to 'vc.flagtickgroup'."; exit 1; }
  fi
  
  # Skip and add 'vendor.zip' to .gitignore
  if [ -f "tools/libraries/vendor.zip" ]; then
    cp -f tools/libraries/vendor.zip vc.flagtickgroup || { echo "Failed to move 'vendor.zip' to 'vc.flagtickgroup'."; exit 1; }
  fi
  
  # Skip and add '.env' to .gitignore
  if [ -f "tools/libraries/.env" ]; then
    cp -f tools/libraries/.env vc.flagtickgroup/.env || { echo "Failed to move '.env' to 'vc.flagtickgroup'."; exit 1; }
  fi
  
EOF

echo "Deployment process completed successfully!"
