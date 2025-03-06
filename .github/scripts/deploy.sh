#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "🚀 Starting Nexus Deployment on Remote VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  
  set -e

  echo "🔹 Ensuring necessary dependencies are installed..."

  # Install Git if not available
  if ! command -v git &> /dev/null; then
    sudo yum install -y git || sudo dnf install -y git || sudo apt-get install -y git
  fi

  # Install Docker if not available
  if ! command -v docker &> /dev/null; then
    echo "🔹 Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
  fi

  # Install Docker Compose if not available
  if ! command -v docker-compose &> /dev/null; then
    echo "🔹 Installing Docker Compose..."
    sudo apt-get install -y docker-compose
  fi

  # Define repository details
  REPO_URL="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
  REPO_PATH="/home/ec2-user/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/rsa.pem"

  echo "🔹 Configuring SSH key for GitHub access..."
  chmod 600 "$SSH_KEY_PATH"
  eval $(ssh-agent -s)
  ssh-add "$SSH_KEY_PATH"
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts

  git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

  # Clone or update repository
  if [ -d "$REPO_PATH" ]; then
    cd "$REPO_PATH"
    git reset --hard
    git pull origin master
  else
    git clone "$REPO_URL" "$REPO_PATH"
  fi

  cd "$REPO_PATH"

  echo "🔹 Starting Nexus using Docker Compose..."
  docker-compose up -d

  echo "✅ Nexus Deployment Completed Successfully!"
EOF
