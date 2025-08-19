# Redis CLI Host Parameter Reference

## Basic Syntax

```bash
redis-cli -h <hostname> -p <port> [options] <command>
```

## Connection Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-h <host>` | Redis server hostname or IP | `-h localhost`, `-h 192.168.1.100` |
| `-p <port>` | Redis server port | `-p 6379`, `-p 6380` |
| `-a <password>` | Authentication password | `-a mypassword` |
| `-n <db>` | Database number | `-n 0`, `-n 1` |
| `--askpass` | Prompt for password | `--askpass` |

## Connection Options

| Option | Description | Example |
|--------|-------------|---------|
| `--connect-timeout <sec>` | Connection timeout | `--connect-timeout 10` |
| `--timeout <sec>` | Socket timeout | `--timeout 5` |

## Output Format Options

| Option | Description | Example |
|--------|-------------|---------|
| `--csv` | CSV output format | `--csv HGETALL key` |
| `--raw` | Raw output (no formatting) | `--raw GET key` |
| `--json` | JSON output format | `--json HGETALL key` |

## Monitoring Options

| Option | Description | Usage |
|--------|-------------|-------|
| `--latency` | Show latency statistics | Press Ctrl+C to stop |
| `--latency-history` | Latency over time | Press Ctrl+C to stop |
| `--intrinsic-latency <sec>` | Test intrinsic latency | Duration in seconds |

## Common Host Formats

```bash
# Local connections
redis-cli -h localhost -p 6379
redis-cli -h 127.0.0.1 -p 6379

# Remote connections
redis-cli -h redis.company.com -p 6379
redis-cli -h 10.0.1.100 -p 6380

# With authentication
redis-cli -h secure-redis.com -p 6379 -a password123

# Different database
redis-cli -h localhost -p 6379 -n 1

# With timeouts
redis-cli -h slow-server.com -p 6379 --connect-timeout 15 --timeout 10
```

## Interactive Session

```bash
# Start interactive session
redis-cli -h localhost -p 6379

# Inside session (no host parameters needed)
> PING
> INFO server
> SET key value
> GET key
> EXIT
```

## Pipeline Operations

```bash
# Pipe multiple commands
echo -e "PING\nINFO server\nDBSIZE" | redis-cli -h localhost -p 6379 --pipe

# From file
redis-cli -h localhost -p 6379 --pipe < commands.txt
```

## Error Handling

```bash
# Test connectivity
redis-cli -h localhost -p 6379 ping >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Redis is reachable"
else
    echo "Redis connection failed"
fi
```

## Best Practices

1. **Always specify host and port explicitly**
2. **Use IP addresses for better performance**
3. **Set appropriate timeouts for remote connections**
4. **Use authentication when required**
5. **Handle connection errors gracefully**
6. **Use appropriate output formats for scripts**
