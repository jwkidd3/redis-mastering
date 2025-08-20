#!/bin/bash

# Environment validation script for Lab 8
# Checks all prerequisites and dependencies

echo "🔍 Lab 8 Environment Validation"
echo "================================"

VALIDATION_PASSED=true

# Check Node.js
echo "📦 Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v//' | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -ge 18 ]; then
        echo "✅ Node.js: $NODE_VERSION (compatible)"
    else
        echo "❌ Node.js version must be 18 or higher (current: $NODE_VERSION)"
        VALIDATION_PASSED=false
    fi
else
    echo "❌ Node.js not found"
    VALIDATION_PASSED=false
fi

# Check npm
echo "📦 Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm: v$NPM_VERSION"
else
    echo "❌ npm not found"
    VALIDATION_PASSED=false
fi

# Check Docker
echo "🐳 Checking Docker..."
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo "✅ Docker is running"
    else
        echo "❌ Docker is installed but not running"
        VALIDATION_PASSED=false
    fi
else
    echo "❌ Docker not found"
    VALIDATION_PASSED=false
fi

# Check Redis connection
echo "🔄 Checking Redis connection..."
REDIS_HOST=${REDIS_HOST:-localhost}
REDIS_PORT=${REDIS_PORT:-6379}

if command -v redis-cli &> /dev/null; then
    if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping | grep -q PONG; then
        echo "✅ Redis connection successful ($REDIS_HOST:$REDIS_PORT)"
    else
        echo "❌ Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT"
        echo "💡 Set REDIS_HOST and REDIS_PORT environment variables if using remote Redis"
        VALIDATION_PASSED=false
    fi
else
    echo "⚠️ redis-cli not found (optional, but recommended for debugging)"
fi

# Check required directories
echo "📁 Checking project structure..."
REQUIRED_DIRS=("src" "scripts" "tests" "validation" "monitoring")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ Directory: $dir"
    else
        echo "❌ Missing directory: $dir"
        VALIDATION_PASSED=false
    fi
done

# Check package.json
echo "📄 Checking package.json..."
if [ -f "package.json" ]; then
    echo "✅ package.json found"
    
    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        echo "✅ Dependencies installed"
    else
        echo "⚠️ Dependencies not installed. Run: npm install"
    fi
else
    echo "❌ package.json not found"
    VALIDATION_PASSED=false
fi

# Final result
echo ""
echo "================================"
if [ "$VALIDATION_PASSED" = true ]; then
    echo "🎉 Environment validation PASSED!"
    echo "✅ Ready to proceed with Lab 8"
else
    echo "❌ Environment validation FAILED!"
    echo "🔧 Please fix the issues above before continuing"
    exit 1
fi
