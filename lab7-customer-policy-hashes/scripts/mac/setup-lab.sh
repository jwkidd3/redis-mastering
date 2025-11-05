#!/bin/bash

echo "⚙️ Lab 7 Setup: Customer Profiles & Policy Management"
echo "===================================================="

# Check Node.js
echo "Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "✅ Node.js found: $(node --version)"
else
    echo "❌ Node.js not found"
    echo "Please install Node.js from: https://nodejs.org/"
    exit 1
fi

# Check npm
echo "Checking npm..."
if command -v npm &> /dev/null; then
    echo "✅ npm found: $(npm --version)"
else
    echo "❌ npm not found"
    exit 1
fi

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Test Redis connection
echo ""
echo "Testing Redis connection..."
node test-connection.js

echo ""
echo "📋 Available test scripts:"
echo "  npm run test-customers     # Test customer operations"
echo "  npm run test-policies      # Test policy operations"
echo "  npm run test-integrated    # Test integrated CRM system"
echo "  npm run test-advanced      # Test advanced hash operations"

echo ""
echo "🎯 Lab 7 setup completed!"
echo "📖 Open lab7.md for detailed instructions"
