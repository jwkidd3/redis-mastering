# Lab 5 Troubleshooting Guide

## WSL Ubuntu Issues

### "File not found" when running scripts

This is usually a line ending issue. Fix with:

```bash
# Install required packages
sudo apt update
sudo apt install -y redis-tools bc

# Fix all scripts
find . -name "*.sh" -exec chmod +x {} \;
find . -name "*.sh" -exec sed -i 's/\r$//' {} \;

# Test
./scripts/load-production-data.sh
```

### Permission denied

```bash
chmod +x scripts/*.sh
chmod +x setup-wsl.sh
```

### Redis CLI not found

```bash
sudo apt install redis-tools
redis-cli --version
```

### Docker issues

1. Make sure Docker Desktop is running
2. Enable WSL integration in Docker settings
3. Test: `docker --version`

## Quick Fixes

```bash
# Complete setup
./setup-wsl.sh

# Start Redis
docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine

# Load data
./scripts/load-production-data.sh

# Monitor
./scripts/production-monitor.sh
```
