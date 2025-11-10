@echo off
REM Redis CLI Installation Script for Windows
REM This script helps you install redis-cli on Windows

echo ================================================
echo Redis CLI Installation for Windows
echo ================================================
echo.

REM Check if redis-cli is already installed
where redis-cli >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] redis-cli is already installed!
    echo.
    redis-cli --version
    echo.
    echo To reinstall, please uninstall first and run this script again.
    echo.
    pause
    exit /b 0
)

echo [INFO] redis-cli is not installed on this system.
echo.
echo ================================================
echo Installation Options
echo ================================================
echo.

echo Option 1: Chocolatey (Recommended - Requires Admin)
echo ------------------------------------------------
echo Run PowerShell as Administrator and execute:
echo   choco install redis-64 -y
echo.
echo If you don't have Chocolatey installed:
echo   Set-ExecutionPolicy Bypass -Scope Process -Force
echo   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
echo   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
echo   choco install redis-64 -y
echo.

echo Option 2: Direct Download (No Admin Required)
echo ------------------------------------------------
echo 1. Visit: https://github.com/tporadowski/redis/releases
echo 2. Download: Redis-x64-5.0.14.1.zip (or latest version)
echo 3. Extract to: C:\redis (or your preferred location)
echo 4. Add C:\redis to your PATH:
echo    - Open System Properties ^> Environment Variables
echo    - Edit PATH variable
echo    - Add C:\redis
echo    - Restart terminal
echo.

echo Option 3: WSL (Windows Subsystem for Linux)
echo ------------------------------------------------
echo Run PowerShell as Administrator:
echo   wsl --install
echo.
echo After restart, in WSL terminal:
echo   sudo apt-get update
echo   sudo apt-get install redis-tools
echo.
echo Then use redis-cli from WSL:
echo   wsl redis-cli -h localhost -p 6379
echo.

echo Option 4: Docker (Alternative)
echo ------------------------------------------------
echo Use redis-cli from Docker container:
echo   docker exec redis redis-cli
echo.
echo Note: Requires Redis container to be running
echo       (Use start-redis.bat to start Redis)
echo.

echo ================================================
echo After Installation
echo ================================================
echo.
echo Verify installation:
echo   redis-cli --version
echo.
echo Test connection:
echo   redis-cli -h localhost -p 6379 PING
echo.
echo Start Redis server (if not running):
echo   start-redis.bat
echo.

pause
