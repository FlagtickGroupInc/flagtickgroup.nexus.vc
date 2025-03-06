#!/bin/bash
set -e  # Exit on error

echo "🚀 Deploying Nexus on VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'

  set -e

  echo "🔹 Installing Dependencies..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

  echo "🔹 Setting up SSH for GitHub..."
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts

  SSH_KEY_PATH="/home/ubuntu/.ssh/rsa.pem"
  sudo chown ubuntu:ubuntu "$SSH_KEY_PATH"
  chmod 400 "$SSH_KEY_PATH"

  eval "\$(ssh-agent -s)"
  ssh-add "$SSH_KEY_PATH"

  echo "🔹 Checking SSH access..."
  ssh -T git@github.com || { echo "❌ SSH to GitHub failed."; exit 1; }

  REPO_URL="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
  REPO_PATH="/home/ubuntu/flagtickgroup.nexus.vc"

  echo "🔹 Cloning Repository..."
  if [ -d "$REPO_PATH" ]; then
    cd "$REPO_PATH"
    git reset --hard
    git pull origin master || { echo "❌ Git pull failed."; exit 1; }
  else
    git clone "$REPO_URL" "$REPO_PATH" || { echo "❌ Git clone failed."; exit 1; }
  fi

  cd "$REPO_PATH"

  echo "🔹 Fixing Docker Permissions..."
  sudo usermod -aG docker ubuntu
  newgrp docker
  sudo systemctl enable --now docker
  sudo systemctl restart docker

  echo "🔹 Deploying with Docker..."
  docker system prune -f
  docker-compose down --remove-orphans
  docker-compose up -d --build || { echo "❌ Docker Compose failed."; exit 1; }

EOF
