# Redis Mastering Course

A comprehensive 3-day intensive Redis training course focused on insurance industry applications, covering Redis fundamentals through advanced production deployment patterns.

**Duration:** 3 days (21 hours total)
**Format:** 30% theory, 70% hands-on labs
**Industry Focus:** Insurance applications (Claims, Policies, Customer Management)
**Platform:** Docker + JavaScript/Node.js + Redis Insight + Visual Studio Code

## Table of Contents

- [Quick Start](#quick-start)
- [Course Structure](#course-structure)
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

```bash
# Start Redis with Docker
docker run -d -p 6379:6379 --name redis-course redis:latest

# Verify Redis is running
redis-cli ping  # Should return PONG
```

### 2. Install Dependencies

```bash
# Clone/extract course materials
cd redis-mastering

# Install root dependencies for testing
npm install
```

### 3. Run Your First Lab

```bash
# Lab 1: Redis CLI Basics
cd lab1-redis-cli-basics

# Mac/Linux
bash scripts/mac/setup-lab.sh

# Windows (PowerShell)
.\scripts\win\setup-lab.ps1

# Start using Redis CLI
redis-cli
```

---

## Course Structure

### Day 1: Redis CLI & Core Operations (7 hours)
**Labs 1-5:** Foundation and CLI mastery - **NO JavaScript required**

| Lab | Title | Key Topics |
|-----|-------|------------|
| **Lab 1** | Redis Environment & CLI Basics | Docker setup, CLI navigation, Redis Insight |
| **Lab 2** | RESP Protocol Deep Dive | Protocol monitoring, raw format analysis |
| **Lab 3** | String Operations & Data Management | String ops, INCR/DECR, MSET/MGET, performance |
| **Lab 4** | Key Management & TTL Strategies | Key naming, TTL strategies, SCAN, memory optimization |
| **Lab 5** | Advanced CLI & Production Monitoring | Monitoring, benchmarking, slow queries, alerts |

### Day 2: JavaScript Integration (7 hours)
**Labs 6-10:** Application development patterns

| Lab | Title | Key Topics |
|-----|-------|------------|
| **Lab 6** | JavaScript Redis Client Setup | Node.js client, connection pooling, async/await |
| **Lab 7** | Customer Profiles with Hashes | Hash operations, nested structures, customer management |
| **Lab 8** | Claims Event Sourcing with Streams | Event sourcing, producer/consumer groups, audit trails |
| **Lab 9** | Insurance Analytics with Sets & Sorted Sets | Segmentation, leaderboards, rankings, analytics |
| **Lab 10** | Advanced Caching Patterns | Cache-aside, write-through, event-driven invalidation |

### Day 3: Production & Advanced Topics (7 hours)
**Labs 11-15:** Enterprise deployment

| Lab | Title | Key Topics |
|-----|-------|------------|
| **Lab 11** | Session Management & Security | JWT tokens, RBAC, session cleanup, security monitoring |
| **Lab 12** | Rate Limiting & API Protection | Token bucket, sliding window, DDoS protection |
| **Lab 13** | Production Configuration | RDB/AOF persistence, backups, security hardening |
| **Lab 14** | Production Monitoring & Health Checks | Metrics collection, alerting, dashboards |
| **Lab 15** | Redis Cluster & High Availability | 6-node cluster, sharding, failover, replication |

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

#### 3. Redis CLI Tools

**Mac (Homebrew):**
```bash
brew install redis
```

**Windows (Chocolatey):**
```powershell
choco install redis
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install redis-tools
```

**Alternative (Docker):**
```bash
# Use Redis CLI from Docker container
docker exec redis-course redis-cli
```

#### 4. Optional but Recommended
- **Redis Insight** - GUI tool: https://redis.io/insight/
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

# Test Redis connection
redis-cli ping

# Check VS Code (optional)
code --version
```

---

## Platform Support

### 🎉 100% Cross-Platform Script Coverage

All lab scripts are available for both Mac/Linux and Windows platforms!

```
Total Scripts:
  Mac/Linux (bash):    57 scripts ✅
  Windows (PowerShell): 57 scripts ✅
  Coverage:            100%
```

### Script Organization

All scripts are organized by platform:

```
lab{n}/
├── scripts/
│   ├── mac/          # Bash scripts (.sh) for Mac/Linux
│   └── win/          # PowerShell scripts (.ps1) for Windows
```

### Running Scripts by Platform

**Mac/Linux:**
```bash
cd lab6-javascript-redis-client
bash scripts/mac/setup-lab.sh
```

**Windows (PowerShell):**
```powershell
cd lab6-javascript-redis-client
.\scripts\win\setup-lab.ps1
```

**Windows (Git Bash or WSL):**
```bash
# Can still use Mac scripts
bash scripts/mac/setup-lab.sh
```

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
# Find process using port
netstat -ano | findstr :6379

# Use different port
docker run -d -p 6380:6379 --name redis-course redis:latest
$env:REDIS_PORT = "6380"
```

**Redis CLI Not Found:**
```powershell
# Create PowerShell alias
function redis-cli { docker exec redis-course redis-cli $args }

# OR use full command
docker exec redis-course redis-cli <command>
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

# 4. Run setup scripts if provided
bash scripts/mac/setup-lab.sh      # Mac/Linux
.\scripts\win\setup-lab.ps1         # Windows

# 5. Follow lab-specific instructions in README.md
```

---

## Lab Quick Reference

### Day 1: CLI Labs (No JavaScript)

```bash
# Lab 1: Redis Basics
cd lab1-redis-cli-basics
bash scripts/mac/setup-lab.sh      # Mac/Linux
.\scripts\win\setup-lab.ps1         # Windows
redis-cli

# Lab 2: RESP Protocol
cd lab2-resp-protocol
redis-cli --raw

# Lab 3: String Operations
cd lab3-data-operations-strings
bash scripts/mac/load-sample-data.sh      # Mac/Linux
.\scripts\win\load-sample-data.ps1        # Windows

# Lab 4: Key Management
cd lab4-key-management-ttl
bash scripts/mac/load-key-management-data.sh   # Mac/Linux
.\scripts\win\load-key-management-data.ps1     # Windows
redis-cli KEYS "policy:*"

# Lab 5: Advanced CLI
cd lab5-advanced-cli-monitoring
bash scripts/mac/monitor-performance.sh   # Mac/Linux
.\scripts\win\monitor-performance.ps1     # Windows
```

### Day 2: JavaScript Labs

```bash
# Lab 6: JavaScript Client Setup
cd lab6-javascript-redis-client
npm install
bash scripts/mac/setup-lab.sh      # Mac/Linux
.\scripts\win\setup-lab.ps1         # Windows
node test-connection.js

# Lab 7: Hashes (Customer Profiles)
cd lab7-customer-policy-hashes
npm install
bash scripts/mac/setup-lab.sh      # Mac/Linux
.\scripts\win\setup-lab.ps1         # Windows
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

# Lab 10: Caching Patterns
cd lab10-advanced-caching-patterns
npm install
node test-cache-aside.js
```

### Day 3: Production Labs

```bash
# Lab 11: Session Management
cd lab11-session-management
npm install
bash scripts/mac/setup-lab.sh      # Mac/Linux
.\scripts\win\setup-lab.ps1         # Windows
node test-session.js

# Lab 12: Rate Limiting
cd lab12-rate-limiting-api-protection
npm install
node src/server.js            # Start API server
node examples/test-rate-limits.js

# Lab 13: Production Configuration
cd lab13-production-configuration
docker-compose up -d
bash scripts/mac/backup-redis.sh           # Mac/Linux
.\scripts\win\backup-redis.ps1             # Windows
bash scripts/mac/health-check.sh           # Mac/Linux
.\scripts\win\health-check.ps1             # Windows

# Lab 14: Production Monitoring
cd lab14-production-monitoring
npm install
bash scripts/mac/setup.sh              # Mac/Linux
.\scripts\win\setup.ps1                # Windows
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

- **Total Tests:** 179
- **Pass Rate:** 100% ✅
- **Day 1:** 100% passing ✅
- **Day 2:** 100% passing ✅
- **Day 3:** 100% passing ✅

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

```bash
# Check if Redis is running
docker ps | grep redis

# Restart Redis
docker restart redis-course

# Test connection
redis-cli ping

# Test with password
redis-cli -a <password> ping

# Check Redis logs
docker logs redis-course
```

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
docker stop redis-course

# Start with different port
docker run -d -p 6380:6379 --name redis-course redis:latest
export REDIS_PORT=6380  # Mac/Linux
$env:REDIS_PORT = "6380"  # Windows
```

### Docker Issues

```bash
# Check Docker status
docker info

# Check running containers
docker ps

# View container logs
docker logs redis-course

# Restart Docker Desktop
# Windows/Mac: Restart Docker Desktop application
# Linux: sudo systemctl restart docker

# Remove and recreate Redis container
docker stop redis-course
docker rm redis-course
docker run -d -p 6379:6379 --name redis-course redis:latest
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
├── lab10-advanced-caching-patterns/
├── lab11-session-management/        # Day 3: Production
├── lab12-rate-limiting-api-protection/
├── lab13-production-configuration/
├── lab14-production-monitoring/
├── lab15-redis-cluster-ha/          # ⭐ Cluster HA
├── presentations/                    # Course slides (Reveal.js)
├── tests/                           # Integration tests
├── CROSS-PLATFORM-SCRIPTS-COMPLETE.md  # Script platform docs
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

Course includes 9 Reveal.js HTML presentations in the `presentations/` folder:

### Day 1 Presentations
- `content1_presentation.html` - Introduction to Redis (50 min)
- `content2_presentation.html` - String Operations (45 min)
- `content3_presentation.html` - Advanced CLI (45 min)

### Day 2 Presentations
- `content4_presentation.html` - JavaScript Integration (50 min)
- `content5.html` - Hash & List Structures (45 min)
- `content6-presentation.html` - Advanced Patterns (45 min)

### Day 3 Presentations
- `content7_presentation.html` - Production Deployment (50 min)
- `content8_presentation.html` - Persistence & HA (45 min)
- `content9_presentation.html` - Performance & Monitoring (45 min)

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
- [ ] Lab 10 - Advanced caching patterns implementation

### Day 3: Production & Advanced ✅
- [ ] Lab 11 - Session management with JWT and RBAC
- [ ] Lab 12 - Rate limiting and API protection
- [ ] Lab 13 - Production configuration (RDB/AOF, backups)
- [ ] Lab 14 - Production monitoring and health checks
- [ ] Lab 15 - Redis Cluster with high availability

### Final Deliverables
- [ ] Pass all lab tests (`npm test`)
- [ ] Review all 9 presentations
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
- **CROSS-PLATFORM-SCRIPTS-COMPLETE.md** - Complete script documentation
- **Lab-specific READMEs** - Detailed instructions in each lab directory
- **Architecture docs** - In `docs/` subdirectories
- **Code examples** - In `examples/` subdirectories

---

## Support & Contact

For questions or issues:
1. Check lab-specific README files in each lab directory
2. Review the CROSS-PLATFORM-SCRIPTS-COMPLETE.md for script usage
3. Consult the presentations in `presentations/` folder
4. Run tests to verify setup: `npm test`

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
