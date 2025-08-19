# Basic Redis Commands Reference

## Connection Commands

```bash
# Basic connection test
redis-cli -h hostname -p port PING

# With authentication
redis-cli -h hostname -p port -a password PING

# Interactive session
redis-cli -h hostname -p port
redis> [commands here]
redis> QUIT

# Single command execution
redis-cli -h hostname -p port COMMAND args
```

## String Operations

```bash
# Basic string operations
SET key value                    # Store string value
GET key                         # Retrieve string value
APPEND key value                # Append to existing string
STRLEN key                      # Get string length

# String with expiration
SETEX key seconds value         # Set with expiration
TTL key                         # Check time to live
EXPIRE key seconds              # Set expiration on existing key

# Multiple strings
MSET key1 val1 key2 val2        # Set multiple keys
MGET key1 key2 key3             # Get multiple keys
```

## Numeric Operations

```bash
# Counters
SET counter 0                   # Initialize counter
INCR counter                    # Increment by 1
DECR counter                    # Decrement by 1
INCRBY counter 5                # Increment by specific amount
DECRBY counter 3                # Decrement by specific amount
```

## Key Management

```bash
# Key information
EXISTS key                      # Check if key exists (1=yes, 0=no)
TYPE key                        # Get data type of key
TTL key                         # Time to live (-1=no expiry, -2=expired)
DEL key                         # Delete key
RENAME oldkey newkey            # Rename key

# Key discovery
KEYS *                          # List all keys (use carefully in production)
KEYS user:*                     # List keys matching pattern
SCAN 0                          # Safer key discovery (cursor-based)
```

## Database Information

```bash
# Server and database info
INFO server                     # Redis server information
INFO memory                     # Memory usage information
INFO stats                      # Server statistics
DBSIZE                         # Number of keys in database
CLIENT LIST                     # List connected clients
```

## Connection Testing

```bash
# Performance testing
redis-cli -h hostname -p port --latency           # Continuous latency test
redis-cli -h hostname -p port --latency-history   # Latency with timestamps
redis-cli -h hostname -p port --stat              # Real-time stats

# Connection options
redis-cli -h hostname -p port --timeout 10        # Connection timeout
redis-cli -h hostname -p port --connect-timeout 5 # Connection timeout
```

## Redis Insight Commands

These operations can be performed in Redis Insight GUI:

- **Browser Tab:** View and edit keys visually
- **Workbench Tab:** Execute CLI commands in web interface
- **Analysis Tab:** Memory usage and slow query analysis
- **Overview Tab:** Server statistics and monitoring

## Command Line Tips

### Interactive Mode
```bash
# Start interactive session
redis-cli -h hostname -p port

# Useful in interactive mode
redis> HELP                     # Show help
redis> HELP command             # Help for specific command
redis> QUIT                     # Exit interactive mode
```

### Batch Operations
```bash
# Execute multiple commands from file
redis-cli -h hostname -p port < commands.txt

# Pipe commands
echo "SET test value" | redis-cli -h hostname -p port

# JSON output
redis-cli -h hostname -p port --json GET key
```

### Common Patterns

**Check server health:**
```bash
redis-cli -h hostname -p port PING
redis-cli -h hostname -p port INFO server | grep redis_version
```

**Basic data operations:**
```bash
# Store user data
redis-cli -h hostname -p port SET user:1001 "John Doe"
redis-cli -h hostname -p port SET user:1001:email "john@example.com"

# Retrieve user data
redis-cli -h hostname -p port GET user:1001
redis-cli -h hostname -p port MGET user:1001 user:1001:email
```

**Session management pattern:**
```bash
# Create session
redis-cli -h hostname -p port SETEX session:abc123 3600 "user_data"

# Check session
redis-cli -h hostname -p port GET session:abc123
redis-cli -h hostname -p port TTL session:abc123
```

**Counter pattern:**
```bash
# Page views counter
redis-cli -h hostname -p port INCR page:views
redis-cli -h hostname -p port INCRBY page:views 5
redis-cli -h hostname -p port GET page:views
```
