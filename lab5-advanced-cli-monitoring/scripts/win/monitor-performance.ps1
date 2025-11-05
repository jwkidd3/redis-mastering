# Lab 5: Redis Performance Monitoring Script (PowerShell)
# Monitors Redis performance metrics in real-time

Write-Host "=== Redis Performance Monitor ===" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    Clear-Host
    Write-Host "=== Redis Performance Metrics - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Cyan
    Write-Host ""

    # Get INFO stats
    Write-Host "Stats:" -ForegroundColor Green
    redis-cli INFO stats | Select-String "total_commands_processed|instantaneous_ops_per_sec|rejected_connections"

    Write-Host ""

    # Get memory info
    Write-Host "Memory:" -ForegroundColor Green
    redis-cli INFO memory | Select-String "used_memory_human|used_memory_peak_human|mem_fragmentation_ratio"

    Write-Host ""

    # Get client connections
    Write-Host "Clients:" -ForegroundColor Green
    redis-cli INFO clients | Select-String "connected_clients|blocked_clients"

    Start-Sleep -Seconds 2
}
