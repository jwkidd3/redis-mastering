# Lab 15: Redis Cluster HA Operation
# PowerShell version - Auto-generated template

Write-Host "🔧 Redis Cluster Operation: $(Split-Path -Leaf $PSCommandPath)" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Check Docker availability (most cluster ops use Docker)
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Host "❌ Docker not found. Most cluster operations require Docker." -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Check docker-compose
$composeCmd = Get-Command docker-compose -ErrorAction SilentlyContinue
if (-not $composeCmd) {
    Write-Host "⚠️  docker-compose not found. Trying 'docker compose'..." -ForegroundColor Yellow
    $composeV2 = docker compose version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ docker-compose not available" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Docker environment ready" -ForegroundColor Green

# Redis CLI check
$redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
if (-not $redisCli) {
    Write-Host "⚠️  redis-cli not found. Some operations may require it." -ForegroundColor Yellow
    Write-Host "Install Redis CLI tools or use Docker: docker exec redis-cluster redis-cli"
}

Write-Host ""
Write-Host "💡 This is a cluster management script." -ForegroundColor Cyan
Write-Host "💡 Most operations work via docker-compose commands." -ForegroundColor Cyan
Write-Host "💡 Refer to lab15.md for detailed instructions." -ForegroundColor Cyan

Write-Host ""
Write-Host "📌 Common cluster commands:" -ForegroundColor Yellow
Write-Host "  docker-compose ps                 - Show cluster status"
Write-Host "  docker-compose logs               - View cluster logs"
Write-Host "  docker exec redis-1 redis-cli ... - Run Redis commands"

Write-Host ""
Write-Host "⚠️  For complex operations, consider using the Mac/Linux script via WSL or Git Bash" -ForegroundColor Yellow
Write-Host "   bash scripts/mac/$(Split-Path -Leaf $PSCommandPath -Replace '.ps1','.sh')"

Write-Host ""
