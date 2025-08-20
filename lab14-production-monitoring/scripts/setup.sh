#!/bin/bash

# Setup script for Lab 14: Production Monitoring Setup

set -e

echo "🚀 Setting up Lab 14 Production Monitoring..."

# Install npm dependencies
echo "📦 Installing npm dependencies..."
npm install

# Make scripts executable
chmod +x scripts/*.sh

# Create log directory
mkdir -p logs

echo "🎉 Setup complete!"
echo "🚀 Run 'npm start' to begin monitoring"
echo "📊 Health check: http://localhost:3000/health"
echo "📈 Dashboard: http://localhost:4000"
