#!/bin/bash
set -e

echo "Installing Docker on Ubuntu..."

# Update package index
echo ">>> Updating package list..."
sudo apt-get update

# Install prerequisites
echo ">>> Installing prerequisites..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo ">>> Adding Docker's GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the repository
echo ">>> Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo ">>> Updating package list with Docker repository..."
sudo apt-get update

# Install Docker Engine
echo ">>> Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
echo ">>> Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
echo ">>> Adding $USER to docker group..."
sudo usermod -aG docker $USER

echo ""
echo "✓ Docker installed successfully!"
echo ""
echo "IMPORTANT: You need to log out and log back in (or run 'newgrp docker')"
echo "for the group changes to take effect, so you can run Docker without sudo."
echo ""
echo "To verify installation, run: docker --version"