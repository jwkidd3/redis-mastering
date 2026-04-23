# Lab 4: Key Management & TTL

**Duration:** 50 minutes
**Focus:** Key organization patterns and TTL strategies using Redis Insight
**Prerequisites:** Lab 3 completed (String operations), Redis Insight connected

## 🎯 Learning Objectives

- Design hierarchical key naming conventions
- Implement TTL for quotes, sessions, and temporary data
- Monitor key expiration and memory usage using Redis Insight
- Build session management with automatic cleanup
- Visualize key patterns in Redis Insight Browser
- Track TTL countdown in real-time

## 📁 Project Structure

```
lab4-key-management-ttl/
├── README.md                         # This file
└── docs/
    └── key-patterns.md              # Key naming best practices
```

## 🚀 Quick Start

### Step 1: Ensure Redis is Running

**Windows:**
```cmd
cd scripts
start-redis.bat
```

**Mac/Linux:**
```bash
docker run -d -p 6379:6379 --name redis redis/redis-stack:latest
```

### Step 2: Open Redis Insight Workbench

1. Open Redis Insight
2. Connect to your database
3. Click **"Workbench"** tab
4. You're ready to run commands!

### Step 3: Test Connection

**In Workbench, run:**
```redis
PING
```
Expected response: `PONG`

---

## Part 1: Key Naming Conventions

### Hierarchical Key Design

**In Workbench, run these commands:**

Use colon-separated patterns for organization:

```redis
// Pattern: entity:type:id:attribute

// Policy keys
SET policy:auto:100001:status "active"
SET policy:auto:100001:premium "1200.00"
SET policy:home:200001:status "active"
SET policy:life:300001:status "pending"

// Customer keys
SET customer:C001:name "John Smith"
SET customer:C001:email "john@example.com"
SET customer:C001:tier "premium"

// Claims keys
SET claim:CLM001:status "submitted"
SET claim:CLM001:amount "5000"
SET claim:CLM001:policy "policy:auto:100001"
```

### Visualize Key Hierarchy in Browser

1. Switch to **Browser** tab in Redis Insight
2. Notice how keys are automatically grouped:
   - `policy:*` (policies)
   - `customer:*` (customers)
   - `claim:*` (claims)
3. Expand each group to see the hierarchical structure
4. Click any key to view its value and properties

💡 **Why This Matters:** Hierarchical keys make your data self-organizing in Redis Insight Browser. It's like having folders without actually having folders!

### Search by Pattern

**In Workbench:**

```redis
// Find all auto policies
KEYS policy:auto:*

// Find all customer data
KEYS customer:*

// Find specific customer's data
KEYS customer:C001:*

// Get total key count
DBSIZE
```

⚠️ **Production Note:** KEYS command blocks Redis. In production, use SCAN instead. But for learning in Workbench, KEYS is fine!

### Best Practices

- ✅ Use lowercase with colons: `customer:123:email`
- ✅ Be consistent: Always use same order (`entity:id:attribute`)
- ✅ Avoid special characters and spaces
- ✅ Keep keys under 100 characters
- ✅ Use meaningful prefixes that group well in Browser tab

---

## Part 2: TTL Management

### Set Expiration

**In Workbench, run these commands:**

```redis
// Set TTL when creating key (SETEX) - Best Practice!
SETEX quote:Q12345 3600 '{"coverage":"100k", "premium":"50"}'

// Add TTL to existing key
SET session:user123 "session-data"
EXPIRE session:user123 1800

// TTL in milliseconds (for very short durations)
PSETEX temp:data 5000 "expires in 5 seconds"
```

### Watch TTL Countdown in Browser

1. After running the commands above, switch to **Browser** tab
2. Find the key `quote:Q12345`
3. Look for the **TTL column** - you'll see the countdown!
4. Click **refresh** icon periodically to watch it decrease
5. When TTL reaches 0, the key disappears automatically

💡 **Redis Insight Magic:** You can watch keys expire in real-time without any monitoring scripts!

### Check TTL Programmatically

**In Workbench:**

```redis
// Check remaining time (seconds)
TTL quote:Q12345

// Check in milliseconds
PTTL quote:Q12345

// Check if key has TTL
TTL mykey
```

**TTL Return Values:**
- `-2` = key doesn't exist
- `-1` = key exists but has no TTL (permanent)
- `positive number` = seconds remaining

### Remove Expiration

```redis
// Make a key permanent (remove TTL)
PERSIST session:user123

// Verify (should return -1)
TTL session:user123
```

**Verify in Browser:** The TTL column for this key will now show "-" (no TTL)

### Update Expiration

```redis
// Reset TTL to a new value
EXPIRE session:user123 3600

// Example: Short TTL for testing
SET test:expiring "watch me disappear"
EXPIRE test:expiring 30
// Check remaining time
TTL test:expiring
```

**Challenge:** Create a key with 60-second TTL and watch it disappear in Browser tab!

---

## Part 3: Quote Management System

### Create Quote with TTL

**In Workbench, run these commands:**

```redis
// Quotes expire after 24 hours (86400 seconds)
SETEX quote:Q001 86400 '{"type":"auto","premium":"1200"}'
SETEX quote:Q002 86400 '{"type":"home","premium":"850"}'
SETEX quote:Q003 86400 '{"type":"life","premium":"45"}'
```

**For testing, let's create a short-lived quote:**
```redis
// This quote expires in 2 minutes
SETEX quote:Q004 120 '{"type":"test","premium":"100"}'
```

### Check Quote Status

```redis
// How long until quote expires?
TTL quote:Q001

// Is quote still valid?
EXISTS quote:Q001

// Get quote details
GET quote:Q001
```

### Visualize Quotes in Browser

1. Switch to **Browser** tab
2. Search for `quote:*`
3. See all quotes with their TTLs
4. Click on `quote:Q004` (2-minute expiration)
5. Watch the TTL column count down!
6. Refresh after 2 minutes - the key is gone!

### Extend Quote Expiration

**In Workbench:**

```redis
// Customer requests extension - add another 24 hours
EXPIRE quote:Q001 86400

// Verify new TTL
TTL quote:Q001
```

💡 **Real-World Scenario:** Insurance quotes often expire after 30 days. Use SETEX to automatically cleanup old quotes without manual intervention!

### Monitor Quote Expiration

```redis
// Check remaining quotes
KEYS quote:*

// Count active quotes
DBSIZE
```

**In Browser:** Use the search bar to filter `quote:*` and visually see which quotes are expiring soon.

---

## Part 4: Session Management

### Create User Session

**In Workbench, run these commands:**

```redis
// Sessions expire after 30 minutes (1800 seconds)
SETEX session:user:alice 1800 '{"userId":"alice","role":"admin","loginTime":"2024-11-10T10:00:00Z"}'
SETEX session:user:bob 1800 '{"userId":"bob","role":"user","loginTime":"2024-11-10T10:05:00Z"}'
SETEX session:user:charlie 1800 '{"userId":"charlie","role":"user","loginTime":"2024-11-10T10:10:00Z"}'
```

**For testing, create short-lived sessions:**
```redis
// This session expires in 3 minutes
SETEX session:user:test 180 '{"userId":"test","role":"tester"}'
```

### Renew Session

```redis
// User activity detected - extend session by another 30 minutes
EXPIRE session:user:alice 1800

// Verify session was extended
TTL session:user:alice
```

💡 **Real-World Pattern:** Every time a user makes a request, renew their session with EXPIRE. This keeps active users logged in!

### Check Session

```redis
// Is session still valid?
EXISTS session:user:alice

// Get session data
GET session:user:alice

// How much time left?
TTL session:user:alice
```

### Visualize Active Sessions in Browser

1. Switch to **Browser** tab
2. Search for `session:*`
3. See all active sessions with TTLs
4. Sort by TTL to find sessions expiring soon
5. Watch `session:user:test` expire after 3 minutes!

### Monitor Session Count

**In Workbench:**

```redis
// Count active sessions
KEYS session:*

// Get total database size
DBSIZE
```

**In Browser:**
- Use the search filter to view only session keys
- The key count shows number of active sessions
- TTL column shows which sessions are about to expire

💡 **No Monitoring Scripts Needed!** Redis Insight Browser provides all the session monitoring you need with real-time TTL display.

---

## Part 5: Temporary Data Management

### Cache with TTL

**In Workbench, run these commands:**

```redis
// Cache API response for 5 minutes
SETEX cache:weather:london 300 '{"temp":18,"conditions":"cloudy"}'

// Cache search results for 10 minutes
SETEX cache:search:term123 600 '[{"id":1},{"id":2}]'

// Cache database query for 1 hour
SETEX cache:query:top-policies 3600 '[{"id":"AUTO-001"},{"id":"HOME-002"}]'
```

**Verify in Browser:** Search for `cache:*` and watch TTL countdown!

### Rate Limiting

**In Workbench:**

```redis
// Allow 100 API calls per hour per user
SET ratelimit:user:alice:2024-11-10-10 0
EXPIRE ratelimit:user:alice:2024-11-10-10 3600

// Simulate API calls
INCR ratelimit:user:alice:2024-11-10-10
INCR ratelimit:user:alice:2024-11-10-10
INCR ratelimit:user:alice:2024-11-10-10

// Check how many calls made
GET ratelimit:user:alice:2024-11-10-10

// Check TTL - when counter resets
TTL ratelimit:user:alice:2024-11-10-10
```

💡 **Real-World Pattern:** Rate limiting prevents API abuse. Counter automatically resets after 1 hour when key expires!

### Temporary Locks (Distributed Locking)

```redis
// Acquire lock for 30 seconds (NX = only if not exists)
SET lock:process:batch-001 "worker-1" NX EX 30

// Try to acquire same lock (should fail)
SET lock:process:batch-001 "worker-2" NX EX 30

// Check if lock exists
EXISTS lock:process:batch-001

// Get lock owner
GET lock:process:batch-001
```

**Wait 30 seconds then try again:**
```redis
// Lock should be released now
SET lock:process:batch-001 "worker-2" NX EX 30
```

**Watch in Browser:**
1. Search for `lock:*`
2. See the lock with its 30-second TTL
3. Watch it disappear when TTL reaches 0
4. Lock is automatically released - no cleanup code needed!

💡 **Why TTL Matters:** If a worker crashes, the lock doesn't stay forever. TTL ensures automatic cleanup!

---

## Part C: Advanced Key Operations (10 min)

These commands round out the TTL / key-management toolkit. Run every command in **Redis Insight Workbench** and watch the results in **Browser**.

### C.1 — `EXPIREAT` — Expire a Key at a Specific Calendar Time

`EXPIRE` takes a duration; `EXPIREAT` takes an absolute Unix timestamp (seconds since 1970-01-01 UTC). Use it when business rules dictate a specific calendar deadline rather than "N seconds from now."

**Insurance use case:** An auto policy expires at midnight UTC on its renewal date regardless of when the key was written.

```redis
// Policy that must expire at 2026-12-31T23:59:59Z
// 2026-12-31T23:59:59Z = 1798761599 (Unix seconds)
SET policy:auto:P900001:status "active"
EXPIREAT policy:auto:P900001:status 1798761599

// Verify
TTL policy:auto:P900001:status
// Expected: large positive number of seconds until that date

// Quick demo: expire at "now + 30 seconds" as a Unix timestamp
SET demo:expireat "watch me vanish"
EVAL "redis.call('EXPIREAT', KEYS[1], tonumber(ARGV[1])) return redis.call('TTL', KEYS[1])" 1 demo:expireat $(date -v+30S +%s 2>/dev/null || date -d '+30 seconds' +%s)
```

**Expected output for `TTL policy:auto:P900001:status`:** A positive integer equal to seconds remaining until the configured timestamp.

---

### C.2 — `PEXPIRE` and `PTTL` — Millisecond-Precision Expiration

`EXPIRE`/`TTL` work in seconds. For sub-second precision (real-time pricing quotes, short-lived lock leases, fraud-detection windows), use `PEXPIRE` and `PTTL`.

**Insurance use case:** A real-time quote page shows a "lock-in price" for the next **2500 ms** while the UI commits the selection. Anything longer risks a stale rate.

```redis
SET quote:realtime:R42 '{"premium":"1142.50"}'
PEXPIRE quote:realtime:R42 2500

// Check remaining milliseconds
PTTL quote:realtime:R42
// Expected: a number between 0 and 2500

// Check seconds view of the same key
TTL quote:realtime:R42
// Expected: 2 or 3 (rounded from milliseconds)
```

---

### C.3 — `PSETEX` — Atomic `SET` + Millisecond TTL

Combines `SET` and `PEXPIRE` into one atomic command. Prefer this over the two-step version in production.

**Insurance use case:** Fraud-scoring microservice caches the current risk score for **1500 ms** to absorb duplicate downstream calls without staleness.

```redis
PSETEX fraud:score:CUST001 1500 '{"score":0.87,"model":"v3"}'

PTTL fraud:score:CUST001
// Expected: <= 1500
```

---

### C.4 — `SCAN` vs `KEYS` — Production-Safe Iteration

`KEYS policy:*` blocks Redis for the entire scan — fatal on a large dataset. `SCAN` is cursor-based and non-blocking.

**Insurance use case:** Nightly job that touches every `policy:*` key to refresh a derived cache — must not stall the live quote engine.

```redis
// Seed some policies
MSET policy:auto:P1:status active policy:auto:P2:status active policy:home:P3:status active policy:life:P4:status active

// Iterate non-blocking
SCAN 0 MATCH policy:* COUNT 100
// Returns: [next_cursor, [matching keys batch]]
// Continue passing the returned cursor back until it returns 0

// Compare: the blocking version (DO NOT use on prod)
KEYS policy:*
```

**Expected behavior:** `SCAN` returns a cursor plus a *partial* batch. Keep re-running with the returned cursor until it is `0`. In Redis Insight Browser the key-tree filter uses `SCAN` under the hood — that's why it's always safe.

---

### C.5 — `RENAME` and `RENAMENX` — Moving Keys Without Data Copy

`RENAME` atomically moves a key to a new name, overwriting the target if it exists. `RENAMENX` only renames if the target does **not** already exist.

**Insurance use case:** A quote is accepted and becomes a policy — rename `quote:Q501` to `policy:auto:P501` in one atomic step rather than copying data and deleting.

```redis
// Quote created
SETEX quote:Q501 86400 '{"type":"auto","premium":1180}'

// Customer accepts → promote to policy
RENAME quote:Q501 policy:auto:P501

// Verify
EXISTS quote:Q501
// Expected: 0
EXISTS policy:auto:P501
// Expected: 1
TTL policy:auto:P501
// Expected: TTL is preserved from the original quote

// RENAMENX example — refuse to overwrite an existing policy
SET policy:auto:P501 "already exists"
SET quote:Q502 "pending conversion"
RENAMENX quote:Q502 policy:auto:P501
// Expected: 0 (not renamed, target exists)
```

**Why `RENAMENX` matters:** Guards against accidentally clobbering an active policy with a stale quote during a race.

---

### Part C Summary Table

| Command    | Purpose                                  | Insurance example                              |
|------------|------------------------------------------|-----------------------------------------------|
| `EXPIREAT` | Expire at absolute Unix timestamp        | Policy end-of-term calendar date              |
| `PEXPIRE`  | Millisecond-precision TTL                | Real-time quote lock window                   |
| `PTTL`     | Query TTL in milliseconds                | Inspect remaining quote-lock window           |
| `PSETEX`   | Atomic SET + millisecond TTL             | Fraud-score cache (<2s)                       |
| `SCAN`     | Non-blocking key iteration               | Nightly refresh over `policy:*`               |
| `RENAME`   | Atomic key move (with TTL preserved)     | Quote → policy promotion                      |
| `RENAMENX` | Rename only if target absent             | Safe quote→policy promotion without overwrite |

---

## 🎓 Exercises

Complete these exercises in **Redis Insight Workbench** and verify results in **Browser** tab:

### Exercise 1: Policy Organization

**Goal:** Create 20 policies with hierarchical naming

```redis
// Your solution - follow the pattern
SET policy:auto:100001:status "active"
SET policy:auto:100001:premium "1200"
SET policy:auto:100002:status "pending"
SET policy:home:200001:status "active"
SET policy:life:300001:status "active"
// ...continue for 20 policies
```

**Verify in Browser:** Search for `policy:*` and see hierarchical grouping

---

### Exercise 2: Quote System

**Goal:** Build a quote expiration system

```redis
// 1. Create 10 quotes with 24-hour expiration
SETEX quote:Q001 86400 '{"type":"auto","premium":"1200"}'
SETEX quote:Q002 86400 '{"type":"home","premium":"850"}'
// ...create 8 more

// 2. Check TTL for each quote
TTL quote:Q001
TTL quote:Q002
// ...check all

// 3. Extend 3 quotes by 12 hours (43200 seconds)
EXPIRE quote:Q001 43200
EXPIRE quote:Q002 43200
EXPIRE quote:Q003 43200

// 4. Create test quote with 10-second expiration
SETEX quote:TEST 10 '{"type":"test"}'
// Wait and check
EXISTS quote:TEST
```

**Challenge:** Watch the test quote disappear in Browser tab!

---

### Exercise 3: Session Management

**Goal:** Implement session handling

```redis
// 1. Create sessions for 5 users (30-minute TTL = 1800 seconds)
SETEX session:user:alice 1800 '{"userId":"alice"}'
SETEX session:user:bob 1800 '{"userId":"bob"}'
SETEX session:user:charlie 1800 '{"userId":"charlie"}'
SETEX session:user:diana 1800 '{"userId":"diana"}'
SETEX session:user:eve 1800 '{"userId":"eve"}'

// 2. Renew 2 sessions (simulate user activity)
EXPIRE session:user:alice 1800
EXPIRE session:user:bob 1800

// 3. Check remaining TTL for all
TTL session:user:alice
TTL session:user:bob
TTL session:user:charlie
TTL session:user:diana
TTL session:user:eve

// 4. Count active sessions
KEYS session:*
```

**Verify in Browser:** Compare TTLs - alice and bob should have longer TTL!

---

### Exercise 4: Memory Monitoring

**Goal:** Monitor memory usage with Redis Insight

```redis
// 1. Create keys with various TTLs
SETEX temp:1min:001 60 "expires in 1 minute"
SETEX temp:1min:002 60 "expires in 1 minute"
SETEX temp:5min:001 300 "expires in 5 minutes"
SETEX temp:5min:002 300 "expires in 5 minutes"
SETEX temp:10min:001 600 "expires in 10 minutes"
// Create 95 more with varying TTLs

// 2. Check memory usage
INFO memory

// 3. Wait 1-2 minutes, then check again
INFO memory

// 4. Count remaining keys
DBSIZE
```

**In Redis Insight:**
1. Go to **Analysis** tab
2. View memory usage by key pattern
3. Watch total memory decrease as keys expire!

---

## 📋 Key Redis Commands Reference

**Run these in Redis Insight Workbench:**

### Set with Expiration
```redis
SETEX key seconds value           // Set with TTL (Best practice!)
PSETEX key milliseconds value     // Set with TTL in milliseconds
```

### Add Expiration to Existing Key
```redis
EXPIRE key seconds                 // Add or update TTL
PEXPIRE key milliseconds          // Add TTL in milliseconds
EXPIREAT key timestamp            // Expire at specific Unix timestamp
```

### Check Expiration
```redis
TTL key                           // Check TTL in seconds
PTTL key                          // Check TTL in milliseconds
```

**TTL Return Values:**
- `-2` = Key doesn't exist
- `-1` = Key exists but no TTL (permanent)
- `positive number` = Seconds remaining

### Remove Expiration
```redis
PERSIST key                       // Make key permanent (remove TTL)
```

### Key Operations
```redis
KEYS pattern                      // Find keys by pattern (use with caution!)
SCAN cursor MATCH pattern         // Iterate keys safely (production-ready)
EXISTS key [key ...]              // Check if key(s) exist
DEL key [key ...]                 // Delete key(s)
TYPE key                          // Get key data type
DBSIZE                            // Get total key count
```

💡 **Workbench Tip:** Use autocomplete (Tab key) to quickly enter these commands!

---

## 💡 Best Practices

### Key Naming

```redis
// ✅ GOOD EXAMPLES
SET customer:123:email "user@example.com"
SET policy:auto:456:status "active"
SET cache:user:789:profile "{...}"
SET session:user:alice "session-data"

// ❌ BAD EXAMPLES
SET "customer 123 email" "user@example.com"  // Spaces are problematic
SET CUSTOMER_123_EMAIL "user@example.com"    // Inconsistent casing
SET c123e "user@example.com"                 // Not descriptive
SET customer-123-email "user@example.com"    // Dashes harder to group in Browser
```

**Why Good Naming Matters:**
- Colon-separated keys group beautifully in Redis Insight Browser
- Consistent patterns make searching and filtering easy
- Hierarchical structure mirrors your domain model

### TTL Strategy

```redis
// ✅ GOOD: Set TTL when creating (atomic operation)
SETEX quote:Q001 86400 "data"

// ❌ BAD: Separate commands (potential race condition)
SET quote:Q001 "data"
EXPIRE quote:Q001 86400
// Risk: If app crashes between SET and EXPIRE, key never expires!
```

**Best Practice:** Always use SETEX or SET with EX option when you know the TTL upfront.

### Memory Management

```redis
// ✅ GOOD: Use TTL for all temporary data
SETEX cache:data 3600 "temporary"
SETEX session:user:bob 1800 "user-session"
SETEX quote:Q123 86400 "insurance-quote"

// ❌ BAD: Permanent keys for temporary data
SET cache:data "temporary"        // Never expires - memory leak!
SET session:user:bob "data"       // Manual cleanup required
```

**Memory Tip:** Use Redis Insight's **Analysis** tab to find keys without TTL that should have one!

---

## 🔍 Monitoring with Redis Insight

### Check Key Distribution in Browser Tab

1. Open **Browser** tab in Redis Insight
2. Use search filters for key patterns:
   - `policy:*` - See all policies
   - `customer:*` - See all customers
   - `session:*` - See all sessions
3. Key count appears at the top of the list
4. Sort by TTL to find keys expiring soon

### Memory Usage in Analysis Tab

1. Open **Analysis** tab in Redis Insight
2. Click **"New Report"**
3. View memory usage by:
   - Key patterns
   - Data types
   - TTL ranges
4. Identify memory hotspots and optimization opportunities

### Real-Time Monitoring in Workbench

**Run these commands:**

```redis
// Total memory usage
INFO memory

// Get specific memory metrics
INFO memory | grep used_memory_human

// Count all keys
DBSIZE

// Check expiration statistics
INFO stats
```

**Key Metrics to Watch:**
- `used_memory_human` - Total memory used
- `expired_keys` - Total keys expired
- `evicted_keys` - Keys removed due to memory limits

### TTL Monitoring Tips

**In Workbench:**
```redis
// Find keys with no TTL (should they have one?)
KEYS *

// Check TTL for specific patterns
TTL quote:Q001
TTL session:user:alice
```

**In Browser:**
- TTL column shows countdown for each key
- Click refresh to see updated values
- Keys turn red when TTL is very low
- Keys disappear when TTL reaches 0

💡 **No Scripts Needed!** Redis Insight provides all monitoring capabilities you need with its built-in Browser, Analysis, and Workbench tools.

---

## ⚠️ Important Notes

1. **KEYS Command Warning**
   - KEYS blocks Redis while scanning
   - Safe for learning in Workbench with small datasets
   - In production, use SCAN instead
   - Redis Insight Browser uses SCAN automatically - it's safe!

2. **TTL Precision**
   - Redis checks for expired keys lazily (on access) and periodically (background scan)
   - Keys may exist slightly past their TTL
   - Accessing an expired key triggers immediate deletion and returns null
   - Watch this behavior in Browser tab!

3. **Memory Considerations**
   - Expired keys consume memory until actually deleted
   - Use Redis Insight Analysis tab to monitor memory usage
   - Set appropriate TTLs for all temporary data

4. **Persistence**
   - RDB and AOF save unexpired TTLs correctly
   - When Redis restarts, keys resume expiring normally
   - Test by creating a key with 60-second TTL, checking in Browser, then restarting Redis

---

## ✅ Lab Completion Checklist

- [ ] Opened Redis Insight and connected to database
- [ ] Ran all commands in Workbench (not terminal)
- [ ] Created hierarchical key structures for policies, customers, claims
- [ ] Visualized key hierarchy in Browser tab
- [ ] Implemented quote system with 24-hour TTL
- [ ] Built session management with 30-minute TTL
- [ ] Used SETEX, EXPIRE, TTL, PERSIST commands
- [ ] Watched TTL countdown in Browser tab
- [ ] Monitored key expiration patterns using Browser and Analysis tabs
- [ ] Understood lazy expiration behavior
- [ ] Completed all 4 exercises

**Estimated time:** 50 minutes

---

## 🔍 Redis Insight Features Used in This Lab

| Feature | Purpose | When Used |
|---------|---------|-----------|
| **Workbench** | Execute all Redis commands | All parts and exercises |
| **Browser** | Visualize keys, watch TTL countdown | Key organization, TTL monitoring |
| **Analysis** | Memory usage analysis | Exercise 4, optimization |
| **TTL Column** | Real-time TTL countdown | Monitoring quote/session expiration |
| **Search Filter** | Find keys by pattern | Monitoring key distribution |

---

## 📚 Additional Resources

- **Redis Keys Documentation:** https://redis.io/docs/manual/keyspace/
- **Redis TTL Commands:** https://redis.io/commands/ttl/
- **Redis Insight Features:** https://redis.io/docs/stack/insight/
- **Key Naming Best Practices:** `docs/key-patterns.md`

---

## 💡 Key Takeaways

1. **Hierarchical key naming** makes data self-organizing in Redis Insight Browser
2. **SETEX is safer than SET + EXPIRE** - atomic operation prevents race conditions
3. **TTL is essential** for session management, caching, and temporary data
4. **Redis Insight Browser** provides visual TTL monitoring without scripts
5. **KEYS is learning-friendly** but use SCAN in production
6. **Automatic cleanup** via TTL prevents memory leaks and manual housekeeping
7. **Visual tools** make Redis more accessible than terminal-only approaches

---

## ⏭️ Next Steps

**Lab 5:** Monitoring Redis with Redis Insight's advanced features including Profiler, Analysis, and Slowlog.

Ready to continue? Open Lab 5's README.md!
