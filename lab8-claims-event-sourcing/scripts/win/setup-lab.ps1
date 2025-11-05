# Setting up Lab 8: Claims Event Sourcing with Redis Streams
# PowerShell version for Windows

Write-Host "🚀 Setting up Lab 8: Claims Event Sourcing with Redis Streams" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Check if Node.js is installed
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "❌ Node.js not found. Please install Node.js 16+ before continuing." -ForegroundColor Red
    exit 1
}

# Check if npm is installed
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmCmd) {
    Write-Host "❌ npm not found. Please install npm before continuing." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Node.js and npm found" -ForegroundColor Green

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

# Create .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "⚙️  Creating .env file from template..." -ForegroundColor Yellow
    if (Test-Path ".env.template") {
        Copy-Item ".env.template" ".env"
        Write-Host "📝 Please edit .env file with your Redis connection details" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Validate the setup
Write-Host "🔍 Running validation..." -ForegroundColor Yellow
if (Test-Path "validation/validate-setup.js") {
    node validation/validate-setup.js
}

Write-Host ""
Write-Host "🎉 Lab 8 setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Edit .env with your Redis connection details"
Write-Host "2. Run: npm run validate"
Write-Host "3. Start the lab: open lab8.md"
Write-Host ""
Write-Host "Available commands:"
Write-Host "  npm run producer  - Start claim producer API"
Write-Host "  npm run consumer  - Start claim processor"
Write-Host "  npm run analytics - Run claim analytics"
Write-Host "  npm run validate  - Validate setup"
Write-Host "  npm run health    - Health check"
