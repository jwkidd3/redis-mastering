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

    const labDir = path.join(process.cwd(), 'lab1-redis-environment-cli-basics');
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

        // Test 2: Check if setup script exists
        const setupScriptExists = await testUtils.fileExists(path.join(labDir, 'setup-lab.sh'));
        if (setupScriptExists) {
            testUtils.logTest('Lab 1', 'Setup script exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 1', 'Setup script exists', false, 'setup-lab.sh not found');
            failed++;
        }

        // Test 3: Execute setup script
        if (setupScriptExists) {
            const result = await testUtils.executeScript('setup-lab.sh', labDir);
            if (result.success) {
                testUtils.logTest('Lab 1', 'Execute setup script', true);
                passed++;
            } else {
                testUtils.logTest('Lab 1', 'Execute setup script', false, result.stderr);
                failed++;
            }
        }

        // Test 4: Test basic Redis commands
        await testUtils.initRedisClient();

        // SET command
        await testUtils.redisClient.set('test:lab1:key', 'Hello Redis');
        const value = await testUtils.redisClient.get('test:lab1:key');
        if (value === 'Hello Redis') {
            testUtils.logTest('Lab 1', 'Basic SET/GET commands', true);
            passed++;
        } else {
            testUtils.logTest('Lab 1', 'Basic SET/GET commands', false, 'Value mismatch');
            failed++;
        }

        // Test 5: Check if test script exists and runs
        const testScriptExists = await testUtils.fileExists(path.join(labDir, 'test-lab.sh'));
        if (testScriptExists) {
            testUtils.logTest('Lab 1', 'Test script exists', true);
            passed++;

            const result = await testUtils.executeScript('test-lab.sh', labDir);
            if (result.success || result.stdout.includes('✓')) {
                testUtils.logTest('Lab 1', 'Execute test script', true);
                passed++;
            } else {
                testUtils.logTest('Lab 1', 'Execute test script', false, result.stderr);
                failed++;
            }
        } else {
            testUtils.logTest('Lab 1', 'Test script exists', false);
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

        // Test 2: Test RESP protocol with redis-cli
        await testUtils.initRedisClient();

        // Test simple string response
        const pong = await testUtils.redisClient.ping();
        if (pong === 'PONG') {
            testUtils.logTest('Lab 2', 'RESP Simple String (PING)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'RESP Simple String (PING)', false);
            failed++;
        }

        // Test integer response
        await testUtils.redisClient.set('test:lab2:counter', '0');
        const incrResult = await testUtils.redisClient.incr('test:lab2:counter');
        if (incrResult === 1) {
            testUtils.logTest('Lab 2', 'RESP Integer (INCR)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'RESP Integer (INCR)', false);
            failed++;
        }

        // Test bulk string response
        await testUtils.redisClient.set('test:lab2:bulk', 'This is a bulk string');
        const bulk = await testUtils.redisClient.get('test:lab2:bulk');
        if (bulk === 'This is a bulk string') {
            testUtils.logTest('Lab 2', 'RESP Bulk String (GET)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'RESP Bulk String (GET)', false);
            failed++;
        }

        // Test array response
        await testUtils.redisClient.rPush('test:lab2:list', ['item1', 'item2', 'item3']);
        const list = await testUtils.redisClient.lRange('test:lab2:list', 0, -1);
        if (Array.isArray(list) && list.length === 3) {
            testUtils.logTest('Lab 2', 'RESP Array (LRANGE)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 2', 'RESP Array (LRANGE)', false);
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

    const labDir = path.join(process.cwd(), 'lab3-string-operations');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check if sample data loading script exists
        const loadDataExists = await testUtils.fileExists(path.join(labDir, 'load-sample-data.sh'));
        if (loadDataExists) {
            testUtils.logTest('Lab 3', 'Sample data script exists', true);
            passed++;

            // Execute the data loading script
            const result = await testUtils.executeScript('load-sample-data.sh', labDir);
            if (result.success) {
                testUtils.logTest('Lab 3', 'Load sample data', true);
                passed++;
            } else {
                testUtils.logTest('Lab 3', 'Load sample data', false, result.stderr);
                failed++;
            }
        } else {
            testUtils.logTest('Lab 3', 'Sample data script exists', false);
            failed++;
        }

        // Test 2: Basic string operations
        await testUtils.redisClient.set('test:lab3:policy', 'POL-AUTO-12345');
        const policy = await testUtils.redisClient.get('test:lab3:policy');
        if (policy === 'POL-AUTO-12345') {
            testUtils.logTest('Lab 3', 'SET/GET operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'SET/GET operations', false);
            failed++;
        }

        // Test 3: SETNX (Set if not exists)
        const setnx1 = await testUtils.redisClient.setNX('test:lab3:unique', 'first');
        const setnx2 = await testUtils.redisClient.setNX('test:lab3:unique', 'second');
        if (setnx1 && !setnx2) {
            testUtils.logTest('Lab 3', 'SETNX operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'SETNX operation', false);
            failed++;
        }

        // Test 4: INCR/DECR operations
        await testUtils.redisClient.set('test:lab3:views', '100');
        await testUtils.redisClient.incr('test:lab3:views');
        const views = await testUtils.redisClient.get('test:lab3:views');
        if (views === '101') {
            testUtils.logTest('Lab 3', 'INCR operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'INCR operation', false);
            failed++;
        }

        // Test 5: MGET/MSET operations
        await testUtils.redisClient.mSet({
            'test:lab3:policy1': 'POL-001',
            'test:lab3:policy2': 'POL-002',
            'test:lab3:policy3': 'POL-003'
        });
        const policies = await testUtils.redisClient.mGet([
            'test:lab3:policy1',
            'test:lab3:policy2',
            'test:lab3:policy3'
        ]);
        if (policies.length === 3 && policies[0] === 'POL-001') {
            testUtils.logTest('Lab 3', 'MGET/MSET operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'MGET/MSET operations', false);
            failed++;
        }

        // Test 6: String append operation
        await testUtils.redisClient.set('test:lab3:message', 'Hello');
        await testUtils.redisClient.append('test:lab3:message', ' World');
        const message = await testUtils.redisClient.get('test:lab3:message');
        if (message === 'Hello World') {
            testUtils.logTest('Lab 3', 'APPEND operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 3', 'APPEND operation', false);
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

        // Test 1: Key patterns and scanning
        await testUtils.redisClient.mSet({
            'policy:auto:001': 'Auto Policy 1',
            'policy:home:001': 'Home Policy 1',
            'policy:auto:002': 'Auto Policy 2',
            'claim:001': 'Claim 1'
        });

        const keys = await testUtils.redisClient.keys('policy:auto:*');
        if (keys.length === 2) {
            testUtils.logTest('Lab 4', 'Key pattern matching (KEYS)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Key pattern matching (KEYS)', false, `Expected 2 keys, got ${keys.length}`);
            failed++;
        }

        // Test 2: TTL operations
        await testUtils.redisClient.set('test:lab4:session', 'session-data');
        await testUtils.redisClient.expire('test:lab4:session', 5);
        const ttl = await testUtils.redisClient.ttl('test:lab4:session');
        if (ttl > 0 && ttl <= 5) {
            testUtils.logTest('Lab 4', 'EXPIRE and TTL operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'EXPIRE and TTL operations', false);
            failed++;
        }

        // Test 3: SETEX (Set with expiration)
        await testUtils.redisClient.setEx('test:lab4:temp', 10, 'temporary data');
        const tempTtl = await testUtils.redisClient.ttl('test:lab4:temp');
        if (tempTtl > 0 && tempTtl <= 10) {
            testUtils.logTest('Lab 4', 'SETEX operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'SETEX operation', false);
            failed++;
        }

        // Test 4: EXISTS operation
        await testUtils.redisClient.set('test:lab4:exists', 'value');
        const exists = await testUtils.redisClient.exists('test:lab4:exists');
        const notExists = await testUtils.redisClient.exists('test:lab4:notexists');
        if (exists === 1 && notExists === 0) {
            testUtils.logTest('Lab 4', 'EXISTS operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'EXISTS operation', false);
            failed++;
        }

        // Test 5: DEL operation
        await testUtils.redisClient.set('test:lab4:delete', 'to-delete');
        const deleted = await testUtils.redisClient.del('test:lab4:delete');
        const afterDelete = await testUtils.redisClient.exists('test:lab4:delete');
        if (deleted === 1 && afterDelete === 0) {
            testUtils.logTest('Lab 4', 'DEL operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'DEL operation', false);
            failed++;
        }

        // Test 6: PERSIST operation (remove TTL)
        await testUtils.redisClient.setEx('test:lab4:persist', 100, 'data');
        await testUtils.redisClient.persist('test:lab4:persist');
        const persistTtl = await testUtils.redisClient.ttl('test:lab4:persist');
        if (persistTtl === -1) {
            testUtils.logTest('Lab 4', 'PERSIST operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'PERSIST operation', false);
            failed++;
        }

        // Test 7: TYPE operation
        await testUtils.redisClient.set('test:lab4:string', 'value');
        await testUtils.redisClient.hSet('test:lab4:hash', 'field', 'value');

        const stringType = await testUtils.redisClient.type('test:lab4:string');
        const hashType = await testUtils.redisClient.type('test:lab4:hash');

        if (stringType === 'string' && hashType === 'hash') {
            testUtils.logTest('Lab 4', 'TYPE operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'TYPE operation', false);
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

    const labDir = path.join(process.cwd(), 'lab5-advanced-cli-operations');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check if monitoring scripts exist
        const scriptFiles = [
            'monitor-performance.sh',
            'analyze-memory.sh',
            'slow-log-analysis.sh'
        ];

        for (const scriptFile of scriptFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, scriptFile));
            if (exists) {
                testUtils.logTest('Lab 5', `Script ${scriptFile} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 5', `Script ${scriptFile} exists`, false);
                failed++;
            }
        }

        // Test 2: INFO command
        const info = await testUtils.redisClient.info('server');
        if (info.includes('redis_version')) {
            testUtils.logTest('Lab 5', 'INFO command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'INFO command', false);
            failed++;
        }

        // Test 3: DBSIZE command
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

        // Test 4: MEMORY USAGE command (if supported)
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

        // Test 5: SCAN operation (better than KEYS for production)
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

        // Test 6: Pipeline operations
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
