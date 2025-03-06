#!/bin/bash

# Exit on any error
set -e

echo "Starting deployment process..."

ssh -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" << 'EOF'
  set -e

  REPO_PATH="/home/ec2-user/flagtickgroup.nexus.vc"
  SSH_KEY_PATH="/home/ec2-user/.ssh/rsa.pem"

  if ! command -v git &> /dev/null; then
    sudo yum install -y git || sudo dnf install -y git || sudo apt-get install -y git || { echo "Failed to install Git."; exit 1; }
  fi

  chmod 600 "$SSH_KEY_PATH"
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts || { echo "Failed to add GitHub key to known_hosts."; exit 1; }
  git config --global core.sshCommand "ssh -i $SSH_KEY_PATH"

  if [ ! -d "$REPO_PATH" ]; then
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || { echo "Failed to clone repository."; exit 1; }
  fi

  cd "$REPO_PATH" || { echo "Failed to navigate to repository directory."; exit 1; }

  if [ ! -d ".git" ]; then
    cd ..
    rm -rf "$REPO_PATH"
    git clone git@github.com:FlagtickGroupInc/flagtickgroup.nexus.vc.git "$REPO_PATH" || { echo "Failed to re-clone repository."; exit 1; }
    cd "$REPO_PATH"
  fi

  git checkout master || { echo "Failed to checkout master branch."; exit 1; }
  git pull origin master || { echo "Failed to pull latest changes from master."; exit 1; }

EOF

echo "Deployment process completed successfully!"
