# Lab 6 Setup Validation
# PowerShell version for Windows

Write-Host "✅ Lab 6 Setup Validation" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$success = $true

# Check Node.js
Write-Host "🟢 Checking Node.js..." -ForegroundColor Yellow
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVersion = node --version
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green

    # Check version >= 16
    $majorVersion = [int]($nodeVersion -replace 'v','').Split('.')[0]
    if ($majorVersion -ge 16) {
        Write-Host "✅ Node.js version is compatible" -ForegroundColor Green
    } else {
        Write-Host "❌ Node.js version should be 16 or higher" -ForegroundColor Red
        $success = $false
    }
} else {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    $success = $false
}

# Check npm
Write-Host ""
Write-Host "🟢 Checking npm..." -ForegroundColor Yellow
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    $npmVersion = npm --version
    Write-Host "✅ npm: v$npmVersion" -ForegroundColor Green
} else {
    Write-Host "❌ npm not found" -ForegroundColor Red
    $success = $false
}

# Check project files
Write-Host ""
Write-Host "🟢 Checking project structure..." -ForegroundColor Yellow

$requiredFiles = @(
    "package.json",
    ".env",
    "src/app.js",
    "src/config/redis.js",
    "src/clients/redisClient.js",
    "tests/connection-test.js"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
        $success = $false
    }
}

# Check node_modules
Write-Host ""
Write-Host "🟢 Checking dependencies..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Write-Host "✅ node_modules directory exists" -ForegroundColor Green

    # Check key dependencies
    if (Test-Path "node_modules/redis") {
        Write-Host "✅ Redis client installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Redis client not installed" -ForegroundColor Red
        $success = $false
    }

    if (Test-Path "node_modules/dotenv") {
        Write-Host "✅ dotenv installed" -ForegroundColor Green
    } else {
        Write-Host "❌ dotenv not installed" -ForegroundColor Red
        $success = $false
    }
} else {
    Write-Host "❌ node_modules not found - run npm install" -ForegroundColor Red
    $success = $false
}

# Check environment configuration
Write-Host ""
Write-Host "🟢 Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "REDIS_HOST=(.+)") {
        $redisHost = $matches[1]
        if ($redisHost -and $redisHost -ne "redis-server.training.com") {
            Write-Host "✅ REDIS_HOST configured: $redisHost" -ForegroundColor Green
        } else {
            Write-Host "⚠️  REDIS_HOST needs to be updated with actual server details" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ REDIS_HOST not found in .env" -ForegroundColor Red
        $success = $false
    }

    if ($envContent -match "REDIS_PORT=") {
        Write-Host "✅ REDIS_PORT configured" -ForegroundColor Green
    } else {
        Write-Host "❌ REDIS_PORT not found in .env" -ForegroundColor Red
        $success = $false
    }
} else {
    Write-Host "❌ .env file not found" -ForegroundColor Red
    $success = $false
}

# Test Redis connection (if everything else is OK)
if ($success) {
    Write-Host ""
    Write-Host "🟢 Testing Redis connection..." -ForegroundColor Yellow
    $testResult = node tests/connection-test.js 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Redis connection successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Redis connection failed" -ForegroundColor Red
        Write-Host "💡 Check your .env file and server details"
        $success = $false
    }
}

Write-Host ""
Write-Host "================================="
if ($success) {
    Write-Host "🎉 Lab 6 setup validation PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Ready to start the lab!"
    Write-Host "Run: npm start"
} else {
    Write-Host "❌ Lab 6 setup validation FAILED!" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Actions needed:"
    Write-Host "1. Fix the issues listed above"
    Write-Host "2. Run this validation again"
    Write-Host "3. Contact instructor if problems persist"
}

Write-Host ""
exit $(if ($success) { 0 } else { 1 })
