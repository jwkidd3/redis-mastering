# Lab 1: Redis Environment Setup Script (PowerShell)
# Sets up the Redis environment and loads initial data

Write-Host "=== Lab 1: Redis Environment Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if Redis is running
Write-Host "Checking Redis connection..." -ForegroundColor Yellow
try {
    $ping = redis-cli ping 2>$null
    if ($ping -eq "PONG") {
        Write-Host "✓ Redis is running and accessible" -ForegroundColor Green
    } else {
        Write-Host "✗ Redis is not responding correctly" -ForegroundColor Red
        Write-Host "Please ensure Redis is running: docker run -d -p 6379:6379 --name redis-course redis:latest" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Cannot connect to Redis" -ForegroundColor Red
    Write-Host "Please ensure Redis is running: docker run -d -p 6379:6379 --name redis-course redis:latest" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Loading sample data..." -ForegroundColor Yellow

# Set up some basic keys for the lab
redis-cli SET "insurance:welcome" "Welcome to Redis Mastering Course!"
redis-cli SET "lab:number" "1"
redis-cli SET "lab:name" "Redis Environment and CLI Basics"

# Create a simple counter
redis-cli SET "lab:visits" "0"

# Create some policy data
redis-cli SET "policy:AUTO-001" "Active Auto Policy"
redis-cli SET "policy:HOME-001" "Active Home Policy"
redis-cli SET "policy:LIFE-001" "Active Life Policy"

Write-Host "✓ Sample data loaded successfully" -ForegroundColor Green
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Try these commands:" -ForegroundColor Yellow
Write-Host "  redis-cli GET insurance:welcome"
Write-Host "  redis-cli KEYS policy:*"
Write-Host "  redis-cli INCR lab:visits"
Write-Host ""
Write-Host "To start the Redis CLI:" -ForegroundColor Yellow
Write-Host "  redis-cli"
