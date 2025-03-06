#!/bin/bash

set -e

echo "🚀 Starting Nexus Deployment on Remote VPS..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'

  set -e

  echo "🔹 Ensuring necessary dependencies are installed..."

  # Detect package manager
  if command -v apt-get &> /dev/null; then
    echo "🔹 Detected Ubuntu/Debian - Using apt-get"
    sudo apt-get update
    sudo apt-get remove -y containerd containerd.io docker docker.io docker-engine
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

  elif command -v dnf &> /dev/null; then
    echo "🔹 Detected Amazon Linux / Red Hat - Using dnf"
    sudo dnf install -y docker docker-compose
    sudo systemctl enable docker
    sudo systemctl start docker

  else
    echo "❌ Unsupported package manager. Exiting."
    exit 1
  fi

  echo "✅ Docker and dependencies installed."

  echo "🔹 Cloning or updating Nexus repository..."
  REPO_URL="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
  REPO_PATH="/home/ec2-user/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/rsa.pem"

  if ! command -v git &> /dev/null; then
    echo "🔹 Installing Git..."
    sudo dnf install -y git || sudo apt-get install -y git || { echo "❌ Failed to install Git"; exit 1; }
  fi

  chmod 600 "$SSH_KEY_PATH"
  eval $(ssh-agent -s)
  ssh-add "$SSH_KEY_PATH"

  ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "❌ Failed to add GitHub key"; exit 1; }

  git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

  if [ -d "$REPO_PATH" ]; then
    cd "$REPO_PATH"
    git reset --hard
    git pull origin master || { echo "❌ Failed to pull latest changes"; exit 1; }
  else
    git clone "$REPO_URL" "$REPO_PATH" || { echo "❌ Failed to clone repository"; exit 1; }
  fi

  echo "✅ Repository updated."

  echo "🔹 Starting Nexus using Docker Compose..."
  cd "$REPO_PATH"
  docker-compose down
  docker-compose up -d --build

  echo "✅ Nexus successfully deployed!"

EOF
