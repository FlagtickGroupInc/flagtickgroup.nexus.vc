#!/bin/bash

set -e

echo "🚀 Starting deployment process..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  
  set -e

  REPO_URL="git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git"
  REPO_PATH="/home/ec2-user/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/id_rsa"

  if ! command -v git &> /dev/null; then
    sudo yum install -y git || sudo dnf install -y git || sudo apt-get install -y git || { echo "❌ Failed to install Git"; exit 1; }
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

EOF
