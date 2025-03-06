#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Nexus Deployment on Remote VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'

  set -e

  echo "🔹 Ensuring necessary dependencies are installed..."

  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get remove -y docker docker.io docker-engine containerd runc || true
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # 🚀 Add Docker GPG key & repository manually for Ubuntu 24.04
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # 🔹 Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi

  # 🔹 Ensure Docker is running
  sudo systemctl enable docker
  sudo systemctl restart docker

  REPO_URL="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
  REPO_PATH="/home/ubuntu/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ubuntu/.ssh/rsa.pem"

  # Ensure Git is installed
  if ! command -v git &> /dev/null; then
    sudo apt-get install -y git || { echo "❌ Failed to install Git"; exit 1; }
  fi

  # 🔹 Fix SSH key permissions
  sudo chown ubuntu:ubuntu "$SSH_KEY_PATH"
  chmod 400 "$SSH_KEY_PATH"

  export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes"

  # 🔹 Add GitHub to known hosts
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "❌ Failed to add GitHub key"; exit 1; }

  # 🔹 Clone or update repository
  if [ -d "$REPO_PATH" ]; then
    cd "$REPO_PATH"
    git reset --hard
    git pull origin master || { echo "❌ Failed to pull latest changes"; exit 1; }
  else
    git clone "$REPO_URL" "$REPO_PATH" || { echo "❌ Failed to clone repository"; exit 1; }
  fi

  cd "$REPO_PATH"

  # 🔹 Deploy Docker containers
  docker system prune -f
  docker-compose down --remove-orphans
  docker-compose up -d --build

EOF
