#!/bin/bash

echo "✅ Lab 6 Setup Validation"
echo "========================="

SUCCESS=true

# Check Node.js
echo "🟢 Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js: $NODE_VERSION"
    
    # Check version >= 16
    MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v//' | cut -d'.' -f1)
    if [ "$MAJOR_VERSION" -ge 16 ]; then
        echo "✅ Node.js version is compatible"
    else
        echo "❌ Node.js version should be 16 or higher"
        SUCCESS=false
    fi
else
    echo "❌ Node.js not found"
    SUCCESS=false
fi

# Check npm
echo ""
echo "🟢 Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm: v$NPM_VERSION"
else
    echo "❌ npm not found"
    SUCCESS=false
fi

# Check project files
echo ""
echo "🟢 Checking project structure..."

REQUIRED_FILES=(
    "package.json"
    ".env"
    "src/app.js"
    "src/config/redis.js"
    "src/clients/redisClient.js"
    "tests/connection-test.js"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file missing"
        SUCCESS=false
    fi
done

# Check node_modules
echo ""
echo "🟢 Checking dependencies..."
if [ -d "node_modules" ]; then
    echo "✅ node_modules directory exists"
    
    # Check key dependencies
    if [ -d "node_modules/redis" ]; then
        echo "✅ Redis client installed"
    else
        echo "❌ Redis client not installed"
        SUCCESS=false
    fi
    
    if [ -d "node_modules/dotenv" ]; then
        echo "✅ dotenv installed"
    else
        echo "❌ dotenv not installed"
        SUCCESS=false
    fi
else
    echo "❌ node_modules not found - run npm install"
    SUCCESS=false
fi

# Check environment configuration
echo ""
echo "🟢 Checking environment configuration..."
if [ -f ".env" ]; then
    if grep -q "REDIS_HOST=" .env; then
        REDIS_HOST=$(grep "REDIS_HOST=" .env | cut -d'=' -f2)
        if [ "$REDIS_HOST" != "" ] && [ "$REDIS_HOST" != "redis-server.training.com" ]; then
            echo "✅ REDIS_HOST configured: $REDIS_HOST"
        else
            echo "⚠️ REDIS_HOST needs to be updated with actual server details"
        fi
    else
        echo "❌ REDIS_HOST not found in .env"
        SUCCESS=false
    fi
    
    if grep -q "REDIS_PORT=" .env; then
        echo "✅ REDIS_PORT configured"
    else
        echo "❌ REDIS_PORT not found in .env"
        SUCCESS=false
    fi
else
    echo "❌ .env file not found"
    SUCCESS=false
fi

# Test Redis connection (if everything else is OK)
if [ "$SUCCESS" = true ]; then
    echo ""
    echo "🟢 Testing Redis connection..."
    if node tests/connection-test.js > /dev/null 2>&1; then
        echo "✅ Redis connection successful"
    else
        echo "❌ Redis connection failed"
        echo "💡 Check your .env file and server details"
        SUCCESS=false
    fi
fi

echo ""
echo "================================="
if [ "$SUCCESS" = true ]; then
    echo "🎉 Lab 6 setup validation PASSED!"
    echo ""
    echo "🚀 Ready to start the lab!"
    echo "Run: npm start"
else
    echo "❌ Lab 6 setup validation FAILED!"
    echo ""
    echo "🔧 Actions needed:"
    echo "1. Fix the issues listed above"
    echo "2. Run this validation again"
    echo "3. Contact instructor if problems persist"
fi

echo ""
exit $([ "$SUCCESS" = true ] && echo 0 || echo 1)
