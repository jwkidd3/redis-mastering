# Lab 15: Redis Cluster Setup Script (PowerShell)
# Sets up a 6-node Redis cluster (3 masters + 3 replicas)

Write-Host "=== Redis Cluster Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if docker-compose is available
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "✗ docker-compose not found. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if cluster is already running
$running = docker-compose ps 2>$null | Select-String "redis"
if (-not $running) {
    Write-Host "Starting Redis cluster with docker-compose..." -ForegroundColor Yellow
    docker-compose up -d
    Start-Sleep -Seconds 5
} else {
    Write-Host "Redis cluster containers are already running" -ForegroundColor Green
}

Write-Host "Waiting for Redis nodes to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Create the cluster
Write-Host "Creating Redis cluster..." -ForegroundColor Yellow
Write-Host ""

# Note: This command requires manual confirmation in interactive mode
# For automated setup, you may need to pipe 'yes' to the command
$clusterCreate = @"
redis-cli --cluster create \
  127.0.0.1:7000 \
  127.0.0.1:7001 \
  127.0.0.1:7002 \
  127.0.0.1:7003 \
  127.0.0.1:7004 \
  127.0.0.1:7005 \
  --cluster-replicas 1
"@

Write-Host "Run this command to create the cluster:" -ForegroundColor Yellow
Write-Host $clusterCreate -ForegroundColor Cyan
Write-Host ""
Write-Host "Or execute directly (will prompt for confirmation):" -ForegroundColor Yellow

# Try to create cluster (this may require manual confirmation)
$env:REDISCLI_AUTH = ""
docker exec redis-node-1 redis-cli --cluster create `
    redis-node-1:7000 `
    redis-node-2:7001 `
    redis-node-3:7002 `
    redis-node-4:7003 `
    redis-node-5:7004 `
    redis-node-6:7005 `
    --cluster-replicas 1 `
    --cluster-yes 2>&1

Write-Host ""
Write-Host "=== Cluster Setup Complete ===" -ForegroundColor Cyan
Write-Host ""

# Show cluster status
Write-Host "Cluster nodes:" -ForegroundColor Yellow
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES

Write-Host ""
Write-Host "Cluster info:" -ForegroundColor Yellow
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO

Write-Host ""
Write-Host "To connect to the cluster:" -ForegroundColor Green
Write-Host "  redis-cli -c -p 7000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or via Docker:" -ForegroundColor Green
Write-Host "  docker exec -it redis-node-1 redis-cli -c -p 7000" -ForegroundColor Cyan
