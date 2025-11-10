# Lab 1: Redis Insight Workbench Commands

This guide contains all Redis commands for Lab 1 that can be executed directly in **Redis Insight Workbench**.

## 🚀 Getting Started

1. Open Redis Insight (`http://localhost:8001` or desktop app)
2. Click **"Add Database"** if not already connected
3. Enter connection details:
   - **Host:** (provided by instructor)
   - **Port:** 6379 (or as provided)
   - **Password:** (if required)
4. Click **"Test Connection"** → **"Add Database"**

## 📝 Using Redis Insight Workbench

### Open Workbench
- Click on your database connection
- Go to **"Workbench"** tab (or **"CLI"** tab in older versions)
- Type commands and press **Enter** or click **Run**

### Browser Tab
- Use the **"Browser"** tab to visually explore keys
- Click on any key to see its value, type, and TTL
- Edit, delete, or refresh keys through the GUI

---

## Part 1: Basic String Operations

### Store and Retrieve Data

```redis
// Set values
SET customer:1001 "John Smith"
SET policy:AUTO-001 "Active"
SET premium:AUTO-001 1200

// Get values
GET customer:1001
GET policy:AUTO-001
GET premium:AUTO-001
```

**Expected Output:**
```
OK
OK
OK
"John Smith"
"Active"
"1200"
```

### Numeric Operations

```redis
// Create and increment counter
SET visitors:count 0
INCR visitors:count
INCR visitors:count
GET visitors:count

// Increment/decrement by amount
INCRBY visitors:count 10
DECRBY visitors:count 2
GET visitors:count
```

**Expected Output:**
```
OK
(integer) 1
(integer) 2
"2"
(integer) 12
(integer) 10
"10"
```

---

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
TYPE premium:AUTO-001
```

**Expected Output:**
```
(integer) 1
(integer) 0
1) "customer:1001"
1) "policy:AUTO-001"
string
string
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
TTL customer:1001
```

**Expected Output:**
```
OK
(integer) 1
(integer) 3599
(integer) 86399
(integer) 1
(integer) -1
```

---

## Part 3: Exercises

### Exercise 1: Customer Management

```redis
// 1. Create 5 customer records
SET customer:1001 "John Smith"
SET customer:1002 "Jane Doe"
SET customer:1003 "Bob Johnson"
SET customer:1004 "Alice Williams"
SET customer:1005 "Charlie Brown"

// 2. Retrieve all customers
KEYS customer:*

// 3. Check if customer:1005 exists
EXISTS customer:1005

// 4. Delete customer:1005
DEL customer:1005

// 5. Verify deletion
EXISTS customer:1005
```

### Exercise 2: Session Management

```redis
// 1. Create sessions with 30-minute TTL (1800 seconds)
SETEX session:user001 1800 "user001-session-data"
SETEX session:user002 1800 "user002-session-data"
SETEX session:user003 1800 "user003-session-data"

// 2. Check TTL for each session
TTL session:user001
TTL session:user002
TTL session:user003

// 3. Extend session:user001 by 1 hour (3600 seconds)
EXPIRE session:user001 3600
TTL session:user001

// 4. Remove expiration from session:user002
PERSIST session:user002
TTL session:user002
```

### Exercise 3: Counter Operations

```redis
// 1. Create page view counter
SET page:views 0

// 2. Increment it multiple times (run this command many times)
INCR page:views

// 3. Increment by 50
INCRBY page:views 50

// 4. Get final value
GET page:views
```

---

## Part 4: Server Information

```redis
// Check total number of keys
DBSIZE

// Get server information
INFO server

// Check memory usage
INFO memory
```

---

## 🔍 Using the Browser Tab

After running commands in Workbench:

1. **Switch to Browser Tab**
   - Click **"Browser"** in the left sidebar
   - See all your keys listed

2. **Explore Keys**
   - Click on `customer:1001` to see its value
   - Check the TTL countdown for `session:*` keys
   - See key types (string, hash, list, etc.)

3. **Visual Operations**
   - **Edit:** Click on a value to modify it
   - **Delete:** Click trash icon to delete a key
   - **Refresh:** Click refresh icon to see updated TTL
   - **Filter:** Use search box to find keys by pattern

4. **Tree View**
   - Enable "Tree View" toggle to see hierarchical key structure
   - Keys like `customer:1001`, `customer:1002` will be grouped under `customer:`

---

## 💡 Tips for Redis Insight

1. **Multi-line Commands**: Not needed for basic commands, but you can use them for Lua scripts
2. **Command History**: Use up/down arrows to recall previous commands
3. **Auto-complete**: Start typing and Redis Insight will suggest commands
4. **Copy Results**: Click on results to copy them to clipboard
5. **Split View**: Open Browser and Workbench side-by-side (desktop version)

---

## ✅ Lab Completion Checklist

Using Redis Insight Workbench, verify you can:

- [ ] Connect to Redis server successfully
- [ ] Execute SET and GET commands
- [ ] Use INCR and INCRBY for counters
- [ ] Create keys with SETEX
- [ ] Check TTL with TTL command
- [ ] Find keys with KEYS pattern
- [ ] Delete keys with DEL
- [ ] View all keys in Browser tab
- [ ] Edit a value through Browser GUI
- [ ] See TTL countdown in Browser tab

---

## 🎯 Key Redis Commands Used

| Command | Purpose | Example |
|---------|---------|---------|
| `SET` | Store a string value | `SET key value` |
| `GET` | Retrieve a string value | `GET key` |
| `INCR` | Increment number by 1 | `INCR counter` |
| `INCRBY` | Increment by amount | `INCRBY counter 10` |
| `SETEX` | Set with TTL | `SETEX key 3600 value` |
| `EXISTS` | Check if key exists | `EXISTS key` |
| `KEYS` | Find keys by pattern | `KEYS customer:*` |
| `TYPE` | Get key type | `TYPE key` |
| `DEL` | Delete a key | `DEL key` |
| `EXPIRE` | Set TTL on key | `EXPIRE key 3600` |
| `TTL` | Check remaining TTL | `TTL key` |
| `PERSIST` | Remove expiration | `PERSIST key` |
| `DBSIZE` | Count total keys | `DBSIZE` |

---

## 📚 Next Steps

- Try all commands in the Workbench
- Compare experience with terminal redis-cli
- Explore the Browser tab's visual interface
- Practice the exercises until comfortable
