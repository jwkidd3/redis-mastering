# Redis CLI Installation Script for Windows
# This script provides multiple methods to install redis-cli on Windows

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("chocolatey", "direct", "wsl", "manual")]
    [string]$Method = "chocolatey"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Redis CLI Installation for Windows" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some installation methods require Administrator privileges" -ForegroundColor Yellow
    Write-Host ""
}

# Function to check if redis-cli is already installed
function Test-RedisCliInstalled {
    try {
        $null = Get-Command redis-cli -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to install via Chocolatey
function Install-ViaChocolatey {
    Write-Host "Method 1: Installing via Chocolatey" -ForegroundColor Green
    Write-Host "----------------------------------------" -ForegroundColor Green
    Write-Host ""

    # Check if Chocolatey is installed
    try {
        $null = Get-Command choco -ErrorAction Stop
        Write-Host "✓ Chocolatey is already installed" -ForegroundColor Green
    }
    catch {
        Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
        Write-Host ""

        if (-not $isAdmin) {
            Write-Host "ERROR: Administrator privileges required to install Chocolatey" -ForegroundColor Red
            Write-Host "Please run this script as Administrator or choose a different method" -ForegroundColor Red
            return $false
        }

        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "✓ Chocolatey installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to install Chocolatey: $_" -ForegroundColor Red
            return $false
        }
    }

    Write-Host ""
    Write-Host "Installing Redis (includes redis-cli)..." -ForegroundColor Yellow

    if (-not $isAdmin) {
        Write-Host "ERROR: Administrator privileges required to install packages" -ForegroundColor Red
        return $false
    }

    try {
        choco install redis-64 -y
        Write-Host ""
        Write-Host "✓ Redis installed successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to install Redis: $_" -ForegroundColor Red
        return $false
    }
}

# Function to install via direct download
function Install-ViaDirect {
    Write-Host "Method 2: Installing via Direct Download" -ForegroundColor Green
    Write-Host "----------------------------------------" -ForegroundColor Green
    Write-Host ""

    $installPath = "$env:USERPROFILE\redis-cli"
    $binPath = "$installPath\bin"

    Write-Host "Installing to: $installPath" -ForegroundColor Yellow
    Write-Host ""

    # Create installation directory
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }

    if (-not (Test-Path $binPath)) {
        New-Item -ItemType Directory -Path $binPath -Force | Out-Null
    }

    # Download Redis for Windows (Memurai Community Edition - free)
    Write-Host "Downloading Redis for Windows..." -ForegroundColor Yellow
    $downloadUrl = "https://github.com/tporadowski/redis/releases/download/v5.0.14.1/Redis-x64-5.0.14.1.zip"
    $zipFile = "$installPath\redis.zip"

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        Write-Host "✓ Download complete" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to download Redis: $_" -ForegroundColor Red
        return $false
    }

    # Extract the archive
    Write-Host "Extracting files..." -ForegroundColor Yellow
    try {
        Expand-Archive -Path $zipFile -DestinationPath $installPath -Force

        # Copy executables to bin directory
        Copy-Item "$installPath\*.exe" -Destination $binPath -Force

        # Cleanup
        Remove-Item $zipFile -Force

        Write-Host "✓ Extraction complete" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to extract Redis: $_" -ForegroundColor Red
        return $false
    }

    # Add to PATH
    Write-Host ""
    Write-Host "Adding to PATH..." -ForegroundColor Yellow

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$binPath*") {
        try {
            [Environment]::SetEnvironmentVariable(
                "Path",
                "$currentPath;$binPath",
                "User"
            )

            # Update current session PATH
            $env:Path += ";$binPath"

            Write-Host "✓ Added to PATH" -ForegroundColor Green
            Write-Host ""
            Write-Host "NOTE: You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
        }
        catch {
            Write-Host "WARNING: Failed to update PATH automatically" -ForegroundColor Yellow
            Write-Host "Please add manually: $binPath" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "✓ Already in PATH" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "✓ Redis CLI installed successfully!" -ForegroundColor Green
    Write-Host "Installation location: $binPath" -ForegroundColor Cyan

    return $true
}

# Function to guide WSL installation
function Install-ViaWSL {
    Write-Host "Method 3: Installing via WSL (Windows Subsystem for Linux)" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------" -ForegroundColor Green
    Write-Host ""

    Write-Host "This method installs redis-cli in WSL (Ubuntu)" -ForegroundColor Yellow
    Write-Host ""

    # Check if WSL is available
    try {
        $wslVersion = wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ WSL is installed" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "WSL is not installed. Installing WSL..." -ForegroundColor Yellow
        Write-Host ""

        if (-not $isAdmin) {
            Write-Host "ERROR: Administrator privileges required to install WSL" -ForegroundColor Red
            Write-Host ""
            Write-Host "Please run this command as Administrator:" -ForegroundColor Yellow
            Write-Host "  wsl --install" -ForegroundColor Cyan
            return $false
        }

        Write-Host "Running: wsl --install" -ForegroundColor Cyan
        wsl --install

        Write-Host ""
        Write-Host "WSL installation initiated." -ForegroundColor Green
        Write-Host "You may need to restart your computer for changes to take effect." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "After restart, run this script again to continue redis-cli installation." -ForegroundColor Yellow
        return $false
    }

    Write-Host ""
    Write-Host "Installing redis-tools in WSL Ubuntu..." -ForegroundColor Yellow
    Write-Host ""

    # Install redis-tools in WSL
    $wslCommand = "sudo apt-get update && sudo apt-get install -y redis-tools"

    Write-Host "Executing in WSL: $wslCommand" -ForegroundColor Cyan
    Write-Host ""

    try {
        wsl -e bash -c $wslCommand

        Write-Host ""
        Write-Host "✓ redis-cli installed in WSL!" -ForegroundColor Green
        Write-Host ""
        Write-Host "To use redis-cli in WSL:" -ForegroundColor Cyan
        Write-Host "  wsl redis-cli -h hostname -p port" -ForegroundColor White
        Write-Host ""
        Write-Host "Or start a WSL session:" -ForegroundColor Cyan
        Write-Host "  wsl" -ForegroundColor White
        Write-Host "  redis-cli -h hostname -p port" -ForegroundColor White

        return $true
    }
    catch {
        Write-Host "ERROR: Failed to install redis-tools in WSL: $_" -ForegroundColor Red
        return $false
    }
}

# Function to display manual installation instructions
function Show-ManualInstructions {
    Write-Host "Method 4: Manual Installation Instructions" -ForegroundColor Green
    Write-Host "-------------------------------------------" -ForegroundColor Green
    Write-Host ""

    Write-Host "Option A: Download Redis for Windows (Recommended)" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Visit: https://github.com/tporadowski/redis/releases" -ForegroundColor White
    Write-Host "2. Download: Redis-x64-5.0.14.1.zip (or latest version)" -ForegroundColor White
    Write-Host "3. Extract to: C:\redis (or your preferred location)" -ForegroundColor White
    Write-Host "4. Add to PATH: C:\redis (System Properties > Environment Variables)" -ForegroundColor White
    Write-Host "5. Open new terminal and test: redis-cli --version" -ForegroundColor White
    Write-Host ""

    Write-Host "Option B: Use Chocolatey" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run PowerShell as Administrator:" -ForegroundColor White
    Write-Host "  Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Yellow
    Write-Host "  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072" -ForegroundColor Yellow
    Write-Host "  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Yellow
    Write-Host "  choco install redis-64 -y" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Option C: Use WSL" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run PowerShell as Administrator:" -ForegroundColor White
    Write-Host "  wsl --install" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After restart, in WSL:" -ForegroundColor White
    Write-Host "  sudo apt-get update" -ForegroundColor Yellow
    Write-Host "  sudo apt-get install redis-tools" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Option D: Use Memurai (Commercial, Free Trial)" -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Visit: https://www.memurai.com/" -ForegroundColor White
    Write-Host "2. Download Memurai (includes redis-cli)" -ForegroundColor White
    Write-Host "3. Run installer" -ForegroundColor White
    Write-Host "4. Test: redis-cli --version" -ForegroundColor White
    Write-Host ""
}

# Main installation logic
Write-Host "Select installation method:" -ForegroundColor Cyan
Write-Host "  1. Chocolatey (Recommended - requires admin)" -ForegroundColor White
Write-Host "  2. Direct Download (No admin needed)" -ForegroundColor White
Write-Host "  3. WSL (Linux tools in Windows)" -ForegroundColor White
Write-Host "  4. Show Manual Instructions" -ForegroundColor White
Write-Host ""

# Check if already installed
if (Test-RedisCliInstalled) {
    Write-Host "✓ redis-cli is already installed!" -ForegroundColor Green
    Write-Host ""

    try {
        $version = redis-cli --version
        Write-Host "Installed version: $version" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Version information unavailable" -ForegroundColor Yellow
    }

    Write-Host ""
    $reinstall = Read-Host "Do you want to reinstall? (y/n)"

    if ($reinstall -ne "y") {
        Write-Host ""
        Write-Host "Installation cancelled. redis-cli is already available." -ForegroundColor Green
        exit 0
    }
}

# Execute selected installation method
$success = $false

switch ($Method.ToLower()) {
    "chocolatey" {
        $success = Install-ViaChocolatey
    }
    "direct" {
        $success = Install-ViaDirect
    }
    "wsl" {
        $success = Install-ViaWSL
    }
    "manual" {
        Show-ManualInstructions
        $success = $true
    }
    default {
        Write-Host "Invalid method specified. Use: chocolatey, direct, wsl, or manual" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan

if ($success) {
    Write-Host "Installation Process Complete!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    # Test installation
    Write-Host "Testing installation..." -ForegroundColor Yellow
    Write-Host ""

    try {
        $version = redis-cli --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ redis-cli is working!" -ForegroundColor Green
            Write-Host "Version: $version" -ForegroundColor Cyan
        }
        else {
            Write-Host "redis-cli installed but not in PATH" -ForegroundColor Yellow
            Write-Host "You may need to restart your terminal" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "redis-cli installed but not yet in PATH" -ForegroundColor Yellow
        Write-Host "Please restart your terminal or PowerShell window" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host "  redis-cli -h localhost -p 6379 PING" -ForegroundColor White
    Write-Host ""
    Write-Host "Connect to remote Redis:" -ForegroundColor Cyan
    Write-Host "  redis-cli -h hostname -p port" -ForegroundColor White
    Write-Host ""
    Write-Host "View help:" -ForegroundColor Cyan
    Write-Host "  redis-cli --help" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host "Installation Failed or Incomplete" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please try one of the alternative methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run this script with a different method:" -ForegroundColor Cyan
    Write-Host "  .\install-redis-cli-windows.ps1 -Method chocolatey" -ForegroundColor White
    Write-Host "  .\install-redis-cli-windows.ps1 -Method direct" -ForegroundColor White
    Write-Host "  .\install-redis-cli-windows.ps1 -Method wsl" -ForegroundColor White
    Write-Host "  .\install-redis-cli-windows.ps1 -Method manual" -ForegroundColor White
    Write-Host ""
    exit 1
}
