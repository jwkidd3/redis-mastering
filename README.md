# Redis Mastering Course

A focused 3-day intensive Redis training course focused on insurance industry applications, covering Redis fundamentals through advanced production deployment patterns.

**Schedule:** 3 days, 9:00 AM – 4:00 PM (7 hours/day with 1-hour lunch + two 15-min breaks)
**Teaching time:** 5.5 hours/day × 3 = 16.5 hours of instruction and labs
**Format:** 30% theory, 70% hands-on labs
**Industry Focus:** Insurance applications (Claims, Policies, Customer Management)
**Platform:** Docker + JavaScript/Node.js + Redis Insight + Visual Studio Code

## Table of Contents

- [Quick Start](#quick-start)
- [Course Structure](#course-structure)
- [Detailed Course Flow](#detailed-course-flow)
- [Prerequisites & Installation](#prerequisites--installation)
- [Platform Support](#platform-support)
- [Running Labs](#running-labs)
- [Lab Quick Reference](#lab-quick-reference)
- [Testing](#testing)
- [Key Concepts](#key-concepts-covered)
- [Troubleshooting](#troubleshooting)
- [Course Completion](#course-completion-checklist)

---

## Quick Start

### 1. Start Redis Server

**Windows:**
```cmd
cd scripts
start-redis.bat
```

**Mac/Linux:**
```bash
cd scripts
bash start-redis.sh
```

📖 **See `scripts/README.md` for detailed Redis server management**

### 2. Install Redis CLI (Optional)

Redis Insight includes a built-in CLI, but you can also install the terminal redis-cli:

**Windows:**
```cmd
cd scripts
install-redis-cli.bat
```

**Mac/Linux:**
```bash
cd scripts
bash install-redis-cli.sh
```

### 3. Connect Redis Insight

1. Open Redis Insight (desktop app or http://localhost:8001)
2. Click **"Add Database"**
3. Enter connection details:
   - Host: `localhost`
   - Port: `6379`
   - Name: `Redis Course`
4. Click **"Test Connection"** → **"Add Database"**

### 4. Install Course Dependencies

```bash
# In course root directory
npm install
```

### 5. Start Your First Lab

1. Open Redis Insight
2. Click your database connection
3. Go to **"Workbench"** tab
4. Open `lab1-redis-cli-basics/README.md`
5. Follow the instructions and run all commands in Workbench

💡 **All labs are designed to be run in Redis Insight Workbench**

---

## Course Structure

### Day 1: Redis CLI & Core Operations (5.5 hrs teaching)
**Labs 1-5:** Foundation and CLI mastery — **NO JavaScript required**

| Lab | Title | Key Topics |
|-----|-------|------------|
| **Lab 1** | Redis Environment & CLI Basics | Docker setup, CLI navigation, Redis Insight |
| **Lab 2** | RESP Protocol Deep Dive | Protocol monitoring, raw format analysis |
| **Lab 3** | String Operations & Data Management | String ops, INCR/DECR, MSET/MGET, performance |
| **Lab 4** | Key Management & TTL Strategies | Key naming, TTL strategies, SCAN, memory optimization |
| **Lab 5** | Advanced CLI & Production Monitoring | Monitoring, benchmarking, slow queries, alerts |

### Day 2: JavaScript Integration (5.5 hrs teaching)
**Labs 6-9:** Application development patterns. **Lab 10 is optional / take-home.**

| Lab | Title | Key Topics |
|-----|-------|------------|
| **Lab 6** | JavaScript Redis Client Setup | Node.js client, connection pooling, async/await |
| **Lab 7** | Customer Profiles with Hashes | Hash operations, nested structures, customer management |
| **Lab 8** | Claims Event Sourcing with Streams | Event sourcing, producer/consumer groups, audit trails |
| **Lab 9** | Insurance Analytics with Sets & Sorted Sets | Segmentation, leaderboards, rankings, analytics |
| **Lab 10** *(optional)* | Advanced Caching Patterns | Cache-aside, write-through, event-driven invalidation |

### Day 3: Production & Advanced Topics (5.5 hrs teaching)
**Labs 11, 12, 14, 15:** Enterprise deployment. **Lab 13's config exercises are folded into Lab 14.**

| Lab | Title | Key Topics |
|-----|-------|------------|
| **Lab 11** | Session Management & Security | JWT tokens, RBAC, session cleanup, security monitoring |
| **Lab 12** | Rate Limiting & API Protection | Token bucket, sliding window, DDoS protection |
| **Lab 14** | Production Configuration & Monitoring | RDB/AOF, backups, metrics collection, alerting, dashboards |
| **Lab 15** | Redis Cluster & High Availability | 6-node cluster, sharding, failover, replication |

---

## Detailed Course Flow

Each day runs 9:00 AM – 4:00 PM with a 1-hour lunch and two 15-minute breaks, leaving **5.5 hours (330 min) of teaching/lab time per day**.

### Day 1: Redis CLI & Core Operations (330 min — 27% pres / 73% lab)

**Morning (9:00 – 12:05)**

| Time | Item | File / Directory |
|------|------|------------------|
| 9:00 – 9:30 (30 min) | **Presentation 1: Introduction to Redis** — Redis overview, architecture, use cases, installation, CLI basics | `presentations/content1_presentation.html` |
| 9:30 – 10:15 (45 min) | **Lab 1: Redis Environment & CLI Basics** — Docker setup, CLI navigation, Redis Insight | `lab1-redis-cli-basics/` |
| 10:15 – 10:30 | **Break** (15 min) | |
| 10:30 – 11:00 (30 min) | **Presentation 2: RESP Protocol & CLI Operations** — RESP protocol, CLI debugging, hash basics | `presentations/content2_presentation.html` |
| 11:00 – 11:50 (50 min) | **Lab 2: RESP Protocol Deep Dive** — Protocol monitoring, raw format analysis, CLIENT/MONITOR/SLOWLOG/CONFIG | `lab2-resp-protocol/` |
| 11:50 – 12:05 | Buffer / Q&A | |

**Lunch (12:05 – 1:05)**

**Afternoon (1:05 – 4:00)**

| Time | Item | File / Directory |
|------|------|------------------|
| 1:05 – 1:35 (30 min) | **Presentation 3: String Operations & Key Management** — String ops, TTL, SETEX/PSETEX | `presentations/content3_presentation.html` |
| 1:35 – 2:25 (50 min) | **Lab 3: String Operations & Data Management** — INCR/DECR, MSET/MGET, SCAN, performance | `lab3-data-operations-strings/` |
| 2:25 – 2:40 | **Break** (15 min) | |
| 2:40 – 3:30 (50 min) | **Lab 4: Key Management & TTL Strategies** — Key naming, EXPIREAT/PEXPIRE/PTTL/PSETEX, SCAN, RENAME | `lab4-key-management-ttl/` |
| 3:30 – 4:00 (30 min) | **Lab 5: Advanced CLI & Production Monitoring** — MONITOR, SLOWLOG, CLIENT KILL, CONFIG SET | `lab5-advanced-cli-monitoring/` |

---

### Day 2: JavaScript Integration (330 min — 29% pres / 71% lab)

**Morning (9:00 – 12:25)**

| Time | Item | File / Directory |
|------|------|------------------|
| 9:00 – 9:30 (30 min) | **Presentation 4: JavaScript Redis Client Fundamentals** — Node.js client, connection pooling, async/await | `presentations/content4_presentation.html` |
| 9:30 – 10:25 (55 min) | **Lab 6: JavaScript Redis Client Setup** — Client, pooling, async patterns, error handling | `lab6-javascript-redis-client/` |
| 10:25 – 10:40 | **Break** (15 min) | |
| 10:40 – 11:15 (35 min) | **Presentation 5: Hash, List, Set & Sorted Set Data Structures** — Comprehensive data structures module preparing for Labs 7 & 9 | `presentations/content5_presentation.html` |
| 11:15 – 12:05 (50 min) | **Lab 7: Customer Profiles with Hashes** — Hash ops, nested structures | `lab7-customer-policy-hashes/` |
| 12:05 – 12:25 | Buffer / Q&A | |

**Lunch (12:25 – 1:25)**

**Afternoon (1:25 – 4:00)**

| Time | Item | File / Directory |
|------|------|------------------|
| 1:25 – 1:55 (30 min) | **Presentation 6: Streams, Event Sourcing & Caching Patterns** — XADD/XREAD, consumer groups, cache-aside, write-through | `presentations/content6_presentation.html` |
| 1:55 – 3:10 (75 min) | **Lab 8: Claims Event Sourcing with Streams** — Producer/consumer, XACK, XPENDING, XINFO, audit trails | `lab8-claims-event-sourcing/` |
| 3:10 – 3:25 | **Break** (15 min) | |
| 3:25 – 4:00 (35 min) | **Lab 9: Insurance Analytics with Sets & Sorted Sets** — Segmentation, leaderboards, SREM/ZREM/ZREVRANK | `lab9-sets-analytics/` |

> **Lab 10 (Advanced Caching Patterns)** is optional / take-home. The core caching material is covered in Presentation 6.

---

### Day 3: Production & Advanced Topics (330 min — 30% pres / 70% lab)

**Morning (9:00 – 12:30)**

| Time | Item | File / Directory |
|------|------|------------------|
| 9:00 – 9:35 (35 min) | **Presentation 7: Security, Sessions & Rate Limiting** — Auth, ACL, TLS, JWT/RBAC, token bucket, sliding window | `presentations/content7_presentation.html` |
| 9:35 – 10:30 (55 min) | **Lab 11: Session Management & Security** — JWT, RBAC, EVAL/Lua, LPUSH/LRANGE audit logs | `lab11-session-management/` |
| 10:30 – 10:45 | **Break** (15 min) | |
| 10:45 – 11:40 (55 min) | **Lab 12: Rate Limiting & API Protection** — Token bucket, sliding window, DDoS | `lab12-rate-limiting-api-protection/` |
| 11:40 – 12:15 (35 min) | **Presentation 8 + 9: Persistence, Configuration & Monitoring** — RDB/AOF, backups, metrics, alerting | `presentations/content8_presentation.html` + `content9_presentation.html` |
| 12:15 – 12:30 | Buffer / Q&A | |

**Lunch (12:30 – 1:30)**

**Afternoon (1:30 – 4:00)**

| Time | Item | File / Directory |
|------|------|------------------|
| 1:30 – 2:35 (65 min) | **Lab 14: Production Configuration & Monitoring** — BGSAVE, BGREWRITEAOF, AUTH, ACL SETUSER, health checks *(includes former Lab 13 config exercises)* | `lab14-production-monitoring/` |
| 2:35 – 3:05 (30 min) | **Presentation 10: Redis Cluster & High Availability** — Clustering fundamentals, sharding, failover | `presentations/content15_presentation.html` |
| 3:05 – 3:20 | **Break** (15 min) | |
| 3:20 – 4:00 (55 min) | **Lab 15: Redis Cluster & High Availability** — 6-node cluster, CLUSTER SLOTS/KEYSLOT, failover testing | `lab15-redis-cluster-ha/` |

---

## Course Timing Summary

| Day | Presentations | Labs | Teaching Time | Lab/Pres Ratio |
|-----|---------------|------|---------------|----------------|
| **Day 1** | 3 (90 min) | 5 (225 min + 15 buffer) | 330 min | 73 / 27 |
| **Day 2** | 3 (95 min) | 4 core + 1 optional (215 min + 20 buffer) | 330 min | 71 / 29 |
| **Day 3** | 3 (100 min) | 4 (215 min + 15 buffer) | 330 min | 70 / 30 |
| **Total** | **10 presentations (285 min)** | **13 core labs (705 min incl. buffer)** | **16.5 hours** | **~71 / 29** |

**Note:** Each day runs 9:00 AM – 4:00 PM with a 1-hour lunch and two 15-minute breaks. Labs occupy ~70% of teaching time; presentations ~30%.

---

## Prerequisites & Installation

### Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| **Docker Desktop** | Latest | Redis server and containerized labs |
| **Node.js** | v18.0+ | JavaScript labs (Day 2-3) |
| **Redis CLI** | Latest | Command-line interface |
| **Terminal** | - | Bash (Mac/Linux) or PowerShell (Windows) |

### Installation Steps

#### 1. Docker Desktop
- **Download:** https://www.docker.com/products/docker-desktop/
- **Windows:** Requires Windows 10/11 Pro/Enterprise with WSL 2
- **Mac:** macOS 10.15+ (Catalina or later)
- **Linux:** Ubuntu 18.04+, CentOS 7+, or equivalent

#### 2. Node.js (LTS Version)
- **Download:** https://nodejs.org/
- **Verify:** `node --version` (should be 18.0+)
- **Includes:** npm (Node Package Manager)

#### 3. Redis CLI (Optional)

**Redis Insight includes a built-in CLI** - separate installation is optional.

If you prefer terminal redis-cli, use the automated scripts:

**Windows:**
```cmd
cd scripts
install-redis-cli.bat
```

**Mac/Linux:**
```bash
cd scripts
bash install-redis-cli.sh
```

📖 **See `scripts/README.md` for detailed installation guides and manual installation options**

#### 4. Redis Insight (Required)

**Redis Insight** is the primary tool for this course alongside your terminal:

- **Download:** https://redis.io/insight/
- **Purpose:** Visual Redis management, command execution, monitoring
- **Required for:** All 15 labs include Redis Insight exercises

**Why Redis Insight:**
- **Workbench:** Execute Redis commands with autocomplete and formatting
- **Browser:** Visual key explorer with tree view
- **Profiler:** Real-time command monitoring (better than MONITOR)
- **Memory Analyzer:** Visual memory usage analysis

💡 **All lab instructions are in each lab's README.md**

#### 5. Optional but Recommended
- **VS Code** - Code editor: https://code.visualstudio.com/
- **Windows Terminal** - Modern terminal (Windows only)

### System Requirements

- **RAM:** 8GB minimum (16GB recommended)
- **Storage:** 10GB free space
- **CPU:** Dual-core processor
- **Network:** Internet connection for package downloads

### Verification Commands

```bash
# Check Node.js and npm
node --version
npm --version

# Check Docker
docker --version
docker run hello-world

# Test Redis connection in Redis Insight Workbench
# Open Redis Insight → Workbench → Run: PING

# Check VS Code (optional)
code --version
```

---

## Platform Support

The course supports both Mac/Linux and Windows. Most labs use Node.js scripts (`npm` commands) that run unchanged on either platform. A few labs — notably **Lab 15 (Redis Cluster)** — include platform-specific shell scripts.

### Script Organization (where present)

```
lab{n}/
├── scripts/
│   ├── mac/          # Bash scripts (.sh) for Mac/Linux
│   └── win/          # PowerShell scripts (.ps1) for Windows
```

### Running platform-specific scripts

**Mac/Linux:**
```bash
cd lab15-redis-cluster-ha
bash scripts/mac/init-cluster.sh
```

**Windows (PowerShell):**
```powershell
cd lab15-redis-cluster-ha
.\scripts\win\init-cluster.ps1
```

**Windows (Git Bash or WSL):** the Mac scripts run directly.

### Windows-Specific Setup

#### Enable PowerShell Script Execution (One-Time Setup)

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy
```

#### Windows Environment Variables

```powershell
# Set for current session
$env:REDIS_HOST = "localhost"
$env:REDIS_PORT = "6379"

# Set permanently
[System.Environment]::SetEnvironmentVariable('REDIS_HOST', 'localhost', 'User')
```

#### Windows Troubleshooting

**Docker Desktop Not Starting:**
```powershell
# Ensure WSL 2 is enabled
wsl --install
wsl --set-default-version 2
```

**Port 6379 Already in Use:**
```powershell
# Stop existing Redis
cd scripts
stop-redis.bat

# Find process using port
netstat -ano | findstr :6379

# Use different port if needed
docker run -d -p 6380:6379 --name redis-alt redis/redis-stack:latest
$env:REDIS_PORT = "6380"
```

**Redis CLI Not Found (Optional):**

Redis Insight includes a built-in CLI in Workbench. If you still want terminal redis-cli:

```cmd
cd scripts
install-redis-cli.bat
```

---

## Running Labs

Each lab is self-contained with its own README and instructions.

### General Pattern

```bash
# 1. Navigate to lab directory
cd lab{n}-{name}

# 2. Read the lab instructions
cat README.md

# 3. For JavaScript labs (Day 2-3), install dependencies
npm install

# 4. Run any platform-specific setup scripts the lab provides (see lab README)

# 5. Follow lab-specific instructions in README.md
```

---

## Lab Quick Reference

### Day 1: CLI Labs (No JavaScript)

**All Day 1 labs use Redis Insight Workbench:**

1. Start Redis server (see Quick Start)
2. Open Redis Insight → Connect to database
3. Go to Workbench tab
4. Open each lab's README.md and follow instructions

```bash
# Lab 1: Redis Basics
cd lab1-redis-cli-basics
# Follow README.md in Redis Insight Workbench

# Lab 2: RESP Protocol
cd lab2-resp-protocol
# Follow README.md - use Profiler instead of MONITOR

# Lab 3: String Operations
cd lab3-data-operations-strings
# Follow README.md - all commands in Workbench

# Lab 4: Key Management
cd lab4-key-management-ttl
# Follow README.md - practice SCAN and TTL commands

# Lab 5: Advanced CLI
cd lab5-advanced-cli-monitoring
# Follow README.md - use Profiler and Memory Analyzer
```

### Day 2: JavaScript Labs

```bash
# Lab 6: JavaScript Client Setup
cd lab6-javascript-redis-client
npm install
node test-connection.js

# Lab 7: Hashes (Customer Profiles)
cd lab7-customer-policy-hashes
npm install
node src/customer-service.js

# Lab 8: Streams (Claims Event Sourcing) ⭐
cd lab8-claims-event-sourcing
npm install
npm run validate              # Validate setup
npm run load-data             # Load sample claims
npm run producer              # Submit claims (Terminal 1)
npm run consumer              # Process events (Terminal 2)
npm run analytics             # View analytics (Terminal 3)

# Lab 9: Sets & Sorted Sets (Analytics)
cd lab9-sets-analytics
npm install
npm run segments              # Customer segmentation
npm run leaderboard           # Agent rankings

# Lab 10 (optional / take-home): Caching Patterns
cd lab10-advanced-caching-patterns
npm install
node test-cache-aside.js
```

### Day 3: Production Labs

```bash
# Lab 11: Session Management
cd lab11-session-management
npm install
node test-session.js

# Lab 12: Rate Limiting
cd lab12-rate-limiting-api-protection
npm install
node src/server.js            # Start API server
node examples/test-rate-limits.js

# Lab 14: Production Configuration & Monitoring
# (Includes the former Lab 13 RDB/AOF config exercises)
cd lab14-production-monitoring
npm install
node health-check.js

# Lab 15: Redis Cluster ⭐
cd lab15-redis-cluster-ha
npm install
docker-compose up -d
bash scripts/mac/init-cluster.sh       # Mac/Linux
.\scripts\win\init-cluster.ps1         # Windows
npm run test-sharding
npm run load-data
npm run monitor
```

### Key Lab Highlights

**🌟 Lab 8: Claims Event Sourcing** - Modern event-driven architecture
- Producer/Consumer pattern with Redis Streams
- Real-time event processing
- Immutable audit trails for compliance
- Analytics dashboard

**🌟 Lab 15: Redis Cluster** - Production-grade high availability
- 6-node Redis Cluster (3 masters, 3 replicas)
- Automatic sharding across 16,384 slots
- Automatic failover and recovery
- Cluster management tools

---

## Testing

### Run All Tests

```bash
# From root directory
npm test
```

### Run Tests by Day

```bash
npm run test:day1  # CLI & Core Operations (Labs 1-5)
npm run test:day2  # JavaScript Integration (Labs 6-10)
npm run test:day3  # Production & Advanced (Labs 11-15)
```

### Current Test Status

- **Default run (13 core labs):** 132 tests — **100% passing ✅**
  - Day 1: 38/38 ✅ (Labs 1–5)
  - Day 2: 48/48 ✅ (Labs 6–9)
  - Day 3: 46/46 ✅ (Labs 11, 12, 14, 15)
- **Optional labs (run individually):**
  - `npm run test:lab -- --lab=10` — Lab 10 (optional/take-home): 12 tests, 100% ✅
  - `npm run test:lab -- --lab=13` — Lab 13 (legacy, content folded into Lab 14): 8 tests, 100% ✅

Every Redis operation taught in the course is covered by at least one test, including admin/ops commands (MONITOR, SLOWLOG, CLIENT, CONFIG), stream lifecycle (XACK, XPENDING, XINFO), Lua scripting (EVAL), persistence (BGSAVE, BGREWRITEAOF), and security (AUTH, ACL SETUSER).

---

## Key Concepts Covered

### Redis Data Structures
- **Strings:** Counters, flags, simple values, policy numbers
- **Hashes:** Customer profiles, policy data, nested structures
- **Lists:** Queues, activity logs, timeline data
- **Sets:** Tags, categories, unique items, customer segments
- **Sorted Sets:** Leaderboards, rankings, time series, risk scores
- **Streams:** Event sourcing, audit trails, real-time processing

### Design Patterns
- **Caching Patterns:** Cache-aside, write-through, write-behind
- **Event Sourcing:** Immutable event logs, audit trails
- **Consumer Groups:** Distributed stream processing
- **Session Management:** Redis-based sessions with TTL
- **Rate Limiting:** Token bucket, sliding window algorithms
- **Key Design:** Hierarchical naming (policy:type:id:attribute)

### Production Topics
- **Docker Deployment:** Containerized Redis instances
- **Configuration:** RDB snapshots, AOF logging, memory management
- **Persistence:** Data durability strategies
- **Security:** Authentication, encryption, network security
- **Monitoring:** Performance metrics, alerting, dashboards
- **High Availability:** Redis Sentinel and Cluster
- **Backups:** Automated backup and recovery procedures
- **Clustering:** Sharding, replication, failover

### Insurance Domain Examples
- **Claims Processing:** Event sourcing with audit trails
- **Customer Management:** Profile storage with hashes
- **Policy Administration:** Key-value operations with TTL
- **Risk Analysis:** Sorted sets for scoring and rankings
- **Agent Performance:** Leaderboards with sorted sets
- **Session Management:** Secure customer portal sessions
- **Rate Limiting:** API protection for quote systems
- **Real-time Analytics:** Stream-powered dashboards

---

## Troubleshooting

### Redis Connection Issues

**Windows (Use Scripts):**
```cmd
cd scripts

# Stop and restart Redis
stop-redis.bat
start-redis.bat

# Or clean restart
cleanup-redis.bat
start-redis.bat
```

**Mac/Linux:**
```bash
# Check if Redis is running
docker ps | grep redis

# Restart Redis
docker restart redis

# Check Redis logs
docker logs redis

# Stop and restart
docker stop redis
docker start redis
```

**Test Connection:**

Open Redis Insight → Workbench → Run:
```redis
PING
```
Expected response: `PONG`

### Node.js Dependencies

```bash
# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Verify Redis module
npm list redis
```

### Port Conflicts

```bash
# Check if port 6379 is in use
# Mac/Linux
lsof -i :6379

# Windows
netstat -ano | findstr :6379

# Stop conflicting process
docker stop redis

# Start with different port
docker run -d -p 6380:6379 --name redis-alt redis/redis-stack:latest
export REDIS_PORT=6380  # Mac/Linux
$env:REDIS_PORT = "6380"  # Windows
```

### Docker Issues

**Windows (Use Scripts):**
```cmd
cd scripts

# Clean restart
cleanup-redis.bat
start-redis.bat
```

**Mac/Linux:**
```bash
# Check Docker status
docker info

# Check running containers
docker ps

# View container logs
docker logs redis

# Restart Docker Desktop
# Windows/Mac: Restart Docker Desktop application
# Linux: sudo systemctl restart docker

# Remove and recreate Redis container
docker stop redis
docker rm redis
docker run -d -p 6379:6379 --name redis redis/redis-stack:latest
```

### Common Environment Variable Issues

```bash
# Verify environment variables are set
# Mac/Linux
echo $REDIS_HOST
echo $REDIS_PORT

# Windows
echo $env:REDIS_HOST
echo $env:REDIS_PORT

# Set environment variables
# Mac/Linux
export REDIS_HOST="localhost"
export REDIS_PORT="6379"

# Windows
$env:REDIS_HOST = "localhost"
$env:REDIS_PORT = "6379"
```

---

## Repository Structure

```
redis-mastering/
├── lab1-redis-cli-basics/           # Day 1: Foundation
├── lab2-resp-protocol/
├── lab3-data-operations-strings/
├── lab4-key-management-ttl/
├── lab5-advanced-cli-monitoring/
├── lab6-javascript-redis-client/    # Day 2: JavaScript
├── lab7-customer-policy-hashes/
├── lab8-claims-event-sourcing/      # ⭐ Event Sourcing
├── lab9-sets-analytics/
├── lab10-advanced-caching-patterns/ # Optional / take-home
├── lab11-session-management/        # Day 3: Production
├── lab12-rate-limiting-api-protection/
├── lab13-production-configuration/  # Content folded into Lab 14
├── lab14-production-monitoring/     # Config + Monitoring
├── lab15-redis-cluster-ha/          # ⭐ Cluster HA
├── presentations/                    # Course slides (Reveal.js)
├── tests/                           # Integration tests
└── README.md                        # This file
```

Each lab directory contains:
```
lab{n}-{name}/
├── README.md                        # Lab instructions
├── scripts/
│   ├── mac/                         # Bash scripts for Mac/Linux
│   └── win/                         # PowerShell scripts for Windows
├── src/                             # Source code (JavaScript labs)
├── tests/                           # Lab-specific tests
├── examples/                        # Example implementations
├── docs/                            # Additional documentation
└── package.json                     # Node.js config (if applicable)
```

---

## Presentations

Course includes 10 Reveal.js single-file HTML presentations in the `presentations/` folder:

### Day 1 Presentations
- `content1_presentation.html` — Introduction to Redis (30 min)
- `content2_presentation.html` — RESP Protocol & CLI Operations (30 min)
- `content3_presentation.html` — String Operations & Key Management (30 min)

### Day 2 Presentations
- `content4_presentation.html` — JavaScript Redis Client Fundamentals (30 min)
- `content5_presentation.html` — Hash, List, Set & Sorted Set Data Structures (35 min)
- `content6_presentation.html` — Streams, Event Sourcing & Caching Patterns (30 min)

### Day 3 Presentations
- `content7_presentation.html` — Security, Sessions & Rate Limiting (35 min)
- `content8_presentation.html` + `content9_presentation.html` — Persistence, Configuration & Monitoring (35 min combined)
- `content15_presentation.html` — Redis Cluster & High Availability (30 min)

**To view presentations:** Open any HTML file in a browser. Use arrow keys to navigate.

---

## Best Practices

### Development
- Use environment variables for Redis configuration
- Implement connection pooling in applications
- Handle Redis errors gracefully with try-catch
- Use appropriate data structures for use cases
- Monitor memory usage regularly
- Follow key naming conventions (namespace:type:id:attribute)

### Production
- Enable persistence (RDB + AOF)
- Configure maxmemory and eviction policies
- Use Redis Sentinel or Cluster for high availability
- Implement monitoring and alerting
- Schedule regular backups and test disaster recovery
- Enable authentication and use TLS for network encryption
- Tune configuration for workload (read-heavy vs write-heavy)

---

## Course Completion Checklist

### Day 1: CLI & Core Operations ✅
- [ ] Lab 1 - Redis environment setup and basic CLI operations
- [ ] Lab 2 - RESP protocol monitoring and analysis
- [ ] Lab 3 - String operations and atomic counters
- [ ] Lab 4 - Key management and TTL strategies
- [ ] Lab 5 - Advanced monitoring and performance analysis

### Day 2: JavaScript Integration ✅
- [ ] Lab 6 - JavaScript Redis client setup and connection pooling
- [ ] Lab 7 - Hash operations for customer and policy management
- [ ] Lab 8 - Event sourcing with Redis Streams (producer/consumer)
- [ ] Lab 9 - Analytics with sets and sorted sets
- [ ] Lab 10 *(optional/take-home)* - Advanced caching patterns implementation

### Day 3: Production & Advanced ✅
- [ ] Lab 11 - Session management with JWT and RBAC
- [ ] Lab 12 - Rate limiting and API protection
- [ ] Lab 14 - Production configuration & monitoring (RDB/AOF, backups, health checks)
- [ ] Lab 15 - Redis Cluster with high availability

### Final Deliverables
- [ ] Pass all lab tests (`npm test`)
- [ ] Review all 10 presentations
- [ ] Build a sample insurance application using Redis
- [ ] Deploy Redis in production configuration
- [ ] Implement monitoring and alerting
- [ ] Practice backup and recovery procedures

---

## Learning Objectives

By the end of this course, you will be able to:

1. ✅ **Master Redis Fundamentals** - Architecture, data structures, and operations
2. ✅ **Build Production Applications** - JavaScript/Node.js integration with Redis
3. ✅ **Implement Event-Driven Architecture** - Redis Streams for event sourcing
4. ✅ **Deploy Production Systems** - Persistence, security, and monitoring
5. ✅ **Scale with Clustering** - Redis Cluster for high availability
6. ✅ **Optimize Performance** - Memory management, query optimization, troubleshooting
7. ✅ **Apply to Insurance Domain** - Claims, policies, customers, analytics

---

## Additional Resources

### Official Redis Resources
- **Redis Documentation:** https://redis.io/docs/
- **Redis Commands Reference:** https://redis.io/commands/
- **Redis Best Practices:** https://redis.io/docs/management/optimization/
- **Redis University:** https://university.redis.com/

### Tools
- **Redis Insight:** https://redis.io/insight/ - Redis GUI
- **Redis CLI:** https://redis.io/docs/ui/cli/ - Command-line interface
- **Docker Desktop:** https://www.docker.com/products/docker-desktop/

### Course Files
- **Lab-specific READMEs** - Detailed instructions in each lab directory
- **Architecture docs** - In `docs/` subdirectories
- **Code examples** - In `examples/` subdirectories

---

## Support & Contact

For questions or issues:
1. Check lab-specific README files in each lab directory
2. Consult the presentations in `presentations/` folder
3. Run tests to verify setup: `npm test`

---

## Technology Stack

- **Languages:** JavaScript/Node.js, Bash, PowerShell
- **Runtime:** Node.js 18+
- **Database:** Redis 7.0+
- **Container Platform:** Docker + Docker Compose
- **Libraries:** redis (Node.js client), express, ioredis (cluster support)
- **Tools:** Redis CLI, Redis Insight, VS Code

---

## License

MIT License - See individual lab directories for details.

---

**Ready to master Redis?** Start with Lab 1:

```bash
cd lab1-redis-cli-basics
cat README.md
```

🎓 **Happy Learning!** 🎓
