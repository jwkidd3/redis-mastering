# Lab 5: Redis Memory Analysis Script (PowerShell)
# Analyzes memory usage and provides recommendations

Write-Host "=== Redis Memory Analysis ===" -ForegroundColor Cyan
Write-Host ""

# Get memory information
Write-Host "Current Memory Usage:" -ForegroundColor Green
redis-cli INFO memory | Select-String "used_memory_human|used_memory_peak_human|used_memory_rss_human|mem_fragmentation_ratio|maxmemory_human|maxmemory_policy"

Write-Host ""
Write-Host "Memory by Data Type:" -ForegroundColor Green
redis-cli MEMORY STATS | Select-String "keys.count|dataset.bytes"

Write-Host ""
Write-Host "Database Size:" -ForegroundColor Green
redis-cli DBSIZE

Write-Host ""
Write-Host "Sample Key Memory Usage:" -ForegroundColor Green
# Get a sample key to analyze
$sampleKey = redis-cli RANDOMKEY
if ($sampleKey) {
    Write-Host "Analyzing key: $sampleKey" -ForegroundColor Yellow
    redis-cli MEMORY USAGE $sampleKey
}

Write-Host ""
Write-Host "=== Analysis Complete ===" -ForegroundColor Cyan
