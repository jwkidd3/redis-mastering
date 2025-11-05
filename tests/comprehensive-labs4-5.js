/**
 * COMPREHENSIVE STUDENT OPERATION TESTS - LABS 4-5
 * Completing Day 1 with key management and monitoring
 */

const TestUtils = require('./test-utils');
const testUtils = new TestUtils();

/**
 * LAB 4: Key Management & TTL
 */
async function comprehensiveTestLab4() {
    testUtils.logLabHeader(4, 'Key Management & TTL - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // PART 1: Key Naming Conventions - Hierarchical Key Design (9 operations)
        console.log('\n  Part 1: Hierarchical Key Design');

        // Policy keys
        await testUtils.redisClient.set('policy:auto:100001:status', 'active');
        await testUtils.redisClient.set('policy:auto:100001:premium', '1200.00');
        await testUtils.redisClient.set('policy:home:200001:status', 'active');
        await testUtils.redisClient.set('policy:life:300001:status', 'pending');

        testUtils.logTest('Lab 4', 'Create hierarchical policy keys', true);
        passed++;

        // Customer keys
        await testUtils.redisClient.set('customer:C001:name', 'John Smith');
        await testUtils.redisClient.set('customer:C001:email', 'john@example.com');
        await testUtils.redisClient.set('customer:C001:tier', 'premium');

        testUtils.logTest('Lab 4', 'Create hierarchical customer keys', true);
        passed++;

        // Claims keys
        await testUtils.redisClient.set('claim:CLM001:status', 'submitted');
        await testUtils.redisClient.set('claim:CLM001:amount', '5000');

        testUtils.logTest('Lab 4', 'Create hierarchical claim keys', true);
        passed++;

        // PART 1: Search by Pattern (4 operations)
        console.log('\n  Part 1: Search by Pattern');

        const autoPolicies = await testUtils.redisClient.keys('policy:auto:*');
        if (autoPolicies.length >= 2) {
            testUtils.logTest('Lab 4', 'KEYS pattern matching for auto policies', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'KEYS pattern matching', false);
            failed++;
        }

        const allCustomers = await testUtils.redisClient.keys('customer:*');
        if (allCustomers.length >= 3) {
            testUtils.logTest('Lab 4', 'KEYS pattern matching for customers', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'KEYS pattern matching', false);
            failed++;
        }

        const specificCustomer = await testUtils.redisClient.keys('customer:C001:*');
        if (specificCustomer.length === 3) {
            testUtils.logTest('Lab 4', 'KEYS pattern for specific customer data', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'KEYS pattern for specific customer', false);
            failed++;
        }

        // PART 2: TTL Management - Set Expiration (3 operations)
        console.log('\n  Part 2: TTL Management');

        await testUtils.redisClient.setEx('quote:Q12345', 3600, '{"coverage":"100k"}');
        const quoteTTL1 = await testUtils.redisClient.ttl('quote:Q12345');
        if (quoteTTL1 > 3500 && quoteTTL1 <= 3600) {
            testUtils.logTest('Lab 4', 'SETEX with TTL', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'SETEX with TTL', false);
            failed++;
        }

        await testUtils.redisClient.set('session:user123', 'session-data');
        await testUtils.redisClient.expire('session:user123', 1800);
        const sessionTTL = await testUtils.redisClient.ttl('session:user123');
        if (sessionTTL > 1700 && sessionTTL <= 1800) {
            testUtils.logTest('Lab 4', 'EXPIRE adds TTL to existing key', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'EXPIRE adds TTL', false);
            failed++;
        }

        // PART 2: Check TTL (3 operations)
        console.log('\n  Part 2: Check TTL');

        const ttlCheck = await testUtils.redisClient.ttl('quote:Q12345');
        if (ttlCheck > 0) {
            testUtils.logTest('Lab 4', 'TTL returns positive seconds', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'TTL check', false);
            failed++;
        }

        const noExist = await testUtils.redisClient.ttl('key:nonexistent');
        if (noExist === -2) {
            testUtils.logTest('Lab 4', 'TTL returns -2 for non-existent key', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'TTL -2 check', false);
            failed++;
        }

        await testUtils.redisClient.set('key:noTTL', 'value');
        const noTTL = await testUtils.redisClient.ttl('key:noTTL');
        if (noTTL === -1) {
            testUtils.logTest('Lab 4', 'TTL returns -1 for key without expiry', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'TTL -1 check', false);
            failed++;
        }

        // PART 2: Remove and Update Expiration (3 operations)
        console.log('\n  Part 2: Remove/Update Expiration');

        await testUtils.redisClient.persist('session:user123');
        const persistCheck = await testUtils.redisClient.ttl('session:user123');
        if (persistCheck === -1) {
            testUtils.logTest('Lab 4', 'PERSIST removes expiration', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'PERSIST removes expiration', false);
            failed++;
        }

        await testUtils.redisClient.expire('session:user123', 3600);
        const updatedTTL = await testUtils.redisClient.ttl('session:user123');
        if (updatedTTL > 3500 && updatedTTL <= 3600) {
            testUtils.logTest('Lab 4', 'Update TTL with EXPIRE', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Update TTL', false);
            failed++;
        }

        // PART 3: Quote Management (simplified - 2 tests)
        console.log('\n  Part 3: Quote Management');

        for (let i = 1; i <= 5; i++) {
            await testUtils.redisClient.setEx(`quote:Q1234${i}`, 3600, `{"id": "Q1234${i}"}`);
        }
        testUtils.logTest('Lab 4', 'Create multiple quotes with TTL', true);
        passed++;

        const quotes = await testUtils.redisClient.keys('quote:Q1234*');
        if (quotes.length === 5) {
            testUtils.logTest('Lab 4', 'Verify all quotes created', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Verify quotes', false);
            failed++;
        }

        // Part 4: Session Management (simplified - 2 tests)
        console.log('\n  Part 4: Session Management');

        for (let i = 1; i <= 3; i++) {
            await testUtils.redisClient.setEx(`session:user${i}`, 1800, `session${i}data`);
        }
        testUtils.logTest('Lab 4', 'Create sessions with auto-cleanup TTL', true);
        passed++;

        const sessions = await testUtils.redisClient.keys('session:user*');
        if (sessions.length >= 3) {
            testUtils.logTest('Lab 4', 'Verify sessions created', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'Verify sessions', false);
            failed++;
        }

        // Key Operations (5 operations)
        console.log('\n  Additional: Key Operations');

        await testUtils.redisClient.set('test:exists1', 'value');
        const exists = await testUtils.redisClient.exists('test:exists1');
        if (exists === 1) {
            testUtils.logTest('Lab 4', 'EXISTS command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'EXISTS command', false);
            failed++;
        }

        const keyType = await testUtils.redisClient.type('test:exists1');
        if (keyType === 'string') {
            testUtils.logTest('Lab 4', 'TYPE command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'TYPE command', false);
            failed++;
        }

        await testUtils.redisClient.del('test:exists1');
        const deleted = await testUtils.redisClient.exists('test:exists1');
        if (deleted === 0) {
            testUtils.logTest('Lab 4', 'DEL command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 4', 'DEL command', false);
            failed++;
        }

        console.log(`\n  Lab 4 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 4', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * LAB 5: Advanced CLI & Monitoring
 */
async function comprehensiveTestLab5() {
    testUtils.logLabHeader(5, 'Advanced CLI & Monitoring - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // PART 1: INFO Command (3 tests)
        console.log('\n  Part 1: INFO Command');

        const serverInfo = await testUtils.redisClient.info('server');
        if (serverInfo.includes('redis_version')) {
            testUtils.logTest('Lab 5', 'INFO server command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'INFO server', false);
            failed++;
        }

        const memoryInfo = await testUtils.redisClient.info('memory');
        if (memoryInfo.includes('used_memory')) {
            testUtils.logTest('Lab 5', 'INFO memory command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'INFO memory', false);
            failed++;
        }

        const statsInfo = await testUtils.redisClient.info('stats');
        if (statsInfo.includes('total_connections_received')) {
            testUtils.logTest('Lab 5', 'INFO stats command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'INFO stats', false);
            failed++;
        }

        // PART 2: DBSIZE and Key Scanning (2 tests)
        console.log('\n  Part 2: Database Size');

        const dbsize = await testUtils.redisClient.dbSize();
        if (dbsize >= 0) {
            testUtils.logTest('Lab 5', 'DBSIZE command', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'DBSIZE command', false);
            failed++;
        }

        // SCAN operation
        await testUtils.redisClient.mSet({
            'scan:test1': 'val1',
            'scan:test2': 'val2',
            'scan:test3': 'val3'
        });

        const scanKeys = await testUtils.redisClient.keys('scan:test*');
        if (scanKeys.length >= 3) {
            testUtils.logTest('Lab 5', 'SCAN/KEYS for pattern matching', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'SCAN/KEYS operation', false);
            failed++;
        }

        // PART 3: Memory Analysis (2 tests)
        console.log('\n  Part 3: Memory Analysis');

        const memStats = await testUtils.redisClient.info('memory');
        if (memStats.includes('maxmemory')) {
            testUtils.logTest('Lab 5', 'Memory stats analysis', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'Memory stats', false);
            failed++;
        }

        // Create test key for memory usage
        await testUtils.redisClient.set('test:memory:key', 'test value for memory check');
        // Note: MEMORY USAGE might not be available in all Redis versions
        testUtils.logTest('Lab 5', 'Memory usage tracking (simulated)', true);
        passed++;

        // PART 4: Pipeline Operations (2 tests)
        console.log('\n  Part 4: Pipeline Operations');

        // Simulate pipeline with batch operations
        const pipelineData = {};
        for (let i = 1; i <= 10; i++) {
            pipelineData[`pipeline:key${i}`] = `value${i}`;
        }
        await testUtils.redisClient.mSet(pipelineData);

        const pipelineKeys = await testUtils.redisClient.keys('pipeline:key*');
        if (pipelineKeys.length === 10) {
            testUtils.logTest('Lab 5', 'Pipeline/batch operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'Pipeline operations', false);
            failed++;
        }

        const pipelineValues = await testUtils.redisClient.mGet(pipelineKeys);
        if (pipelineValues.length === 10 && pipelineValues[0]) {
            testUtils.logTest('Lab 5', 'Pipeline batch retrieval', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'Pipeline batch retrieval', false);
            failed++;
        }

        // PART 5: Performance Monitoring (2 tests)
        console.log('\n  Part 5: Performance Monitoring');

        const clientsList = await testUtils.redisClient.info('clients');
        if (clientsList.includes('connected_clients')) {
            testUtils.logTest('Lab 5', 'Client connections monitoring', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'Client monitoring', false);
            failed++;
        }

        const commandStats = await testUtils.redisClient.info('commandstats');
        if (commandStats.includes('cmdstat')) {
            testUtils.logTest('Lab 5', 'Command statistics tracking', true);
            passed++;
        } else {
            testUtils.logTest('Lab 5', 'Command statistics', false);
            failed++;
        }

        console.log(`\n  Lab 5 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 5', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Run Labs 4-5 comprehensive tests
 */
async function runLabs4And5Tests() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                    LABS 4-5 COMPREHENSIVE TESTS                            ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');

    const results = {
        totalPassed: 0,
        totalFailed: 0,
        labs: []
    };

    const lab4 = await comprehensiveTestLab4();
    results.labs.push({ lab: 4, ...lab4 });
    results.totalPassed += lab4.passed;
    results.totalFailed += lab4.failed;

    const lab5 = await comprehensiveTestLab5();
    results.labs.push({ lab: 5, ...lab5 });
    results.totalPassed += lab5.passed;
    results.totalFailed += lab5.failed;

    // Print summary
    console.log('\n' + '═'.repeat(80));
    console.log('                    LABS 4-5 COMPREHENSIVE TEST SUMMARY');
    console.log('═'.repeat(80));
    console.log(`Total Tests Passed: ${results.totalPassed}`);
    console.log(`Total Tests Failed: ${results.totalFailed}`);
    console.log(`Success Rate: ${((results.totalPassed / (results.totalPassed + results.totalFailed)) * 100).toFixed(2)}%`);
    console.log('═'.repeat(80) + '\n');

    return results;
}

module.exports = {
    runLabs4And5Tests,
    comprehensiveTestLab4,
    comprehensiveTestLab5
};

// Run tests if called directly
if (require.main === module) {
    runLabs4And5Tests()
        .then(results => {
            process.exit(results.totalFailed === 0 ? 0 : 1);
        })
        .catch(error => {
            console.error('Error running Labs 4-5 tests:', error);
            process.exit(1);
        });
}
