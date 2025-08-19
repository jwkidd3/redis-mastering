# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes  
**Objective:** Connect to Redis server and master basic CLI operations

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Connect to a remote Redis server using CLI host parameters
- Execute basic Redis commands with proper syntax
- Navigate Redis Insight GUI for data visualization
- Understand fundamental Redis data operations
- Use both command-line and GUI tools effectively

---

## Part 1: Connection Setup (10 minutes)

### Step 1: Get Redis Server Information

**Ask your instructor for:**
- Redis server hostname/IP address
- Port number (usually 6379)
- Password (if authentication is required)

**Example connection details:**
```
Hostname: redis-server.training.com
Port: 6379
Password: (will be provided)
```

### Step 2: Test Basic Connection

Test your connection using the Redis CLI with host parameters:

```bash
# Basic connection test (replace with your server details)
redis-cli -h redis-server.training.com -p 6379 PING

# If password required
redis-cli -h redis-server.training.com -p 6379 -a your_password PING

# Should return: PONG
```

**Windows Command Prompt:**
```cmd
redis-cli -h redis-server.training.com -p 6379 PING
```

**macOS Terminal:**
```bash
redis-cli -h redis-server.training.com -p 6379 PING
```

### Step 3: Interactive CLI Session

Start an interactive session for easier command execution:

```bash
# Start interactive session
redis-cli -h redis-server.training.com -p 6379

# Now you can type commands directly without repeating host info
redis> PING
redis> INFO server
redis> QUIT
```

**💡 Note:** Replace `redis-server.training.com` with your actual server hostname throughout this lab.

---

## Part 2: Redis Insight Configuration (8 minutes)

### Step 1: Launch Redis Insight

1. **Open Redis Insight** (installed on your machine)
2. **Add New Database Connection:**
   - Click **"Add Database"** or **"+"** button
   - Select **"Connect to a Redis Database"**

### Step 2: Configure Connection

**Enter connection details provided by instructor:**
- **Host:** `redis-server.training.com` (your server)
- **Port:** `6379` (your port)
- **Name:** `Lab Training Server`
- **Username:** (if required)
- **Password:** (if required)

### Step 3: Test GUI Connection

1. Click **"Test Connection"** to verify
2. Should show **"Successfully connected"**
3. Click **"Add Redis Database"**
4. You should see the database appear in your connections list

### Step 4: Explore Redis Insight Interface

Navigate through the main tabs:
- **Overview:** Server statistics and info
- **Browser:** Key-value data browser
- **Workbench:** Built-in CLI interface
- **Analysis:** Memory usage analysis

---

## Part 3: Basic Data Operations (20 minutes)

### Step 1: String Operations

Using CLI (remember to use your server hostname):

```bash
# Set and get string values
redis-cli -h redis-server.training.com -p 6379 SET mykey "Hello Redis"
redis-cli -h redis-server.training.com -p 6379 GET mykey

# Check if key exists
redis-cli -h redis-server.training.com -p 6379 EXISTS mykey

# Get key information
redis-cli -h redis-server.training.com -p 6379 TYPE mykey
redis-cli -h redis-server.training.com -p 6379 TTL mykey
```

**Using interactive session (easier):**
```bash
# Start session
redis-cli -h redis-server.training.com -p 6379

# Execute commands
redis> SET greeting "Welcome to Redis"
redis> GET greeting
redis> APPEND greeting " - Training Lab"
redis> GET greeting
redis> STRLEN greeting
redis> QUIT
```

### Step 2: Numeric Operations

```bash
# In interactive session
redis-cli -h redis-server.training.com -p 6379

redis> SET counter 0
redis> INCR counter
redis> INCR counter
redis> GET counter
redis> INCRBY counter 5
redis> GET counter
redis> DECR counter
redis> GET counter
```

### Step 3: Key Management

```bash
# Set keys with expiration
redis> SETEX temp_key 60 "This expires in 60 seconds"
redis> TTL temp_key
redis> GET temp_key

# Multiple keys operations
redis> MSET name "John" age "30" city "New York"
redis> MGET name age city
redis> KEYS *
redis> EXISTS name age email
```

### Step 4: Data Exploration in Redis Insight

1. **Switch to Redis Insight Browser tab**
2. **Refresh** to see the keys you created
3. **Click on keys** to view their values
4. **Try editing** a key value through the GUI
5. **Add a new key** using the GUI interface
6. **Set TTL** on a key using the GUI

---

## Part 4: Basic Monitoring & Information (7 minutes)

### Step 1: Server Information

```bash
# Get server information
redis-cli -h redis-server.training.com -p 6379 INFO server
redis-cli -h redis-server.training.com -p 6379 INFO memory
redis-cli -h redis-server.training.com -p 6379 INFO stats

# Check database size
redis-cli -h redis-server.training.com -p 6379 DBSIZE

# List sample keys
redis-cli -h redis-server.training.com -p 6379 KEYS "*" | head -10
```

### Step 2: Performance Testing

```bash
# Test latency to server
redis-cli -h redis-server.training.com -p 6379 --latency

# Press Ctrl+C to stop latency test

# Simple performance test
redis-cli -h redis-server.training.com -p 6379 --latency-history -i 1
```

### Step 3: Basic Monitoring

```bash
# Monitor Redis commands in real-time (optional)
# WARNING: This shows all activity - use carefully
redis-cli -h redis-server.training.com -p 6379 MONITOR

# Press Ctrl+C to stop monitoring
```

**In Redis Insight:**
1. Go to **Analysis** tab
2. View **Memory Usage** breakdown
3. Check **Slow Log** if available
4. Review **Connected Clients** information

---

## Part 5: Command Reference & Cleanup

### Essential Commands Learned

**Connection:**
```bash
redis-cli -h hostname -p port PING              # Test connection
redis-cli -h hostname -p port -a password       # With authentication
redis-cli -h hostname -p port                   # Interactive session
```

**Basic Operations:**
```bash
SET key value                    # Store string
GET key                         # Retrieve string
EXISTS key                      # Check existence
TYPE key                        # Get data type
TTL key                         # Time to live
DEL key                         # Delete key
```

**Numeric Operations:**
```bash
INCR key                        # Increment by 1
DECR key                        # Decrement by 1
INCRBY key amount               # Increment by amount
```

**Multiple Keys:**
```bash
MSET key1 val1 key2 val2        # Set multiple
MGET key1 key2                  # Get multiple
KEYS pattern                    # Find keys
```

**Information:**
```bash
INFO server                     # Server information
DBSIZE                         # Number of keys
```

### Cleanup (Optional)

If you want to clean up your test data:
```bash
# Delete specific keys
redis-cli -h redis-server.training.com -p 6379 DEL mykey greeting counter

# Or delete all keys you created
redis-cli -h redis-server.training.com -p 6379 DEL name age city temp_key
```

---

## Lab Completion Checklist

- [ ] Successfully connected to Redis server using CLI
- [ ] Tested basic PING command with host parameters
- [ ] Configured Redis Insight with server connection
- [ ] Created and retrieved string data
- [ ] Performed numeric operations (increment/decrement)
- [ ] Explored keys with TTL and expiration
- [ ] Used both CLI and Redis Insight interfaces
- [ ] Retrieved server information and statistics
- [ ] Tested connection latency and performance

---

## Troubleshooting

### Connection Issues

**Problem:** "Could not connect to Redis at hostname:port"
```bash
# Check server details with instructor
# Verify hostname and port are correct
# Test network connectivity
ping redis-server.training.com
telnet redis-server.training.com 6379
```

**Problem:** "NOAUTH Authentication required"
```bash
# Use password provided by instructor
redis-cli -h hostname -p port -a password PING
```

**Problem:** "Connection timeout"
```bash
# Check firewall/network
# Verify server is running
# Ask instructor for alternative connection details
```

### CLI Issues

**Windows specific:**
```cmd
# Use full path if redis-cli not in PATH
"C:\Program Files\Redis\redis-cli.exe" -h hostname -p port PING

# Or use PowerShell
powershell
redis-cli -h hostname -p port PING
```

**macOS specific:**
```bash
# Install via Homebrew if needed
brew install redis

# Use system Redis CLI
/usr/local/bin/redis-cli -h hostname -p port PING
```

### Redis Insight Issues

1. **Cannot connect:** Verify host/port details match CLI settings
2. **Timeout:** Check if server allows GUI connections
3. **Permission denied:** Verify authentication credentials

---

## Key Takeaways

🎉 **Congratulations!** You've completed Lab 1. You should now:

1. **Understand remote connections** - Using `-h` and `-p` parameters
2. **Know basic Redis operations** - Setting, getting, and managing data
3. **Be comfortable with tools** - Both CLI and Redis Insight
4. **Have practical experience** - Real server operations, not just theory

**Next Lab Preview:** Lab 2 will dive deeper into the RESP protocol and advanced CLI monitoring techniques.

---

## Quick Reference Card

**Connection Template:**
```bash
redis-cli -h [hostname] -p [port] -a [password] [command]
```

**Most Used Commands:**
- `PING` - Test connection
- `SET key value` - Store data
- `GET key` - Retrieve data
- `KEYS *` - List all keys
- `INFO server` - Server details
- `QUIT` - Exit interactive mode

**Remember:** Always replace `[hostname]` and `[port]` with your actual server details!
