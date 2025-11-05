# Lab 6 Setup: JavaScript Redis Client
# PowerShell version for Windows

Write-Host "⚙️ Lab 6 Setup: JavaScript Redis Client" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check Node.js
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVersion = node --version
    Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green

    # Check if version is 16+
    $majorVersion = [int]($nodeVersion -replace 'v','').Split('.')[0]
    if ($majorVersion -ge 16) {
        Write-Host "✅ Node.js version is compatible (16+)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Node.js version should be 16 or higher" -ForegroundColor Yellow
        Write-Host "Current version: $nodeVersion"
    }
} else {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Node.js from: https://nodejs.org/"
    Write-Host "Recommended: Latest LTS version"
    exit 1
}

# Check npm
Write-Host ""
Write-Host "Checking npm..." -ForegroundColor Yellow
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    $npmVersion = npm --version
    Write-Host "✅ npm found: v$npmVersion" -ForegroundColor Green
} else {
    Write-Host "❌ npm not found (should come with Node.js)" -ForegroundColor Red
    exit 1
}

# Check Redis CLI (for verification)
Write-Host ""
Write-Host "Checking Redis CLI..." -ForegroundColor Yellow
$redisCmd = Get-Command redis-cli -ErrorAction SilentlyContinue
if ($redisCmd) {
    $redisVersion = redis-cli --version
    Write-Host "✅ Redis CLI found: $redisVersion" -ForegroundColor Green
    Write-Host "💡 Use for testing connection before JavaScript development"
} else {
    Write-Host "⚠️  Redis CLI not found" -ForegroundColor Yellow
    Write-Host "💡 Not required for this lab, but useful for testing"
}

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Get Redis server details from instructor"
Write-Host "2. Copy .env.template to .env and update with server details"
Write-Host "3. Run: npm install"
Write-Host "4. Test connection: npm run test"
Write-Host "5. Start development: npm run dev"

Write-Host ""
Write-Host "🎯 Lab 6 environment check complete!" -ForegroundColor Green
