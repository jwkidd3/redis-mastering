#!/bin/bash

# Quick Start Script for Lab 5 - WSL Compatible
# Automatically sets up and starts the lab environment

set -e

echo "🚀 Lab 5 Quick Start"
echo "==================="

# Step 1: Setup WSL environment
echo "Step 1: Setting up WSL environment..."
if [ -f "setup-wsl.sh" ]; then
    ./setup-wsl.sh
else
    echo "⚠️  setup-wsl.sh not found, continuing..."
fi

# Step 2: Start Redis if not running
echo ""
echo "Step 2: Starting Redis..."
if ! redis-cli ping &> /dev/null; then
    echo "Starting Redis container..."
    docker run -d --name redis-lab5 -p 6379:6379 -v redis-lab5-data:/data redis:7-alpine redis-server --appendonly yes
    
    # Wait for Redis to start
    echo "Waiting for Redis to start..."
    sleep 5
    
    # Test connection
    if redis-cli ping &> /dev/null; then
        echo "✅ Redis started successfully"
    else
        echo "❌ Redis failed to start"
        exit 1
    fi
else
    echo "✅ Redis already running"
fi

# Step 3: Load production data
echo ""
echo "Step 3: Loading production data..."
if [ -f "scripts/load-production-data.sh" ]; then
    ./scripts/load-production-data.sh
else
    echo "❌ Data loader script not found"
    exit 1
fi

# Step 4: Run initial health check
echo ""
echo "Step 4: Running initial health check..."
if [ -f "scripts/health-report.sh" ]; then
    ./scripts/health-report.sh
else
    echo "⚠️  Health report script not found"
fi

echo ""
echo "🎉 Lab 5 Quick Start Complete!"
echo "=============================="
echo ""
echo "✅ Redis is running on localhost:6379"
echo "✅ Production data loaded"
echo "✅ Scripts ready to use"
echo ""
echo "🔍 Next steps:"
echo "   • Open Redis Insight → Connect to localhost:6379"
echo "   • Run monitoring: ./scripts/production-monitor.sh"
echo "   • Follow lab5.md for detailed instructions"
echo ""
echo "📊 Available commands:"
echo "   ./scripts/production-monitor.sh    - Real-time monitoring"
echo "   ./scripts/performance-analysis.sh  - Performance testing"
echo "   ./scripts/capacity-planning.sh     - Capacity analysis"
echo "   ./scripts/setup-alerts.sh          - Configure alerts"
echo ""
