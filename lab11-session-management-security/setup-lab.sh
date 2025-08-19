#!/bin/bash

echo "⚙️ Lab 11 Setup: Customer Portal Session Management & Security"
echo "=============================================================="

# Check Node.js
echo "Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "✅ Node.js found: $(node --version)"
else
    echo "❌ Node.js not found"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check npm
echo "Checking npm installation..."
if command -v npm &> /dev/null; then
    echo "✅ npm found: $(npm --version)"
else
    echo "❌ npm not found"
    exit 1
fi

# Check Redis CLI
echo "Checking Redis CLI installation..."
if command -v redis-cli &> /dev/null; then
    echo "✅ Redis CLI found: $(redis-cli --version)"
else
    echo "❌ Redis CLI not found"
    echo ""
    echo "Installation instructions:"
    echo "Windows: Download from https://github.com/tporadowski/redis/releases"
    echo "macOS: brew install redis"
    echo "Linux: sudo apt-get install redis-tools"
    exit 1
fi

# Install npm dependencies
echo ""
echo "Installing npm dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Create environment file
if [ ! -f .env ]; then
    echo ""
    echo "Creating environment configuration..."
    cp config/.env.example .env
    echo "✅ Environment file created (.env)"
    echo "⚠️  Please update .env with your Redis connection details"
fi

# Test Redis connection
echo ""
echo "Testing Redis connection..."
echo "ℹ️  Make sure you have the Redis host details from your instructor"

echo ""
echo "📋 Next steps:"
echo "1. Update .env file with Redis connection details from instructor"
echo "2. Test connection: redis-cli -h [host] -p 6379 PING"
echo "3. Run basic test: npm test"
echo "4. Run RBAC test: npm run test-rbac"
echo "5. Run security test: npm run test-security"
echo "6. Follow lab11.md for complete instructions"

echo ""
echo "🎯 Lab 11 is ready to begin!"
