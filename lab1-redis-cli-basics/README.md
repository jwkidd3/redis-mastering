# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes
**Focus:** Redis Insight Workbench for basic operations
**Prerequisites:** Redis Insight installed, Redis server running

## 🎯 Learning Objectives

- Connect to Redis server using Redis Insight
- Execute basic Redis commands in Workbench
- Navigate Redis Insight Browser and Workbench
- Understand fundamental Redis data operations
- Manage keys with TTL

## 🚀 Quick Start

### Step 1: Start Redis Server

**Windows:**
```cmd
cd scripts
start-redis.bat
```

**Mac/Linux:**
```bash
docker run -d -p 6379:6379 --name redis redis/redis-stack:latest
```

### Step 2: Connect Redis Insight

1. Open Redis Insight (desktop app or `http://localhost:8001`)
2. Click **"Add Database"**
3. Enter connection details:
   - **Host:** `localhost`
   - **Port:** `6379`
   - **Name:** `Redis Course`
4. Click **"Test Connection"** → **"Add Database"**

### Step 3: Open Workbench

1. Click your database connection
2. Go to **"Workbench"** tab in the left sidebar
3. You're ready to run Redis commands!

## Part 1: Basic String Operations

**In Redis Insight Workbench, run these commands:**

### Store and Retrieve Data

```redis
// Set values
SET customer:1001 "John Smith"
SET policy:AUTO-001 "Active"
SET premium:AUTO-001 1200

// Get values
GET customer:1001
GET policy:AUTO-001
```

### Numeric Operations

```redis
// Create counter
SET visitors:count 0
INCR visitors:count
INCR visitors:count
GET visitors:count

// Increment by amount
INCRBY visitors:count 10
DECRBY visitors:count 2
```

## Part 2: Key Management

### Check Keys

```redis
// Check if key exists
EXISTS customer:1001
EXISTS customer:9999

// Find keys by pattern
KEYS customer:*
KEYS policy:*

// Get key type
TYPE customer:1001
```

### TTL Management

```redis
// Set key with expiration (3600 seconds = 1 hour)
SETEX session:user123 3600 "session-data"

// Add TTL to existing key (86400 seconds = 1 day)
EXPIRE customer:1001 86400

// Check remaining TTL
TTL session:user123
TTL customer:1001

// Remove expiration
PERSIST customer:1001
```

## Part 3: Redis Insight Browser

### Explore the Browser Tab

Now switch from Workbench to Browser to see your data visually:

1. Click **"Browser"** tab in the left sidebar
2. View all keys you created (customer:*, session:*, etc.)
3. Click on a key to see:
   - Its value
   - TTL countdown (for keys with expiration)
   - Key type (string, hash, list, etc.)
4. Try editing a value through the GUI
5. Delete a test key using the trash icon

### Practice Both Interfaces

- **Workbench:** Best for running commands and learning Redis
- **Browser:** Best for visualizing data and quick edits
- Use both throughout the course!

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

**Run these in Redis Insight Workbench:**

```redis
// Connection test
PING

// String operations
SET key value
GET key
INCR key
INCRBY key increment
SETEX key seconds value

// Key operations
EXISTS key
KEYS pattern
TYPE key
DEL key
EXPIRE key seconds
TTL key
PERSIST key

// Server info
INFO server
DBSIZE
```

## ✅ Lab Completion Checklist

- [ ] Connected Redis Insight to Redis server
- [ ] Executed SET/GET commands in Workbench
- [ ] Used INCR for counters
- [ ] Managed keys with TTL (SETEX, EXPIRE)
- [ ] Explored data in Browser tab
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
