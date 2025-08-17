#!/bin/bash

# Lab 1 Content Generator Script
# Generates complete content and code for Lab 1: Redis Environment & CLI Basics
# Duration: 45 minutes
# Focus: Docker setup, Redis Insight, CLI commands, RESP protocol

set -e

LAB_DIR="lab1-redis-environment"
LAB_NUMBER="1"
LAB_TITLE="Redis Environment & CLI Basics"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Redis environment setup and basic command-line operations"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples}

# Create main package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab1-redis-environment",
  "version": "1.0.0",
  "description": "Lab 1: Redis Environment & CLI Basics",
  "main": "redis-connection.js",
  "type": "module",
  "scripts": {
    "start": "node redis-connection.js",
    "cli": "node examples/cli-operations.js",
    "benchmark": "node examples/benchmark.js",
    "resp": "node examples/resp-protocol.js",
    "test": "node scripts/test-connection.js",
    "setup": "node scripts/setup-check.js"
  },
  "dependencies": {
    "redis": "^4.6.0"
  },
  "keywords": ["redis", "javascript", "lab", "environment"]
}
EOF

echo "🔧 Installing dependencies..."
npm install

# Create main lab instructions markdown file
echo "📋 Creating lab1.md..."
cat > lab1.md << 'EOF'
# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes  
**Objective:** Master Redis environment setup and basic command-line operations

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Navigate the Docker Redis environment
- Use Redis Insight GUI effectively
- Execute basic Redis CLI commands
- Understand RESP protocol communication
- Test JavaScript client connections
- Perform basic performance benchmarking

---

## Part 1: Environment Setup & Verification (10 minutes)

### Step 1: Verify Docker Redis Environment

First, let's verify that Redis is running in Docker:

```bash
# Check if Redis container is running
docker ps | grep redis

# Check Redis container logs
docker logs redis-server
```

**Expected Output:**
```
Redis server v=7.2.0 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=c6e4fbeede1c73c5
Server initialized
Ready to accept connections tcp
```

### Step 2: Test Basic Connectivity

```bash
# Test Redis CLI connection
redis-cli ping

# Should return: PONG
```

### Step 3: Open Redis Insight

1. Launch Redis Insight from your desktop applications or start menu
2. If this is your first time using Redis Insight, you'll see the welcome screen
3. Click "Add Redis Database" to connect to your local Redis
4. Use connection details:
   - **Host:** localhost
   - **Port:** 6379
   - **Name:** Lab Redis
5. Click "Add Redis Database" to establish connection

---

## Part 2: Redis CLI Exploration (15 minutes)

### Step 1: Basic CLI Commands

Open a terminal and start Redis CLI:

```bash
redis-cli
```

Execute these basic commands:

```redis
# Test connection
PING

# Get server information
INFO server

# Check database size
DBSIZE

# List all keys (should be empty initially)
KEYS *

# Set and get a simple key
SET hello "world"
GET hello

# Check if key exists
EXISTS hello

# Delete the key
DEL hello

# Verify deletion
EXISTS hello
```

### Step 2: Explore Data Types

```redis
# String operations
SET counter 100
GET counter
INCR counter
GET counter

# Check data type
TYPE counter

# Set with expiration
SETEX temp_key 30 "temporary value"
TTL temp_key

# Check TTL again after a few seconds
TTL temp_key
```

### Step 3: RESP Protocol Observation

In Redis CLI, enable protocol monitoring:

```redis
# Monitor all commands (run this in a separate terminal)
redis-cli monitor

# In your main CLI, execute commands and observe RESP output
SET user:1 "john"
GET user:1
HSET user:2 name "jane" age 25
```

**What to observe:**
- RESP protocol structure
- Command serialization
- Response formats

---

## Part 3: JavaScript Client Connection (10 minutes)

### Step 1: Test Basic Connection

Run the connection test script:

```bash
npm run test
```

**Expected Output:**
```
🔗 Testing Redis Connection...
✅ Successfully connected to Redis
📊 Server Info:
   Redis Version: 7.2.0
   Connected Clients: 2
   Used Memory: 1.2MB
   Total Commands: 145
✅ Connection test completed
```

### Step 2: Basic JavaScript Operations

Run the CLI operations example:

```bash
npm run cli
```

This will demonstrate:
- Basic string operations
- Atomic counters
- Key expiration
- Batch operations

### Step 3: RESP Protocol Demo

```bash
npm run resp
```

Observe how JavaScript commands translate to RESP protocol.

---

## Part 4: Performance Benchmarking (10 minutes)

### Step 1: Built-in Redis Benchmark

```bash
# Simple benchmark (10,000 operations)
redis-benchmark -q -n 10000

# Specific operation benchmarks
redis-benchmark -t set,get -n 10000 -q

# With pipeline (50 commands per pipeline)
redis-benchmark -t set,get -n 10000 -P 50 -q
```

### Step 2: JavaScript Benchmark

```bash
npm run benchmark
```

**Expected Output:**
```
🏃 Running Redis Performance Benchmark...

📊 String Operations (1000 operations):
   SET operations: 125.5 ops/sec
   GET operations: 234.7 ops/sec
   INCR operations: 189.3 ops/sec

📊 Batch Operations (100 batches of 10):
   MSET operations: 89.2 batches/sec
   MGET operations: 156.8 batches/sec

📊 Memory Usage:
   Used Memory: 1.45MB
   Peak Memory: 1.67MB
   Total Keys: 1000
```

### Step 3: Redis Insight Performance View

1. Open Redis Insight application on your desktop
2. Select your "Lab Redis" connection
3. Navigate to "Analysis" tab in the sidebar
4. Click "Memory Analysis" to view memory usage patterns
5. Check the "Slow Log" section for query performance
6. Review command statistics in the "Overview" tab

---

## 🏆 Challenge Exercises

### Challenge 1: Key Patterns (5 minutes)

Create a set of keys following different patterns and explore them:

```redis
# Create user keys
SET user:1:name "john"
SET user:2:name "jane"
SET user:3:name "bob"

# Create session keys
SET session:abc123 "user1_data"
SET session:def456 "user2_data"

# Use pattern matching
KEYS user:*
KEYS session:*
KEYS *:name
```

### Challenge 2: Memory Monitoring

Use Redis CLI to monitor memory usage:

```redis
# Get memory info
MEMORY usage user:1:name
INFO memory

# Monitor memory while adding data
SET large_key [create a large string value]
MEMORY usage large_key
```

### Challenge 3: Connection Pooling Investigation

Modify the JavaScript connection script to:
1. Create multiple connections
2. Test concurrent operations
3. Monitor connection count in Redis Insight application

---

## 📚 Key Takeaways

✅ **Redis Environment**: Successfully set up and verified Docker Redis environment  
✅ **CLI Mastery**: Learned essential Redis CLI commands and navigation  
✅ **RESP Protocol**: Understood Redis protocol communication structure  
✅ **JavaScript Integration**: Connected Node.js application to Redis  
✅ **Performance Awareness**: Conducted basic benchmarking and monitoring  
✅ **Redis Insight**: Explored GUI tools for Redis management and monitoring

## 🔗 Next Steps

In **Lab 2: String Operations & Counters**, you'll dive deeper into:
- Advanced string manipulation
- Atomic counter patterns
- Batch operations optimization
- Real-world caching scenarios

---

## 📖 Additional Resources

- [Redis Commands Reference](https://redis.io/commands)
- [RESP Protocol Specification](https://redis.io/docs/reference/protocol-spec/)
- [Redis Insight Documentation](https://redis.io/docs/stack/insight/)
- [Node.js Redis Client Guide](https://github.com/redis/node-redis)
EOF

# Create Redis connection module
echo "🔗 Creating redis-connection.js..."
cat > redis-connection.js << 'EOF'
// Redis Connection Module
// Demonstrates basic Redis connection and operations

import { createClient } from 'redis';

class RedisConnection {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect() {
        try {
            console.log('🔗 Connecting to Redis...');
            
            this.client = createClient({
                url: 'redis://localhost:6379'
            });

            // Handle connection events
            this.client.on('error', (err) => {
                console.error('❌ Redis Client Error:', err);
                this.isConnected = false;
            });

            this.client.on('connect', () => {
                console.log('🔌 Connected to Redis server');
                this.isConnected = true;
            });

            this.client.on('ready', () => {
                console.log('✅ Redis client ready');
            });

            this.client.on('end', () => {
                console.log('🔚 Redis connection ended');
                this.isConnected = false;
            });

            await this.client.connect();
            return this.client;

        } catch (error) {
            console.error('❌ Failed to connect to Redis:', error);
            throw error;
        }
    }

    async getServerInfo() {
        if (!this.isConnected) {
            throw new Error('Not connected to Redis');
        }

        try {
            const info = await this.client.info('server');
            const memory = await this.client.info('memory');
            const stats = await this.client.info('stats');
            
            return {
                server: this.parseInfo(info),
                memory: this.parseInfo(memory),
                stats: this.parseInfo(stats)
            };
        } catch (error) {
            console.error('❌ Failed to get server info:', error);
            throw error;
        }
    }

    parseInfo(infoString) {
        const info = {};
        const lines = infoString.split('\r\n');
        
        for (const line of lines) {
            if (line && !line.startsWith('#')) {
                const [key, value] = line.split(':');
                if (key && value) {
                    info[key] = isNaN(value) ? value : Number(value);
                }
            }
        }
        
        return info;
    }

    async basicOperations() {
        console.log('\n🔧 Demonstrating Basic Operations...\n');

        try {
            // String operations
            console.log('1. String Operations:');
            await this.client.set('demo:string', 'Hello Redis!');
            const stringValue = await this.client.get('demo:string');
            console.log(`   SET/GET: ${stringValue}`);

            // Counter operations
            console.log('\n2. Counter Operations:');
            await this.client.set('demo:counter', 0);
            const count1 = await this.client.incr('demo:counter');
            const count2 = await this.client.incrBy('demo:counter', 10);
            console.log(`   Counter progression: 0 → ${count1} → ${count2}`);

            // Key expiration
            console.log('\n3. Key Expiration:');
            await this.client.setEx('demo:temp', 5, 'temporary data');
            const ttl = await this.client.ttl('demo:temp');
            console.log(`   Temporary key TTL: ${ttl} seconds`);

            // Key existence
            console.log('\n4. Key Existence Check:');
            const exists = await this.client.exists('demo:string');
            const notExists = await this.client.exists('demo:nonexistent');
            console.log(`   demo:string exists: ${exists === 1}`);
            console.log(`   demo:nonexistent exists: ${notExists === 1}`);

            // Database size
            console.log('\n5. Database Information:');
            const dbSize = await this.client.dbSize();
            console.log(`   Total keys in database: ${dbSize}`);

        } catch (error) {
            console.error('❌ Error in basic operations:', error);
            throw error;
        }
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
            console.log('👋 Disconnected from Redis');
        }
    }
}

// Main execution function
async function main() {
    const redis = new RedisConnection();
    
    try {
        // Connect to Redis
        await redis.connect();
        
        // Get and display server information
        console.log('\n📊 Redis Server Information:');
        const info = await redis.getServerInfo();
        
        console.log(`   Redis Version: ${info.server.redis_version}`);
        console.log(`   OS: ${info.server.os}`);
        console.log(`   Connected Clients: ${info.stats.connected_clients}`);
        console.log(`   Total Commands: ${info.stats.total_commands_processed}`);
        console.log(`   Used Memory: ${(info.memory.used_memory / 1024 / 1024).toFixed(2)}MB`);
        
        // Demonstrate basic operations
        await redis.basicOperations();
        
        console.log('\n✅ Lab 1 basic operations completed successfully!');
        console.log('\n🎯 Next Steps:');
        console.log('   • Try the CLI examples: npm run cli');
        console.log('   • Run benchmarks: npm run benchmark');
        console.log('   • Explore RESP protocol: npm run resp');
        console.log('   • Open Redis Insight: Launch Redis Insight application');
        
    } catch (error) {
        console.error('❌ Main execution error:', error);
        process.exit(1);
    } finally {
        await redis.disconnect();
    }
}

// Export for use in other modules
export { RedisConnection };

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    main();
}
EOF

# Create CLI operations example
echo "⚡ Creating examples/cli-operations.js..."
cat > examples/cli-operations.js << 'EOF'
// CLI Operations Example
// Demonstrates Redis operations that mirror CLI commands

import { createClient } from 'redis';

async function cliOperations() {
    const client = createClient({ url: 'redis://localhost:6379' });
    
    try {
        await client.connect();
        console.log('🔗 Connected to Redis for CLI operations demo\n');

        // === Basic String Operations ===
        console.log('1. 📝 String Operations (mirroring CLI commands):');
        
        // SET command
        await client.set('cli:message', 'Hello from JavaScript');
        console.log('   SET cli:message "Hello from JavaScript"');
        
        // GET command
        const message = await client.get('cli:message');
        console.log(`   GET cli:message → "${message}"`);
        
        // EXISTS command
        const exists = await client.exists('cli:message');
        console.log(`   EXISTS cli:message → ${exists}`);

        // === Numeric Operations ===
        console.log('\n2. 🔢 Numeric Operations:');
        
        await client.set('cli:views', '1000');
        console.log('   SET cli:views 1000');
        
        const incr1 = await client.incr('cli:views');
        console.log(`   INCR cli:views → ${incr1}`);
        
        const incr10 = await client.incrBy('cli:views', 10);
        console.log(`   INCRBY cli:views 10 → ${incr10}`);
        
        const decr5 = await client.decrBy('cli:views', 5);
        console.log(`   DECRBY cli:views 5 → ${decr5}`);

        // === Expiration Operations ===
        console.log('\n3. ⏰ Expiration Operations:');
        
        await client.setEx('cli:session', 30, 'user123_session_data');
        console.log('   SETEX cli:session 30 "user123_session_data"');
        
        const ttl = await client.ttl('cli:session');
        console.log(`   TTL cli:session → ${ttl} seconds`);
        
        await client.expire('cli:views', 60);
        console.log('   EXPIRE cli:views 60');
        
        const viewsTtl = await client.ttl('cli:views');
        console.log(`   TTL cli:views → ${viewsTtl} seconds`);

        // === Batch Operations ===
        console.log('\n4. 📦 Batch Operations:');
        
        await client.mSet([
            'cli:user:1', 'john',
            'cli:user:2', 'jane',
            'cli:user:3', 'bob'
        ]);
        console.log('   MSET cli:user:1 "john" cli:user:2 "jane" cli:user:3 "bob"');
        
        const users = await client.mGet(['cli:user:1', 'cli:user:2', 'cli:user:3']);
        console.log(`   MGET cli:user:1 cli:user:2 cli:user:3 → [${users.join(', ')}]`);

        // === Key Pattern Operations ===
        console.log('\n5. 🔍 Key Pattern Operations:');
        
        // Note: KEYS command should be avoided in production, but useful for learning
        const userKeys = await client.keys('cli:user:*');
        console.log(`   KEYS cli:user:* → [${userKeys.join(', ')}]`);
        
        // Better alternative: SCAN (more production-friendly)
        console.log('\n   Using SCAN instead of KEYS (production best practice):');
        const scanResult = await client.scan(0, { MATCH: 'cli:*', COUNT: 100 });
        console.log(`   SCAN 0 MATCH cli:* COUNT 100 → Found ${scanResult.keys.length} keys`);

        // === Database Operations ===
        console.log('\n6. 🗄️ Database Operations:');
        
        const dbSize = await client.dbSize();
        console.log(`   DBSIZE → ${dbSize} keys`);
        
        const randomKey = await client.randomKey();
        console.log(`   RANDOMKEY → ${randomKey}`);

        // === Info Commands ===
        console.log('\n7. ℹ️ Information Commands:');
        
        const memoryInfo = await client.info('memory');
        const usedMemory = memoryInfo.match(/used_memory:(\d+)/);
        if (usedMemory) {
            const memoryMB = (parseInt(usedMemory[1]) / 1024 / 1024).toFixed(2);
            console.log(`   INFO memory → Used: ${memoryMB}MB`);
        }

        // === Cleanup ===
        console.log('\n8. 🧹 Cleanup Operations:');
        
        const deleteCount = await client.del(['cli:message', 'cli:views', 'cli:session']);
        console.log(`   DEL cli:message cli:views cli:session → ${deleteCount} keys deleted`);
        
        // Clean up user keys
        const userDeleteCount = await client.del(userKeys);
        console.log(`   DEL ${userKeys.join(' ')} → ${userDeleteCount} keys deleted`);

        console.log('\n✅ CLI operations demonstration completed!');
        console.log('\n💡 Key Takeaways:');
        console.log('   • JavaScript Redis client mirrors CLI commands closely');
        console.log('   • Use SCAN instead of KEYS in production');
        console.log('   • Batch operations (MGET/MSET) are more efficient');
        console.log('   • Always set appropriate TTL for temporary data');

    } catch (error) {
        console.error('❌ CLI operations error:', error);
    } finally {
        await client.quit();
        console.log('👋 Disconnected from Redis');
    }
}

// Run the CLI operations demo
cliOperations();
EOF

# Create benchmark example
echo "📊 Creating examples/benchmark.js..."
cat > examples/benchmark.js << 'EOF'
// Redis Performance Benchmark
// Tests basic Redis operations performance

import { createClient } from 'redis';

class RedisBenchmark {
    constructor() {
        this.client = null;
        this.results = {};
    }

    async connect() {
        this.client = createClient({ url: 'redis://localhost:6379' });
        await this.client.connect();
        console.log('🔗 Connected to Redis for benchmarking\n');
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
            console.log('👋 Disconnected from Redis');
        }
    }

    async benchmark(operation, iterations, operationFn) {
        console.log(`🏃 Running ${operation} benchmark (${iterations} iterations)...`);
        
        const startTime = Date.now();
        
        for (let i = 0; i < iterations; i++) {
            await operationFn(i);
        }
        
        const endTime = Date.now();
        const duration = endTime - startTime;
        const opsPerSecond = (iterations / (duration / 1000)).toFixed(1);
        
        this.results[operation] = {
            iterations,
            duration,
            opsPerSecond
        };
        
        console.log(`   ✅ ${operation}: ${opsPerSecond} ops/sec (${duration}ms total)\n`);
        return opsPerSecond;
    }

    async runStringBenchmarks() {
        console.log('📝 === STRING OPERATIONS BENCHMARKS ===\n');

        // SET operations
        await this.benchmark('SET', 1000, async (i) => {
            await this.client.set(`bench:string:${i}`, `value_${i}`);
        });

        // GET operations
        await this.benchmark('GET', 1000, async (i) => {
            await this.client.get(`bench:string:${i}`);
        });

        // INCR operations
        await this.benchmark('INCR', 1000, async (i) => {
            await this.client.incr(`bench:counter:${i % 100}`);
        });

        // DEL operations
        await this.benchmark('DEL', 1000, async (i) => {
            await this.client.del(`bench:string:${i}`);
        });
    }

    async runBatchBenchmarks() {
        console.log('📦 === BATCH OPERATIONS BENCHMARKS ===\n');

        // MSET operations (10 keys per operation)
        await this.benchmark('MSET (batch of 10)', 100, async (i) => {
            const keyValues = [];
            for (let j = 0; j < 10; j++) {
                keyValues.push(`bench:batch:${i}:${j}`, `batch_value_${i}_${j}`);
            }
            await this.client.mSet(keyValues);
        });

        // MGET operations (10 keys per operation)
        await this.benchmark('MGET (batch of 10)', 100, async (i) => {
            const keys = [];
            for (let j = 0; j < 10; j++) {
                keys.push(`bench:batch:${i}:${j}`);
            }
            await this.client.mGet(keys);
        });

        // Cleanup batch keys
        console.log('🧹 Cleaning up batch test keys...');
        const batchKeys = [];
        for (let i = 0; i < 100; i++) {
            for (let j = 0; j < 10; j++) {
                batchKeys.push(`bench:batch:${i}:${j}`);
            }
        }
        await this.client.del(batchKeys);
        console.log(`   Cleaned up ${batchKeys.length} keys\n`);
    }

    async runMemoryBenchmark() {
        console.log('💾 === MEMORY USAGE BENCHMARK ===\n');

        const initialInfo = await this.client.info('memory');
        const initialMemory = this.extractMemoryUsage(initialInfo);
        console.log(`📊 Initial memory usage: ${(initialMemory / 1024 / 1024).toFixed(2)}MB`);

        // Create large dataset
        console.log('📈 Creating test dataset (1000 keys with 1KB values)...');
        const largeValue = 'x'.repeat(1024); // 1KB value
        
        for (let i = 0; i < 1000; i++) {
            await this.client.set(`bench:large:${i}`, largeValue);
        }

        const afterInfo = await this.client.info('memory');
        const afterMemory = this.extractMemoryUsage(afterInfo);
        const memoryIncrease = afterMemory - initialMemory;
        
        console.log(`📊 Memory after dataset: ${(afterMemory / 1024 / 1024).toFixed(2)}MB`);
        console.log(`📈 Memory increase: ${(memoryIncrease / 1024 / 1024).toFixed(2)}MB`);
        console.log(`📏 Avg memory per key: ${(memoryIncrease / 1000).toFixed(0)} bytes\n`);

        // Cleanup
        console.log('🧹 Cleaning up memory test keys...');
        const largeKeys = [];
        for (let i = 0; i < 1000; i++) {
            largeKeys.push(`bench:large:${i}`);
        }
        await this.client.del(largeKeys);
        console.log(`   Cleaned up ${largeKeys.length} keys\n`);
    }

    extractMemoryUsage(infoString) {
        const match = infoString.match(/used_memory:(\d+)/);
        return match ? parseInt(match[1]) : 0;
    }

    async runConnectionBenchmark() {
        console.log('🔗 === CONNECTION BENCHMARK ===\n');

        console.log('🏃 Testing PING latency (100 pings)...');
        const pingTimes = [];
        
        for (let i = 0; i < 100; i++) {
            const start = Date.now();
            await this.client.ping();
            const latency = Date.now() - start;
            pingTimes.push(latency);
        }
        
        const avgLatency = (pingTimes.reduce((a, b) => a + b, 0) / pingTimes.length).toFixed(2);
        const minLatency = Math.min(...pingTimes);
        const maxLatency = Math.max(...pingTimes);
        
        console.log(`   📊 Average latency: ${avgLatency}ms`);
        console.log(`   📊 Min latency: ${minLatency}ms`);
        console.log(`   📊 Max latency: ${maxLatency}ms\n`);
    }

    generateReport() {
        console.log('📋 === BENCHMARK REPORT ===\n');
        
        console.log('🏆 Performance Summary:');
        for (const [operation, result] of Object.entries(this.results)) {
            console.log(`   ${operation}: ${result.opsPerSecond} ops/sec`);
        }
        
        console.log('\n💡 Performance Insights:');
        if (this.results['GET'] && this.results['SET']) {
            const getRatio = parseFloat(this.results['GET'].opsPerSecond) / parseFloat(this.results['SET'].opsPerSecond);
            console.log(`   • GET operations are ${getRatio.toFixed(1)}x faster than SET operations`);
        }
        
        if (this.results['MGET (batch of 10)'] && this.results['GET']) {
            const batchRatio = parseFloat(this.results['MGET (batch of 10)'].opsPerSecond) * 10 / parseFloat(this.results['GET'].opsPerSecond);
            console.log(`   • Batch MGET is ${batchRatio.toFixed(1)}x more efficient than individual GETs`);
        }
        
        console.log('\n📝 Recommendations:');
        console.log('   • Use batch operations (MGET/MSET) when possible');
        console.log('   • Monitor memory usage with large datasets');
        console.log('   • Consider pipelining for high-throughput scenarios');
        console.log('   • Use appropriate data structures for your use case');
    }
}

async function runBenchmarks() {
    const benchmark = new RedisBenchmark();
    
    try {
        await benchmark.connect();
        
        await benchmark.runStringBenchmarks();
        await benchmark.runBatchBenchmarks();
        await benchmark.runMemoryBenchmark();
        await benchmark.runConnectionBenchmark();
        
        benchmark.generateReport();
        
    } catch (error) {
        console.error('❌ Benchmark error:', error);
    } finally {
        await benchmark.disconnect();
    }
}

// Run benchmarks
runBenchmarks();
EOF

# Create RESP protocol example
echo "🌐 Creating examples/resp-protocol.js..."
cat > examples/resp-protocol.js << 'EOF'
// RESP Protocol Demonstration
// Shows how JavaScript commands translate to Redis RESP protocol

import { createClient } from 'redis';
import net from 'net';

class RESPDemo {
    constructor() {
        this.client = null;
        this.rawSocket = null;
        this.responses = [];
    }

    async connect() {
        // Regular Redis client
        this.client = createClient({ url: 'redis://localhost:6379' });
        await this.client.connect();
        
        // Raw TCP socket for RESP demonstration
        this.rawSocket = new net.Socket();
        await new Promise((resolve, reject) => {
            this.rawSocket.connect(6379, 'localhost', resolve);
            this.rawSocket.on('error', reject);
        });
        
        console.log('🔗 Connected to Redis for RESP protocol demo\n');
    }

    async disconnect() {
        if (this.client) await this.client.quit();
        if (this.rawSocket) this.rawSocket.destroy();
        console.log('👋 Disconnected from Redis');
    }

    // Convert JavaScript command to RESP format
    toRESP(command, ...args) {
        const parts = [command, ...args];
        let resp = `*${parts.length}\r\n`;
        
        for (const part of parts) {
            const str = String(part);
            resp += `$${str.length}\r\n${str}\r\n`;
        }
        
        return resp;
    }

    // Parse RESP response
    parseRESP(data) {
        const str = data.toString();
        
        if (str.startsWith('+')) {
            return { type: 'Simple String', value: str.slice(1, -2) };
        } else if (str.startsWith('-')) {
            return { type: 'Error', value: str.slice(1, -2) };
        } else if (str.startsWith(':')) {
            return { type: 'Integer', value: parseInt(str.slice(1, -2)) };
        } else if (str.startsWith('$')) {
            const lines = str.split('\r\n');
            const length = parseInt(lines[0].slice(1));
            if (length === -1) {
                return { type: 'Null Bulk String', value: null };
            }
            return { type: 'Bulk String', value: lines[1] };
        } else if (str.startsWith('*')) {
            return { type: 'Array', value: 'Array parsing not implemented in this demo' };
        }
        
        return { type: 'Unknown', value: str };
    }

    async sendRawCommand(command, ...args) {
        const respCommand = this.toRESP(command, ...args);
        
        console.log(`📤 Sending RESP command:`);
        console.log(`   Raw: ${JSON.stringify(respCommand)}`);
        console.log(`   Formatted:`);
        console.log(respCommand.split('\r\n').map(line => `     ${line}`).join('\n'));
        
        return new Promise((resolve) => {
            this.rawSocket.once('data', (data) => {
                const parsed = this.parseRESP(data);
                console.log(`📥 Received RESP response:`);
                console.log(`   Raw: ${JSON.stringify(data.toString())}`);
                console.log(`   Parsed: ${parsed.type} = "${parsed.value}"`);
                console.log('');
                resolve(parsed);
            });
            
            this.rawSocket.write(respCommand);
        });
    }

    async demonstrateBasicCommands() {
        console.log('🔤 === BASIC RESP COMMANDS ===\n');

        // PING command
        console.log('1. PING Command:');
        await this.sendRawCommand('PING');

        // SET command
        console.log('2. SET Command:');
        await this.sendRawCommand('SET', 'resp:demo', 'Hello RESP!');

        // GET command
        console.log('3. GET Command:');
        await this.sendRawCommand('GET', 'resp:demo');

        // INCR command
        console.log('4. INCR Command:');
        await this.sendRawCommand('SET', 'resp:counter', '0');
        await this.sendRawCommand('INCR', 'resp:counter');
    }

    async demonstrateDataTypes() {
        console.log('📊 === RESP DATA TYPES ===\n');

        console.log('1. Simple String Response (+):');
        await this.sendRawCommand('PING');

        console.log('2. Integer Response (:):');
        await this.sendRawCommand('INCR', 'resp:counter');

        console.log('3. Bulk String Response ($):');
        await this.sendRawCommand('GET', 'resp:demo');

        console.log('4. Null Response ($-1):');
        await this.sendRawCommand('GET', 'resp:nonexistent');

        console.log('5. Error Response (-):');
        await this.sendRawCommand('INCR', 'resp:demo'); // This will error
    }

    async compareWithJavaScript() {
        console.log('⚖️ === JAVASCRIPT VS RESP COMPARISON ===\n');

        console.log('1. JavaScript Redis Client:');
        console.log('   Code: await client.set("js:key", "value")');
        const jsResult = await this.client.set('js:key', 'value');
        console.log(`   Result: "${jsResult}"`);
        console.log('');

        console.log('2. Raw RESP Protocol:');
        console.log('   Code: sendRawCommand("SET", "resp:key", "value")');
        const respResult = await this.sendRawCommand('SET', 'resp:key', 'value');

        console.log('💡 Observation:');
        console.log('   • JavaScript client abstracts RESP protocol details');
        console.log('   • Both methods achieve the same result');
        console.log('   • RESP shows the actual wire protocol');
        console.log('   • JavaScript client handles response parsing automatically\n');
    }

    async demonstratePipelining() {
        console.log('🚀 === PIPELINING CONCEPT ===\n');

        console.log('Sequential commands (what we\'ve been doing):');
        console.log('   Client → Server: SET key1 value1');
        console.log('   Server → Client: +OK');
        console.log('   Client → Server: SET key2 value2');
        console.log('   Server → Client: +OK');
        console.log('   Total round trips: 2\n');

        console.log('Pipelined commands (more efficient):');
        console.log('   Client → Server: SET key1 value1, SET key2 value2');
        console.log('   Server → Client: +OK, +OK');
        console.log('   Total round trips: 1\n');

        console.log('🔧 JavaScript Pipelining Example:');
        const pipeline = this.client.multi();
        pipeline.set('pipe:1', 'value1');
        pipeline.set('pipe:2', 'value2');
        pipeline.incr('pipe:counter');
        
        console.log('   Code: client.multi().set().set().incr().exec()');
        const results = await pipeline.exec();
        console.log(`   Results: [${results.map(r => `"${r}"`).join(', ')}]`);
    }

    generateRESPReference() {
        console.log('📚 === RESP PROTOCOL REFERENCE ===\n');
        
        console.log('RESP Data Types:');
        console.log('   + Simple Strings  → +OK\\r\\n');
        console.log('   - Errors          → -ERR unknown command\\r\\n');
        console.log('   : Integers        → :42\\r\\n');
        console.log('   $ Bulk Strings    → $5\\r\\nhello\\r\\n');
        console.log('   * Arrays          → *2\\r\\n$3\\r\\nfoo\\r\\n$3\\r\\nbar\\r\\n');
        console.log('');
        
        console.log('Command Format:');
        console.log('   *<number-of-arguments>\\r\\n');
        console.log('   $<number-of-bytes-of-argument-1>\\r\\n');
        console.log('   <argument-1-data>\\r\\n');
        console.log('   ...');
        console.log('   $<number-of-bytes-of-argument-N>\\r\\n');
        console.log('   <argument-N-data>\\r\\n');
        console.log('');
        
        console.log('Examples:');
        console.log('   SET key value:');
        console.log('   *3\\r\\n$3\\r\\nSET\\r\\n$3\\r\\nkey\\r\\n$5\\r\\nvalue\\r\\n');
        console.log('');
        console.log('   GET key:');
        console.log('   *2\\r\\n$3\\r\\nGET\\r\\n$3\\r\\nkey\\r\\n');
    }
}

async function runRESPDemo() {
    const demo = new RESPDemo();
    
    try {
        await demo.connect();
        
        await demo.demonstrateBasicCommands();
        await demo.demonstrateDataTypes();
        await demo.compareWithJavaScript();
        await demo.demonstratePipelining();
        
        demo.generateRESPReference();
        
        console.log('\n✅ RESP protocol demonstration completed!');
        console.log('\n🎓 Key Learning Points:');
        console.log('   • RESP is Redis\'s wire protocol');
        console.log('   • JavaScript client abstracts RESP complexity');
        console.log('   • Understanding RESP helps with debugging');
        console.log('   • Pipelining reduces network round trips');
        console.log('   • All Redis data types map to RESP format');
        
    } catch (error) {
        console.error('❌ RESP demo error:', error);
    } finally {
        await demo.disconnect();
    }
}

// Run RESP demonstration
runRESPDemo();
EOF

# Create setup check script
echo "✅ Creating scripts/setup-check.js..."
cat > scripts/setup-check.js << 'EOF'
// Redis Setup Verification Script
// Checks if Redis environment is properly configured

import { createClient } from 'redis';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class SetupChecker {
    constructor() {
        this.checks = [];
        this.client = null;
    }

    async checkDocker() {
        try {
            const { stdout } = await execAsync('docker --version');
            this.checks.push({
                name: 'Docker Installation',
                status: 'PASS',
                details: stdout.trim()
            });
        } catch (error) {
            this.checks.push({
                name: 'Docker Installation',
                status: 'FAIL',
                details: 'Docker not found. Please install Docker.',
                error: error.message
            });
        }
    }

    async checkRedisContainer() {
        try {
            const { stdout } = await execAsync('docker ps --filter "name=redis" --format "table {{.Names}}\\t{{.Status}}"');
            
            if (stdout.includes('redis')) {
                this.checks.push({
                    name: 'Redis Container',
                    status: 'PASS',
                    details: 'Redis container is running'
                });
            } else {
                this.checks.push({
                    name: 'Redis Container',
                    status: 'WARN',
                    details: 'Redis container not found. Try: docker run -d --name redis -p 6379:6379 redis:latest'
                });
            }
        } catch (error) {
            this.checks.push({
                name: 'Redis Container',
                status: 'FAIL',
                details: 'Unable to check Docker containers',
                error: error.message
            });
        }
    }

    async checkRedisConnection() {
        try {
            this.client = createClient({ url: 'redis://localhost:6379' });
            
            // Set a timeout for connection
            const connectionTimeout = new Promise((_, reject) => {
                setTimeout(() => reject(new Error('Connection timeout')), 5000);
            });
            
            await Promise.race([this.client.connect(), connectionTimeout]);
            
            const pong = await this.client.ping();
            
            if (pong === 'PONG') {
                this.checks.push({
                    name: 'Redis Connection',
                    status: 'PASS',
                    details: 'Successfully connected to Redis on localhost:6379'
                });
            } else {
                this.checks.push({
                    name: 'Redis Connection',
                    status: 'FAIL',
                    details: `Unexpected PING response: ${pong}`
                });
            }
        } catch (error) {
            this.checks.push({
                name: 'Redis Connection',
                status: 'FAIL',
                details: 'Cannot connect to Redis on localhost:6379',
                error: error.message
            });
        }
    }

    async checkRedisInsight() {
        try {
            // Since Redis Insight is installed locally, we'll check if it's accessible
            // by looking for common installation paths or process
            const { stdout: processes } = await execAsync('tasklist /FI "IMAGENAME eq RedisInsight*" 2>nul || ps aux | grep -i redisinsight | grep -v grep || echo "not_running"');
            
            if (processes.includes('RedisInsight') || processes.includes('redisinsight')) {
                this.checks.push({
                    name: 'Redis Insight',
                    status: 'PASS',
                    details: 'Redis Insight is installed and may be running'
                });
            } else {
                this.checks.push({
                    name: 'Redis Insight',
                    status: 'INFO',
                    details: 'Redis Insight should be installed on your machine. Launch it from your applications menu.'
                });
            }
        } catch (error) {
            this.checks.push({
                name: 'Redis Insight',
                status: 'INFO',
                details: 'Please ensure Redis Insight is installed and launch it from your applications menu.',
                error: 'Could not detect Redis Insight process'
            });
        }
    }

    async checkNodeDependencies() {
        try {
            // Check if redis package is installed
            const redis = await import('redis');
            
            this.checks.push({
                name: 'Node.js Redis Package',
                status: 'PASS',
                details: 'Redis npm package is installed and importable'
            });
        } catch (error) {
            this.checks.push({
                name: 'Node.js Redis Package',
                status: 'FAIL',
                details: 'Redis npm package not found. Run: npm install',
                error: error.message
            });
        }
    }

    async checkRedisCommands() {
        if (!this.client) {
            this.checks.push({
                name: 'Redis Commands Test',
                status: 'SKIP',
                details: 'Skipped due to connection failure'
            });
            return;
        }

        try {
            // Test basic commands
            await this.client.set('setup:test', 'success');
            const result = await this.client.get('setup:test');
            await this.client.del('setup:test');
            
            if (result === 'success') {
                this.checks.push({
                    name: 'Redis Commands Test',
                    status: 'PASS',
                    details: 'Basic Redis commands (SET, GET, DEL) working correctly'
                });
            } else {
                this.checks.push({
                    name: 'Redis Commands Test',
                    status: 'FAIL',
                    details: `SET/GET test failed. Expected 'success', got '${result}'`
                });
            }
        } catch (error) {
            this.checks.push({
                name: 'Redis Commands Test',
                status: 'FAIL',
                details: 'Redis commands not working properly',
                error: error.message
            });
        }
    }

    async runAllChecks() {
        console.log('🔍 Running Redis Lab Environment Setup Check...\n');

        await this.checkDocker();
        await this.checkRedisContainer();
        await this.checkRedisConnection();
        await this.checkRedisInsight();
        await this.checkNodeDependencies();
        await this.checkRedisCommands();

        this.displayResults();
        this.displayRecommendations();
    }

    displayResults() {
        console.log('📋 === SETUP CHECK RESULTS ===\n');

        for (const check of this.checks) {
            const statusEmoji = {
                'PASS': '✅',
                'WARN': '⚠️',
                'FAIL': '❌',
                'SKIP': '⏭️'
            };

            console.log(`${statusEmoji[check.status]} ${check.name}: ${check.status}`);
            console.log(`   ${check.details}`);
            
            if (check.error) {
                console.log(`   Error: ${check.error}`);
            }
            console.log('');
        }
    }

    displayRecommendations() {
        const failures = this.checks.filter(check => check.status === 'FAIL');
        const warnings = this.checks.filter(check => check.status === 'WARN');

        if (failures.length === 0 && warnings.length === 0) {
            console.log('🎉 === ALL CHECKS PASSED ===');
            console.log('Your Redis lab environment is ready!');
            console.log('\n🚀 Next Steps:');
            console.log('   1. Open VS Code in this directory: code .');
            console.log('   2. Start the lab: npm start');
            console.log('   3. Launch Redis Insight from your applications');
            console.log('   4. Follow the lab instructions in lab1.md');
        } else {
            console.log('🔧 === SETUP RECOMMENDATIONS ===\n');

            if (failures.length > 0) {
                console.log('❌ Critical Issues (must fix):');
                for (const failure of failures) {
                    console.log(`   • ${failure.name}: ${failure.details}`);
                }
                console.log('');
            }

            if (warnings.length > 0) {
                console.log('⚠️ Optional Issues (recommended to fix):');
                for (const warning of warnings) {
                    console.log(`   • ${warning.name}: ${warning.details}`);
                }
                console.log('');
            }

            console.log('🛠️ Common Solutions:');
            console.log('   • Install Docker: https://docs.docker.com/get-docker/');
            console.log('   • Start Redis: docker run -d --name redis -p 6379:6379 redis:latest');
            console.log('   • Install dependencies: npm install');
            console.log('   • Install Redis Insight: Download from https://redis.io/insight/');
        }
    }

    async cleanup() {
        if (this.client) {
            await this.client.quit();
        }
    }
}

async function runSetupCheck() {
    const checker = new SetupChecker();
    
    try {
        await checker.runAllChecks();
    } catch (error) {
        console.error('❌ Setup check error:', error);
    } finally {
        await checker.cleanup();
    }
}

// Run setup check
runSetupCheck();
EOF

# Create test connection script
echo "🧪 Creating scripts/test-connection.js..."
cat > scripts/test-connection.js << 'EOF'
// Redis Connection Test Script
// Quick verification that Redis connection is working

import { RedisConnection } from '../redis-connection.js';

async function testConnection() {
    console.log('🔗 Testing Redis Connection...\n');
    
    const redis = new RedisConnection();
    
    try {
        // Connect
        await redis.connect();
        console.log('✅ Connection established successfully\n');
        
        // Get server information
        const info = await redis.getServerInfo();
        
        console.log('📊 Server Info:');
        console.log(`   Redis Version: ${info.server.redis_version}`);
        console.log(`   Connected Clients: ${info.stats.connected_clients}`);
        console.log(`   Used Memory: ${(info.memory.used_memory / 1024 / 1024).toFixed(2)}MB`);
        console.log(`   Total Commands: ${info.stats.total_commands_processed}`);
        
        // Test basic operations
        console.log('\n🧪 Testing basic operations...');
        await redis.client.set('test:connection', 'success');
        const result = await redis.client.get('test:connection');
        await redis.client.del('test:connection');
        
        if (result === 'success') {
            console.log('✅ Basic operations working correctly');
        } else {
            console.log('❌ Basic operations failed');
        }
        
        console.log('\n✅ Connection test completed successfully!');
        
    } catch (error) {
        console.error('❌ Connection test failed:', error);
        console.log('\n🔧 Troubleshooting:');
        console.log('   • Ensure Redis is running: docker ps | grep redis');
        console.log('   • Check Redis logs: docker logs redis');
        console.log('   • Verify port 6379 is available: netstat -an | grep 6379');
        process.exit(1);
    } finally {
        await redis.disconnect();
    }
}

testConnection();
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes  
**Focus:** Redis environment setup and basic command-line operations

## 📁 Project Structure

```
lab1-redis-environment/
├── lab1.md                     # Complete lab instructions (START HERE)
├── package.json                # Node.js project configuration
├── redis-connection.js         # Redis client connection module
├── examples/
│   ├── cli-operations.js       # CLI command demonstrations
│   ├── benchmark.js            # Performance benchmarking
│   └── resp-protocol.js        # RESP protocol exploration
├── scripts/
│   ├── setup-check.js          # Environment verification
│   └── test-connection.js      # Connection testing
├── docs/                       # Additional documentation
└── README.md                   # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab1.md` for complete lab guidance
2. **Check Setup:** `npm run setup`
3. **Test Connection:** `npm run test`
4. **Start Lab:** `npm start`

## 📝 Available Scripts

- `npm start` - Run main Redis connection demo
- `npm run cli` - Demonstrate CLI operations
- `npm run benchmark` - Run performance benchmarks
- `npm run resp` - Explore RESP protocol
- `npm run test` - Test Redis connection
- `npm run setup` - Verify environment setup

## 🎯 Lab Objectives

✅ Master Redis CLI and Redis Insight navigation  
✅ Understand RESP protocol communication  
✅ Implement JavaScript Redis client operations  
✅ Perform basic performance benchmarking  
✅ Learn key management and TTL strategies

## 🔗 Resources

- **Lab Instructions:** `lab1.md`
- **Redis Insight:** Launch from your applications menu
- **Redis CLI:** `redis-cli`
- **Documentation:** `/docs` folder

## 🆘 Troubleshooting

**Connection Issues:**
```bash
# Check if Redis is running
docker ps | grep redis

# Start Redis if needed
docker run -d --name redis -p 6379:6379 redis:latest

# Test connection
redis-cli ping
```

**Environment Issues:**
```bash
# Verify setup
npm run setup

# Check detailed connection
npm run test
```

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. **Lab 1:** Environment & CLI Basics ← *You are here*
2. **Lab 2:** String Operations & Counters
3. **Lab 3:** Key Management & Patterns
4. **Lab 4:** Basic Caching Implementation
5. **Lab 5:** Web API Integration

---

**Ready to start?** Open `lab1.md` and begin your Redis journey! 🚀
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs generated by jscoverage/JSCover
lib-cov

# Coverage directory used by tools like istanbul
coverage
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage (https://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# Bower dependency directory (https://bower.io/)
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons (https://nodejs.org/api/addons.html)
build/Release

# Dependency directories
node_modules/
jspm_packages/

# TypeScript v1 declaration files
typings/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
public

# Vuepress build output
.vuepress/dist

# Serverless directories
.serverless/

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab1.md                     📋 START HERE - Complete lab guide"
echo "   ├── package.json                📦 Project configuration"
echo "   ├── redis-connection.js         🔗 Redis connection module"
echo "   ├── examples/"
echo "   │   ├── cli-operations.js       ⚡ CLI operations demo"
echo "   │   ├── benchmark.js            📊 Performance benchmarking"
echo "   │   └── resp-protocol.js        🌐 RESP protocol exploration"
echo "   ├── scripts/"
echo "   │   ├── setup-check.js          ✅ Environment verification"
echo "   │   └── test-connection.js      🧪 Connection testing"
echo "   ├── docs/                       📚 Documentation"
echo "   ├── README.md                   📖 Project documentation"
echo "   ├── .gitignore                  🚫 Git ignore rules"
echo "   └── node_modules/               📁 Dependencies"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                       # Open in VS Code"
echo "   3. Read lab1.md                 # Follow complete lab guide"
echo "   4. npm run setup                # Verify environment"
echo "   5. npm start                    # Run basic operations"
echo ""
echo "🌐 RESOURCES:"
echo "   📋 Complete Lab Guide: lab1.md"
echo "   🌐 Redis Insight: Launch from applications menu"
echo "   ⚡ Redis CLI: redis-cli"
echo "   📚 Project Docs: README.md"
echo ""
echo "🏆 LAB OBJECTIVES:"
echo "   ✅ Master Redis CLI and Redis Insight"
echo "   ✅ Understand RESP protocol"
echo "   ✅ JavaScript Redis client operations"
echo "   ✅ Performance benchmarking"
echo "   ✅ Key management and TTL strategies"
echo ""
echo "🎉 READY TO START LAB 1!"
echo "   Open lab1.md for the complete 45-minute guided experience!"