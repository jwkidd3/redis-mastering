#!/bin/bash

echo "🔄 Resetting Lab 6 Environment"
echo "=============================="

# Confirm reset
read -p "⚠️ This will remove all local changes. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Reset cancelled."
    exit 1
fi

echo "🧹 Cleaning up..."

# Remove generated files
rm -rf node_modules package-lock.json

# Remove any test data files
rm -f *.log *.tmp

# Remove environment file (keep template)
rm -f .env

echo "📦 Reinstalling dependencies..."
if [ -f "package.json" ]; then
    npm install
else
    echo "⚠️ package.json not found. Run setup first."
fi

echo "🔧 Recreating environment file..."
if [ -f ".env.template" ]; then
    cp .env.template .env
    echo "✅ Environment template copied to .env"
    echo "⚠️ Remember to update Redis server details!"
else
    echo "❌ .env.template not found"
fi

echo ""
echo "✅ Lab 6 environment reset complete!"
echo ""
echo "Next steps:"
echo "1. Update .env with Redis server details"
echo "2. Run: npm test"
echo "3. Start development: npm run dev"
