# Lab 13: Production Configuration for Insurance Systems

**Duration:** 45 minutes  
**Objective:** Configure Redis for production deployment in insurance environments with proper persistence, security, memory management, and backup strategies

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Configure RDB persistence for insurance data backup and compliance
- Set up AOF (Append Only File) for transaction-level insurance data protection
- Implement memory management and eviction policies for insurance data retention
- Configure basic authentication and security for insurance production environments
- Create automated backup scripts for insurance data protection
- Set up production-ready Redis configuration files for insurance compliance
- Monitor production Redis instances with Redis Insight for insurance operations

---

## Part 1: Production Configuration Setup (15 minutes)

### Step 1: Environment Setup

**Important:** Connect to your assigned remote Redis host (replace with actual values provided by instructor).

```bash
# Set your Redis connection parameters
export REDIS_HOST="your-redis-host.com"  # Replace with actual host
export REDIS_PORT="6379"                  # Replace with actual port  
export REDIS_PASSWORD=""                  # Replace if password required

# Test connection to remote Redis instance
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# Create production configuration directory
mkdir -p /tmp/redis-production-config
cd /tmp/redis-production-config

# Load sample insurance data for production testing
./scripts/load-insurance-production-data.sh
```

### Step 2: Configure RDB Persistence for Insurance Data

RDB (Redis Database) provides point-in-time snapshots of your insurance data for backup and compliance.

```bash
# Create production Redis configuration file
cp config/redis-production.conf redis-production-custom.conf

# View current RDB configuration
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET save

# Configure RDB snapshots for insurance data protection
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET save "900 1 300 10 60 1000"

# Set RDB file location (if you have write permissions)
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dbfilename

# Enable RDB compression for efficient storage
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET rdbcompression yes

# Configure RDB checksum for data integrity
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET rdbchecksum yes
```

**💡 Understanding RDB Configuration:**
- `save "900 1"` - Save if at least 1 key changed in 900 seconds (15 minutes)
- `save "300 10"` - Save if at least 10 keys changed in 300 seconds (5 minutes)
- `save "60 1000"` - Save if at least 1000 keys changed in 60 seconds (1 minute)

### Step 3: Test RDB Snapshot Creation

```bash
# Force an immediate snapshot
redis-cli -h $REDIS_HOST -p $REDIS_PORT BGSAVE

# Check last save time
redis-cli -h $REDIS_HOST -p $REDIS_PORT LASTSAVE

# Monitor background save status
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO persistence | grep rdb
```

---

## Part 2: AOF Configuration for Transaction Logging (10 minutes)

### Step 1: Enable AOF for Insurance Transaction Durability

AOF (Append Only File) logs every write operation for maximum durability of insurance transactions.

```bash
# Check current AOF status
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendonly

# Enable AOF for transaction logging
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET appendonly yes

# Configure AOF sync policy for insurance transactions
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET appendfsync everysec

# Configure AOF rewrite settings
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET auto-aof-rewrite-percentage 100
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET auto-aof-rewrite-min-size 67108864

# Check AOF configuration
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO persistence | grep aof
```

**💡 AOF Sync Policies:**
- `always` - Sync every write (slowest, safest)
- `everysec` - Sync every second (recommended for insurance)
- `no` - Let OS decide when to sync (fastest, least safe)

### Step 2: Test AOF Functionality

```bash
# Perform some insurance data operations to generate AOF entries
redis-cli -h $REDIS_HOST -p $REDIS_PORT SET policy:P123456 "Auto Policy - Customer ID: C789"
redis-cli -h $REDIS_HOST -p $REDIS_PORT SET claim:C987654 "Active claim for policy P123456"
redis-cli -h $REDIS_HOST -p $REDIS_PORT HSET customer:C789 name "John Smith" policy_count 3

# Force AOF rewrite to optimize file size
redis-cli -h $REDIS_HOST -p $REDIS_PORT BGREWRITEAOF

# Check AOF status
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO persistence | grep aof_rewrite
```

---

## Part 3: Memory Management & Security Configuration (15 minutes)

### Step 1: Configure Memory Management for Insurance Data

```bash
# Check current memory usage
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory

# Set maximum memory limit (adjust based on your system)
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET maxmemory 1gb

# Configure eviction policy for insurance data
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET maxmemory-policy allkeys-lru

# Set memory sampling for eviction
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET maxmemory-samples 5

# Check memory configuration
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory*
```

**💡 Eviction Policies for Insurance:**
- `allkeys-lru` - Remove least recently used keys (recommended)
- `volatile-lru` - Remove LRU keys with expire set
- `allkeys-lfu` - Remove least frequently used keys
- `noeviction` - Don't evict, return errors (for critical insurance data)

### Step 2: Configure Basic Security

```bash
# Set a password for production security (if supported)
# redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET requirepass "your-secure-password"

# Disable dangerous commands in production
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET rename-command FLUSHDB "DANGEROUS_FLUSHDB_RENAMED"
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET rename-command FLUSHALL "DANGEROUS_FLUSHALL_RENAMED"

# Configure timeout for idle clients
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET timeout 300

# Limit number of client connections
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET maxclients 1000

# Check security settings
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET "*timeout*"
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxclients
```

### Step 3: Performance Monitoring Setup

```bash
# Enable slow log for performance monitoring
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET slowlog-log-slower-than 10000
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET slowlog-max-len 128

# Check slow log settings
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET slowlog*

# View current slow log
redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG GET 5

# Monitor real-time operations (run briefly)
timeout 10s redis-cli -h $REDIS_HOST -p $REDIS_PORT MONITOR | head -20 || true
```

---

## Part 4: Backup & Monitoring (5 minutes)

### Step 1: Create Production Backup Script

```bash
# Run the automated backup script
./scripts/backup-insurance-redis.sh

# Check backup creation
ls -la backup/

# Test backup validation
./scripts/validate-backup.sh
```

### Step 2: Health Check Implementation

```bash
# Run comprehensive health check
./scripts/health-check.sh

# Run performance benchmark
./scripts/benchmark-production.sh

# Generate configuration report
./scripts/generate-config-report.sh
```

### Step 3: Redis Insight Monitoring Setup

```bash
# Setup monitoring configuration for Redis Insight
./scripts/setup-monitoring.sh

echo ""
echo "🔍 Redis Insight Setup:"
echo "1. Open Redis Insight application"
echo "2. Add new database connection:"
echo "   - Host: $REDIS_HOST"
echo "   - Port: $REDIS_PORT"
echo "   - Name: Insurance Production"
echo "3. Navigate to Analysis section"
echo "4. Review memory usage patterns"
echo "5. Check slow operations"
echo "6. Monitor key patterns"
```

---

## 🧪 Verification Steps

### Test Production Configuration

```bash
# Verify persistence configuration
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET save
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendonly

# Test memory limits
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory-policy

# Check security settings
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET timeout
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxclients

# Verify backup automation
./scripts/test-backup-automation.sh

# Run final validation
./scripts/validate-production-config.sh
```

### Expected Results

```bash
✅ RDB persistence: Enabled with appropriate save intervals
✅ AOF logging: Enabled with everysec sync policy
✅ Memory management: Configured with LRU eviction
✅ Security: Basic timeout and connection limits set
✅ Monitoring: Slow log and performance tracking enabled
✅ Backups: Automated backup scripts functional
```

---

## 📊 Key Configuration Summary

| Setting | Production Value | Purpose |
|---------|------------------|---------|
| `save` | "900 1 300 10 60 1000" | RDB snapshots for backup |
| `appendonly` | yes | Transaction durability |
| `appendfsync` | everysec | Balance performance/safety |
| `maxmemory` | 1gb | Memory limit |
| `maxmemory-policy` | allkeys-lru | Eviction strategy |
| `timeout` | 300 | Client timeout |
| `maxclients` | 1000 | Connection limit |
| `slowlog-log-slower-than` | 10000 | Performance monitoring |

---

## 🔧 Troubleshooting

### Common Issues

1. **RDB Save Failures:**
   ```bash
   # Check disk space and permissions
   redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO persistence | grep rdb_last_save_time
   redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir
   ```

2. **AOF File Growing Too Large:**
   ```bash
   # Force AOF rewrite
   redis-cli -h $REDIS_HOST -p $REDIS_PORT BGREWRITEAOF
   # Check rewrite status
   redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO persistence | grep aof_rewrite
   ```

3. **Memory Usage Issues:**
   ```bash
   # Check memory fragmentation
   redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep fragmentation
   # Analyze big keys
   redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys
   ```

---

## 🎓 Lab Completion

**Congratulations!** You have successfully:

✅ **Configured RDB persistence** for insurance data backup and compliance  
✅ **Set up AOF logging** for transaction-level insurance data protection  
✅ **Implemented memory management** with appropriate eviction policies  
✅ **Configured basic security** for production insurance environments  
✅ **Created automated backup scripts** for insurance data protection  
✅ **Set up monitoring** with Redis Insight for production operations  

### Next Steps

- **Lab 14:** Comprehensive monitoring and alerting for insurance operations
- **Lab 15:** Microservices integration patterns for insurance systems

### Production Readiness Checklist

- [ ] RDB persistence configured with appropriate intervals
- [ ] AOF enabled for transaction durability
- [ ] Memory limits and eviction policies set
- [ ] Basic security measures implemented
- [ ] Automated backup procedures tested
- [ ] Monitoring and alerting configured
- [ ] Performance baselines established
- [ ] Disaster recovery procedures documented

---

## 📚 Additional Resources

- [Redis Persistence Guide](https://redis.io/topics/persistence)
- [Redis Security Best Practices](https://redis.io/topics/security)
- [Redis Memory Optimization](https://redis.io/topics/memory-optimization)
- [Redis Production Deployment](https://redis.io/topics/admin)
