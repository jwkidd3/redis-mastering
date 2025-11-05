# Lab 13: Redis Backup Script (PowerShell)
# Creates backups of Redis data (RDB and AOF files)

$backupDir = ".\backups"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "redis_backup_$timestamp"

Write-Host "=== Redis Backup Script ===" -ForegroundColor Cyan
Write-Host "Starting backup: $backupName" -ForegroundColor Green
Write-Host ""

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# Trigger BGSAVE
Write-Host "Triggering background save..." -ForegroundColor Yellow
redis-cli BGSAVE

# Wait for save to complete
$initialSave = redis-cli LASTSAVE
Start-Sleep -Seconds 1

do {
    $currentSave = redis-cli LASTSAVE
    if ($currentSave -ne $initialSave) {
        break
    }
    Start-Sleep -Seconds 1
} while ($true)

Write-Host "Background save completed" -ForegroundColor Green

# Get Redis data directory
$dataDir = redis-cli CONFIG GET dir | Select-Object -Last 1
Write-Host "Redis data directory: $dataDir" -ForegroundColor Cyan

# Create backup archive
Write-Host "Creating backup archive..." -ForegroundColor Yellow
$backupPath = "$backupDir\$backupName.zip"

$filesToBackup = @(
    "$dataDir\dump.rdb",
    "$dataDir\appendonly.aof"
)

$existingFiles = $filesToBackup | Where-Object { Test-Path $_ }

if ($existingFiles.Count -gt 0) {
    Compress-Archive -Path $existingFiles -DestinationPath $backupPath -Force

    $backupSize = (Get-Item $backupPath).Length / 1MB
    Write-Host "Backup created: $backupPath ($([math]::Round($backupSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "Backup failed - no data files found" -ForegroundColor Red
    exit 1
}

# Keep only last 7 backups
Write-Host "Cleaning old backups (keeping last 7)..." -ForegroundColor Yellow
Get-ChildItem "$backupDir\redis_backup_*.zip" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 7 |
    Remove-Item

Write-Host ""
Write-Host "=== Backup Complete ===" -ForegroundColor Cyan
Write-Host "Backup location: $backupPath" -ForegroundColor Green
