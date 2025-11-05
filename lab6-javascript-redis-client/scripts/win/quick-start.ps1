# Quick Start: Lab 6 JavaScript Redis Client
# PowerShell version for Windows

Write-Host "🚀 Quick Start: Lab 6 JavaScript Redis Client" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check if package.json exists
if (-not (Test-Path "package.json")) {
    Write-Host "📦 Initializing Node.js project..." -ForegroundColor Yellow
    if (Test-Path "package.json.template") {
        Copy-Item "package.json.template" "package.json"
    }
    npm install
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
}

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "🔧 Setting up environment..." -ForegroundColor Yellow
    if (Test-Path ".env.template") {
        Copy-Item ".env.template" ".env"
        Write-Host "⚠️  Please update .env with your Redis server details!" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "✅ Environment file found" -ForegroundColor Green
}

# Test Redis connection
Write-Host ""
Write-Host "🧪 Testing Redis connection..." -ForegroundColor Yellow
if (Test-Path "tests/connection-test.js") {
    node tests/connection-test.js
} else {
    Write-Host "⚠️  Connection test not found. Run full lab setup first." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Quick start complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:"
Write-Host "  npm start       - Run main application"
Write-Host "  npm run dev     - Run with auto-restart"
Write-Host "  npm test        - Test Redis connection"
Write-Host "  npm run examples - Run example operations"
