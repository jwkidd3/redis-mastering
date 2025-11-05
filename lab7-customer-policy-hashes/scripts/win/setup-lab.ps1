# Lab 7 Setup: Customer Profiles & Policy Management
# PowerShell version for Windows

Write-Host "⚙️ Lab 7 Setup: Customer Profiles & Policy Management" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Check Node.js
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVersion = node --version
    Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    Write-Host "Please install Node.js from: https://nodejs.org/"
    exit 1
}

# Check npm
Write-Host "Checking npm..." -ForegroundColor Yellow
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    $npmVersion = npm --version
    Write-Host "✅ npm found: $npmVersion" -ForegroundColor Green
} else {
    Write-Host "❌ npm not found" -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install

# Test Redis connection
Write-Host ""
Write-Host "Testing Redis connection..." -ForegroundColor Yellow
node test-connection.js

Write-Host ""
Write-Host "📋 Available test scripts:" -ForegroundColor Cyan
Write-Host "  npm run test-customers     # Test customer operations"
Write-Host "  npm run test-policies      # Test policy operations"
Write-Host "  npm run test-integrated    # Test integrated CRM system"
Write-Host "  npm run test-advanced      # Test advanced hash operations"

Write-Host ""
Write-Host "🎯 Lab 7 setup completed!" -ForegroundColor Green
Write-Host "📖 Open lab7.md for detailed instructions"
