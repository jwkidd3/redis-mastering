/**
 * Comprehensive Test Suite - All Student Operations
 * Tests EVERY operation students will perform throughout the course
 */

const TestUtils = require('./test-utils');
const testUtils = new TestUtils();

/**
 * Test ALL Lab 1 student operations
 */
async function testLab1StudentOperations() {
    console.log('\n=== Lab 1: Student Operations Test ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Clean database for accurate KEYS test
        await testUtils.redisClient.flushDb();

        // Student Operation 1: PING
        const ping = await testUtils.redisClient.ping();
        if (ping === 'PONG') {
            console.log('✓ PING command');
            passed++;
        } else {
            console.log('✗ PING command');
            failed++;
        }

        // Student Operation 2: SET
        await testUtils.redisClient.set('insurance:greeting', 'Welcome to Redis');
        console.log('✓ SET command');
        passed++;

        // Student Operation 3: GET
        const val = await testUtils.redisClient.get('insurance:greeting');
        if (val === 'Welcome to Redis') {
            console.log('✓ GET command');
            passed++;
        } else {
            console.log('✗ GET command');
            failed++;
        }

        // Student Operation 4: Multiple SETs
        await testUtils.redisClient.set('policy:1', 'AUTO');
        await testUtils.redisClient.set('policy:2', 'HOME');
        await testUtils.redisClient.set('policy:3', 'LIFE');
        console.log('✓ Multiple SET commands');
        passed++;

        // Student Operation 5: KEYS pattern
        const keys = await testUtils.redisClient.keys('policy:*');
        if (keys.length === 3) {
            console.log('✓ KEYS pattern matching');
            passed++;
        } else {
            console.log('✗ KEYS pattern matching');
            failed++;
        }

        // Student Operation 6: DEL
        await testUtils.redisClient.del('policy:3');
        const deleted = await testUtils.redisClient.get('policy:3');
        if (!deleted) {
            console.log('✓ DEL command');
            passed++;
        } else {
            console.log('✗ DEL command');
            failed++;
        }

        // Student Operation 7: EXISTS
        const exists1 = await testUtils.redisClient.exists('policy:1');
        const exists2 = await testUtils.redisClient.exists('policy:999');
        if (exists1 === 1 && exists2 === 0) {
            console.log('✓ EXISTS command');
            passed++;
        } else {
            console.log('✗ EXISTS command');
            failed++;
        }

        // Student Operation 8: INCR counter
        await testUtils.redisClient.set('counter', '0');
        await testUtils.redisClient.incr('counter');
        await testUtils.redisClient.incr('counter');
        const counter = await testUtils.redisClient.get('counter');
        if (counter === '2') {
            console.log('✓ INCR command');
            passed++;
        } else {
            console.log('✗ INCR command');
            failed++;
        }

        // Student Operation 9: DECR counter
        await testUtils.redisClient.decr('counter');
        const decremented = await testUtils.redisClient.get('counter');
        if (decremented === '1') {
            console.log('✓ DECR command');
            passed++;
        } else {
            console.log('✗ DECR command');
            failed++;
        }

        // Student Operation 10: DBSIZE
        const dbsize = await testUtils.redisClient.dbSize();
        if (dbsize > 0) {
            console.log('✓ DBSIZE command');
            passed++;
        } else {
            console.log('✗ DBSIZE command');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 2 student operations (RESP Protocol)
 */
async function testLab2StudentOperations() {
    console.log('\n=== Lab 2: Student Operations Test (RESP Protocol) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Student Operation 1: PING (Simple String response)
        const ping = await testUtils.redisClient.ping();
        if (ping === 'PONG') {
            console.log('✓ PING command (RESP Simple String)');
            passed++;
        } else {
            console.log('✗ PING command');
            failed++;
        }

        // Student Operation 2: INCR (Integer response)
        await testUtils.redisClient.set('resp:counter', '0');
        const incremented = await testUtils.redisClient.incr('resp:counter');
        if (incremented === 1) {
            console.log('✓ INCR command (RESP Integer)');
            passed++;
        } else {
            console.log('✗ INCR command');
            failed++;
        }

        // Student Operation 3: GET (Bulk String response)
        await testUtils.redisClient.set('resp:message', 'Hello Redis');
        const message = await testUtils.redisClient.get('resp:message');
        if (message === 'Hello Redis') {
            console.log('✓ GET command (RESP Bulk String)');
            passed++;
        } else {
            console.log('✗ GET command');
            failed++;
        }

        // Student Operation 4: LRANGE (Array response)
        await testUtils.redisClient.rPush('resp:list', ['item1', 'item2', 'item3']);
        const list = await testUtils.redisClient.lRange('resp:list', 0, -1);
        if (list.length === 3 && list[0] === 'item1') {
            console.log('✓ LRANGE command (RESP Array)');
            passed++;
        } else {
            console.log('✗ LRANGE command');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 3 student operations (String Operations)
 */
async function testLab3StudentOperations() {
    console.log('\n=== Lab 3: Student Operations Test (String Operations) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Student Operation 1: SET/GET
        await testUtils.redisClient.set('policy:P001', 'AUTO-12345');
        const policy = await testUtils.redisClient.get('policy:P001');
        if (policy === 'AUTO-12345') {
            console.log('✓ SET/GET operations');
            passed++;
        } else {
            console.log('✗ SET/GET operations');
            failed++;
        }

        // Student Operation 2: SETNX
        const set1 = await testUtils.redisClient.setNX('policy:P002', 'HOME-67890');
        const set2 = await testUtils.redisClient.setNX('policy:P002', 'DIFFERENT');
        if (set1 && !set2) {
            console.log('✓ SETNX operation');
            passed++;
        } else {
            console.log('✗ SETNX operation');
            failed++;
        }

        // Student Operation 3: INCR for counters
        await testUtils.redisClient.set('claims:count', '0');
        await testUtils.redisClient.incr('claims:count');
        await testUtils.redisClient.incr('claims:count');
        const count = await testUtils.redisClient.get('claims:count');
        if (count === '2') {
            console.log('✓ INCR operation');
            passed++;
        } else {
            console.log('✗ INCR operation');
            failed++;
        }

        // Student Operation 4: MGET/MSET
        await testUtils.redisClient.mSet({
            'agent:A001': 'John',
            'agent:A002': 'Jane',
            'agent:A003': 'Bob'
        });
        const agents = await testUtils.redisClient.mGet(['agent:A001', 'agent:A002', 'agent:A003']);
        if (agents.length === 3 && agents[0] === 'John') {
            console.log('✓ MGET/MSET operations');
            passed++;
        } else {
            console.log('✗ MGET/MSET operations');
            failed++;
        }

        // Student Operation 5: APPEND
        await testUtils.redisClient.set('notes', 'Initial note');
        await testUtils.redisClient.append('notes', '. Additional info');
        const notes = await testUtils.redisClient.get('notes');
        if (notes === 'Initial note. Additional info') {
            console.log('✓ APPEND operation');
            passed++;
        } else {
            console.log('✗ APPEND operation');
            failed++;
        }

        // Student Operation 6: STRLEN
        const len = await testUtils.redisClient.strLen('notes');
        if (len > 0) {
            console.log('✓ STRLEN operation');
            passed++;
        } else {
            console.log('✗ STRLEN operation');
            failed++;
        }

        // Student Operation 7: GETRANGE
        await testUtils.redisClient.set('text', 'Hello Redis World');
        const range = await testUtils.redisClient.getRange('text', 0, 4);
        if (range === 'Hello') {
            console.log('✓ GETRANGE operation');
            passed++;
        } else {
            console.log('✗ GETRANGE operation');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 5 student operations (Advanced CLI)
 */
async function testLab5StudentOperations() {
    console.log('\n=== Lab 5: Student Operations Test (Advanced CLI) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Student Operation 1: INFO command
        const info = await testUtils.redisClient.info();
        if (info.includes('redis_version')) {
            console.log('✓ INFO command');
            passed++;
        } else {
            console.log('✗ INFO command');
            failed++;
        }

        // Student Operation 2: DBSIZE
        await testUtils.redisClient.set('test:key1', 'value1');
        await testUtils.redisClient.set('test:key2', 'value2');
        const dbsize = await testUtils.redisClient.dbSize();
        if (dbsize >= 2) {
            console.log('✓ DBSIZE command');
            passed++;
        } else {
            console.log('✗ DBSIZE command');
            failed++;
        }

        // Student Operation 3: MEMORY USAGE
        await testUtils.redisClient.set('memory:test', 'test data for memory analysis');
        const memUsage = await testUtils.redisClient.memoryUsage('memory:test');
        if (memUsage > 0) {
            console.log('✓ MEMORY USAGE command');
            passed++;
        } else {
            console.log('✗ MEMORY USAGE command');
            failed++;
        }

        // Student Operation 4: SCAN
        await testUtils.redisClient.set('scan:1', 'val1');
        await testUtils.redisClient.set('scan:2', 'val2');
        const scanResult = await testUtils.redisClient.scan(0, { MATCH: 'scan:*', COUNT: 100 });
        if (scanResult.keys.length >= 2) {
            console.log('✓ SCAN operation');
            passed++;
        } else {
            console.log('✗ SCAN operation');
            failed++;
        }

        // Student Operation 5: Pipeline operations
        const pipeline = testUtils.redisClient.multi();
        pipeline.set('pipeline:1', 'val1');
        pipeline.set('pipeline:2', 'val2');
        pipeline.get('pipeline:1');
        const results = await pipeline.exec();
        if (results && results.length === 3) {
            console.log('✓ Pipeline operations');
            passed++;
        } else {
            console.log('✗ Pipeline operations');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 10 student operations (Caching Patterns)
 */
async function testLab10StudentOperations() {
    console.log('\n=== Lab 10: Student Operations Test (Caching Patterns) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Student Operation 1: Cache-aside pattern (SET with TTL)
        await testUtils.redisClient.setEx('cache:user:123', 300, JSON.stringify({ id: 123, name: 'John' }));
        const cached = await testUtils.redisClient.get('cache:user:123');
        if (cached && JSON.parse(cached).name === 'John') {
            console.log('✓ Cache-aside pattern (SET with TTL)');
            passed++;
        } else {
            console.log('✗ Cache-aside pattern');
            failed++;
        }

        // Student Operation 2: Cache invalidation (DEL)
        await testUtils.redisClient.set('cache:item:456', 'data');
        await testUtils.redisClient.del('cache:item:456');
        const deleted = await testUtils.redisClient.get('cache:item:456');
        if (!deleted) {
            console.log('✓ Cache invalidation (DEL)');
            passed++;
        } else {
            console.log('✗ Cache invalidation');
            failed++;
        }

        // Student Operation 3: Pattern-based invalidation (KEYS + DEL)
        await testUtils.redisClient.set('cache:product:1', 'p1');
        await testUtils.redisClient.set('cache:product:2', 'p2');
        await testUtils.redisClient.set('cache:product:3', 'p3');
        const keysToDelete = await testUtils.redisClient.keys('cache:product:*');
        if (keysToDelete.length > 0) {
            await testUtils.redisClient.del(keysToDelete);
            console.log('✓ Pattern-based invalidation');
            passed++;
        } else {
            console.log('✗ Pattern-based invalidation');
            failed++;
        }

        // Student Operation 4: TTL verification
        await testUtils.redisClient.setEx('cache:temp', 60, 'temporary');
        const ttl = await testUtils.redisClient.ttl('cache:temp');
        if (ttl > 0 && ttl <= 60) {
            console.log('✓ TTL verification');
            passed++;
        } else {
            console.log('✗ TTL verification');
            failed++;
        }

        // Student Operation 5: Write-through cache (SET + expire)
        await testUtils.redisClient.set('cache:order:789', JSON.stringify({ id: 789, total: 100 }));
        await testUtils.redisClient.expire('cache:order:789', 600);
        const order = await testUtils.redisClient.get('cache:order:789');
        const orderTtl = await testUtils.redisClient.ttl('cache:order:789');
        if (order && orderTtl > 0) {
            console.log('✓ Write-through cache');
            passed++;
        } else {
            console.log('✗ Write-through cache');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 4 student operations (TTL & Expiration)
 */
async function testLab4StudentOperations() {
    console.log('\n=== Lab 4: Student Operations Test (TTL) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Student Operation 1: EXPIRE
        await testUtils.redisClient.set('session:temp', 'data');
        await testUtils.redisClient.expire('session:temp', 60);
        const ttl = await testUtils.redisClient.ttl('session:temp');
        if (ttl > 0 && ttl <= 60) {
            console.log('✓ EXPIRE command');
            passed++;
        } else {
            console.log('✗ EXPIRE command');
            failed++;
        }

        // Student Operation 2: TTL
        if (ttl > 0) {
            console.log('✓ TTL command');
            passed++;
        } else {
            console.log('✗ TTL command');
            failed++;
        }

        // Student Operation 3: SETEX
        await testUtils.redisClient.setEx('session:user123', 300, 'session-data');
        const setexTtl = await testUtils.redisClient.ttl('session:user123');
        if (setexTtl > 0 && setexTtl <= 300) {
            console.log('✓ SETEX command');
            passed++;
        } else {
            console.log('✗ SETEX command');
            failed++;
        }

        // Student Operation 4: PERSIST
        await testUtils.redisClient.persist('session:user123');
        const persistTtl = await testUtils.redisClient.ttl('session:user123');
        if (persistTtl === -1) {
            console.log('✓ PERSIST command');
            passed++;
        } else {
            console.log('✗ PERSIST command');
            failed++;
        }

        // Student Operation 5: PEXPIRE (milliseconds)
        await testUtils.redisClient.set('temp', 'value');
        await testUtils.redisClient.pExpire('temp', 5000);
        const pttl = await testUtils.redisClient.pTTL('temp');
        if (pttl > 0) {
            console.log('✓ PEXPIRE/PTTL command');
            passed++;
        } else {
            console.log('✗ PEXPIRE/PTTL command');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 7 student operations (Hashes)
 */
async function testLab7StudentOperations() {
    console.log('\n=== Lab 7: Student Operations Test (Hashes) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Student Operation 1: HSET
        await testUtils.redisClient.hSet('customer:C001', 'name', 'John Doe');
        await testUtils.redisClient.hSet('customer:C001', 'email', 'john@example.com');
        await testUtils.redisClient.hSet('customer:C001', 'age', '35');
        console.log('✓ HSET command');
        passed++;

        // Student Operation 2: HGET
        const name = await testUtils.redisClient.hGet('customer:C001', 'name');
        if (name === 'John Doe') {
            console.log('✓ HGET command');
            passed++;
        } else {
            console.log('✗ HGET command');
            failed++;
        }

        // Student Operation 3: HGETALL
        const customer = await testUtils.redisClient.hGetAll('customer:C001');
        if (customer.name === 'John Doe' && customer.email === 'john@example.com') {
            console.log('✓ HGETALL command');
            passed++;
        } else {
            console.log('✗ HGETALL command');
            failed++;
        }

        // Student Operation 4: HMGET
        const fields = await testUtils.redisClient.hmGet('customer:C001', ['name', 'email']);
        if (fields[0] === 'John Doe' && fields[1] === 'john@example.com') {
            console.log('✓ HMGET command');
            passed++;
        } else {
            console.log('✗ HMGET command');
            failed++;
        }

        // Student Operation 5: HINCRBY
        await testUtils.redisClient.hSet('customer:C001', 'orders', '10');
        await testUtils.redisClient.hIncrBy('customer:C001', 'orders', 5);
        const orders = await testUtils.redisClient.hGet('customer:C001', 'orders');
        if (orders === '15') {
            console.log('✓ HINCRBY command');
            passed++;
        } else {
            console.log('✗ HINCRBY command');
            failed++;
        }

        // Student Operation 6: HEXISTS
        const exists = await testUtils.redisClient.hExists('customer:C001', 'name');
        const notExists = await testUtils.redisClient.hExists('customer:C001', 'nonexistent');
        if (exists && !notExists) {
            console.log('✓ HEXISTS command');
            passed++;
        } else {
            console.log('✗ HEXISTS command');
            failed++;
        }

        // Student Operation 7: HDEL
        await testUtils.redisClient.hDel('customer:C001', 'age');
        const deleted = await testUtils.redisClient.hExists('customer:C001', 'age');
        if (!deleted) {
            console.log('✓ HDEL command');
            passed++;
        } else {
            console.log('✗ HDEL command');
            failed++;
        }

        // Student Operation 8: HLEN
        const len = await testUtils.redisClient.hLen('customer:C001');
        if (len === 3) { // name, email, orders
            console.log('✓ HLEN command');
            passed++;
        } else {
            console.log('✗ HLEN command');
            failed++;
        }

        // Student Operation 9: HKEYS
        const keys = await testUtils.redisClient.hKeys('customer:C001');
        if (keys.includes('name') && keys.includes('email')) {
            console.log('✓ HKEYS command');
            passed++;
        } else {
            console.log('✗ HKEYS command');
            failed++;
        }

        // Student Operation 10: HVALS
        const vals = await testUtils.redisClient.hVals('customer:C001');
        if (vals.includes('John Doe')) {
            console.log('✓ HVALS command');
            passed++;
        } else {
            console.log('✗ HVALS command');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 8 student operations (Streams)
 */
async function testLab8StudentOperations() {
    console.log('\n=== Lab 8: Student Operations Test (Streams) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        const streamKey = 'claims:events';

        // Student Operation 1: XADD
        const id1 = await testUtils.redisClient.xAdd(streamKey, '*', {
            event: 'claim.submitted',
            claim_id: 'CLM-001',
            amount: '1000'
        });
        if (id1) {
            console.log('✓ XADD command');
            passed++;
        } else {
            console.log('✗ XADD command');
            failed++;
        }

        // Student Operation 2: XLEN
        const len = await testUtils.redisClient.xLen(streamKey);
        if (len >= 1) {
            console.log('✓ XLEN command');
            passed++;
        } else {
            console.log('✗ XLEN command');
            failed++;
        }

        // Student Operation 3: XRANGE
        const messages = await testUtils.redisClient.xRange(streamKey, '-', '+');
        if (messages.length >= 1) {
            console.log('✓ XRANGE command');
            passed++;
        } else {
            console.log('✗ XRANGE command');
            failed++;
        }

        // Student Operation 4: XREAD
        const read = await testUtils.redisClient.xRead({ key: streamKey, id: '0' });
        if (read && read.length > 0) {
            console.log('✓ XREAD command');
            passed++;
        } else {
            console.log('✗ XREAD command');
            failed++;
        }

        // Student Operation 5: XGROUP CREATE
        try {
            await testUtils.redisClient.xGroupCreate(streamKey, 'processors', '0', {
                MKSTREAM: true
            });
            console.log('✓ XGROUP CREATE command');
            passed++;
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                console.log('✓ XGROUP CREATE command (group exists)');
                passed++;
            } else {
                console.log('✗ XGROUP CREATE command');
                failed++;
            }
        }

        // Student Operation 6: XREADGROUP
        const groupRead = await testUtils.redisClient.xReadGroup(
            'processors',
            'consumer-1',
            [{ key: streamKey, id: '>' }],
            { COUNT: 10 }
        );
        console.log('✓ XREADGROUP command');
        passed++;

        // Student Operation 7: XINFO STREAM
        const info = await testUtils.redisClient.xInfoStream(streamKey);
        if (info.length > 0) {
            console.log('✓ XINFO STREAM command');
            passed++;
        } else {
            console.log('✗ XINFO STREAM command');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Test ALL Lab 9 student operations (Sets & Sorted Sets)
 */
async function testLab9StudentOperations() {
    console.log('\n=== Lab 9: Student Operations Test (Sets & Sorted Sets) ===\n');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Sets Operations
        // Student Operation 1: SADD
        await testUtils.redisClient.sAdd('customers:auto', ['C001', 'C002', 'C003']);
        await testUtils.redisClient.sAdd('customers:home', ['C002', 'C003', 'C004']);
        console.log('✓ SADD command');
        passed++;

        // Student Operation 2: SMEMBERS
        const members = await testUtils.redisClient.sMembers('customers:auto');
        if (members.length === 3) {
            console.log('✓ SMEMBERS command');
            passed++;
        } else {
            console.log('✗ SMEMBERS command');
            failed++;
        }

        // Student Operation 3: SCARD
        const card = await testUtils.redisClient.sCard('customers:auto');
        if (card === 3) {
            console.log('✓ SCARD command');
            passed++;
        } else {
            console.log('✗ SCARD command');
            failed++;
        }

        // Student Operation 4: SISMEMBER
        const isMember = await testUtils.redisClient.sIsMember('customers:auto', 'C001');
        if (isMember) {
            console.log('✓ SISMEMBER command');
            passed++;
        } else {
            console.log('✗ SISMEMBER command');
            failed++;
        }

        // Student Operation 5: SINTER
        const inter = await testUtils.redisClient.sInter(['customers:auto', 'customers:home']);
        if (inter.length === 2) { // C002, C003
            console.log('✓ SINTER command');
            passed++;
        } else {
            console.log('✗ SINTER command');
            failed++;
        }

        // Student Operation 6: SUNION
        const union = await testUtils.redisClient.sUnion(['customers:auto', 'customers:home']);
        if (union.length === 4) { // C001, C002, C003, C004
            console.log('✓ SUNION command');
            passed++;
        } else {
            console.log('✗ SUNION command');
            failed++;
        }

        // Student Operation 7: SDIFF
        const diff = await testUtils.redisClient.sDiff(['customers:auto', 'customers:home']);
        if (diff.length === 1) { // C001
            console.log('✓ SDIFF command');
            passed++;
        } else {
            console.log('✗ SDIFF command');
            failed++;
        }

        // Sorted Sets Operations
        // Student Operation 8: ZADD
        await testUtils.redisClient.zAdd('leaderboard', [
            { score: 100, value: 'agent1' },
            { score: 200, value: 'agent2' },
            { score: 150, value: 'agent3' }
        ]);
        console.log('✓ ZADD command');
        passed++;

        // Student Operation 9: ZRANGE
        const range = await testUtils.redisClient.zRange('leaderboard', 0, -1);
        if (range.length === 3) {
            console.log('✓ ZRANGE command');
            passed++;
        } else {
            console.log('✗ ZRANGE command');
            failed++;
        }

        // Student Operation 10: ZREVRANGE
        const revRange = await testUtils.redisClient.zRange('leaderboard', 0, -1, { REV: true });
        if (revRange[0] === 'agent2') { // Highest score
            console.log('✓ ZREVRANGE command');
            passed++;
        } else {
            console.log('✗ ZREVRANGE command');
            failed++;
        }

        // Student Operation 11: ZSCORE
        const score = await testUtils.redisClient.zScore('leaderboard', 'agent2');
        if (parseFloat(score) === 200) {
            console.log('✓ ZSCORE command');
            passed++;
        } else {
            console.log('✗ ZSCORE command');
            failed++;
        }

        // Student Operation 12: ZINCRBY
        await testUtils.redisClient.zIncrBy('leaderboard', 50, 'agent1');
        const newScore = await testUtils.redisClient.zScore('leaderboard', 'agent1');
        if (parseFloat(newScore) === 150) {
            console.log('✓ ZINCRBY command');
            passed++;
        } else {
            console.log('✗ ZINCRBY command');
            failed++;
        }

        // Student Operation 13: ZRANK
        const rank = await testUtils.redisClient.zRank('leaderboard', 'agent1');
        if (rank !== null) {
            console.log('✓ ZRANK command');
            passed++;
        } else {
            console.log('✗ ZRANK command');
            failed++;
        }

        // Student Operation 14: ZCARD
        const zcard = await testUtils.redisClient.zCard('leaderboard');
        if (zcard === 3) {
            console.log('✓ ZCARD command');
            passed++;
        } else {
            console.log('✗ ZCARD command');
            failed++;
        }

    } catch (error) {
        console.log(`✗ Error: ${error.message}`);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Run all comprehensive student operation tests
 */
async function runAllComprehensiveTests() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║        COMPREHENSIVE STUDENT OPERATIONS TEST - ALL COURSE COMMANDS        ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');

    const allResults = {
        totalPassed: 0,
        totalFailed: 0,
        labs: []
    };

    // Test Lab 1
    const lab1 = await testLab1StudentOperations();
    allResults.totalPassed += lab1.passed;
    allResults.totalFailed += lab1.failed;
    allResults.labs.push({ lab: 1, ...lab1 });

    // Test Lab 2
    const lab2 = await testLab2StudentOperations();
    allResults.totalPassed += lab2.passed;
    allResults.totalFailed += lab2.failed;
    allResults.labs.push({ lab: 2, ...lab2 });

    // Test Lab 3
    const lab3 = await testLab3StudentOperations();
    allResults.totalPassed += lab3.passed;
    allResults.totalFailed += lab3.failed;
    allResults.labs.push({ lab: 3, ...lab3 });

    // Test Lab 4
    const lab4 = await testLab4StudentOperations();
    allResults.totalPassed += lab4.passed;
    allResults.totalFailed += lab4.failed;
    allResults.labs.push({ lab: 4, ...lab4 });

    // Test Lab 5
    const lab5 = await testLab5StudentOperations();
    allResults.totalPassed += lab5.passed;
    allResults.totalFailed += lab5.failed;
    allResults.labs.push({ lab: 5, ...lab5 });

    // Test Lab 7
    const lab7 = await testLab7StudentOperations();
    allResults.totalPassed += lab7.passed;
    allResults.totalFailed += lab7.failed;
    allResults.labs.push({ lab: 7, ...lab7 });

    // Test Lab 8
    const lab8 = await testLab8StudentOperations();
    allResults.totalPassed += lab8.passed;
    allResults.totalFailed += lab8.failed;
    allResults.labs.push({ lab: 8, ...lab8 });

    // Test Lab 9
    const lab9 = await testLab9StudentOperations();
    allResults.totalPassed += lab9.passed;
    allResults.totalFailed += lab9.failed;
    allResults.labs.push({ lab: 9, ...lab9 });

    // Test Lab 10
    const lab10 = await testLab10StudentOperations();
    allResults.totalPassed += lab10.passed;
    allResults.totalFailed += lab10.failed;
    allResults.labs.push({ lab: 10, ...lab10 });

    // Summary
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                    COMPREHENSIVE TEST SUMMARY                              ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');
    console.log(`Total Student Operations Tested: ${allResults.totalPassed + allResults.totalFailed}`);
    console.log(`Passed: \x1b[32m${allResults.totalPassed}\x1b[0m`);
    console.log(`Failed: \x1b[31m${allResults.totalFailed}\x1b[0m`);
    console.log(`Success Rate: ${((allResults.totalPassed / (allResults.totalPassed + allResults.totalFailed)) * 100).toFixed(2)}%`);

    if (allResults.totalFailed === 0) {
        console.log('\n\x1b[32m✓ ALL STUDENT OPERATIONS TESTED AND PASSING! 🎉\x1b[0m\n');
    } else {
        console.log('\n\x1b[31m✗ Some student operations failed. Review above for details.\x1b[0m\n');
    }

    process.exit(allResults.totalFailed === 0 ? 0 : 1);
}

// Run if executed directly
if (require.main === module) {
    runAllComprehensiveTests();
}

module.exports = {
    testLab1StudentOperations,
    testLab2StudentOperations,
    testLab3StudentOperations,
    testLab4StudentOperations,
    testLab5StudentOperations,
    testLab7StudentOperations,
    testLab8StudentOperations,
    testLab9StudentOperations,
    testLab10StudentOperations
};
