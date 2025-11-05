# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes
**Focus:** Redis CLI and Redis Insight for basic operations
**Prerequisites:** Redis CLI and Redis Insight installed

## 🎯 Learning Objectives

- Connect to remote Redis server using CLI
- Execute basic Redis commands
- Navigate Redis Insight GUI
- Understand fundamental Redis data operations
- Manage keys with TTL

## 🚀 Quick Start

### Step 1: Get Server Details

Your instructor will provide:
- **Hostname:** (e.g., `redis-server.training.com`)
- **Port:** (usually `6379`)
- **Password:** (if required)

### Step 2: Test Connection

```bash
# Test connection
redis-cli -h [hostname] -p [port] PING
# Expected: PONG

# Set alias for convenience (optional)
alias rcli='redis-cli -h [hostname] -p [port]'
```

### Step 3: Configure Redis Insight

1. Open Redis Insight: `http://localhost:8001`
2. Click **"Add Database"**
3. Enter connection details from instructor
4. Test connection

## Part 1: Basic String Operations

### Store and Retrieve Data

```bash
# Set values
rcli SET customer:1001 "John Smith"
rcli SET policy:AUTO-001 "Active"
rcli SET premium:AUTO-001 1200

# Get values
rcli GET customer:1001
rcli GET policy:AUTO-001
```

### Numeric Operations

```bash
# Counters
rcli SET visitors:count 0
rcli INCR visitors:count
rcli INCR visitors:count
rcli GET visitors:count

# Increment by amount
rcli INCRBY visitors:count 10
rcli DECRBY visitors:count 2
```

## Part 2: Key Management

### Check Keys

```bash
# Check if key exists
rcli EXISTS customer:1001
rcli EXISTS customer:9999

# Find keys
rcli KEYS customer:*
rcli KEYS policy:*

# Get key type
rcli TYPE customer:1001
```

### TTL Management

```bash
# Set key with expiration (session example)
rcli SETEX session:user123 3600 "session-data"

# Add TTL to existing key
rcli EXPIRE customer:1001 86400

# Check remaining TTL
rcli TTL session:user123
rcli TTL customer:1001

# Remove expiration
rcli PERSIST customer:1001
```

## Part 3: Redis Insight

### Navigate Redis Insight

1. Open **Browser** tab
2. View all keys created in exercises
3. Click on a key to see its value and TTL
4. Try editing a value through GUI
5. Delete a test key

### Use CLI in Redis Insight

1. Go to **CLI** tab in Redis Insight
2. Execute same commands as terminal
3. Compare experience with command-line CLI

## 🎓 Exercises

### Exercise 1: Customer Management

1. Create 5 customer records using SET
2. Retrieve all customers using KEYS pattern
3. Check if customer:1005 exists
4. Delete customer:1005

### Exercise 2: Session Management

1. Create session for 3 users (30-minute TTL)
2. Check TTL for each session
3. Extend one session by 1 hour
4. Remove expiration from one session

### Exercise 3: Counter Operations

1. Create page view counter
2. Increment it 100 times
3. Increment by 50
4. Get final value

## 📋 Key Commands Reference

```bash
# Connection
redis-cli -h hostname -p port PING

# String operations
SET key value
GET key
INCR key
INCRBY key increment
SETEX key seconds value

# Key operations
EXISTS key
KEYS pattern
TYPE key
DEL key
EXPIRE key seconds
TTL key
PERSIST key

# Server info
INFO server
DBSIZE
```

## ✅ Lab Completion Checklist

- [ ] Connected to remote Redis server
- [ ] Executed SET/GET commands
- [ ] Used INCR for counters
- [ ] Managed keys with TTL
- [ ] Used Redis Insight browser and CLI
- [ ] Completed all exercises

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **Redis Commands:** `https://redis.io/commands/`
- **Redis Insight:** `https://redis.io/docs/stack/insight/`

## 🔧 Troubleshooting

**Connection failed:**
```bash
# Check connection details
redis-cli -h hostname -p port PING

# Test network connectivity
ping hostname
```

**Authentication error:**
```bash
# Use password if required
redis-cli -h hostname -p port -a password PING
```
