#!/bin/bash

echo "🚀 Setting up Lab 8: Claims Event Sourcing with Redis Streams"
echo "================================================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 16+ before continuing."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm before continuing."
    exit 1
fi

echo "✅ Node.js and npm found"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file from template..."
    cp .env.template .env
    echo "📝 Please edit .env file with your Redis connection details"
else
    echo "✅ .env file already exists"
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh

# Validate the setup
echo "🔍 Running validation..."
node validation/validate-setup.js

echo ""
echo "🎉 Lab 8 setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env with your Redis connection details"
echo "2. Run: npm run validate"
echo "3. Start the lab: open lab8.md"
echo ""
echo "Available commands:"
echo "  npm run producer  - Start claim producer API"
echo "  npm run consumer  - Start claim processor"
echo "  npm run analytics - Run claim analytics"
echo "  npm run validate  - Validate setup"
echo "  npm run health    - Health check"
