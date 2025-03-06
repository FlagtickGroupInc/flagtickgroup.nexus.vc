#!/bin/bash

set -e

echo "🚀 Starting Nexus Deployment on Remote VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'

  set -e

  echo "🔹 Ensuring necessary dependencies are installed..."

  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get remove -y containerd containerd.io docker docker.io docker-engine
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

  elif command -v dnf &> /dev/null; then
    sudo dnf install -y docker

    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    sudo systemctl enable docker
    sudo systemctl start docker

  else
    exit 1
  fi

  REPO_URL="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
  REPO_PATH="/home/ubuntu/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ubuntu/.ssh/rsa.pem"

  if ! command -v git &> /dev/null; then
    sudo apt-get install -y git || sudo dnf install -y git || { echo "❌ Failed to install Git"; exit 1; }
  fi

  sudo chown ubuntu:ubuntu "$SSH_KEY_PATH"
  chmod 400 "$SSH_KEY_PATH"

  export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes"

  ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "❌ Failed to add GitHub key"; exit 1; }

  if [ -d "$REPO_PATH" ]; then
    cd "$REPO_PATH"
    git reset --hard
    git pull origin master || { echo "❌ Failed to pull latest changes"; exit 1; }
  else
    git clone "$REPO_URL" "$REPO_PATH" || { echo "❌ Failed to clone repository"; exit 1; }
  fi

  cd "$REPO_PATH"
  docker system prune -f
  docker-compose down --remove-orphans
  docker-compose up -d --build

EOF
