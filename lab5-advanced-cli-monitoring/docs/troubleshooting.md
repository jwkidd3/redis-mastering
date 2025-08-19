# Lab 5 Troubleshooting Guide

## WSL Ubuntu Specific Issues

### "File not found" errors when running scripts

**Problem:** `./scripts/script-name.sh: No such file or directory`
**Solutions:**
1. Run WSL setup: `./setup-wsl.sh`
2. Fix line endings: `dos2unix scripts/*.sh`
3. Set permissions: `chmod +x scripts/*.sh`
4. Use troubleshoot script: `./troubleshoot-wsl.sh`

### Permission denied errors

**Problem:** `bash: ./script.sh: Permission denied`
**Solutions:**
1. Fix permissions: `chmod +x script.sh`
2. Run as: `bash script.sh` instead of `./script.sh`
3. Use setup script: `./setup-wsl.sh`

### Docker issues in WSL

**Problem:** Cannot connect to Docker daemon
**Solutions:**
1. Enable Docker integration in WSL settings
2. Start Docker Desktop on Windows
3. Verify with: `docker --version && docker ps`

### Redis connection issues

**Problem:** `redis-cli` command not found
**Solutions:**
1. Install Redis tools: `sudo apt install redis-tools`
2. Or use Docker: `docker exec redis-lab5 redis-cli ping`

### Script execution fails with "bad interpreter"

**Problem:** `/bin/bash^M: bad interpreter`
**Solutions:**
1. Convert line endings: `dos2unix script.sh`
2. Or use sed: `sed -i 's/\r$//' script.sh`

## Quick WSL Setup Commands

```bash
# Complete WSL setup
./setup-wsl.sh

# Quick troubleshooting
./troubleshoot-wsl.sh

# Manual fixes
sudo apt update
sudo apt install -y redis-tools bc dos2unix
find . -name "*.sh" -exec dos2unix {} \;
find . -name "*.sh" -exec chmod +x {} \;

# Start everything
./quick-start.sh
```

## Common Redis Issues

### Redis Connection Issues

**Problem:** `redis-cli ping` fails
**Solutions:**
1. Check if Redis container is running: `docker ps`
2. Restart Redis container: `docker restart redis-lab5`
3. Check port binding: `docker port redis-lab5`

### Memory Issues

**Problem:** High memory usage warnings
**Solutions:**
1. Run memory analysis: `redis-cli --bigkeys`
2. Check for expired keys: `redis-cli INFO keyspace`

### Performance Issues

**Problem:** Slow operations detected
**Solutions:**
1. Check slow log: `redis-cli SLOWLOG GET 10`
2. Analyze command patterns: Use Redis Insight Profiler
3. Review client connections: `redis-cli CLIENT LIST`
