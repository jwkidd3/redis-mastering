# Lab 2 Troubleshooting Guide

## Common Issues

### Monitor Not Showing Output

**Problem:** `redis-cli monitor` shows nothing

**Solution:**
```bash
# Check Redis is running
docker ps | grep redis

# Test connection
redis-cli ping

# Generate test traffic
redis-cli SET test "value"
```

### Netcat (nc) Not Available

**Problem:** `nc: command not found`

**Solution:**
```bash
# Mac
brew install netcat

# Ubuntu/Debian
sudo apt-get install netcat

# Alternative: Use telnet
telnet localhost 6379
```

### Raw Protocol Commands Failing

**Problem:** Raw RESP commands return errors

**Solution:**
- Ensure proper line endings (\r\n)
- Check command syntax
- Verify array count matches arguments

Example:
```bash
# Correct
echo -e "*2\r\n\$3\r\nGET\r\n\$3\r\nkey\r\n"

# Incorrect (missing \r\n)
echo -e "*2\$3\nGET\$3\nkey"
```

### High Latency in Monitoring

**Problem:** Commands show high latency

**Check:**
```bash
# Redis server info
redis-cli INFO stats

# Check slow log
redis-cli SLOWLOG GET 10

# Monitor client connections
redis-cli CLIENT LIST
```

### Redis Insight Not Connecting

**Problem:** Cannot connect to Redis from Insight

**Solution:**
1. Check Redis is bound to all interfaces:
```bash
redis-cli CONFIG GET bind
```

2. For Docker, ensure port mapping:
```bash
docker run -p 6379:6379 redis:7-alpine
```

3. Test from host:
```bash
telnet localhost 6379
```

## Performance Tips

### Reduce Protocol Overhead
- Use pipelining for bulk operations
- Prefer MSET/MGET over individual SET/GET
- Use transactions for related operations

### Monitor Efficiently
- Don't use MONITOR in production continuously
- Use SLOWLOG for performance issues
- Enable latency monitoring when needed

### Debug Protocol Issues
1. Start with simple commands (PING)
2. Use monitor to see exact protocol
3. Compare with working examples
4. Check Redis logs for errors
