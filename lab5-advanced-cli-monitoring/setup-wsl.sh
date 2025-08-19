#!/bin/bash

# WSL Ubuntu Setup for Lab 5
set -e

echo "🐧 Setting up Lab 5 for WSL Ubuntu..."

# Install required packages
sudo apt update
sudo apt install -y redis-tools bc

# Fix script permissions
find . -name "*.sh" -exec chmod +x {} \;

# Fix line endings
find . -name "*.sh" -exec sed -i "s/\r$//" {} \;

# Create directories
mkdir -p monitoring analysis docs

# Test Redis CLI
redis-cli --version

echo "✅ WSL setup complete!"
echo "Next: docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine"
