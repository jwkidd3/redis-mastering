# Redis Mastering Course - Labs Quick Reference

## Lab Overview Table

| Lab | Title | Duration | Type | Key Topics | Main Scripts/Files |
|-----|-------|----------|------|------------|-------------------|
| 1 | Redis Environment & CLI Basics | 45 min | CLI | Docker setup, CLI navigation, Redis Insight | `setup-lab.sh`, `test-lab.sh` |
| 2 | RESP Protocol | 45 min | CLI | Protocol monitoring, raw format analysis | `lab2.md` |
| 3 | Data Operations with Strings | 45 min | CLI | String ops, INCR/DECR, MSET/MGET | `load-sample-data.sh`, performance tests |
| 4 | Key Management & TTL | 45 min | CLI | Key naming, TTL strategies, SCAN | `load-key-management-data.sh` |
| 5 | Advanced CLI Operations | 45 min | CLI | Monitoring, benchmarking, alerts | 9 analysis/monitoring scripts |
| 6 | JavaScript Redis Client Setup | 45 min | Node.js | Client setup, connection pooling, CRUD | `setup-lab.sh`, Docker compose |
| 7 | Customer Profiles & Hashes | 45 min | Node.js | Hash operations, structured data | `test-connection.js`, examples |
| 8 | Claims Event Sourcing (Streams) | 45 min | Node.js | Event sourcing, producer/consumer groups | `npm run producer/consumer/analytics` |
| 9 | Insurance Analytics (Sets/Sorted Sets) | 45 min | Node.js | Customer segmentation, leaderboards | Analytics scripts |
| 10 | Advanced Caching Patterns | 45 min | Node.js | Cache-aside, write-through, TTL | Caching implementations |
| 11 | Session Management & Security | 45 min | Node.js | JWT, RBAC, session cleanup | `setup-lab.sh`, RBAC service |
| 12 | Rate Limiting & API Protection | 45 min | Node.js | Token bucket, tier-based limits | Express server, rate limit service |
| 13 | Production Configuration | 45 min | Bash/CLI | RDB/AOF, backups, security | 12 configuration scripts |
| 14 | Production Monitoring | 45 min | Node.js | Health checks, metrics, dashboards | Monitoring service, scripts |
| 15 | Redis Cluster HA | 45 min+ | Node.js/Docker | 6-node cluster, sharding, failover | 16 cluster scripts, Docker compose |

---

## Runnable Commands by Lab

### Lab 1: Redis CLI Basics
```bash
cd lab1-redis-cli-basics
./setup-lab.sh
./test-lab.sh
redis-cli -h redis-server.training.com -p 6379 PING
```

### Lab 3: String Operations
```bash
cd lab3-data-operations-strings
./scripts/load-sample-data.sh
redis-cli SET policy:AUTO-100001 "customer_id:CUST001|premium:1200"
redis-cli INCR policy:AUTO-100001:counter
```

### Lab 6: JavaScript Client Setup
```bash
cd lab6-javascript-redis-client
npm install redis
./scripts/setup-lab.sh
./scripts/validate-setup.sh
node test-connection.js
```

### Lab 8: Claims Event Sourcing
```bash
cd lab8-claims-event-sourcing
npm install
npm run validate          # Validate setup
npm run load-data         # Load sample claims
npm run producer          # Submit claims (Terminal 1)
npm run consumer          # Process events (Terminal 2)
npm run analytics         # View analytics (Terminal 3)
npm test                  # Run tests
```

### Lab 11: Session Management
```bash
cd lab11-session-management
npm install
./scripts/setup-lab.sh
npm test
npm run monitor-sessions
```

### Lab 12: Rate Limiting
```bash
cd lab12-rate-limiting-api-protection
npm install
node src/server.js        # Start API server
node examples/test-rate-limits.js  # Test limits
node scripts/monitor-limits.js
```

### Lab 13: Production Configuration
```bash
cd lab13-production-configuration
./scripts/validate-production-config.sh
./scripts/load-insurance-production-data.sh
./scripts/backup-insurance-redis.sh
./scripts/health-check.sh
```

### Lab 14: Production Monitoring
```bash
cd lab14-production-monitoring
npm install
node scripts/setup.sh
node src/health-check-service.js
node scripts/test-monitoring.sh
```

### Lab 15: Redis Cluster
```bash
cd lab15-redis-cluster-ha
npm install
docker compose up -d
./scripts/init-cluster.sh
npm run test-sharding
npm run load-data
npm run monitor
```

---

## Data Files & Sample Data

### Lab 8 Sample Claims
```javascript
{
  customer_id: 'CUST-001',
  policy_number: 'POL-AUTO-001',
  amount: 750,
  description: 'Minor fender bender - rear bumper repair',
  incident_date: '2024-08-15T10:30:00Z'
}
```

### Key Naming Patterns
- **Policies:** `policy:POL-AUTO-001`
- **Customers:** `customer:CUST-001`
- **Claims:** `claim:CLM-001`
- **Sessions:** `session:[uuid]`
- **Quotes:** `quote:QUOTE-001` (with TTL)

### Stream Event Types (Lab 8)
- `claim.submitted` - Initial claim creation
- `claim.assigned` - Assigned to adjuster
- `claim.document.uploaded` - Supporting docs
- `claim.investigated` - Investigation
- `claim.approved` - Approval decision
- `claim.rejected` - Denial
- `claim.payment.initiated` - Payment start
- `claim.payment.completed` - Settlement

---

## Docker Usage

### Lab 6: Single Redis Instance
```bash
docker run -d --name redis-lab6 -p 6379:6379 redis:7-alpine
```

### Lab 15: Redis Cluster (6 nodes)
```bash
cd lab15-redis-cluster-ha
docker compose up -d
docker compose logs -f
docker compose down
```

---

## npm Scripts by Lab

| Lab | Scripts Available |
|-----|------------------|
| 6 | N/A (template) |
| 8 | start, dev, test, test:all, validate, health, setup, producer, consumer, analytics, load-data, verify |
| 10 | N/A |
| 11 | test, setup, cleanup-sessions, monitor-sessions |
| 12 | start (implicit in server.js) |
| 14 | setup, test-monitoring, lab-completion-summary |
| 15 | test, start, monitor, test-sharding, test-hash-tags, load-data, chaos-test, simulate-partition, simulate-failure |

---

## Key Monitoring Tools

| Lab | Monitoring Tool | Command |
|-----|-----------------|---------|
| 1 | Redis Insight | Open and connect to Redis instance |
| 5 | CLI Scripts | `./scripts/production-monitor.sh` |
| 8 | npm Dashboard | `npm run analytics` |
| 11 | Session Monitor | `npm run monitor-sessions` |
| 12 | Rate Limit Monitor | `node scripts/monitor-limits.js` |
| 13 | Health Check | `./scripts/health-check.sh` |
| 14 | Health Service | `node src/health-check-service.js` |
| 15 | Cluster Dashboard | `npm run monitor` |

---

## Configuration Files

| Lab | Config Files |
|-----|--------------|
| 6 | `.env`, `package.json.template` |
| 8 | `.env.template`, `config/` |
| 11 | `config/.env` |
| 12 | `.env.example`, `config/` |
| 13 | `redis-production.conf` |
| 14 | `.env` |
| 15 | `docker-compose.yml`, cluster config files |

---

## Environment Variables

### Common Variables
```bash
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DATABASE=0
NODE_ENV=development
```

### Lab-Specific Variables
| Lab | Variable | Default |
|-----|----------|---------|
| 8 | STREAM_NAME | claims:events |
| 8 | CONSUMER_GROUP | claims-processors |
| 12 | PORT | 3000 |
| 13 | RDB_SAVE_CONFIG | 900 1 300 10 60 1000 |
| 14 | LOG_LEVEL | info |

---

## Testing & Validation

| Lab | Test Command | Type |
|-----|--------------|------|
| 1 | `./test-lab.sh` | Shell |
| 8 | `npm test` | Mocha/JavaScript |
| 8 | `npm run validate` | Custom validation |
| 10 | `npm run verify` | Completion check |
| 14 | `npm run test-monitoring` | Shell |
| 15 | `npm test` | Mocha/JavaScript |

---

## Architecture Diagrams

### Lab 8: Event Sourcing
```
Claims Producer → Redis Stream (claims:events) → Consumer Group
                                                    ├─ Processor Consumer
                                                    ├─ Analytics Consumer
                                                    └─ Notification Consumer
```

### Lab 15: Redis Cluster (6 nodes)
```
Master-1 (Port 9000, Slots 0-5461)      Master-2 (Port 9001, Slots 5462-10922)      Master-3 (Port 9002, Slots 10923-16383)
    ↓                                        ↓                                            ↓
Replica-1 (Port 9003)                   Replica-2 (Port 9004)                       Replica-3 (Port 9005)
```

---

## Performance Benchmarking

| Lab | Benchmark Tool |
|-----|-----------------|
| 3 | `performance-tests/string-operations-performance.sh` |
| 5 | `scripts/performance-analysis.sh` |
| 13 | `scripts/benchmark-production.sh` |
| 15 | `scripts/benchmark-cluster.sh` |

---

## Cluster Management Commands (Lab 15)

```bash
# Initialize cluster
./scripts/init-cluster.sh

# View slot distribution
./scripts/show-slot-distribution.sh

# Add new master node
./scripts/add-master-node.sh

# Test failover
./scripts/manual-failover.sh

# Simulate node failure
./scripts/simulate-node-failure.sh

# Monitor failover
./scripts/watch-failover.sh

# Rolling upgrade
./scripts/rolling-upgrade.sh
```

---

## Backup & Recovery

| Lab | Backup Command |
|-----|-----------------|
| 13 | `./scripts/backup-insurance-redis.sh` |
| 13 | `./scripts/validate-backup.sh` |
| 15 | `./scripts/backup-cluster.sh` |
| 15 | `./scripts/restore-cluster.sh` |

---

## Troubleshooting

### Connection Issues
```bash
# Test basic connectivity
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# With password
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping

# Verify environment variables
echo $REDIS_HOST $REDIS_PORT
```

### Node.js Issues
```bash
# Check Node.js version
node --version

# Verify Redis module
npm list redis

# Check connection in Node
node -e "const redis = require('redis'); console.log('✓ Redis module OK')"
```

### Docker Issues
```bash
# Check running containers
docker ps | grep redis

# View logs
docker logs <container_id>

# Stop/restart
docker stop <container_id>
docker start <container_id>
```

---

## Course Completion Checklist

### Day 1 (CLI-Only)
- [ ] Lab 1 - CLI basics complete
- [ ] Lab 2 - RESP protocol understood
- [ ] Lab 3 - String operations mastered
- [ ] Lab 4 - Key management patterns learned
- [ ] Lab 5 - Monitoring tools practiced

### Day 2 (JavaScript Integration)
- [ ] Lab 6 - JavaScript client setup complete
- [ ] Lab 7 - Hash operations working
- [ ] Lab 8 - Event sourcing with streams implemented
- [ ] Lab 9 - Analytics with sets/sorted sets
- [ ] Lab 10 - Caching patterns implemented

### Day 3 (Production Ready)
- [ ] Lab 11 - Session management operational
- [ ] Lab 12 - Rate limiting functional
- [ ] Lab 13 - Production configuration validated
- [ ] Lab 14 - Monitoring dashboard working
- [ ] Lab 15 - Redis cluster tested

---

## Additional Resources

- `COURSE_OVERVIEW.md` - Comprehensive course documentation
- `course_flow.md` - Detailed course schedule
- Each lab's `lab*.md` - Detailed lab instructions
- `docs/` directories - Architecture and implementation guides
- `reference/` directories - Code examples and patterns

