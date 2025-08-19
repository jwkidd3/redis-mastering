#!/bin/bash

# WSL Troubleshooting Script for Lab 5
# Diagnoses and fixes common WSL issues

set -e

echo "🔧 WSL Troubleshooting for Lab 5"
echo "================================"

# Function to check and report status
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
    fi
}

# Check WSL environment
echo "🐧 Environment Check:"
echo "---------------------"
uname -a
grep -i microsoft /proc/version && echo "✅ Running in WSL" || echo "⚠️  Not running in WSL"

# Check required commands
echo ""
echo "📦 Required Tools Check:"
echo "------------------------"
command -v docker &> /dev/null
check_status "Docker available"

command -v redis-cli &> /dev/null
check_status "Redis CLI available"

command -v bc &> /dev/null
check_status "bc calculator available"

command -v dos2unix &> /dev/null
check_status "dos2unix available"

# Check Docker
echo ""
echo "🐳 Docker Check:"
echo "----------------"
docker --version &> /dev/null
check_status "Docker version accessible"

docker ps &> /dev/null
check_status "Docker daemon running"

# Check Redis container
echo ""
echo "📊 Redis Check:"
echo "---------------"
if docker ps | grep redis-lab5 &> /dev/null; then
    echo "✅ Redis container running"
    redis-cli ping &> /dev/null
    check_status "Redis responding to ping"
else
    echo "⚠️  Redis container not found"
    echo "   Run: docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine"
fi

# Check script permissions
echo ""
echo "🔑 Script Permissions Check:"
echo "----------------------------"
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script executable"
    else
        echo "❌ $script not executable"
        chmod +x "$script"
        echo "   Fixed: chmod +x $script"
    fi
done

# Check line endings
echo ""
echo "📝 Line Endings Check:"
echo "----------------------"
for script in scripts/*.sh; do
    if file "$script" | grep -q "CRLF"; then
        echo "❌ $script has Windows line endings"
        if command -v dos2unix &> /dev/null; then
            dos2unix "$script"
            echo "   Fixed: converted to Unix line endings"
        else
            sed -i 's/\r$//' "$script"
            echo "   Fixed: converted with sed"
        fi
    else
        echo "✅ $script has Unix line endings"
    fi
done

# Check file structure
echo ""
echo "📁 File Structure Check:"
echo "------------------------"
[ -f "lab5.md" ] && echo "✅ lab5.md" || echo "❌ lab5.md missing"
[ -d "scripts" ] && echo "✅ scripts/ directory" || echo "❌ scripts/ directory missing"
[ -d "monitoring" ] && echo "✅ monitoring/ directory" || echo "❌ monitoring/ directory missing"
[ -d "analysis" ] && echo "✅ analysis/ directory" || echo "❌ analysis/ directory missing"

# Quick fixes
echo ""
echo "🔧 Quick Fixes:"
echo "---------------"

# Create missing directories
for dir in monitoring analysis docs samples automation; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "✅ Created $dir/ directory"
    fi
done

# Fix all script permissions
find . -name "*.sh" -type f -exec chmod +x {} \;
echo "✅ Fixed all script permissions"

echo ""
echo "🎯 Summary:"
echo "----------"
echo "If issues persist:"
echo "1. Run: ./setup-wsl.sh"
echo "2. Start Redis: docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine"
echo "3. Test script: ./scripts/load-production-data.sh"
echo "4. Check Docker is running in WSL settings"
echo ""
echo "For more help, check docs/troubleshooting.md"
