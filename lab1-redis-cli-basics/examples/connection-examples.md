# Connection Examples for Different Scenarios

## Basic Connection

```bash
# Simple connection test
redis-cli -h redis-server.training.com -p 6379 PING

# With output
redis-cli -h redis-server.training.com -p 6379 PING
# Output: PONG
```

## Interactive Sessions

```bash
# Start interactive mode
redis-cli -h redis-server.training.com -p 6379

# Now execute commands without repeating host info
redis> SET name "Alice"
redis> GET name
redis> INCR visits
redis> GET visits
redis> QUIT
```

## Authentication (if required)

```bash
# With password
redis-cli -h redis-server.training.com -p 6379 -a secretpassword PING

# Interactive with auth
redis-cli -h redis-server.training.com -p 6379 -a secretpassword
redis> GET secure_data
```

## Different Output Formats

```bash
# JSON output
redis-cli -h redis-server.training.com -p 6379 --json INFO server

# Raw output (no quotes)
redis-cli -h redis-server.training.com -p 6379 --raw GET message

# CSV output for multiple values
redis-cli -h redis-server.training.com -p 6379 --csv MGET key1 key2 key3
```

## Batch Operations

```bash
# Multiple commands in one call
redis-cli -h redis-server.training.com -p 6379 \
  MSET user:1 "John" user:2 "Jane" user:3 "Bob"

# Execute commands from file
echo "SET batch:test 'Hello'
GET batch:test
INCR batch:counter" | redis-cli -h redis-server.training.com -p 6379
```

## Performance Testing

```bash
# Latency monitoring
redis-cli -h redis-server.training.com -p 6379 --latency

# Latency with history
redis-cli -h redis-server.training.com -p 6379 --latency-history -i 5

# Real-time stats
redis-cli -h redis-server.training.com -p 6379 --stat
```

## Troubleshooting Connections

```bash
# Test basic network connectivity
ping redis-server.training.com
telnet redis-server.training.com 6379

# Check Redis server status
redis-cli -h redis-server.training.com -p 6379 INFO server | grep redis_version

# Verbose connection info
redis-cli -h redis-server.training.com -p 6379 --verbose PING
```

## Windows-Specific Examples

```cmd
REM Windows Command Prompt
redis-cli -h redis-server.training.com -p 6379 PING

REM PowerShell
powershell -Command "redis-cli -h redis-server.training.com -p 6379 PING"

REM Full path if not in PATH
"C:\Program Files\Redis\redis-cli.exe" -h redis-server.training.com -p 6379 PING
```

## macOS-Specific Examples

```bash
# Using Homebrew installation
/usr/local/bin/redis-cli -h redis-server.training.com -p 6379 PING

# Check installation
which redis-cli
redis-cli --version
```
