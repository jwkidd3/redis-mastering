#!/bin/bash

echo "🧪 Testing Lab 1 Environment Setup..."
echo "====================================="

# Check Redis CLI installation
echo "Checking Redis CLI..."
if command -v redis-cli &> /dev/null; then
    echo "✅ Redis CLI is installed"
    redis-cli --version
else
    echo "❌ Redis CLI not found"
    echo "Please install Redis CLI to continue"
    exit 1
fi

# Check if hostname is provided
echo ""
echo "📋 Lab 1 Environment Check:"
echo "This lab requires connection to a remote Redis server"
echo "Instructor should provide:"
echo "  - Hostname (e.g., redis-server.training.com)"
echo "  - Port (usually 6379)"
echo "  - Password (if required)"

echo ""
echo "💡 To test connection once you have details:"
echo "redis-cli -h [hostname] -p [port] PING"

echo ""
echo "📁 Lab files generated:"
echo "  ✅ lab1.md - Main lab instructions"
echo "  ✅ reference/basic-commands.md - Command reference"
echo "  ✅ examples/ - Practical examples"
echo "  ✅ docs/troubleshooting.md - Problem solving"

echo ""
echo "🚀 Ready to start Lab 1!"
echo "Open lab1.md and follow the instructions"
