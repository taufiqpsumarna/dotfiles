#!/bin/sh
PATH="/tmp/code-server/bin:$PATH"

set -e
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' sudo -E bash
echo "Install server packages"
# Run programs at workspace startup
apt update && apt upgrade -y \
apt install -y \
infisical \
git \
curl \
wget \
vim \
nano \
dnsutils

# Fixing folder permissions inside container
echo "Fixing folder permissions"
sudo chown -R $(whoami):$(whoami) /home/$(whoami)
touch /home/$(whoami)/personalize && chmod +x /home/$(whoami)/personalize
chmod +x /home/$(whoami)/.config/coderv2/dotfiles/install.sh


# Install python packages
pip install awscli 
