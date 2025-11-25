#!/bin/bash
# DevOps Engineer Dotfiles Initialization Script
# This script installs essential system packages, CLI tools, and DevOps utilities.
# Designed for container or workstation bootstrap.

set -euo pipefail

PATH="/tmp/code-server/bin:$PATH"

# --- Install System Packages ---
echo "Updating package lists and upgrading system packages..."
sudo apt-get update -y
sudo apt-get dist-upgrade -y

echo "Installing essential system packages..."
sudo apt-get install -y \
  git \
  curl \
  wget \
  vim \
  nano \
  dnsutils \
  zip \
  unzip \
  tar

# --- Fix Folder Permissions ---
echo "Fixing folder permissions"
USER_HOME="/home/$(whoami)"
sudo chown -R $(whoami):$(whoami) "$USER_HOME"

touch "$USER_HOME/personalize"
chmod +x "$USER_HOME/personalize"

mkdir -p "$USER_HOME/.config/coderv2/dotfiles"
touch "$USER_HOME/.config/coderv2/dotfiles/install.sh"
chmod +x "$USER_HOME/.config/coderv2/dotfiles/install.sh"

# --- Install AWS CLI v2 ---
echo "Installing AWS CLI v2"
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -o /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update

# --- Install kubectl ---
echo "Installing kubectl"
curl -sLO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# --- Install kubectx ---
echo "Installing kubectx"
sudo apt install kubectx

# --- Install k9s ---
echo "Installing k9s"
LATEST_K9S=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep browser_download_url | grep Linux_x86_64.tar.gz | cut -d '"' -f 4)
curl -sL "$LATEST_K9S" -o /tmp/k9s.tar.gz
tar -xzf /tmp/k9s.tar.gz -C /tmp
sudo mv /tmp/k9s /usr/local/bin/

# --- Install Helm ---
echo "Installing Helm"
curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# --- Install lazydocker ---
echo "Installing lazydocker"
curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

echo "Dotfiles setup completed."
