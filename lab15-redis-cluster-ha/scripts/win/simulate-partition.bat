@echo off
REM Lab 15: Redis Cluster HA Operation
REM Batch version - Cluster management script

echo Redis Cluster Operation: simulate-partition.bat
echo ============================================================

REM Check Docker availability
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] Docker not found. Most cluster operations require Docker.
    echo Please install Docker Desktop for Windows: https://www.docker.com/products/docker-desktop
    exit /b 1
)

REM Check docker-compose
where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] docker-compose not found. Trying 'docker compose'...
    docker compose version >nul 2>&1
    if %errorlevel% neq 0 (
        echo [X] docker-compose not available
        exit /b 1
    )
)

echo [OK] Docker environment ready

REM Redis CLI check
where redis-cli >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] redis-cli not found. Some operations may require it.
    echo Install Redis CLI tools or use Docker: docker exec redis-cluster redis-cli
)

echo.
echo This is a cluster management script.
echo Most operations work via docker-compose commands.
echo Refer to lab15 README for detailed instructions.

echo.
echo Common cluster commands:
echo   docker-compose ps                 - Show cluster status
echo   docker-compose logs               - View cluster logs
echo   docker exec redis-1 redis-cli ... - Run Redis commands

echo.
echo For complex operations, consider using the Mac/Linux script via WSL or Git Bash
echo    bash scripts/mac/simulate-partition.sh

echo.
