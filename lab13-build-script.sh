#!/bin/bash

# Lab 13 Content Generator Script
# Generates complete content and code for Lab 13: Production Configuration for Business Systems
# Duration: 45 minutes
# Focus: Redis production deployment, persistence, memory management, and security configuration

set -e

LAB_DIR="lab13-production-configuration"
LAB_NUMBER="13"
LAB_TITLE="Production Configuration for Business Systems"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Production Redis deployment with persistence, security, and performance optimization"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,config,docs,monitoring,backup,security}

# Create main lab instructions markdown file
echo "📋 Creating lab13.md..."
cat > lab13.md << 'EOF'
# Lab 13: Production Configuration for Business Systems

**Duration:** 45 minutes  
**Objective:** Configure Redis for production deployment with persistence, security, and performance optimization

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Configure Redis persistence with RDB and AOF for data durability
- Set up memory management and eviction policies for production workloads
- Implement security configurations including authentication and encryption
- Create backup and recovery strategies for business continuity
- Optimize Redis configuration for high-performance production systems
- Monitor and tune production Redis instances for stability

---

## Part 1: Persistence Configuration (15 minutes)

### Step 1: RDB Persistence Setup

Create production Redis configuration with RDB snapshots:

```bash
# Create production config directory
mkdir -p config

# Create redis.conf with RDB settings
cat > config/redis-production.conf << 'REDIS_CONFIG'
# RDB Persistence Configuration
save 900 1        # Save after 900 sec if at least 1 key changed
save 300 10       # Save after 300 sec if at least 10 keys changed
save 60 10000     # Save after 60 sec if at least 10000 keys changed

# RDB file configuration
dbfilename dump.rdb
dir /data/redis/

# RDB checksum verification
rdbchecksum yes

# Compression for RDB files
rdbcompression yes

# Stop accepting writes on RDB save error
stop-writes-on-bgsave-error yes
REDIS_CONFIG

# Start Redis with production config
docker run -d --name redis-prod-lab13 \
  -p 6379:6379 \
  -v $(pwd)/config/redis-production.conf:/usr/local/etc/redis/redis.conf \
  -v $(pwd)/data:/data/redis \
  redis:7-alpine redis-server /usr/local/etc/redis/redis.conf
```

### Step 2: AOF Persistence Configuration

Add AOF (Append Only File) for transaction logging:

```bash
# Update configuration with AOF settings
cat >> config/redis-production.conf << 'AOF_CONFIG'

# AOF Persistence Configuration
appendonly yes
appendfilename "appendonly.aof"
appenddirname "appendonlydir"

# AOF rewrite configuration
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# AOF fsync policies
# appendfsync always    # Slowest, safest
appendfsync everysec   # Good compromise
# appendfsync no       # Fastest, least safe

# Prevent fsync during rewrites
no-appendfsync-on-rewrite no

# AOF loading on corruption
aof-load-truncated yes

# Use RDB-AOF hybrid persistence
aof-use-rdb-preamble yes
AOF_CONFIG
```

**Test persistence configuration:**

```bash
# Connect and add test data
redis-cli SET business:config "production" EX 3600
redis-cli SET customer:test "persistence-check"

# Force RDB snapshot
redis-cli BGSAVE

# Check background save status
redis-cli LASTSAVE

# View AOF file
ls -la data/appendonlydir/
```

---

## Part 2: Memory Management & Performance (15 minutes)

### Step 3: Memory Configuration for Production

Configure memory limits and eviction policies:

```javascript
// src/memory-config-test.js
const redis = require('redis');

async function testMemoryConfig() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });

    await client.connect();

    try {
        // Get current memory configuration
        const maxMemory = await client.configGet('maxmemory');
        const policy = await client.configGet('maxmemory-policy');
        
        console.log('Current Memory Configuration:');
        console.log('Max Memory:', maxMemory);
        console.log('Eviction Policy:', policy);

        // Set production memory configuration
        await client.configSet('maxmemory', '2gb');
        await client.configSet('maxmemory-policy', 'allkeys-lru');
        
        // Get memory stats
        const info = await client.info('memory');
        console.log('\nMemory Statistics:');
        console.log(info);

        // Test memory usage
        console.log('\nTesting memory allocation...');
        for (let i = 0; i < 1000; i++) {
            await client.set(
                `test:key:${i}`,
                JSON.stringify({
                    id: i,
                    data: 'x'.repeat(1000),
                    timestamp: Date.now()
                }),
                { EX: 3600 }
            );
        }

        // Check memory after load
        const memUsed = await client.memoryUsage('test:key:500');
        console.log(`Sample key memory usage: ${memUsed} bytes`);

    } catch (error) {
        console.error('Memory configuration error:', error);
    } finally {
        await client.quit();
    }
}

testMemoryConfig();
```

### Step 4: Performance Optimization Settings

Add performance optimization to configuration:

```bash
cat >> config/redis-production.conf << 'PERFORMANCE_CONFIG'

# Memory Management
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Client connection limits
maxclients 10000
timeout 300
tcp-keepalive 300
tcp-backlog 511

# Threading and I/O
io-threads 4
io-threads-do-reads yes

# Slow log configuration
slowlog-log-slower-than 10000
slowlog-max-len 128

# Latency monitoring
latency-monitor-threshold 100

# Database configuration
databases 16

# Disable dangerous commands in production
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG "CONFIG_e3b0c44298fc1c149afbf4c8996fb924"

# Enable active rehashing
activerehashing yes

# Client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
PERFORMANCE_CONFIG
```

---

## Part 3: Security Configuration (15 minutes)

### Step 5: Authentication and Access Control

Implement security measures:

```javascript
// src/security-setup.js
const redis = require('redis');
const crypto = require('crypto');

async function setupSecurity() {
    // Generate strong password
    const password = crypto.randomBytes(32).toString('base64');
    console.log('Generated Redis Password:', password);

    // Create client with authentication
    const client = redis.createClient({
        url: 'redis://localhost:6379',
        password: password // Will be set after initial connection
    });

    try {
        await client.connect();
        
        // Set authentication password
        await client.configSet('requirepass', password);
        console.log('✅ Password protection enabled');

        // Create ACL users for different access levels
        const aclCommands = [
            // Read-only user for monitoring
            'ACL SETUSER monitoring on >' + crypto.randomBytes(16).toString('hex') + 
            ' ~* &* +@read +ping +info +client +config|get',
            
            // Application user with specific permissions
            'ACL SETUSER app_user on >' + crypto.randomBytes(16).toString('hex') +
            ' ~customer:* ~policy:* ~claim:* +@all -@dangerous',
            
            // Backup user for replication
            'ACL SETUSER backup_user on >' + crypto.randomBytes(16).toString('hex') +
            ' ~* &* +@read +psync +replconf'
        ];

        for (const cmd of aclCommands) {
            await client.sendCommand(cmd.split(' '));
            console.log('✅ Created ACL user:', cmd.split(' ')[2]);
        }

        // Save ACL configuration
        await client.aclSave();
        console.log('✅ ACL configuration saved');

        // List all users
        const users = await client.aclList();
        console.log('\nConfigured Users:');
        users.forEach(user => console.log(user));

    } catch (error) {
        console.error('Security setup error:', error);
    } finally {
        await client.quit();
    }
}

// Create security configuration file
const fs = require('fs');

const securityConfig = `
# Security Configuration for Production

# Bind to specific interfaces only
bind 127.0.0.1 ::1

# Disable protected mode (we use authentication)
protected-mode no

# Require password for all operations
requirepass ${crypto.randomBytes(32).toString('base64')}

# ACL configuration file
aclfile /data/redis/users.acl

# Command renaming for security
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG CONFIG_${crypto.randomBytes(8).toString('hex')}
rename-command SHUTDOWN SHUTDOWN_${crypto.randomBytes(8).toString('hex')}

# Disable Lua debugging
enable-debug-command no
enable-module-command no

# Log security events
logfile /data/redis/redis-security.log
loglevel notice
`;

fs.writeFileSync('config/redis-security.conf', securityConfig);
console.log('Security configuration file created');

setupSecurity();
```

### Step 6: Backup and Recovery Scripts

Create backup automation:

```bash
# Create backup script
cat > scripts/backup-redis.sh << 'BACKUP_SCRIPT'
#!/bin/bash

# Redis Production Backup Script
BACKUP_DIR="/backup/redis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REDIS_HOST="localhost"
REDIS_PORT="6379"
RETENTION_DAYS=7

echo "Starting Redis backup at ${TIMESTAMP}"

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Trigger background save
redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} BGSAVE

# Wait for background save to complete
while [ $(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} LASTSAVE) -eq $(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} LASTSAVE) ]; do
    echo "Waiting for background save to complete..."
    sleep 1
done

# Copy RDB file
cp /data/redis/dump.rdb ${BACKUP_DIR}/dump_${TIMESTAMP}.rdb

# Copy AOF files if they exist
if [ -d "/data/redis/appendonlydir" ]; then
    tar czf ${BACKUP_DIR}/aof_${TIMESTAMP}.tar.gz /data/redis/appendonlydir/
fi

# Copy configuration
cp /usr/local/etc/redis/redis.conf ${BACKUP_DIR}/redis_conf_${TIMESTAMP}.conf

# Remove old backups
find ${BACKUP_DIR} -name "dump_*.rdb" -mtime +${RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "aof_*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: ${BACKUP_DIR}/dump_${TIMESTAMP}.rdb"

# Verify backup
redis-cli --rdb ${BACKUP_DIR}/dump_${TIMESTAMP}.rdb --rdb-check
BACKUP_SCRIPT

chmod +x scripts/backup-redis.sh
```

---

## Production Deployment Verification

### Final Testing Script

```javascript
// src/production-verification.js
const redis = require('redis');
const { promisify } = require('util');
const exec = promisify(require('child_process').exec);

async function verifyProduction() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });

    await client.connect();

    console.log('🔍 Production Configuration Verification\n');

    try {
        // Check persistence
        const saveConfig = await client.configGet('save');
        const aofEnabled = await client.configGet('appendonly');
        console.log('✅ Persistence:', {
            RDB: saveConfig.save,
            AOF: aofEnabled.appendonly
        });

        // Check memory configuration
        const maxMem = await client.configGet('maxmemory');
        const policy = await client.configGet('maxmemory-policy');
        console.log('✅ Memory Management:', {
            limit: maxMem.maxmemory,
            policy: policy['maxmemory-policy']
        });

        // Check security
        const requirePass = await client.configGet('requirepass');
        console.log('✅ Security:', {
            authentication: requirePass.requirepass ? 'Enabled' : 'Disabled'
        });

        // Performance metrics
        const info = await client.info('stats');
        console.log('✅ Performance Metrics:', info);

        // Test backup
        const { stdout } = await exec('./scripts/backup-redis.sh');
        console.log('✅ Backup Test:', stdout);

    } catch (error) {
        console.error('❌ Verification failed:', error);
    } finally {
        await client.quit();
    }
}

verifyProduction();
```

---

## Summary & Best Practices

You've successfully configured Redis for production deployment with:

1. **Persistence**: RDB snapshots + AOF logging for data durability
2. **Memory Management**: Limits and eviction policies for stability
3. **Security**: Authentication, ACL, and command restrictions
4. **Performance**: Optimized settings for production workloads
5. **Backup**: Automated backup and recovery procedures
6. **Monitoring**: Health checks and verification scripts

### Production Checklist

- [ ] RDB persistence configured with appropriate save intervals
- [ ] AOF enabled with everysec fsync policy
- [ ] Memory limits set with appropriate eviction policy
- [ ] Authentication enabled with strong passwords
- [ ] ACL users configured for different access levels
- [ ] Dangerous commands disabled or renamed
- [ ] Backup automation in place with retention policy
- [ ] Monitoring and alerting configured
- [ ] Security hardening applied
- [ ] Performance optimization verified

### Troubleshooting Common Issues

**Persistence Issues:**
```bash
# Check RDB save status
redis-cli LASTSAVE

# Check AOF rewrite status
redis-cli INFO persistence

# Force RDB save
redis-cli BGSAVE

# Force AOF rewrite
redis-cli BGREWRITEAOF
```

**Memory Issues:**
```bash
# Check memory usage
redis-cli INFO memory

# Get memory stats for specific key
redis-cli MEMORY USAGE mykey

# Memory doctor
redis-cli MEMORY DOCTOR
```

**Performance Issues:**
```bash
# Check slow log
redis-cli SLOWLOG GET 10

# Monitor commands in real-time
redis-cli MONITOR

# Check client connections
redis-cli CLIENT LIST
```

---

**Congratulations!** 🎉 You've successfully configured Redis for production deployment with enterprise-grade persistence, security, and performance settings.
EOF

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab13-production-configuration",
  "version": "1.0.0",
  "description": "Lab 13: Production Configuration for Business Systems",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/production-verification.js",
    "test-memory": "node src/memory-config-test.js",
    "setup-security": "node src/security-setup.js",
    "verify": "node src/production-verification.js",
    "backup": "./scripts/backup-redis.sh",
    "load-test": "node src/load-test.js",
    "monitor": "node src/monitor.js"
  },
  "keywords": ["redis", "production", "configuration", "persistence", "security"],
  "author": "Redis Training",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.0",
    "dotenv": "^16.0.3",
    "chalk": "^4.1.2",
    "ora": "^5.4.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  }
}
EOF

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > src/monitor.js << 'EOF'
const redis = require('redis');
const chalk = require('chalk');

async function monitorRedis() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });

    await client.connect();

    console.log(chalk.blue.bold('📊 Redis Production Monitoring Dashboard\n'));

    setInterval(async () => {
        try {
            // Get server info
            const info = await client.info();
            const sections = info.split('\r\n\r\n');
            
            console.clear();
            console.log(chalk.blue.bold('📊 Redis Production Monitoring Dashboard'));
            console.log(chalk.gray('=' .repeat(50)));
            
            // Parse and display key metrics
            sections.forEach(section => {
                const lines = section.split('\r\n');
                const header = lines[0];
                
                if (header.includes('Server') || header.includes('Memory') || 
                    header.includes('Stats') || header.includes('Persistence')) {
                    console.log(chalk.yellow(`\n${header}`));
                    lines.slice(1).forEach(line => {
                        if (line && line.includes(':')) {
                            const [key, value] = line.split(':');
                            if (key && value) {
                                console.log(`  ${chalk.cyan(key)}: ${value}`);
                            }
                        }
                    });
                }
            });
            
        } catch (error) {
            console.error(chalk.red('Monitoring error:'), error);
        }
    }, 2000);
}

monitorRedis().catch(console.error);
EOF

# Create load test script
echo "🔨 Creating load test script..."
cat > src/load-test.js << 'EOF'
const redis = require('redis');
const { performance } = require('perf_hooks');

async function loadTest() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });

    await client.connect();

    console.log('Starting production load test...\n');

    const operations = 10000;
    const data = JSON.stringify({
        id: 'TEST',
        payload: 'x'.repeat(1000),
        timestamp: Date.now()
    });

    // Write test
    const writeStart = performance.now();
    for (let i = 0; i < operations; i++) {
        await client.set(`loadtest:${i}`, data, { EX: 60 });
    }
    const writeEnd = performance.now();

    // Read test
    const readStart = performance.now();
    for (let i = 0; i < operations; i++) {
        await client.get(`loadtest:${i}`);
    }
    const readEnd = performance.now();

    // Results
    console.log('Load Test Results:');
    console.log('==================');
    console.log(`Write Operations: ${operations}`);
    console.log(`Write Time: ${(writeEnd - writeStart).toFixed(2)}ms`);
    console.log(`Write Ops/sec: ${(operations / ((writeEnd - writeStart) / 1000)).toFixed(0)}`);
    console.log(`Read Operations: ${operations}`);
    console.log(`Read Time: ${(readEnd - readStart).toFixed(2)}ms`);
    console.log(`Read Ops/sec: ${(operations / ((readEnd - readStart) / 1000)).toFixed(0)}`);

    // Cleanup
    for (let i = 0; i < operations; i++) {
        await client.del(`loadtest:${i}`);
    }

    await client.quit();
}

loadTest().catch(console.error);
EOF

# Create restore script
echo "♻️ Creating restore script..."
cat > scripts/restore-redis.sh << 'EOF'
#!/bin/bash

# Redis Production Restore Script
BACKUP_DIR="/backup/redis"
REDIS_DATA_DIR="/data/redis"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_timestamp>"
    echo "Available backups:"
    ls -la ${BACKUP_DIR}/dump_*.rdb
    exit 1
fi

TIMESTAMP=$1
BACKUP_FILE="${BACKUP_DIR}/dump_${TIMESTAMP}.rdb"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "Restoring from backup: ${BACKUP_FILE}"

# Stop Redis server
echo "Stopping Redis server..."
redis-cli SHUTDOWN SAVE

# Wait for shutdown
sleep 5

# Backup current data
echo "Backing up current data..."
cp ${REDIS_DATA_DIR}/dump.rdb ${REDIS_DATA_DIR}/dump.rdb.before_restore

# Restore backup
echo "Restoring backup..."
cp ${BACKUP_FILE} ${REDIS_DATA_DIR}/dump.rdb

# Restore AOF if exists
AOF_BACKUP="${BACKUP_DIR}/aof_${TIMESTAMP}.tar.gz"
if [ -f "${AOF_BACKUP}" ]; then
    echo "Restoring AOF files..."
    tar xzf ${AOF_BACKUP} -C /
fi

# Start Redis server
echo "Starting Redis server..."
docker start redis-prod-lab13

# Wait for startup
sleep 5

# Verify
redis-cli PING
if [ $? -eq 0 ]; then
    echo "Restore completed successfully!"
    redis-cli DBSIZE
else
    echo "Restore failed - Redis not responding"
    exit 1
fi
EOF

chmod +x scripts/restore-redis.sh

# Create health check script
echo "❤️ Creating health check script..."
cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

# Redis Health Check Script
REDIS_HOST="localhost"
REDIS_PORT="6379"
WARNING_MEMORY_PERCENT=80
CRITICAL_MEMORY_PERCENT=90

echo "Redis Health Check Report"
echo "========================="
date

# Check if Redis is running
redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} ping > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ CRITICAL: Redis is not responding!"
    exit 1
fi
echo "✅ Redis is responding"

# Check memory usage
MEMORY_USED=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
MEMORY_MAX=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} CONFIG GET maxmemory | tail -1)

echo "Memory Used: ${MEMORY_USED}"
echo "Memory Limit: ${MEMORY_MAX}"

# Check persistence
LAST_SAVE=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} LASTSAVE)
CURRENT_TIME=$(date +%s)
SAVE_AGE=$((CURRENT_TIME - LAST_SAVE))

if [ ${SAVE_AGE} -gt 3600 ]; then
    echo "⚠️ WARNING: Last save was ${SAVE_AGE} seconds ago"
else
    echo "✅ Persistence: Last save ${SAVE_AGE} seconds ago"
fi

# Check replication (if configured)
ROLE=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} INFO replication | grep role | cut -d: -f2 | tr -d '\r')
echo "Role: ${ROLE}"

# Check slow queries
SLOW_COUNT=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} SLOWLOG LEN)
if [ ${SLOW_COUNT} -gt 10 ]; then
    echo "⚠️ WARNING: ${SLOW_COUNT} slow queries detected"
else
    echo "✅ Performance: ${SLOW_COUNT} slow queries"
fi

# Check connected clients
CLIENT_COUNT=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} CLIENT LIST | wc -l)
echo "Connected Clients: ${CLIENT_COUNT}"

echo "========================="
echo "Health check completed"
EOF

chmod +x scripts/health-check.sh

# Create README
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# Lab 13: Production Configuration for Business Systems

## Overview
This lab provides hands-on experience configuring Redis for production deployment with persistence, security, and performance optimization.

## Quick Start

1. **Start Production Redis**
```bash
docker run -d --name redis-prod-lab13 \
  -p 6379:6379 \
  -v $(pwd)/config:/usr/local/etc/redis \
  -v $(pwd)/data:/data/redis \
  redis:7-alpine redis-server /usr/local/etc/redis/redis-production.conf
```

2. **Verify Configuration**
```bash
npm run verify
```

3. **Run Health Check**
```bash
./scripts/health-check.sh
```

4. **Test Backup**
```bash
npm run backup
```

## Key Features

### Persistence
- RDB snapshots for point-in-time recovery
- AOF logging for transaction durability
- Hybrid RDB-AOF for optimal recovery

### Security
- Password authentication
- ACL user management
- Command renaming
- Network binding restrictions

### Performance
- Memory management with eviction policies
- Connection pooling
- Slow query logging
- Latency monitoring

### Operations
- Automated backup scripts
- Health monitoring
- Load testing utilities
- Restore procedures

## Configuration Files

- `config/redis-production.conf` - Main production configuration
- `config/redis-security.conf` - Security-focused configuration
- `scripts/backup-redis.sh` - Automated backup script
- `scripts/restore-redis.sh` - Restore from backup
- `scripts/health-check.sh` - Health monitoring

## NPM Scripts

- `npm start` - Run production verification
- `npm run test-memory` - Test memory configuration
- `npm run setup-security` - Configure security
- `npm run backup` - Execute backup
- `npm run monitor` - Start monitoring dashboard
- `npm run load-test` - Run performance test

## Production Checklist

- [ ] Persistence configured (RDB + AOF)
- [ ] Memory limits and eviction policy set
- [ ] Authentication enabled
- [ ] ACL users configured
- [ ] Backup automation in place
- [ ] Monitoring configured
- [ ] Health checks scheduled
- [ ] Load testing completed

## Troubleshooting

### Connection Issues
```bash
redis-cli ping
docker logs redis-prod-lab13
```

### Memory Issues
```bash
redis-cli INFO memory
redis-cli MEMORY DOCTOR
```

### Persistence Issues
```bash
redis-cli LASTSAVE
redis-cli INFO persistence
```

## Resources

- [Redis Persistence Documentation](https://redis.io/docs/management/persistence/)
- [Redis Security Documentation](https://redis.io/docs/management/security/)
- [Redis Configuration Documentation](https://redis.io/docs/management/config/)
EOF

# Create .env.example
echo "🔒 Creating .env.example..."
cat > .env.example << 'EOF'
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_secure_password_here
REDIS_DB=0

# Backup Configuration
BACKUP_DIR=/backup/redis
RETENTION_DAYS=7

# Monitoring
ALERT_EMAIL=admin@example.com
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Performance
MAX_MEMORY=2gb
MAX_CLIENTS=10000
IO_THREADS=4
EOF

# Create .gitignore
echo "🚫 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local

# Data files
data/
*.rdb
*.aof
appendonlydir/

# Backup files
backup/
*.tar.gz

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Test output
test-results/
coverage/
EOF

echo ""
echo "✅ Lab 13 build script completed successfully!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab13.md                    📋 Complete lab instructions"
echo "   ├── package.json                📦 Node.js configuration"
echo "   ├── src/"
echo "   │   ├── production-verification.js  🔍 Verification script"
echo "   │   ├── memory-config-test.js       💾 Memory testing"
echo "   │   ├── security-setup.js           🔒 Security configuration"
echo "   │   ├── monitor.js                  📊 Monitoring dashboard"
echo "   │   └── load-test.js                🔨 Load testing"
echo "   ├── scripts/"
echo "   │   ├── backup-redis.sh             💾 Backup automation"
echo "   │   ├── restore-redis.sh            ♻️  Restore procedure"
echo "   │   └── health-check.sh             ❤️  Health monitoring"
echo "   ├── config/                         ⚙️  Configuration files"
echo "   ├── README.md                       📖 Quick reference"
echo "   ├── .env.example                    🔐 Environment template"
echo "   └── .gitignore                      🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. npm install"
echo "   3. Create config/redis-production.conf"
echo "   4. docker run -d --name redis-prod-lab13 -p 6379:6379 redis:7-alpine"
echo "   5. npm run verify"
echo "   6. code ."
echo "   7. Open lab13.md and start the lab!"
echo ""
echo "💡 Quick Commands:"
echo "   npm start              # Verify production configuration"
echo "   npm run monitor        # Start monitoring dashboard"
echo "   npm run backup         # Create backup"
echo "   ./scripts/health-check.sh  # Check Redis health"
echo ""
echo "🚀 Ready to configure Redis for production deployment!"