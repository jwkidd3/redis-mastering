#!/bin/bash

# WSL Ubuntu Setup Script for Lab 5
# Ensures all scripts work properly in WSL environment

set -e

echo "🐧 Setting up Lab 5 for WSL Ubuntu..."
echo "====================================="

# Check if running in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "✅ WSL environment detected"
else
    echo "⚠️  Not running in WSL, but setup will continue"
fi

# Install required packages if missing
echo "📦 Checking required packages..."

# Update package list
sudo apt update

# Check for redis-cli
if ! command -v redis-cli &> /dev/null; then
    echo "Installing Redis CLI..."
    sudo apt install -y redis-tools
else
    echo "✅ Redis CLI found"
fi

# Check for bc (calculator)
if ! command -v bc &> /dev/null; then
    echo "Installing bc calculator..."
    sudo apt install -y bc
else
    echo "✅ bc calculator found"
fi

# Check for dos2unix
if ! command -v dos2unix &> /dev/null; then
    echo "Installing dos2unix..."
    sudo apt install -y dos2unix
else
    echo "✅ dos2unix found"
fi

# Fix line endings for all shell scripts
echo "🔧 Converting line endings..."
find . -name "*.sh" -type f -exec dos2unix {} \; 2>/dev/null || {
    echo "Using sed for line ending conversion..."
    find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
}

# Set proper permissions
echo "🔑 Setting executable permissions..."
find . -name "*.sh" -type f -exec chmod +x {} \;

# Create missing directories
echo "📁 Creating required directories..."
mkdir -p monitoring analysis docs samples automation

# Test Redis connection (if Redis is running)
echo "🔍 Testing Redis connection..."
if redis-cli ping &> /dev/null; then
    echo "✅ Redis connection successful"
else
    echo "⚠️  Redis not running. Start with:"
    echo "   docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine"
fi

echo ""
echo "✅ WSL setup complete!"
echo ""
echo "🚀 Next steps:"
echo "   1. Start Redis: docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine"
echo "   2. Load data: ./scripts/load-production-data.sh"
echo "   3. Start monitoring: ./scripts/production-monitor.sh"
echo "   4. Open Redis Insight and connect to localhost:6379"
echo ""
