#!/bin/bash
# DevOps Engineer Dotfiles Initialization Script
# This script installs essential system packages, CLI tools, and DevOps utilities.
# Designed for container or workstation bootstrap.

set -euo pipefail

PATH="/tmp/code-server/bin:$PATH"

# --- Install System Packages ---
echo "Installing server packages"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y \
  btop \
  git \
  curl \
  wget \
  vim \
  nano \
  dnsutils \
  python3-pip

# --- Fix Folder Permissions ---
echo "Fixing folder permissions"
USER_HOME="/home/$(whoami)"
sudo chown -R $(whoami):$(whoami) "$USER_HOME"

touch "$USER_HOME/personalize"
chmod +x "$USER_HOME/personalize"

mkdir -p "$USER_HOME/.config/coderv2/dotfiles"
touch "$USER_HOME/.config/coderv2/dotfiles/install.sh"
chmod +x "$USER_HOME/.config/coderv2/dotfiles/install.sh"

# --- Python Packages ---
pip3 install --upgrade awscli

echo "Dotfiles setup completed."
