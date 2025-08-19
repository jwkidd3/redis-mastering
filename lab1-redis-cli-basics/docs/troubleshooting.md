# Lab 1 Troubleshooting Guide

## Connection Issues

### Problem: "Could not connect to Redis at hostname:port"

**Possible Causes & Solutions:**

1. **Wrong hostname or port**
   ```bash
   # Verify details with instructor
   # Double-check hostname spelling
   # Confirm port number (usually 6379)
   ```

2. **Network connectivity**
   ```bash
   # Test basic connectivity
   ping redis-server.training.com
   telnet redis-server.training.com 6379
   
   # If ping fails, check network/VPN
   # If telnet fails, check firewall
   ```

3. **Redis server not running**
   ```bash
   # Ask instructor to verify server status
   # Check if using correct environment (training vs production)
   ```

### Problem: "NOAUTH Authentication required"

**Solution:**
```bash
# Use password provided by instructor
redis-cli -h hostname -p port -a password PING

# For interactive session
redis-cli -h hostname -p port -a password
```

### Problem: "Connection timeout"

**Solutions:**
```bash
# Increase timeout
redis-cli -h hostname -p port --connect-timeout 10 PING

# Check network latency
redis-cli -h hostname -p port --latency

# Verify with instructor if server is accessible
```

## Redis CLI Issues

### Problem: "redis-cli: command not found"

**Windows:**
```cmd
# Check if Redis is installed
where redis-cli

# Use full path
"C:\Program Files\Redis\redis-cli.exe" -h hostname -p port PING

# Add to PATH or use absolute path
```

**macOS:**
```bash
# Install via Homebrew
brew install redis

# Check installation
which redis-cli
/usr/local/bin/redis-cli --version

# Use full path if needed
/usr/local/bin/redis-cli -h hostname -p port PING
```

**Linux:**
```bash
# Install Redis tools
sudo apt-get install redis-tools  # Ubuntu/Debian
sudo yum install redis            # CentOS/RHEL

# Check installation
which redis-cli
redis-cli --version
```

### Problem: Commands not working as expected

**Solutions:**
```bash
# Check command syntax
redis-cli HELP command_name

# Verify key exists
redis-cli -h hostname -p port EXISTS keyname

# Check data type
redis-cli -h hostname -p port TYPE keyname

# Use verbose mode for debugging
redis-cli -h hostname -p port --verbose PING
```

## Redis Insight Issues

### Problem: Cannot connect to Redis server

**Solutions:**
1. **Verify connection details match CLI settings**
   - Use same hostname, port, password as CLI
   - Test CLI connection first

2. **Check Redis Insight configuration**
   - Ensure host field doesn't have extra spaces
   - Try IP address instead of hostname
   - Verify port number is numeric

3. **Network and firewall**
   - Some networks block GUI connections differently than CLI
   - Ask instructor about Redis Insight connectivity

### Problem: Redis Insight shows "Connection timeout"

**Solutions:**
```bash
# Test CLI connection first
redis-cli -h hostname -p port PING

# Check if server allows multiple connections
redis-cli -h hostname -p port CLIENT LIST

# Try alternative connection method
# Use SSH tunnel if direct connection fails
```

### Problem: "Database connection failed"

**Solutions:**
1. **Refresh connection**
   - Delete and re-add database connection
   - Restart Redis Insight application

2. **Check credentials**
   - Verify username/password if required
   - Try connection without authentication first

## Performance Issues

### Problem: Slow response times

**Diagnosis:**
```bash
# Check latency
redis-cli -h hostname -p port --latency

# Monitor server stats
redis-cli -h hostname -p port INFO stats | grep instantaneous

# Check network connectivity
ping hostname
```

**Solutions:**
- Check network quality to server
- Ask instructor about server load
- Use closer Redis instance if available

### Problem: Commands timing out

**Solutions:**
```bash
# Increase command timeout
redis-cli -h hostname -p port --timeout 30 PING

# Check server responsiveness
redis-cli -h hostname -p port INFO server | grep uptime

# Monitor server load
redis-cli -h hostname -p port INFO cpu
```

## Data Issues

### Problem: Keys not found

**Verification:**
```bash
# Check if key exists
redis-cli -h hostname -p port EXISTS keyname

# List all keys (use carefully)
redis-cli -h hostname -p port KEYS "*"

# Check if in correct database
redis-cli -h hostname -p port SELECT 0
redis-cli -h hostname -p port DBSIZE
```

### Problem: Unexpected data types

**Diagnosis:**
```bash
# Check data type
redis-cli -h hostname -p port TYPE keyname

# Get detailed info
redis-cli -h hostname -p port OBJECT ENCODING keyname

# View raw value
redis-cli -h hostname -p port --raw GET keyname
```

## Environment-Specific Issues

### Windows Command Prompt Issues

```cmd
REM Use quotes for values with spaces
redis-cli -h hostname -p port SET greeting "Hello World"

REM Escape special characters
redis-cli -h hostname -p port SET json "{\"name\":\"value\"}"

REM Use PowerShell for complex commands
powershell -Command "redis-cli -h hostname -p port MGET key1 key2"
```

### macOS Terminal Issues

```bash
# Handle special characters
redis-cli -h hostname -p port SET data 'special$chars'

# Use proper quoting
redis-cli -h hostname -p port SET json '{"key": "value"}'

# Check terminal encoding
echo $LANG
```

## Getting Help

### Built-in Help

```bash
# General help
redis-cli HELP

# Command-specific help
redis-cli HELP SET
redis-cli HELP GET

# List all commands
redis-cli HELP @string
redis-cli HELP @connection
```

### Diagnostic Commands

```bash
# Server information
redis-cli -h hostname -p port INFO server
redis-cli -h hostname -p port INFO memory
redis-cli -h hostname -p port INFO stats

# Connection information
redis-cli -h hostname -p port CLIENT LIST
redis-cli -h hostname -p port CONFIG GET "*timeout*"

# Database information
redis-cli -h hostname -p port DBSIZE
redis-cli -h hostname -p port LASTSAVE
```

### When to Ask for Help

Contact your instructor if:
1. **Connection consistently fails** after trying troubleshooting steps
2. **Redis Insight cannot connect** but CLI works
3. **Performance is very slow** (>1 second for simple commands)
4. **Commands behave unexpectedly** despite correct syntax
5. **Server seems unresponsive** or returns errors

### Information to Provide

When asking for help, include:
- **Exact error message**
- **Command you're trying to execute**
- **Your operating system** (Windows/macOS/Linux)
- **Redis CLI version** (`redis-cli --version`)
- **Connection details** (hostname, port - not password)

## Quick Diagnostic Script

Save this as `diagnose.sh` and run it:

```bash
#!/bin/bash

HOSTNAME="redis-server.training.com"  # Replace with your hostname
PORT="6379"                           # Replace with your port

echo "🔍 Redis Connection Diagnostics"
echo "================================"

echo "Testing basic connectivity..."
ping -c 3 $HOSTNAME

echo ""
echo "Testing Redis connection..."
redis-cli -h $HOSTNAME -p $PORT PING

echo ""
echo "Getting server info..."
redis-cli -h $HOSTNAME -p $PORT INFO server | head -5

echo ""
echo "Checking Redis CLI version..."
redis-cli --version

echo ""
echo "Testing basic operations..."
redis-cli -h $HOSTNAME -p $PORT SET diagnose:test "working"
redis-cli -h $HOSTNAME -p $PORT GET diagnose:test
redis-cli -h $HOSTNAME -p $PORT DEL diagnose:test

echo ""
echo "✅ Diagnostics complete!"
```
