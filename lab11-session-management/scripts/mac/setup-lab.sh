#!/bin/bash

echo "🚀 Setting up Lab 11: Session Management"
echo "========================================"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 16 or higher"
    exit 1
fi
echo "✅ Node.js available: $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm"
    exit 1
fi
echo "✅ npm available: $(npm --version)"

# Install dependencies
echo ""
echo "📦 Installing Node.js dependencies..."
npm install

# Check Redis CLI (optional but recommended)
if command -v redis-cli &> /dev/null; then
    echo "✅ Redis CLI available: $(redis-cli --version)"
else
    echo "⚠️  Redis CLI not found. Please install Redis CLI tools"
fi

# Create .env if it doesn't exist
if [ ! -f "config/.env" ]; then
    echo ""
    echo "📝 Creating environment configuration..."
    cp config/.env.example config/.env
    echo "⚠️ Please update config/.env with instructor-provided Redis details"
fi

echo ""
echo "✅ Lab 11 setup complete!"
echo ""
echo "Next steps:"
echo "1. Update config/.env with Redis connection details"
echo "2. Run: npm test"
echo "3. Open Redis Insight to monitor sessions"
echo "4. Follow lab11.md instructions"
