# Setting up Lab 11: Session Management
# PowerShell version for Windows

Write-Host "🚀 Setting up Lab 11: Session Management" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check Node.js
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "❌ Node.js not found. Please install Node.js 16 or higher" -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "✅ Node.js available: $nodeVersion" -ForegroundColor Green

# Check npm
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmCmd) {
    Write-Host "❌ npm not found. Please install npm" -ForegroundColor Red
    exit 1
}
$npmVersion = npm --version
Write-Host "✅ npm available: $npmVersion" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow
npm install

# Check Redis CLI (optional but recommended)
$redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
if ($redisCli) {
    $redisVersion = redis-cli --version
    Write-Host "✅ Redis CLI available: $redisVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  Redis CLI not found. Please install Redis CLI tools" -ForegroundColor Yellow
}

# Create .env if it doesn't exist
if (-not (Test-Path "config/.env")) {
    Write-Host ""
    Write-Host "📝 Creating environment configuration..." -ForegroundColor Yellow
    if (Test-Path "config/.env.example") {
        Copy-Item "config/.env.example" "config/.env"
        Write-Host "⚠️  Please update config/.env with instructor-provided Redis details" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Lab 11 setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Update config/.env with Redis connection details"
Write-Host "2. Run: npm test"
Write-Host "3. Open Redis Insight to monitor sessions"
Write-Host "4. Follow lab11.md instructions"
