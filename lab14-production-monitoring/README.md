# Lab 14: Production Configuration & Monitoring - Quick Start Guide

> **📝 Note:** This lab now covers **both production configuration and monitoring**. Lab 13's hands-on configuration exercises (RDB, AOF, backups, security hardening) have been folded into **Part B** below so the 3-day schedule fits cleanly.

**Duration:** 65 minutes
**Focus:** Persistence configuration, security hardening, and real-time production monitoring

---

## 🚀 Quick Setup

```bash
# 1. Install dependencies
npm install

# 2. Start Redis (if not running)
redis-server --daemonize yes

# 3. Load sample data
npm run load-data

# 4. Start monitoring servers
npm start
```

## 📊 Access Points

After starting the servers:

- **Health Check API:** http://localhost:3000/health
- **Monitoring Dashboard:** http://localhost:4000
- **Real-time Metrics:** http://localhost:4000/api/metrics/realtime

---

## Part B: Production Configuration (from Lab 13)

> Complete this section **first** (approximately 15–20 minutes). The monitoring dashboard in Part C depends on having persistence and security configured so the metrics you collect reflect a production-like setup.

Open **Redis Insight → Workbench** and run all commands below there (no terminal needed).

### B.1 — RDB Snapshot Configuration

RDB creates point-in-time snapshots of your dataset — ideal for backups and disaster recovery.

```redis
// Configure automatic snapshot intervals
CONFIG SET save "900 1 300 10 60 1000"

// Enable compression and checksums
CONFIG SET rdbcompression yes
CONFIG SET rdbchecksum yes

// Verify
CONFIG GET save
```

**Interval meaning:**
- `900 1` — save if 1+ keys changed in 15 minutes
- `300 10` — save if 10+ keys changed in 5 minutes
- `60 1000` — save if 1000+ keys changed in 1 minute

Force a manual snapshot and inspect status:

```redis
BGSAVE
LASTSAVE
INFO persistence
```

Look for `rdb_last_save_time`, `rdb_changes_since_last_save`, and `rdb_last_bgsave_status`.

---

### B.2 — AOF (Append-Only File) Setup

AOF logs every write operation — higher durability than RDB alone.

```redis
// Enable AOF
CONFIG SET appendonly yes

// everysec = recommended balance of durability and performance
CONFIG SET appendfsync everysec

// Auto-rewrite thresholds (compact when file doubles, min 64 MB)
CONFIG SET auto-aof-rewrite-percentage 100
CONFIG SET auto-aof-rewrite-min-size 67108864

// Verify
CONFIG GET appendonly
CONFIG GET appendfsync
```

| Sync policy | Durability | Performance | Use case |
|-------------|------------|-------------|----------|
| `always`    | Highest    | Slowest     | Zero-loss financial data |
| `everysec`  | High (≤1s) | Good        | **Recommended default** |
| `no`        | Lowest     | Fastest     | Cache-only workloads |

Generate some writes, then force a rewrite:

```redis
SET policy:P123 "Auto Policy"
HSET customer:C789 name "John Smith" policies 3

BGREWRITEAOF
INFO persistence
```

💡 **Production tip:** Run RDB + AOF together — RDB for fast restart, AOF for minimal data loss.

---

### B.3 — Backup / Restore Workflow

**Manual backup steps:**

```redis
// 1. Trigger a background snapshot
BGSAVE

// 2. Wait until complete
INFO persistence        // watch rdb_bgsave_in_progress → 0

// 3. Find the RDB file
CONFIG GET dir
CONFIG GET dbfilename
```

Once `BGSAVE` completes, copy the resulting `dump.rdb` file from the Redis data directory to your backup location (S3, another host, offsite storage, etc.).

**Restore workflow:**
1. Stop Redis.
2. Replace `dump.rdb` in the data directory with your backup.
3. Start Redis — it will load the snapshot on boot.
4. Verify with `DBSIZE` and a few known keys.

**Best practices:**
- **Frequency:** Daily for production
- **Retention:** 7 daily / 4 weekly / 12 monthly
- **Test restores regularly** — an untested backup is not a backup
- **Offsite copies** outside primary infrastructure

---

### B.4 — Security Hardening Basics

Minimum viable security for a production Redis instance:

```redis
// 1. Require a password for all clients
CONFIG SET requirepass "ChangeMe_StrongPassword!2026"

// From now on clients must AUTH before issuing commands:
AUTH ChangeMe_StrongPassword!2026

// 2. Rename (or disable) dangerous commands
//    Renaming to "" effectively disables a command.
//    NOTE: rename-command only takes effect in redis.conf (not via CONFIG SET on a
//    running instance) — add these lines to your redis.conf and restart:
//
//    rename-command FLUSHALL ""
//    rename-command FLUSHDB  ""
//    rename-command CONFIG   "CONFIG_a7x91"
//    rename-command KEYS     ""

// 3. Bind Redis to specific interfaces (redis.conf)
//    bind 127.0.0.1 10.0.0.5       # loopback + private network only
//    protected-mode yes
//    port 6379
```

**Why each matters:**
- **`requirepass`** — prevents unauthenticated access if the port is ever exposed.
- **`rename-command`** — neutralizes destructive commands (`FLUSHALL`, `KEYS`, `CONFIG`) in case of credential leak.
- **`bind` + `protected-mode`** — ensures Redis never listens on a public interface by accident.

Verify password is active:

```redis
CONFIG GET requirepass
```

💡 **Production tip:** For Redis 6+, prefer **ACLs** (`ACL SETUSER ...`) over a single shared `requirepass`.

---

### B.5 — Configuration Verification Checklist

```redis
CONFIG GET save
CONFIG GET appendonly
CONFIG GET appendfsync
CONFIG GET maxmemory-policy
CONFIG GET requirepass
INFO persistence
```

- [ ] RDB save intervals configured
- [ ] AOF enabled with `everysec`
- [ ] Manual `BGSAVE` / `BGREWRITEAOF` succeed
- [ ] `requirepass` set and `AUTH` required
- [ ] Dangerous commands renamed in `redis.conf` (documented for deploy)
- [ ] `bind` restricted to trusted interfaces

---

## Part C: Production Monitoring

With persistence and security in place, now build the monitoring layer.

### 🧪 Test the Running System

```bash
# Health endpoint
curl http://localhost:3000/health

# Metrics endpoint
curl http://localhost:3000/metrics

# Redis INFO passthrough
curl http://localhost:3000/redis/info
```

### 📁 Project Structure

```
lab14-production-monitoring/
├── src/
│   └── main.js              # Main application with health checks
├── dashboards/
│   └── index.html           # Monitoring dashboard UI
├── scripts/
│   ├── setup.sh             # Setup script
│   ├── load-production-monitoring-data.js  # Data loader
│   └── test-monitoring.sh  # Test script
├── logs/                    # Application logs
├── package.json            # Dependencies
└── README.md              # This file
```

### 🎯 Key Features

1. **Health Checks**
   - Redis connectivity monitoring
   - Memory usage tracking
   - Performance metrics collection

2. **Real-time Dashboard**
   - Live metrics display
   - Auto-refresh every 30 seconds
   - Visual status indicators

3. **Monitoring Metrics**
   - Connected clients
   - Memory usage
   - Operations per second
   - Cache hit/miss ratio
   - Command statistics

---

## 🛠 Troubleshooting

### Redis Connection Issues
```bash
# Check if Redis is running
redis-cli ping

# If not, start Redis
redis-server --daemonize yes
```

### Port Already in Use
```bash
# Check what's using port 3000
lsof -i :3000

# Check what's using port 4000
lsof -i :4000

# Kill the process if needed
kill -9 <PID>
```

### Missing Dependencies
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

---

## 📝 Lab Objectives

By completing this lab, you will:
- ✅ Configure RDB + AOF persistence for production
- ✅ Execute a manual backup and understand restore workflow
- ✅ Apply security hardening (`requirepass`, `rename-command`, `bind`)
- ✅ Set up production monitoring for Redis
- ✅ Create health check endpoints
- ✅ Build a real-time monitoring dashboard
- ✅ Collect and analyze performance metrics

## 🔍 What to Look For

When the system is running correctly:

1. `INFO persistence` shows recent successful RDB save and AOF status `ok`
2. `AUTH` is required before commands succeed
3. Health endpoint returns JSON with status "healthy"
4. Dashboard shows real-time metrics
5. Memory usage and client connections are visible
6. No errors in the console logs

## Part D: Runtime Operations Deep-Dive (20 min)

Part B (persistence) and Part C (monitoring) give you the *configuration* story. Part D is the **runtime operator** story — the commands a production engineer runs during backups, incidents, and access-control changes. Every command is safe to run against a non-production instance and is reversed at the end of the section.

### D.1 — `BGSAVE` — Manual RDB Snapshot

`BGSAVE` asks Redis to fork and write a point-in-time `dump.rdb` without blocking clients. It's the "press the backup button" command you use before a risky deploy.

**Insurance use case:** Before rolling out a schema-changing release to the claims-cache cluster, trigger a `BGSAVE` so rollback is trivial.

```redis
BGSAVE
// Expected: "Background saving started"

// Poll until finished
INFO persistence
// Look for: rdb_bgsave_in_progress:0
```

---

### D.2 — `BGREWRITEAOF` — Manual AOF Rewrite

Over time the AOF file grows; `BGREWRITEAOF` compacts it by rewriting the minimal set of commands that reproduces the current dataset. Safe to run live.

**Insurance use case:** Weekly maintenance window includes a forced AOF rewrite to prevent slow disk fills on the underwriting-cache host.

```redis
BGREWRITEAOF
// Expected: "Background append only file rewriting started"

// Verify status
INFO persistence
// Look for: aof_rewrite_in_progress:0  and  aof_last_bgrewrite_status:ok
```

---

### D.3 — `LASTSAVE` — Verify the Last Successful Snapshot

Returns the Unix timestamp of the last successful `BGSAVE`. Your monitoring alert for "stale RDB" is built on this.

**Insurance use case:** Nagios alert fires if `LASTSAVE` is more than 24 hours old.

```redis
LASTSAVE
// Expected: a Unix timestamp integer

// Convert to human-readable (shell):
date -r $(redis-cli LASTSAVE) 2>/dev/null || date -d @$(redis-cli LASTSAVE)
```

---

### D.4 — `# Persistence` Block from `INFO persistence`

The single most useful health snapshot for persistence. Memorize these fields:

```redis
INFO persistence
```

Key fields to check:

| Field                         | What it means                                         |
|-------------------------------|------------------------------------------------------|
| `rdb_last_save_time`          | Unix time of last successful RDB save                 |
| `rdb_changes_since_last_save` | Writes accumulated since last save (backup pressure)  |
| `rdb_last_bgsave_status`      | `ok` / `err`                                          |
| `aof_enabled`                 | `1` if AOF is on                                      |
| `aof_last_rewrite_time_sec`   | Duration of last AOF rewrite                          |
| `aof_last_bgrewrite_status`   | `ok` / `err`                                          |

**Insurance use case:** Post-incident review — confirm that no writes were lost by checking `rdb_changes_since_last_save` and `aof_last_write_status`.

---

### D.5 — `AUTH` Workflow — `CONFIG SET requirepass` → `AUTH` → Unset

> ⚠️ **Important:** When practicing on a shared instance, always unset `requirepass` at the end of the exercise so other exercises keep working. The flow below does that.

**Insurance use case:** Rotating the shared Redis password during an incident where a credential may have leaked.

```redis
// 1. Set a password
CONFIG SET requirepass "RotatePass_2026!"

// From this point any NEW connection must AUTH before running commands
// In a new redis-cli:
//   AUTH RotatePass_2026!    → OK
//   PING                     → PONG
// Without AUTH:
//   PING                     → (error) NOAUTH Authentication required.

// 3. Unset the password so the rest of the lab keeps working
AUTH RotatePass_2026!
CONFIG SET requirepass ""
```

---

### D.6 — `ACL SETUSER` — Create a Read-Only Monitoring User

For Redis 6+, prefer ACLs over a single shared password. Monitoring/observability tools should get their own *least-privilege* user.

**Insurance use case:** The `prometheus_exporter` service running next to every Redis node logs in as user `monitor` who can only call `INFO`, `PING`, and `CLIENT LIST` — and nothing else.

```redis
// Create a read-only monitoring user
ACL SETUSER monitor on >MonPass_2026! ~* +INFO +PING +CLIENT|LIST

// Verify the user exists and has the right permissions
ACL GETUSER monitor
ACL LIST

// Clean up after the exercise
ACL DELUSER monitor
```

---

### D.7 — `CONFIG SET` Round-Trip for Persistence & Security Knobs

All the major persistence / security settings can be changed at runtime with `CONFIG SET`. A safe practice is to **GET → SET → GET → RESTORE** so you never leave the instance in an unexpected state.

**Insurance use case:** During a write-heavy import job, temporarily relax `appendfsync` to `no`, then restore to `everysec` after the job.

```redis
// Capture current values
CONFIG GET save
CONFIG GET appendonly
CONFIG GET appendfsync
CONFIG GET rdbcompression
CONFIG GET requirepass

// Apply temporary values
CONFIG SET save "900 1 300 10"
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec
CONFIG SET rdbcompression yes

// Verify
CONFIG GET appendfsync
// Expected: 1) "appendfsync"  2) "everysec"

// Restore to defaults if needed
CONFIG SET appendfsync everysec
CONFIG SET requirepass ""
```

---

### Part D Summary Table

| Command                 | Purpose                                  | Insurance example                         |
|-------------------------|------------------------------------------|------------------------------------------|
| `BGSAVE`                | Manual RDB snapshot                      | Pre-deploy backup                         |
| `BGREWRITEAOF`          | Compact AOF file                         | Weekly maintenance window                 |
| `LASTSAVE`              | Last successful RDB Unix timestamp       | Stale-backup monitoring alert             |
| `INFO persistence`      | Full persistence health block            | Post-incident review                      |
| `CONFIG SET requirepass`| Rotate Redis password                    | Incident response — credential rotation   |
| `ACL SETUSER`           | Least-privilege named user               | `monitor` user for Prometheus exporter    |
| `CONFIG SET` round-trip | Runtime tuning                           | Relax fsync during bulk import            |

---

## 📚 Additional Resources

- [Redis persistence](https://redis.io/docs/management/persistence/)
- [Redis security](https://redis.io/docs/management/security/)
- [Redis INFO command](https://redis.io/commands/info/)
- [Redis monitoring best practices](https://redis.io/docs/management/optimization/monitoring/)
- [Express.js documentation](https://expressjs.com/)
