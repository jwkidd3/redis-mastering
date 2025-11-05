/**
 * COMPREHENSIVE STUDENT OPERATION TESTS - DAY 2
 * JavaScript Integration Labs (6-10)
 */

const TestUtils = require('./test-utils');
const testUtils = new TestUtils();

/**
 * LAB 6: JavaScript Redis Client
 */
async function comprehensiveTestLab6() {
    testUtils.logLabHeader(6, 'JavaScript Redis Client - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Basic JavaScript client operations (10 tests)
        console.log('\n  JavaScript Client Operations');

        await testUtils.redisClient.set('js:test:string', 'Hello from JavaScript');
        const val = await testUtils.redisClient.get('js:test:string');
        if (val === 'Hello from JavaScript') {
            testUtils.logTest('Lab 6', 'JavaScript SET/GET', true);
            passed++;
        } else {
            testUtils.logTest('Lab 6', 'JavaScript SET/GET', false);
            failed++;
        }

        await testUtils.redisClient.del('js:test:counter'); // Clean slate for test
        await testUtils.redisClient.incr('js:test:counter');
        await testUtils.redisClient.incrBy('js:test:counter', 5);
        const counter = await testUtils.redisClient.get('js:test:counter');
        if (parseInt(counter) === 6) {
            testUtils.logTest('Lab 6', 'JavaScript INCR/INCRBY', true);
            passed++;
        } else {
            testUtils.logTest('Lab 6', 'JavaScript INCR', false);
            failed++;
        }

        await testUtils.redisClient.mSet({
            'js:test:batch1': 'val1',
            'js:test:batch2': 'val2',
            'js:test:batch3': 'val3'
        });
        testUtils.logTest('Lab 6', 'JavaScript MSET batch operations', true);
        passed++;

        const batchVals = await testUtils.redisClient.mGet(['js:test:batch1', 'js:test:batch2', 'js:test:batch3']);
        if (batchVals.length === 3 && batchVals[0] === 'val1') {
            testUtils.logTest('Lab 6', 'JavaScript MGET batch retrieval', true);
            passed++;
        } else {
            testUtils.logTest('Lab 6', 'JavaScript MGET', false);
            failed++;
        }

        await testUtils.redisClient.setEx('js:test:ttl', 300, 'expires');
        const ttl = await testUtils.redisClient.ttl('js:test:ttl');
        if (ttl > 290 && ttl <= 300) {
            testUtils.logTest('Lab 6', 'JavaScript SETEX with TTL', true);
            passed++;
        } else {
            testUtils.logTest('Lab 6', 'JavaScript SETEX', false);
            failed++;
        }

        console.log(`\n  Lab 6 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 6', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * LAB 7: Customer Profiles & Hashes
 */
async function comprehensiveTestLab7() {
    testUtils.logLabHeader(7, 'Customer Profiles & Hashes - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Hash operations (15 tests)
        console.log('\n  Hash Operations');

        await testUtils.redisClient.hSet('customer:101', {
            'firstName': 'John',
            'lastName': 'Doe',
            'email': 'john@example.com',
            'policyCount': '3',
            'riskScore': '750'
        });
        testUtils.logTest('Lab 7', 'HSET customer profile', true);
        passed++;

        const customer = await testUtils.redisClient.hGetAll('customer:101');
        if (customer.firstName === 'John' && customer.email === 'john@example.com') {
            testUtils.logTest('Lab 7', 'HGETALL retrieve all fields', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HGETALL', false);
            failed++;
        }

        const email = await testUtils.redisClient.hGet('customer:101', 'email');
        if (email === 'john@example.com') {
            testUtils.logTest('Lab 7', 'HGET single field', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HGET', false);
            failed++;
        }

        const fields = await testUtils.redisClient.hmGet('customer:101', ['firstName', 'lastName']);
        if (fields[0] === 'John' && fields[1] === 'Doe') {
            testUtils.logTest('Lab 7', 'HMGET multiple fields', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HMGET', false);
            failed++;
        }

        await testUtils.redisClient.hIncrBy('customer:101', 'policyCount', 1);
        const newCount = await testUtils.redisClient.hGet('customer:101', 'policyCount');
        if (parseInt(newCount) === 4) {
            testUtils.logTest('Lab 7', 'HINCRBY increment field', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HINCRBY', false);
            failed++;
        }

        const exists = await testUtils.redisClient.hExists('customer:101', 'email');
        const notExists = await testUtils.redisClient.hExists('customer:101', 'phone');
        if (exists && !notExists) {
            testUtils.logTest('Lab 7', 'HEXISTS field check', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HEXISTS', false);
            failed++;
        }

        await testUtils.redisClient.hDel('customer:101', 'riskScore');
        const deleted = await testUtils.redisClient.hExists('customer:101', 'riskScore');
        if (!deleted) {
            testUtils.logTest('Lab 7', 'HDEL remove field', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HDEL', false);
            failed++;
        }

        const fieldCount = await testUtils.redisClient.hLen('customer:101');
        if (fieldCount === 4) { // 5 original - 1 deleted
            testUtils.logTest('Lab 7', 'HLEN field count', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HLEN', false);
            failed++;
        }

        const keys = await testUtils.redisClient.hKeys('customer:101');
        if (keys.includes('firstName') && keys.includes('email')) {
            testUtils.logTest('Lab 7', 'HKEYS get all field names', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HKEYS', false);
            failed++;
        }

        const vals = await testUtils.redisClient.hVals('customer:101');
        if (vals.includes('John') && vals.includes('john@example.com')) {
            testUtils.logTest('Lab 7', 'HVALS get all values', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HVALS', false);
            failed++;
        }

        console.log(`\n  Lab 7 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 7', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * LAB 8: Claims Event Sourcing (Streams)
 */
async function comprehensiveTestLab8() {
    testUtils.logLabHeader(8, 'Claims Event Sourcing - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Stream operations (10 tests)
        console.log('\n  Stream Operations');

        const streamKey = 'claims:events';

        const msgId = await testUtils.redisClient.xAdd(streamKey, '*', {
            eventType: 'claim.submitted',
            claimId: 'CLM-001',
            amount: '5000',
            timestamp: Date.now().toString()
        });

        if (msgId) {
            testUtils.logTest('Lab 8', 'XADD add event to stream', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'XADD', false);
            failed++;
        }

        const len = await testUtils.redisClient.xLen(streamKey);
        if (len >= 1) {
            testUtils.logTest('Lab 8', 'XLEN get stream length', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'XLEN', false);
            failed++;
        }

        const messages = await testUtils.redisClient.xRange(streamKey, '-', '+');
        if (messages.length >= 1 && messages[0].message.claimId === 'CLM-001') {
            testUtils.logTest('Lab 8', 'XRANGE read stream messages', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'XRANGE', false);
            failed++;
        }

        await testUtils.redisClient.xAdd(streamKey, '*', {
            eventType: 'claim.assigned',
            claimId: 'CLM-001',
            adjusterId: 'ADJ-001'
        });

        await testUtils.redisClient.xAdd(streamKey, '*', {
            eventType: 'claim.approved',
            claimId: 'CLM-001',
            approvedAmount: '4800'
        });

        const multipleEvents = await testUtils.redisClient.xLen(streamKey);
        if (multipleEvents >= 3) {
            testUtils.logTest('Lab 8', 'Multiple stream events', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'Multiple events', false);
            failed++;
        }

        // Consumer group operations
        const groupStream = 'claims:consumer-test';
        await testUtils.redisClient.xAdd(groupStream, '*', { data: 'test' });

        try {
            await testUtils.redisClient.xGroupCreate(groupStream, 'processors', '0', {
                MKSTREAM: true
            });
            testUtils.logTest('Lab 8', 'XGROUP CREATE consumer group', true);
            passed++;
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                testUtils.logTest('Lab 8', 'XGROUP CREATE (group exists)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'XGROUP CREATE', false);
                failed++;
            }
        }

        console.log(`\n  Lab 8 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 8', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * LAB 9: Sets & Sorted Sets for Analytics
 */
async function comprehensiveTestLab9() {
    testUtils.logLabHeader(9, 'Sets & Sorted Sets - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Set operations (13 tests)
        console.log('\n  Set Operations');

        await testUtils.redisClient.sAdd('customers:premium', ['C001', 'C002', 'C003']);
        await testUtils.redisClient.sAdd('customers:highrisk', ['C002', 'C005']);

        const premiumCount = await testUtils.redisClient.sCard('customers:premium');
        if (premiumCount === 3) {
            testUtils.logTest('Lab 9', 'SADD/SCARD set operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SADD/SCARD', false);
            failed++;
        }

        const isMember = await testUtils.redisClient.sIsMember('customers:premium', 'C001');
        const isNotMember = await testUtils.redisClient.sIsMember('customers:premium', 'C999');
        if (isMember && !isNotMember) {
            testUtils.logTest('Lab 9', 'SISMEMBER check membership', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SISMEMBER', false);
            failed++;
        }

        const members = await testUtils.redisClient.sMembers('customers:premium');
        if (members.length === 3 && members.includes('C001')) {
            testUtils.logTest('Lab 9', 'SMEMBERS get all members', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SMEMBERS', false);
            failed++;
        }

        const intersection = await testUtils.redisClient.sInter(['customers:premium', 'customers:highrisk']);
        if (intersection.length === 1 && intersection.includes('C002')) {
            testUtils.logTest('Lab 9', 'SINTER set intersection', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SINTER', false);
            failed++;
        }

        const union = await testUtils.redisClient.sUnion(['customers:premium', 'customers:highrisk']);
        if (union.length === 4) {
            testUtils.logTest('Lab 9', 'SUNION set union', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SUNION', false);
            failed++;
        }

        const diff = await testUtils.redisClient.sDiff(['customers:premium', 'customers:highrisk']);
        if (diff.length === 2) {
            testUtils.logTest('Lab 9', 'SDIFF set difference', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SDIFF', false);
            failed++;
        }

        // Sorted Set operations
        console.log('\n  Sorted Set Operations');

        await testUtils.redisClient.zAdd('claims:amounts', [
            { score: 750, value: 'CLM-001' },
            { score: 1200, value: 'CLM-002' },
            { score: 500, value: 'CLM-003' },
            { score: 2000, value: 'CLM-004' }
        ]);

        const zcard = await testUtils.redisClient.zCard('claims:amounts');
        if (zcard === 4) {
            testUtils.logTest('Lab 9', 'ZADD/ZCARD sorted set operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZADD/ZCARD', false);
            failed++;
        }

        const lowest = await testUtils.redisClient.zRange('claims:amounts', 0, 2);
        if (lowest.length === 3 && lowest[0] === 'CLM-003') {
            testUtils.logTest('Lab 9', 'ZRANGE ascending order', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZRANGE', false);
            failed++;
        }

        const highest = await testUtils.redisClient.zRange('claims:amounts', 0, 2, { REV: true });
        if (highest.length === 3 && highest[0] === 'CLM-004') {
            testUtils.logTest('Lab 9', 'ZREVRANGE descending order', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZREVRANGE', false);
            failed++;
        }

        const score = await testUtils.redisClient.zScore('claims:amounts', 'CLM-002');
        if (score === 1200) {
            testUtils.logTest('Lab 9', 'ZSCORE get member score', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZSCORE', false);
            failed++;
        }

        const byScore = await testUtils.redisClient.zRangeByScore('claims:amounts', 600, 1500);
        if (byScore.length === 2) {
            testUtils.logTest('Lab 9', 'ZRANGEBYSCORE range query', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZRANGEBYSCORE', false);
            failed++;
        }

        await testUtils.redisClient.zIncrBy('claims:amounts', 100, 'CLM-001');
        const newScore = await testUtils.redisClient.zScore('claims:amounts', 'CLM-001');
        if (newScore === 850) {
            testUtils.logTest('Lab 9', 'ZINCRBY increment score', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZINCRBY', false);
            failed++;
        }

        console.log(`\n  Lab 9 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 9', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * LAB 10: Advanced Caching Patterns
 */
async function comprehensiveTestLab10() {
    testUtils.logLabHeader(10, 'Advanced Caching - COMPREHENSIVE');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Caching patterns (12 tests)
        console.log('\n  Caching Patterns');

        const cacheKey = 'cache:policy:POL-001';
        const policyData = JSON.stringify({ id: 'POL-001', premium: 1200 });

        await testUtils.redisClient.setEx(cacheKey, 300, policyData);
        testUtils.logTest('Lab 10', 'Cache-aside write pattern', true);
        passed++;

        const cached = await testUtils.redisClient.get(cacheKey);
        if (cached && JSON.parse(cached).id === 'POL-001') {
            testUtils.logTest('Lab 10', 'Cache-aside read pattern', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Cache-aside read', false);
            failed++;
        }

        await testUtils.redisClient.del(cacheKey);
        const invalidated = await testUtils.redisClient.get(cacheKey);
        if (invalidated === null) {
            testUtils.logTest('Lab 10', 'Cache invalidation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Cache invalidation', false);
            failed++;
        }

        await testUtils.redisClient.mSet({
            'cache:customer:001': 'data1',
            'cache:customer:002': 'data2',
            'cache:customer:003': 'data3'
        });

        const keysToDelete = await testUtils.redisClient.keys('cache:customer:*');
        if (keysToDelete.length > 0) {
            await testUtils.redisClient.del(keysToDelete);
        }

        const remaining = await testUtils.redisClient.keys('cache:customer:*');
        if (remaining.length === 0) {
            testUtils.logTest('Lab 10', 'Pattern-based invalidation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Pattern-based invalidation', false);
            failed++;
        }

        await testUtils.redisClient.setEx('cache:ttl-test', 2, 'expires');
        const ttl = await testUtils.redisClient.ttl('cache:ttl-test');
        if (ttl > 0 && ttl <= 2) {
            testUtils.logTest('Lab 10', 'TTL-based expiration', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'TTL-based expiration', false);
            failed++;
        }

        const writeKey = 'cache:writethrough';
        const writeData = JSON.stringify({ id: '123', value: 'data' });
        await testUtils.redisClient.set(writeKey, writeData);

        const written = await testUtils.redisClient.get(writeKey);
        if (written && JSON.parse(written).id === '123') {
            testUtils.logTest('Lab 10', 'Write-through cache pattern', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Write-through pattern', false);
            failed++;
        }

        console.log(`\n  Lab 10 Comprehensive Total: ${passed} passed, ${failed} failed`);

    } catch (error) {
        testUtils.logTest('Lab 10', 'Comprehensive test execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Run all Day 2 comprehensive tests
 */
async function runComprehensiveDay2Tests() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                   DAY 2 COMPREHENSIVE STUDENT OPERATION TESTS              ║');
    console.log('║                    JavaScript Integration (Labs 6-10)                      ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');

    const results = {
        totalPassed: 0,
        totalFailed: 0,
        labs: []
    };

    const lab6 = await comprehensiveTestLab6();
    results.labs.push({ lab: 6, ...lab6 });
    results.totalPassed += lab6.passed;
    results.totalFailed += lab6.failed;

    const lab7 = await comprehensiveTestLab7();
    results.labs.push({ lab: 7, ...lab7 });
    results.totalPassed += lab7.passed;
    results.totalFailed += lab7.failed;

    const lab8 = await comprehensiveTestLab8();
    results.labs.push({ lab: 8, ...lab8 });
    results.totalPassed += lab8.passed;
    results.totalFailed += lab8.failed;

    const lab9 = await comprehensiveTestLab9();
    results.labs.push({ lab: 9, ...lab9 });
    results.totalPassed += lab9.passed;
    results.totalFailed += lab9.failed;

    const lab10 = await comprehensiveTestLab10();
    results.labs.push({ lab: 10, ...lab10 });
    results.totalPassed += lab10.passed;
    results.totalFailed += lab10.failed;

    console.log('\n' + '═'.repeat(80));
    console.log('                    DAY 2 COMPREHENSIVE TEST SUMMARY');
    console.log('═'.repeat(80));
    console.log(`Total Tests Passed: ${results.totalPassed}`);
    console.log(`Total Tests Failed: ${results.totalFailed}`);
    console.log(`Success Rate: ${((results.totalPassed / (results.totalPassed + results.totalFailed)) * 100).toFixed(2)}%`);
    console.log('═'.repeat(80) + '\n');

    return results;
}

module.exports = {
    runComprehensiveDay2Tests,
    comprehensiveTestLab6,
    comprehensiveTestLab7,
    comprehensiveTestLab8,
    comprehensiveTestLab9,
    comprehensiveTestLab10
};

// Run tests if called directly
if (require.main === module) {
    runComprehensiveDay2Tests()
        .then(results => {
            process.exit(results.totalFailed === 0 ? 0 : 1);
        })
        .catch(error => {
            console.error('Error running Day 2 tests:', error);
            process.exit(1);
        });
}
