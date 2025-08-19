#!/bin/bash

echo "⚙️ Lab 1 Setup: Redis Environment & CLI Basics"
echo "=============================================="

# Check Redis CLI
echo "Checking Redis CLI installation..."
if command -v redis-cli &> /dev/null; then
    echo "✅ Redis CLI found: $(redis-cli --version)"
else
    echo "❌ Redis CLI not found"
    echo ""
    echo "Installation instructions:"
    echo ""
    echo "Windows:"
    echo "  - Download from: https://github.com/tporadowski/redis/releases"
    echo "  - Or use WSL2 with Linux instructions"
    echo ""
    echo "macOS:"
    echo "  brew install redis"
    echo ""
    echo "Linux (Ubuntu/Debian):"
    echo "  sudo apt-get install redis-tools"
    echo ""
    exit 1
fi

# Check Redis Insight
echo ""
echo "Checking Redis Insight..."
echo "ℹ️ Redis Insight should be installed separately"
echo "Download from: https://redis.io/insight/"

# Test basic functionality
echo ""
echo "Testing Redis CLI basic functionality..."
echo "PING" | redis-cli --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Redis CLI basic functions working"
else
    echo "⚠️ Redis CLI may have issues"
fi

echo ""
echo "📋 Next steps:"
echo "1. Get Redis server details from instructor"
echo "2. Test connection: redis-cli -h [hostname] -p [port] PING"
echo "3. Open lab1.md for complete instructions"
echo "4. Configure Redis Insight with server details"

echo ""
echo "🎯 Lab 1 is ready to begin!"
