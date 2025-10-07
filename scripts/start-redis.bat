@echo off
echo Starting Redis container...

docker start redis 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Redis container started successfully!
    echo Access Redis at: localhost:6379
) else (
    echo Container does not exist, creating new one...
    docker run -d --name redis -p 6379:6379 redis/redis-stack:latest
    echo Redis container created and started successfully!
    echo Access Redis at: localhost:6379
)
