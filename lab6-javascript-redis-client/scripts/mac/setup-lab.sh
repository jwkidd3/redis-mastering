#!/bin/bash

echo "⚙️ Lab 6 Setup: JavaScript Redis Client"
echo "======================================"

# Check Node.js
echo "Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js found: $NODE_VERSION"
    
    # Check if version is 16+
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$MAJOR_VERSION" -ge 16 ]; then
        echo "✅ Node.js version is compatible (16+)"
    else
        echo "⚠️ Node.js version should be 16 or higher"
        echo "Current version: $NODE_VERSION"
    fi
else
    echo "❌ Node.js not found"
    echo ""
    echo "Please install Node.js from: https://nodejs.org/"
    echo "Recommended: Latest LTS version"
    exit 1
fi

# Check npm
echo ""
echo "Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm found: v$NPM_VERSION"
else
    echo "❌ npm not found (should come with Node.js)"
    exit 1
fi

# Check Redis CLI (for verification)
echo ""
echo "Checking Redis CLI..."
if command -v redis-cli &> /dev/null; then
    REDIS_CLI_VERSION=$(redis-cli --version)
    echo "✅ Redis CLI found: $REDIS_CLI_VERSION"
    echo "💡 Use for testing connection before JavaScript development"
else
    echo "⚠️ Redis CLI not found"
    echo "💡 Not required for this lab, but useful for testing"
fi

echo ""
echo "📋 Next steps:"
echo "1. Get Redis server details from instructor"
echo "2. Copy .env.template to .env and update with server details"
echo "3. Run: npm install"
echo "4. Test connection: npm run test"
echo "5. Start development: npm run dev"

echo ""
echo "🎯 Lab 6 environment check complete!"
