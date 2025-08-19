# Lab 4 Troubleshooting Guide - Remote Host Edition

## Remote Connection Issues

### Cannot Connect to Redis Host
**Problem**: Connection refused or timeout errors

**Diagnosis**:
```bash
# Test basic connectivity
ping $REDIS_HOST
telnet $REDIS_HOST $REDIS_PORT

# Test Redis-specific connection
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# Check authentication if required
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping
```

**Solutions**:
- Verify host and port are correct
- Check firewall rules (both client and server side)
- Confirm Redis is running and bound to external interface
- Test authentication credentials if required
- Check network connectivity between client and server

### Authentication Issues
**Problem**: Authentication failed or access denied

**Diagnosis**:
```bash
# Test without password
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# Test with password
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping

# Check Redis configuration
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD CONFIG GET requirepass
```

**Solutions**:
- Verify password is correct
- Check if password is required: `CONFIG GET requirepass`
- Ensure password is properly escaped in scripts
- Use environment variables for passwords instead of hardcoding

### Network Latency Issues
**Problem**: Commands are slow or timing out

**Diagnosis**:
```bash
# Check latency
redis-cli -h $REDIS_HOST -p $REDIS_PORT --latency
redis-cli -h $REDIS_HOST -p $REDIS_PORT --latency-history

# Check network connectivity
ping $REDIS_HOST
traceroute $REDIS_HOST  # On Linux/Mac
tracert $REDIS_HOST     # On Windows
```

**Solutions**:
- Check network path to Redis host
- Consider using a closer Redis instance
- Implement connection pooling
- Use batch operations to reduce round trips
- Set appropriate timeouts in client applications

## Environment Variable Issues

### Variables Not Set
**Problem**: Scripts fail because REDIS_HOST or REDIS_PORT not set
