# Lab 5: Redis Slow Log Analysis Script (PowerShell)
# Analyzes slow queries and provides insights

Write-Host "=== Redis Slow Log Analysis ===" -ForegroundColor Cyan
Write-Host ""

# Get slow log configuration
Write-Host "Slow Log Configuration:" -ForegroundColor Green
redis-cli CONFIG GET slowlog-log-slower-than
redis-cli CONFIG GET slowlog-max-len

Write-Host ""
Write-Host "Slow Log Entries:" -ForegroundColor Green
redis-cli SLOWLOG GET 10

Write-Host ""
Write-Host "Slow Log Statistics:" -ForegroundColor Green
$slowLogLen = redis-cli SLOWLOG LEN
Write-Host "Total slow log entries: $slowLogLen"

Write-Host ""
Write-Host "=== Analysis Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To adjust slow log threshold:" -ForegroundColor Yellow
Write-Host "redis-cli CONFIG SET slowlog-log-slower-than 10000"
