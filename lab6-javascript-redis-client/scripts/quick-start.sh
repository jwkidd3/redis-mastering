#!/bin/bash

echo "🚀 Quick Start: Lab 6 JavaScript Redis Client"
echo "============================================="

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "📦 Initializing Node.js project..."
    cp package.json.template package.json
    npm install
    echo "✅ Dependencies installed"
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "🔧 Setting up environment..."
    cp .env.template .env
    echo "⚠️ Please update .env with your Redis server details!"
    echo ""
else
    echo "✅ Environment file found"
fi

# Test Redis connection
echo ""
echo "🧪 Testing Redis connection..."
if [ -f "tests/connection-test.js" ]; then
    node tests/connection-test.js
else
    echo "⚠️ Connection test not found. Run full lab setup first."
fi

echo ""
echo "🎯 Quick start complete!"
echo ""
echo "Available commands:"
echo "  npm start       - Run main application"
echo "  npm run dev     - Run with auto-restart"
echo "  npm test        - Test Redis connection"
echo "  npm run examples - Run example operations"
