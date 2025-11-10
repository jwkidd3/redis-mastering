# Course Scripts

This directory contains utility scripts for managing Redis and course setup.

---

## Mac/Linux Scripts

### 📥 install-redis-cli.sh

**Purpose:** Install redis-cli on Mac and Linux

**Features:**
- ✅ Bash script for Mac and Linux
- ✅ Automatic OS detection
- ✅ Platform-specific package manager support
- ✅ Colored output and progress indicators
- ✅ Installation verification

**Usage:**

```bash
# Mac/Linux
cd scripts
bash install-redis-cli.sh

# Or make executable and run
chmod +x install-redis-cli.sh
./install-redis-cli.sh
```

**Supported Platforms:**

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| **macOS** | Homebrew | Installs Homebrew if needed |
| **Ubuntu/Debian** | apt | Uses `redis-tools` package |
| **Fedora/RHEL/CentOS** | dnf/yum | Installs full Redis package |
| **Arch/Manjaro** | pacman | Installs Redis package |

**What it does:**
1. Detects your operating system automatically
2. Checks if redis-cli is already installed
3. Installs using the appropriate package manager
4. Verifies installation with version check
5. Provides quick start examples

**After Installation:**

Test the installation:
```bash
redis-cli --version
```

Connect to Redis:
```bash
redis-cli -h localhost -p 6379 PING
```

**Note:** Windows users should use the PowerShell script below.

---

## Windows PowerShell Scripts

### 📥 install-redis-cli-windows.ps1

**Purpose:** Install redis-cli on Windows systems

**Features:**
- ✅ Multiple installation methods (Chocolatey, Direct Download, WSL, Manual)
- ✅ Automatic PATH configuration
- ✅ Version detection and testing
- ✅ Non-admin installation option (direct download)
- ✅ Comprehensive error handling

**Usage:**

```powershell
# Default installation (via Chocolatey)
.\install-redis-cli-windows.ps1

# Install via direct download (no admin needed)
.\install-redis-cli-windows.ps1 -Method direct

# Install via WSL
.\install-redis-cli-windows.ps1 -Method wsl

# Show manual installation instructions
.\install-redis-cli-windows.ps1 -Method manual
```

**Installation Methods:**

| Method | Admin Required | Description |
|--------|---------------|-------------|
| **chocolatey** | ✅ Yes | Uses Chocolatey package manager (recommended) |
| **direct** | ❌ No | Downloads and installs to user directory |
| **wsl** | ✅ Yes (first time) | Installs in Windows Subsystem for Linux |
| **manual** | - | Shows step-by-step instructions |

**What it does:**
1. Checks if redis-cli is already installed
2. Downloads and installs Redis for Windows
3. Adds redis-cli to system PATH
4. Verifies installation with version check
5. Provides connection examples

**Requirements:**
- Windows 10/11
- PowerShell 5.1 or later
- Internet connection
- Administrator privileges (for Chocolatey and WSL methods)

**After Installation:**

Test the installation:
```powershell
redis-cli --version
```

Connect to Redis:
```powershell
redis-cli -h localhost -p 6379 PING
```

---

## Windows Batch Scripts

### 🚀 start-redis.bat

**Purpose:** Start Redis server using Docker

**Usage:**
```cmd
cd scripts
start-redis.bat
```

**What it does:**
- Checks if Redis container exists and starts it
- If container doesn't exist, creates new Redis Stack container named "redis"
- Maps port 6379
- Runs redis/redis-stack:latest
- Detached mode (background)

**Note:** This is the recommended way to start Redis on Windows for this course.

---

### 🛑 stop-redis.bat

**Purpose:** Stop Redis Docker container

**Usage:**
```cmd
cd scripts
stop-redis.bat
```

**What it does:**
- Stops the "redis" container
- Preserves data (does not remove container)

**Note:** Use this to stop Redis when you're done with your labs.

---

### 🧹 cleanup-redis.bat

**Purpose:** Clean up Redis Docker container and data

**Usage:**
```cmd
cleanup-redis.bat
```

**What it does:**
- Stops Redis container if running
- Removes the container
- Cleans up Redis data volume

**⚠️ WARNING:** This will delete all Redis data!

---

### 🔄 update_course.bat

**Purpose:** Update course materials

**Usage:**
```cmd
update_course.bat
```

**What it does:**
- Pulls latest course updates
- Updates dependencies
- Refreshes lab materials

---

## Common Workflows

### First-Time Setup

**Mac/Linux:**
1. **Install redis-cli:**
   ```bash
   cd scripts
   bash install-redis-cli.sh
   ```

2. **Start Redis server:**
   ```bash
   docker run -d --name redis -p 6379:6379 redis/redis-stack:latest
   ```

3. **Test connection:**
   ```bash
   redis-cli -h localhost -p 6379 PING
   ```

**Windows:**
1. **Install redis-cli:**
   ```powershell
   cd scripts
   .\install-redis-cli-windows.ps1
   ```

2. **Start Redis server:**
   ```cmd
   cd scripts
   start-redis.bat
   ```

3. **Test connection:**
   ```powershell
   redis-cli -h localhost -p 6379 PING
   ```

### Daily Workflow

**Windows:**
```cmd
# Start of day
cd scripts
start-redis.bat

# Work with Redis
redis-cli -h localhost -p 6379

# End of day
cd scripts
stop-redis.bat
```

**Mac/Linux:**
```bash
# Start of day (if not running)
docker start redis

# Work with Redis
redis-cli -h localhost -p 6379

# End of day
docker stop redis
```

### Clean Start

**Windows:**
```cmd
cd scripts
cleanup-redis.bat
start-redis.bat
```

**Mac/Linux:**
```bash
docker stop redis
docker rm redis
docker run -d --name redis -p 6379:6379 redis/redis-stack:latest
```

---

## Troubleshooting

### redis-cli not found after installation

**Solution 1:** Restart terminal/PowerShell
```powershell
# Close and reopen PowerShell
```

**Solution 2:** Check PATH manually
```powershell
$env:Path -split ';' | Select-String redis
```

**Solution 3:** Add to PATH manually
```powershell
$env:Path += ";C:\redis"  # Or your redis installation path
```

### Docker not running (for .bat scripts)

**Error:** "Cannot connect to Docker daemon"

**Solution:**
1. Start Docker Desktop
2. Wait for Docker to fully start
3. Run the script again

### Permission denied

**Error:** "Execution of scripts is disabled"

**Solution:**
```powershell
# Allow script execution (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Port 6379 already in use

**Solution:**
```cmd
# Stop existing Redis
stop-redis.bat

# Or find and kill the process
netstat -ano | findstr :6379
taskkill /PID [process_id] /F
```

---

## Alternative: Using Docker Compose

If you prefer Docker Compose over batch scripts:

**Create docker-compose.yml:**
```yaml
version: '3.8'
services:
  redis:
    image: redis:latest
    container_name: redis-course
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes

volumes:
  redis-data:
```

**Usage:**
```powershell
# Start
docker-compose up -d

# Stop
docker-compose down

# Clean up
docker-compose down -v
```

---

## Platform-Specific Notes

### Windows 10/11
- ✅ All scripts fully supported
- ✅ PowerShell 5.1+ recommended
- ✅ Docker Desktop recommended for Redis server

### Windows Server
- ✅ All scripts supported
- ⚠️ May need to enable PowerShell script execution
- ⚠️ Docker setup may vary

### WSL (Windows Subsystem for Linux)
- ✅ Can use Linux redis-cli in WSL
- ✅ Access Windows Docker from WSL
- ✅ Hybrid approach supported

---

## Script Locations

All scripts are in the course root `scripts/` directory:

```
redis-mastering/
├── scripts/
│   ├── README.md (this file)
│   ├── install-redis-cli-windows.ps1
│   ├── start-redis.bat
│   ├── stop-redis.bat
│   ├── cleanup-redis.bat
│   └── update_course.bat
```

Lab-specific scripts are in individual lab directories:
```
lab*/
├── scripts/
│   ├── mac/
│   │   └── *.sh
│   └── win/
│       └── *.ps1
```

---

## Additional Resources

- **Redis CLI Documentation:** https://redis.io/docs/ui/cli/
- **Redis for Windows:** https://github.com/tporadowski/redis
- **Docker Desktop:** https://www.docker.com/products/docker-desktop/
- **WSL Documentation:** https://docs.microsoft.com/en-us/windows/wsl/

---

## Support

If you encounter issues with any scripts:

1. Check this README for troubleshooting steps
2. Verify prerequisites are installed
3. Check the main course README.md
4. Review individual lab README files

---

**Last Updated:** November 10, 2025
**Compatible With:** Windows 10/11, PowerShell 5.1+, Docker Desktop
