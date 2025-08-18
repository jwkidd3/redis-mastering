# Lab 1 Troubleshooting Guide

## Common Issues and Solutions

### 1. Redis Connection Failed

**Problem:** `Could not connect to Redis at 127.0.0.1:6379: Connection refused`

**Solutions:**
```bash
# Check if Docker is running
docker --version

# Check if Redis container is running
docker ps | grep redis

# Start Redis container if not running
docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine

# Check container logs
docker logs redis-insurance
```

### 2. Redis Insight Connection Issues

**Problem:** Redis Insight cannot connect to localhost:6379

**Solutions:**
1. Verify Redis is running: `redis-cli ping`
2. Check port is accessible: `netstat -an | grep 6379`
3. Restart Redis Insight application
4. Try connecting to `127.0.0.1` instead of `localhost`

### 3. Data Not Loading

**Problem:** Sample insurance data not visible in CLI or Redis Insight

**Solutions:**
```bash
# Reload sample data
./scripts/load-insurance-sample-data.sh

# Verify data loaded
redis-cli KEYS "*"
redis-cli DBSIZE

# Check specific keys
redis-cli GET policy:INS001
```

### 4. TTL/Expiration Issues

**Problem:** Quotes expire too quickly or don't expire

**Solutions:**
```bash
# Check remaining TTL
redis-cli TTL quote:AUTO:Q001

# Create new quote with longer TTL
redis-cli SETEX quote:TEST001 600 "Test quote - 10 minutes"

# Monitor TTL countdown
watch "redis-cli TTL quote:TEST001"
```

### 5. Performance Issues

**Problem:** Commands running slowly

**Solutions:**
```bash
# Check Redis performance
redis-cli INFO stats

# Monitor command execution
redis-cli monitor

# Check memory usage
redis-cli INFO memory

# Use SCAN instead of KEYS for large datasets
redis-cli SCAN 0 MATCH policy:* COUNT 10
```

### 6. Docker Issues

**Problem:** Docker container won't start or keeps stopping

**Solutions:**
```bash
# Remove existing container
docker rm -f redis-insurance

# Start with verbose logging
docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine redis-server --loglevel verbose

# Check detailed logs
docker logs -f redis-insurance

# Check Docker resource usage
docker stats redis-insurance
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-insurance`
2. **Verify network connectivity:** `telnet localhost 6379`
3. **Test basic commands:** `redis-cli ping`
4. **Restart services:** Docker Desktop, Redis Insight
5. **Ask instructor** for assistance

## Useful Commands for Debugging

```bash
# Complete environment check
redis-cli ping
redis-cli INFO server
redis-cli DBSIZE
redis-cli KEYS "*" | head -10

# Performance monitoring
redis-cli INFO stats | grep instantaneous
redis-cli INFO memory | grep used_memory_human

# Connection monitoring
redis-cli INFO clients
```
