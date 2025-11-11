/**
 * Integration Tests for Day 1 Labs (Labs 1-5)
 * Focus: CLI & Core Operations
 */

const TestUtils = require('./test-utils');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);
const testUtils = new TestUtils();

/**
 * Lab 1: Redis Environment & CLI Basics
 */
async function testLab1() {
    testUtils.logLabHeader(1, 'Redis Environment & CLI Basics');

    const labDir = path.join(process.cwd(), 'lab1-redis-cli-basics');
    let passed = 0;
    let failed = 0;

    try {
        // Test 1: Check if Redis is running
        const isRunning = await testUtils.isRedisRunning();
        if (isRunning) {
            testUtils.logTest('Lab 1', 'Redis server is running', true);
            passed++;
        } else {
            testUtils.logTest('Lab 1', 'Redis server is running', false, 'Redis is not accessible');
            failed++;
        }

        await testUtils.initRedisClient();

        // Test 2: Exercise 1 - Customer Management
        // Create 5 customer records using SET
        for (let i = 1001; i <= 1005; i++) {
            await testUtils.redisClient.set(`customer:${i}`, `Customer ${i} Data`);
        }

        // Retrieve all customers using KEYS pattern
        const customerKeys = await testUtils.redisClient.keys('customer:*');

        // Check if customer:1005 exists
        const exists = await testUtils.redisClient.exists('customer:1005');

        // Delete customer:1005
        await testUtils.redisClient.del('customer:1005');
        const existsAfterDelete = await testUtils.redisClient.exists('customer:1005');

        if (customerKeys.length >= 5 && exists === 1 && existsAfterDelete === 0) {
            testUtils.logTest('Lab 1', 'Exercise 1: Customer Management (5 customers, EXISTS, DEL)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 1', 'Exercise 1: Customer Management', false,
                `Expected 5 customers, exists=1, after delete=0; Got ${customerKeys.length}, ${exists}, ${existsAfterDelete}`);
            failed++;
        }

        // Test 3: Exercise 2 - Session Management
        // Create session for 3 users (30-minute TTL = 1800 seconds)
        await testUtils.redisClient.setEx('session:user:alice', 1800, 'alice-session-data');
        await testUtils.redisClient.setEx('session:user:bob', 1800, 'bob-session-data');
        await testUtils.redisClient.setEx('session:user:charlie', 1800, 'charlie-session-data');

        // Check TTL for each session
        const ttlAlice = await testUtils.redisClient.ttl('session:user:alice');
        const ttlBob = await testUtils.redisClient.ttl('session:user:bob');
        const ttlCharlie = await testUtils.redisClient.ttl('session:user:charlie');

        // Extend one session by 1 hour (3600 seconds)
        await testUtils.redisClient.expire('session:user:alice', 3600);
        const ttlAliceAfter = await testUtils.redisClient.ttl('session:user:alice');

        // Remove expiration from one session
        await testUtils.redisClient.persist('session:user:bob');
        const ttlBobPersist = await testUtils.redisClient.ttl('session:user:bob');

        if (ttlAlice > 0 && ttlBob > 0 && ttlCharlie > 0 &&
            ttlAliceAfter > 3500 && ttlBobPersist === -1) {
            testUtils.logTest('Lab 1', 'Exercise 2: Session Management (3 sessions, TTL, EXPIRE, PERSIST)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 1', 'Exercise 2: Session Management', false);
            failed++;
        }

        // Test 4: Exercise 3 - Counter Operations
        // Create page view counter
        await testUtils.redisClient.set('pageviews:home', '0');

        // Increment it 100 times
        for (let i = 0; i < 100; i++) {
            await testUtils.redisClient.incr('pageviews:home');
        }

        // Increment by 50
        await testUtils.redisClient.incrBy('pageviews:home', 50);

        // Get final value
        const finalCount = await testUtils.redisClient.get('pageviews:home');

        if (finalCount === '150') {
            testUtils.logTest('Lab 1', 'Exercise 3: Counter Operations (100 INCR + INCRBY 50 = 150)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 1', 'Exercise 3: Counter Operations', false, `Expected 150, got ${finalCount}`);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 1', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 2: RESP Protocol
 */
async function testLab2() {
    testUtils.logLabHeader(2, 'RESP Protocol');

    const labDir = path.join(process.cwd(), 'lab2-resp-protocol');
    let passed = 0;
    let failed = 0;

    try {
        // Test 1: Check lab directory exists
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 2', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'Lab directory exists', false, 'Lab directory not found');
            failed++;
            return { passed, failed };
        }

        await testUtils.initRedisClient();

        // Test 2: Exercise 1 - Company Management (3 companies with hashes)
        // Create 3 companies using HSET
        await testUtils.redisClient.hSet('company:TECH001', {
            name: 'TechCorp',
            industry: 'Technology',
            employees: '500',
            revenue: '25M'
        });
        await testUtils.redisClient.hSet('company:FIN001', {
            name: 'FinBank',
            industry: 'Finance',
            employees: '1000',
            revenue: '100M'
        });
        await testUtils.redisClient.hSet('company:HEALTH001', {
            name: 'HealthCo',
            industry: 'Healthcare',
            employees: '300',
            revenue: '15M'
        });

        // Query companies (HGETALL, HGET, HMGET)
        const techCorp = await testUtils.redisClient.hGetAll('company:TECH001');
        const finRevenue = await testUtils.redisClient.hGet('company:FIN001', 'revenue');
        const healthInfo = await testUtils.redisClient.hmGet('company:HEALTH001', ['industry', 'employees']);

        // Update employee count (HINCRBY)
        await testUtils.redisClient.hIncrBy('company:TECH001', 'employees', 50);
        const updatedEmployees = await testUtils.redisClient.hGet('company:TECH001', 'employees');

        if (techCorp.name === 'TechCorp' && finRevenue === '100M' &&
            healthInfo[0] === 'Healthcare' && updatedEmployees === '550') {
            testUtils.logTest('Lab 2', 'Exercise 1: Company Management (3 companies, HSET, HGETALL, HMGET, HINCRBY)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'Exercise 1: Company Management', false);
            failed++;
        }

        // Test 3: Exercise 2 - Risk Leaderboard (5 customers with risk scores)
        // Add 5 customers with risk scores
        await testUtils.redisClient.zAdd('risk:scores', [
            { score: 35, value: 'CUST001' },
            { score: 72, value: 'CUST002' },
            { score: 45, value: 'CUST003' },
            { score: 88, value: 'CUST004' },
            { score: 15, value: 'CUST005' }
        ]);

        // Find top 3 highest risk (ZREVRANGE)
        const topRisk = await testUtils.redisClient.zRange('risk:scores', 0, 2, { REV: true });
        // topRisk format: ['CUST004', 'CUST002', 'CUST003']

        // Count customers with risk > 50 (ZCOUNT)
        const highRiskCount = await testUtils.redisClient.zCount('risk:scores', 50, 100);

        // Get all low risk customers (< 40) (ZRANGEBYSCORE)
        const lowRisk = await testUtils.redisClient.zRangeByScore('risk:scores', 0, 40);
        // lowRisk format: ['CUST005', 'CUST001']

        if (topRisk.length === 3 && topRisk[0] === 'CUST004' &&
            highRiskCount === 2 && lowRisk.length === 2) {
            testUtils.logTest('Lab 2', 'Exercise 2: Risk Leaderboard (5 customers, ZADD, ZREVRANGE, ZCOUNT, ZRANGEBYSCORE)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'Exercise 2: Risk Leaderboard', false,
                `Top risk: ${topRisk[0]}, High risk count: ${highRiskCount}, Low risk length: ${lowRisk.length}`);
            failed++;
        }

        // Test 4: Exercise 3 - Profiler Practice Commands (can't test GUI, but test the commands)
        // Run the commands from Exercise 3
        await testUtils.redisClient.set('test:monitor:1', 'value1');
        await testUtils.redisClient.hSet('user:100', { name: 'John', age: '30' });
        await testUtils.redisClient.zAdd('scores', [{ score: 100, value: 'player1' }]);
        await testUtils.redisClient.sAdd('tags', ['redis', 'insight', 'profiler']);

        // Verify the commands executed successfully
        const monitorVal = await testUtils.redisClient.get('test:monitor:1');
        const userName = await testUtils.redisClient.hGet('user:100', 'name');
        const playerScore = await testUtils.redisClient.zScore('scores', 'player1');
        const tagCount = await testUtils.redisClient.sCard('tags');

        if (monitorVal === 'value1' && userName === 'John' && playerScore === 100 && tagCount === 3) {
            testUtils.logTest('Lab 2', 'Exercise 3: Profiler Commands (SET, HSET, ZADD, SADD verified)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'Exercise 3: Profiler Commands', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 2', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 3: String Operations
 */
async function testLab3() {
    testUtils.logLabHeader(3, 'String Operations');

    const labDir = path.join(process.cwd(), 'lab3-data-operations-strings');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Exercise 1 - Policy System (20 policies)
        // Generate 20 policy numbers
        for (let i = 1; i <= 20; i++) {
            await testUtils.redisClient.incr('policy:counter:auto');
        }
        const autoCounter = await testUtils.redisClient.get('policy:counter:auto');

        // Store policy data using MSET
        const policyData = {};
        for (let i = 1; i <= 10; i++) {
            policyData[`policy:AUTO-${String(i).padStart(6, '0')}`] = `Customer ${i} - Auto Coverage`;
        }
        for (let i = 1; i <= 10; i++) {
            policyData[`policy:HOME-${String(i).padStart(6, '0')}`] = `Customer ${i} - Home Coverage`;
        }
        await testUtils.redisClient.mSet(policyData);

        // Retrieve multiple policies
        const retrievedPolicies = await testUtils.redisClient.mGet([
            'policy:AUTO-000001',
            'policy:AUTO-000002',
            'policy:HOME-000001'
        ]);

        const policyKeys = await testUtils.redisClient.keys('policy:AUTO-*');
        const homeKeys = await testUtils.redisClient.keys('policy:HOME-*');

        if (autoCounter === '20' && policyKeys.length >= 10 && homeKeys.length >= 10 &&
            retrievedPolicies[0] && retrievedPolicies[2]) {
            testUtils.logTest('Lab 3', 'Exercise 1: Policy System (20 counters, MSET, MGET)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'Exercise 1: Policy System', false);
            failed++;
        }

        // Test 2: Exercise 2 - Premium Calculator (10 premiums with adjustments)
        // Create 10 policies with initial premiums
        const premiums = {
            'premium:AUTO-001': '1000',
            'premium:AUTO-002': '1200',
            'premium:HOME-001': '800',
            'premium:HOME-002': '900',
            'premium:AUTO-003': '1100',
            'premium:AUTO-004': '1300',
            'premium:HOME-003': '850',
            'premium:HOME-004': '950',
            'premium:AUTO-005': '1150',
            'premium:HOME-005': '900'
        };
        await testUtils.redisClient.mSet(premiums);

        // Apply risk adjustments (atomic INCRBY)
        await testUtils.redisClient.incrBy('premium:AUTO-001', 100);  // +10%
        await testUtils.redisClient.incrBy('premium:AUTO-002', 360);  // +30%

        // Apply discounts (DECRBY)
        await testUtils.redisClient.decrBy('premium:AUTO-001', 50);  // -5%
        await testUtils.redisClient.decrBy('premium:AUTO-002', 180); // -15%

        // Get adjusted premiums
        const adjustedPremiums = await testUtils.redisClient.mGet([
            'premium:AUTO-001',
            'premium:AUTO-002',
            'premium:HOME-001',
            'premium:HOME-002'
        ]);

        if (adjustedPremiums[0] === '1050' && adjustedPremiums[1] === '1380') {
            testUtils.logTest('Lab 3', 'Exercise 2: Premium Calculator (10 premiums, INCRBY, DECRBY)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'Exercise 2: Premium Calculator', false,
                `Expected 1050, 1380; Got ${adjustedPremiums[0]}, ${adjustedPremiums[1]}`);
            failed++;
        }

        // Test 3: Exercise 3 - Customer Profiles (15 customers with APPEND)
        // Create 15 customer profiles
        for (let i = 1; i <= 15; i++) {
            await testUtils.redisClient.set(`customer:C${String(i).padStart(3, '0')}`, `Customer ${i}`);
        }

        // Append risk scores to 5 customers
        for (let i = 1; i <= 5; i++) {
            const key = `customer:C${String(i).padStart(3, '0')}`;
            await testUtils.redisClient.append(key, ` | Risk Score: ${700 + i * 10}`);
            await testUtils.redisClient.append(key, ` | Age: ${30 + i}`);
        }

        // Check string length to verify appends
        const customerKeys = await testUtils.redisClient.keys('customer:C*');
        const customer1 = await testUtils.redisClient.get('customer:C001');
        const strlen = await testUtils.redisClient.strLen('customer:C001');

        if (customerKeys.length >= 15 && customer1.includes('Risk Score') && strlen > 30) {
            testUtils.logTest('Lab 3', 'Exercise 3: Customer Profiles (15 customers, APPEND, STRLEN)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'Exercise 3: Customer Profiles', false);
            failed++;
        }

        // Test 4: Exercise 4 - Revenue Tracking (5 days)
        // Track revenue across 5 days
        const dates = ['2024-11-06', '2024-11-07', '2024-11-08', '2024-11-09', '2024-11-10'];
        for (const date of dates) {
            await testUtils.redisClient.incrBy(`revenue:daily:${date}`, 1200);
            await testUtils.redisClient.incrBy(`revenue:daily:${date}`, 800);
            await testUtils.redisClient.incrBy(`revenue:daily:${date}`, 1500);
        }

        // Track by policy type
        await testUtils.redisClient.incrBy('revenue:auto:2024-11-10', 3500);
        await testUtils.redisClient.incrBy('revenue:home:2024-11-10', 2000);

        // Get 5-day totals
        const revenueKeys = dates.map(d => `revenue:daily:${d}`);
        const revenues = await testUtils.redisClient.mGet(revenueKeys);

        // Each day should have 1200 + 800 + 1500 = 3500
        if (revenues.every(r => r === '3500') && revenues.length === 5) {
            testUtils.logTest('Lab 3', 'Exercise 4: Revenue Tracking (5 days, INCRBY, MGET)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'Exercise 4: Revenue Tracking', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 3', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 4: Key Management & TTL
 */
async function testLab4() {
    testUtils.logLabHeader(4, 'Key Management & TTL');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Exercise 1 - Policy Organization (20 policies with hierarchical naming)
        const policyTypes = ['auto', 'home', 'life'];
        let totalPolicies = 0;

        for (const type of policyTypes) {
            const startId = type === 'auto' ? 100001 : type === 'home' ? 200001 : 300001;
            for (let i = 0; i < 7; i++) {
                await testUtils.redisClient.set(`policy:${type}:${startId + i}:status`, 'active');
                await testUtils.redisClient.set(`policy:${type}:${startId + i}:premium`, `${1000 + i * 100}`);
                totalPolicies += 2;
            }
        }

        // Verify hierarchical structure with KEYS pattern
        const autoPolicies = await testUtils.redisClient.keys('policy:auto:*');
        const homePolicies = await testUtils.redisClient.keys('policy:home:*');
        const lifePolicies = await testUtils.redisClient.keys('policy:life:*');

        if (autoPolicies.length >= 14 && homePolicies.length >= 14 && lifePolicies.length >= 14) {
            testUtils.logTest('Lab 4', 'Exercise 1: Policy Organization (20+ policies, hierarchical keys)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Exercise 1: Policy Organization', false,
                `Expected 14+ each type; Got auto:${autoPolicies.length}, home:${homePolicies.length}, life:${lifePolicies.length}`);
            failed++;
        }

        // Test 2: Exercise 2 - Quote System (10 quotes with 24-hour expiration)
        // Create 10 quotes with 24-hour expiration (86400 seconds)
        for (let i = 1; i <= 10; i++) {
            const quoteId = `Q${String(i).padStart(3, '0')}`;
            await testUtils.redisClient.setEx(`quote:${quoteId}`, 86400,
                JSON.stringify({ type: i % 2 === 0 ? 'auto' : 'home', premium: 800 + i * 100 }));
        }

        // Check TTL for quotes
        const ttlQ001 = await testUtils.redisClient.ttl('quote:Q001');
        const ttlQ002 = await testUtils.redisClient.ttl('quote:Q002');

        // Extend 3 quotes by 12 hours (43200 seconds)
        await testUtils.redisClient.expire('quote:Q001', 43200);
        await testUtils.redisClient.expire('quote:Q002', 43200);
        await testUtils.redisClient.expire('quote:Q003', 43200);

        const ttlQ001After = await testUtils.redisClient.ttl('quote:Q001');

        // Verify quote keys exist
        const quoteKeys = await testUtils.redisClient.keys('quote:Q*');

        if (quoteKeys.length >= 10 && ttlQ001 > 80000 && ttlQ001After < 45000 && ttlQ001After > 40000) {
            testUtils.logTest('Lab 4', 'Exercise 2: Quote System (10 quotes, SETEX, EXPIRE)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Exercise 2: Quote System', false);
            failed++;
        }

        // Test 3: Exercise 3 - Session Management (5 users with 30-min TTL)
        // Create sessions for 5 users (30-minute TTL = 1800 seconds)
        const users = ['alice', 'bob', 'charlie', 'diana', 'eve'];
        for (const user of users) {
            await testUtils.redisClient.setEx(`session:user:${user}`, 1800,
                JSON.stringify({ userId: user, loginTime: Date.now() }));
        }

        // Check TTL for all sessions
        const ttls = {};
        for (const user of users) {
            ttls[user] = await testUtils.redisClient.ttl(`session:user:${user}`);
        }

        // Renew 2 sessions (simulate user activity)
        await testUtils.redisClient.expire('session:user:alice', 1800);
        await testUtils.redisClient.expire('session:user:bob', 1800);

        // Count active sessions
        const sessionKeys = await testUtils.redisClient.keys('session:user:*');

        if (sessionKeys.length >= 5 && ttls.alice > 0 && ttls.eve > 0) {
            testUtils.logTest('Lab 4', 'Exercise 3: Session Management (5 sessions, TTL, renewal)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Exercise 3: Session Management', false);
            failed++;
        }

        // Test 4: Exercise 4 - Memory Monitoring (100+ keys with various TTLs)
        // Create 100+ keys with varying TTLs
        for (let i = 1; i <= 50; i++) {
            await testUtils.redisClient.setEx(`temp:short:${i}`, 60, `data-${i}`);  // 1 minute
        }
        for (let i = 1; i <= 30; i++) {
            await testUtils.redisClient.setEx(`temp:medium:${i}`, 300, `data-${i}`); // 5 minutes
        }
        for (let i = 1; i <= 20; i++) {
            await testUtils.redisClient.setEx(`temp:long:${i}`, 3600, `data-${i}`);  // 1 hour
        }

        // Count keys
        const dbSize = await testUtils.redisClient.dbSize();
        const tempKeys = await testUtils.redisClient.keys('temp:*');

        if (dbSize >= 100 && tempKeys.length >= 100) {
            testUtils.logTest('Lab 4', 'Exercise 4: Memory Monitoring (100+ keys with TTLs, DBSIZE)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Exercise 4: Memory Monitoring', false,
                `Expected 100+ keys; Got dbSize:${dbSize}, temp keys:${tempKeys.length}`);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 4', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 5: Advanced CLI Operations
 */
async function testLab5() {
    testUtils.logLabHeader(5, 'Advanced CLI Operations');

    const labDir = path.join(process.cwd(), 'lab5-advanced-cli-monitoring');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: INFO command (removed script checks - use Redis Insight Profiler and Analysis tab)
        const info = await testUtils.redisClient.info('server');
        if (info.includes('redis_version')) {
            testUtils.logTest('Lab 5', 'INFO command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'INFO command', false);
            failed++;
        }

        // Test 2: DBSIZE command
        await testUtils.redisClient.set('test:lab5:key1', 'value1');
        await testUtils.redisClient.set('test:lab5:key2', 'value2');
        const dbsize = await testUtils.redisClient.dbSize();
        if (dbsize >= 2) {
            testUtils.logTest('Lab 5', 'DBSIZE command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'DBSIZE command', false);
            failed++;
        }

        // Test 3: MEMORY USAGE command (if supported)
        try {
            await testUtils.redisClient.set('test:lab5:memory', 'x'.repeat(1000));
            const memory = await testUtils.redisClient.memoryUsage('test:lab5:memory');
            if (memory > 0) {
                testUtils.logTest('Lab 5', 'MEMORY USAGE command', true);
                passed++;
            } else {
                testUtils.logTest('Lab 5', 'MEMORY USAGE command', false);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 5', 'MEMORY USAGE command', false, 'Command not supported');
            failed++;
        }

        // Test 4: SCAN operation (better than KEYS for production)
        await testUtils.redisClient.mSet({
            'scan:test:1': 'v1',
            'scan:test:2': 'v2',
            'scan:test:3': 'v3'
        });

        let scannedKeys = [];
        for await (const key of testUtils.redisClient.scanIterator({ MATCH: 'scan:test:*' })) {
            scannedKeys.push(key);
        }

        if (scannedKeys.length === 3) {
            testUtils.logTest('Lab 5', 'SCAN operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'SCAN operation', false);
            failed++;
        }

        // Test 5: Pipeline operations
        const pipeline = testUtils.redisClient.multi();
        pipeline.set('test:lab5:pipe1', 'value1');
        pipeline.set('test:lab5:pipe2', 'value2');
        pipeline.set('test:lab5:pipe3', 'value3');
        pipeline.get('test:lab5:pipe1');
        const results = await pipeline.exec();

        if (results.length === 4 && results[3] === 'value1') {
            testUtils.logTest('Lab 5', 'Pipeline operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'Pipeline operations', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 5', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Run all Day 1 tests
 */
async function runDay1Tests() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                          DAY 1 INTEGRATION TESTS                           ║');
    console.log('║                      CLI & Core Operations (Labs 1-5)                      ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');

    const results = {
        totalPassed: 0,
        totalFailed: 0,
        labs: []
    };

    // Run all Day 1 lab tests
    const lab1 = await testLab1();
    results.labs.push({ lab: 1, ...lab1 });
    results.totalPassed += lab1.passed;
    results.totalFailed += lab1.failed;

    const lab2 = await testLab2();
    results.labs.push({ lab: 2, ...lab2 });
    results.totalPassed += lab2.passed;
    results.totalFailed += lab2.failed;

    const lab3 = await testLab3();
    results.labs.push({ lab: 3, ...lab3 });
    results.totalPassed += lab3.passed;
    results.totalFailed += lab3.failed;

    const lab4 = await testLab4();
    results.labs.push({ lab: 4, ...lab4 });
    results.totalPassed += lab4.passed;
    results.totalFailed += lab4.failed;

    const lab5 = await testLab5();
    results.labs.push({ lab: 5, ...lab5 });
    results.totalPassed += lab5.passed;
    results.totalFailed += lab5.failed;

    return results;
}

module.exports = {
    runDay1Tests,
    testLab1,
    testLab2,
    testLab3,
    testLab4,
    testLab5
};

// Run tests if called directly
if (require.main === module) {
    runDay1Tests()
        .then(results => {
            testUtils.printTestSummary();
            process.exit(results.totalFailed === 0 ? 0 : 1);
        })
        .catch(error => {
            console.error('Error running Day 1 tests:', error);
            process.exit(1);
        });
}
