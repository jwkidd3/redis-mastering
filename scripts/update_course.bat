@echo off
powershell -Command "Set-Location C:\Users\Administrator\Desktop\REDIS\redis_mastering; Write-Host 'Pulling latest changes from repository...' -ForegroundColor Green; git pull; Write-Host 'Pull complete!' -ForegroundColor Green"
pause
