/**
 * Integration Tests for Day 2 Labs (Labs 6-10)
 * Focus: JavaScript Integration
 */

const TestUtils = require('./test-utils');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;

const execAsync = promisify(exec);
const testUtils = new TestUtils();

/**
 * Lab 6: JavaScript Redis Client Setup
 */
async function testLab6() {
    testUtils.logLabHeader(6, 'JavaScript Redis Client Setup');

    const labDir = path.join(process.cwd(), 'lab6-javascript-redis-client');
    let passed = 0;
    let failed = 0;

    try {
        // Test 1: Check if lab directory and package.json exist
        const labExists = await testUtils.fileExists(labDir);
        const packageExists = await testUtils.fileExists(path.join(labDir, 'package.json'));

        if (labExists && packageExists) {
            testUtils.logTest('Lab 6', 'Lab structure exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 6', 'Lab structure exists', false, 'Missing lab directory or package.json');
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if key files exist
        const keyFiles = [
            'redis-client.js',
            'test-connection.js',
            'docker-compose.yml'
        ];

        for (const file of keyFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, file));
            if (exists) {
                testUtils.logTest('Lab 6', `${file} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 6', `${file} exists`, false);
                failed++;
            }
        }

        // Test 3: Test Redis connection with JavaScript client
        try {
            const connectionTest = await testUtils.executeNodeScript('test-connection.js', labDir);
            if (connectionTest.success && (connectionTest.stdout.includes('Connected') || connectionTest.stdout.includes('✓'))) {
                testUtils.logTest('Lab 6', 'JavaScript Redis connection', true);
                passed++;
            } else {
                testUtils.logTest('Lab 6', 'JavaScript Redis connection', false, connectionTest.stderr);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 6', 'JavaScript Redis connection', false, error.message);
            failed++;
        }

        // Test 4: Test basic operations through JavaScript
        await testUtils.initRedisClient();
        await testUtils.redisClient.set('test:lab6:js', 'JavaScript Redis Client');
        const value = await testUtils.redisClient.get('test:lab6:js');

        if (value === 'JavaScript Redis Client') {
            testUtils.logTest('Lab 6', 'Basic operations via JS client', true);
            passed++;
        } else {
            testUtils.logTest('Lab 6', 'Basic operations via JS client', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 6', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 7: Customer Profiles & Hashes
 */
async function testLab7() {
    testUtils.logLabHeader(7, 'Customer Profiles & Hashes');

    const labDir = path.join(process.cwd(), 'lab7-customer-policy-hashes');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check if lab structure exists
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 7', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Test hash operations - HSET
        await testUtils.redisClient.hSet('customer:CUST-001', {
            'customer_id': 'CUST-001',
            'first_name': 'John',
            'last_name': 'Doe',
            'email': 'john.doe@email.com',
            'policy_count': '3',
            'status': 'active'
        });

        const customer = await testUtils.redisClient.hGetAll('customer:CUST-001');

        if (customer.first_name === 'John' && customer.email === 'john.doe@email.com') {
            testUtils.logTest('Lab 7', 'HSET/HGETALL operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HSET/HGETALL operations', false);
            failed++;
        }

        // Test 3: HGET single field
        const email = await testUtils.redisClient.hGet('customer:CUST-001', 'email');
        if (email === 'john.doe@email.com') {
            testUtils.logTest('Lab 7', 'HGET operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HGET operation', false);
            failed++;
        }

        // Test 4: HMGET multiple fields
        const fields = await testUtils.redisClient.hmGet('customer:CUST-001', ['first_name', 'last_name', 'email']);
        if (fields[0] === 'John' && fields[1] === 'Doe') {
            testUtils.logTest('Lab 7', 'HMGET operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HMGET operation', false);
            failed++;
        }

        // Test 5: HINCRBY operation (increment policy count)
        await testUtils.redisClient.hSet('customer:CUST-002', 'policy_count', '2');
        await testUtils.redisClient.hIncrBy('customer:CUST-002', 'policy_count', 1);
        const policyCount = await testUtils.redisClient.hGet('customer:CUST-002', 'policy_count');

        if (policyCount === '3') {
            testUtils.logTest('Lab 7', 'HINCRBY operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HINCRBY operation', false);
            failed++;
        }

        // Test 6: HEXISTS operation
        const exists = await testUtils.redisClient.hExists('customer:CUST-001', 'email');
        const notExists = await testUtils.redisClient.hExists('customer:CUST-001', 'phone');

        if (exists && !notExists) {
            testUtils.logTest('Lab 7', 'HEXISTS operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HEXISTS operation', false);
            failed++;
        }

        // Test 7: HDEL operation
        await testUtils.redisClient.hSet('customer:CUST-003', 'temp_field', 'temp_value');
        const deleted = await testUtils.redisClient.hDel('customer:CUST-003', 'temp_field');
        const stillExists = await testUtils.redisClient.hExists('customer:CUST-003', 'temp_field');

        if (deleted === 1 && !stillExists) {
            testUtils.logTest('Lab 7', 'HDEL operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HDEL operation', false);
            failed++;
        }

        // Test 8: HLEN operation
        const fieldCount = await testUtils.redisClient.hLen('customer:CUST-001');
        if (fieldCount >= 6) {
            testUtils.logTest('Lab 7', 'HLEN operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HLEN operation', false);
            failed++;
        }

        // Test 9: HKEYS operation
        const keys = await testUtils.redisClient.hKeys('customer:CUST-001');
        if (keys.includes('first_name') && keys.includes('email')) {
            testUtils.logTest('Lab 7', 'HKEYS operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HKEYS operation', false);
            failed++;
        }

        // Test 10: HVALS operation
        const values = await testUtils.redisClient.hVals('customer:CUST-001');
        if (values.includes('John') && values.includes('john.doe@email.com')) {
            testUtils.logTest('Lab 7', 'HVALS operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'HVALS operation', false);
            failed++;
        }

        // Test 11: Check if customer service exists
        const customerServiceExists = await testUtils.fileExists(path.join(labDir, 'customer-service.js'));
        if (customerServiceExists) {
            testUtils.logTest('Lab 7', 'Customer service file exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 7', 'Customer service file exists', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 7', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 8: Claims Event Sourcing (Streams)
 */
async function testLab8() {
    testUtils.logLabHeader(8, 'Claims Event Sourcing (Streams)');

    const labDir = path.join(process.cwd(), 'lab8-claims-event-sourcing');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 8', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Test stream XADD operation
        const streamKey = 'test:lab8:claims-stream';
        const messageId = await testUtils.redisClient.xAdd(streamKey, '*', {
            event_type: 'claim.submitted',
            claim_id: 'CLM-001',
            customer_id: 'CUST-001',
            amount: '750',
            timestamp: new Date().toISOString()
        });

        if (messageId) {
            testUtils.logTest('Lab 8', 'XADD operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'XADD operation', false);
            failed++;
        }

        // Test 3: Test stream XLEN operation
        const streamLength = await testUtils.redisClient.xLen(streamKey);
        if (streamLength >= 1) {
            testUtils.logTest('Lab 8', 'XLEN operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'XLEN operation', false);
            failed++;
        }

        // Test 4: Test stream XRANGE operation
        const messages = await testUtils.redisClient.xRange(streamKey, '-', '+');
        if (messages.length >= 1 && messages[0].message.claim_id === 'CLM-001') {
            testUtils.logTest('Lab 8', 'XRANGE operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'XRANGE operation', false);
            failed++;
        }

        // Test 5: Add multiple events to stream
        await testUtils.redisClient.xAdd(streamKey, '*', {
            event_type: 'claim.assigned',
            claim_id: 'CLM-001',
            adjuster_id: 'ADJ-001'
        });

        await testUtils.redisClient.xAdd(streamKey, '*', {
            event_type: 'claim.approved',
            claim_id: 'CLM-001',
            approved_amount: '700'
        });

        const allMessages = await testUtils.redisClient.xLen(streamKey);
        if (allMessages >= 3) {
            testUtils.logTest('Lab 8', 'Multiple stream events', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'Multiple stream events', false);
            failed++;
        }

        // Test 6: Test consumer group creation
        const groupKey = 'test:lab8:group-stream';
        await testUtils.redisClient.xAdd(groupKey, '*', { data: 'test' });

        try {
            await testUtils.redisClient.xGroupCreate(groupKey, 'test-group', '0', { MKSTREAM: true });
            testUtils.logTest('Lab 8', 'XGROUP CREATE operation', true);
            passed++;
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                // Group already exists, which is fine
                testUtils.logTest('Lab 8', 'XGROUP CREATE operation', true, 'Group already exists');
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'XGROUP CREATE operation', false, error.message);
                failed++;
            }
        }

        // Test 7: Test XREADGROUP operation
        try {
            const groupMessages = await testUtils.redisClient.xReadGroup(
                'test-group',
                'consumer-1',
                [{ key: groupKey, id: '>' }],
                { COUNT: 10, BLOCK: 100 }
            );

            testUtils.logTest('Lab 8', 'XREADGROUP operation', true);
            passed++;
        } catch (error) {
            testUtils.logTest('Lab 8', 'XREADGROUP operation', false, error.message);
            failed++;
        }

        // Test 8: Check if event producer exists
        const producerExists = await testUtils.fileExists(path.join(labDir, 'event-producer.js'));
        if (producerExists) {
            testUtils.logTest('Lab 8', 'Event producer file exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'Event producer file exists', false);
            failed++;
        }

        // Test 9: Check if event consumer exists
        const consumerExists = await testUtils.fileExists(path.join(labDir, 'event-consumer.js'));
        if (consumerExists) {
            testUtils.logTest('Lab 8', 'Event consumer file exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 8', 'Event consumer file exists', false);
            failed++;
        }

        // --- Part D: Inspection, Reliability, DLQ ---

        // Test 10: XREAD (non-group) — tail latest claims
        try {
            const stream = 'test:lab8d:claims';
            await testUtils.redisClient.xAdd(stream, '*', { event: 'claim_submitted', claim_id: 'CLM-D001' });
            await testUtils.redisClient.xAdd(stream, '*', { event: 'claim_submitted', claim_id: 'CLM-D002' });

            const result = await testUtils.redisClient.xRead(
                [{ key: stream, id: '0' }],
                { COUNT: 10 }
            );
            // result shape: [{ name: stream, messages: [{ id, message }] }]
            if (result && result[0] && result[0].messages.length >= 2) {
                testUtils.logTest('Lab 8', 'Part D: XREAD (non-group read)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'Part D: XREAD', false, 'Expected >= 2 messages');
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 8', 'Part D: XREAD', false, error.message);
            failed++;
        }

        // Test 11: XINFO STREAM — inspect stream metadata
        try {
            const stream = 'test:lab8d:info-stream';
            await testUtils.redisClient.xAdd(stream, '*', { a: '1' });
            const info = await testUtils.redisClient.xInfoStream(stream);
            if (info && typeof info.length === 'number' && info.length >= 1) {
                testUtils.logTest('Lab 8', 'Part D: XINFO STREAM', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'Part D: XINFO STREAM', false, `info=${JSON.stringify(info)}`);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 8', 'Part D: XINFO STREAM', false, error.message);
            failed++;
        }

        // Test 12: XPENDING — after XREADGROUP without XACK, message should be pending
        try {
            const stream = 'test:lab8d:pending-stream';
            const group = 'g-pending';
            await testUtils.redisClient.xAdd(stream, '*', { claim_id: 'CLM-D100' });
            try {
                await testUtils.redisClient.xGroupCreate(stream, group, '0', { MKSTREAM: true });
            } catch (e) { /* BUSYGROUP OK */ }
            await testUtils.redisClient.xReadGroup(
                group, 'worker-d1',
                [{ key: stream, id: '>' }],
                { COUNT: 10, BLOCK: 100 }
            );
            const pending = await testUtils.redisClient.xPending(stream, group);
            // pending shape: { pending: n, firstId, lastId, consumers: [...] }
            if (pending && pending.pending >= 1) {
                testUtils.logTest('Lab 8', 'Part D: XPENDING (unacknowledged entries visible)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'Part D: XPENDING', false, `pending=${JSON.stringify(pending)}`);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 8', 'Part D: XPENDING', false, error.message);
            failed++;
        }

        // Test 13: XACK — acknowledge drains the PEL
        try {
            const stream = 'test:lab8d:ack-stream';
            const group = 'g-ack';
            await testUtils.redisClient.xAdd(stream, '*', { claim_id: 'CLM-D200' });
            try {
                await testUtils.redisClient.xGroupCreate(stream, group, '0', { MKSTREAM: true });
            } catch (e) { /* BUSYGROUP OK */ }
            const msgs = await testUtils.redisClient.xReadGroup(
                group, 'worker-d2',
                [{ key: stream, id: '>' }],
                { COUNT: 10, BLOCK: 100 }
            );
            const id = msgs[0].messages[0].id;
            const ackCount = await testUtils.redisClient.xAck(stream, group, id);
            const pendingAfter = await testUtils.redisClient.xPending(stream, group);
            if (ackCount === 1 && pendingAfter.pending === 0) {
                testUtils.logTest('Lab 8', 'Part D: XACK (drains PEL)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'Part D: XACK', false,
                    `ack=${ackCount}, pending=${pendingAfter.pending}`);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 8', 'Part D: XACK', false, error.message);
            failed++;
        }

        // Test 14: Dead-Letter Queue (DLQ) pattern — after N retries, move to claims:dlq
        try {
            const stream = 'test:lab8d:dlq-claims';
            const dlq = 'test:lab8d:claims:dlq';
            const group = 'g-dlq';

            // Clean up any prior state
            await testUtils.redisClient.del(stream);
            await testUtils.redisClient.del(dlq);

            const addedId = await testUtils.redisClient.xAdd(stream, '*', {
                event: 'claim_submitted', claim_id: 'CLM-BAD', amount: 'NaN'
            });
            try {
                await testUtils.redisClient.xGroupCreate(stream, group, '0', { MKSTREAM: true });
            } catch (e) { /* BUSYGROUP OK */ }

            // Read the event — pretend processing fails 3 times
            await testUtils.redisClient.xReadGroup(
                group, 'worker-d3',
                [{ key: stream, id: '>' }],
                { COUNT: 1, BLOCK: 100 }
            );
            const retryKey = 'test:lab8d:retries:CLM-BAD';
            await testUtils.redisClient.incr(retryKey);
            await testUtils.redisClient.incr(retryKey);
            await testUtils.redisClient.incr(retryKey);
            const retries = parseInt(await testUtils.redisClient.get(retryKey), 10);

            if (retries >= 3) {
                // Move to DLQ and ack off the main stream
                await testUtils.redisClient.xAdd(dlq, '*', {
                    original_id: addedId,
                    reason: 'malformed_payload',
                    claim_id: 'CLM-BAD'
                });
                await testUtils.redisClient.xAck(stream, group, addedId);
                await testUtils.redisClient.del(retryKey);
            }

            const dlqLen = await testUtils.redisClient.xLen(dlq);
            const mainPending = await testUtils.redisClient.xPending(stream, group);
            if (dlqLen === 1 && mainPending.pending === 0) {
                testUtils.logTest('Lab 8', 'Part D: DLQ pattern (moved after N retries, main acked)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'Part D: DLQ pattern', false,
                    `dlqLen=${dlqLen}, mainPending=${mainPending.pending}`);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 8', 'Part D: DLQ pattern', false, error.message);
            failed++;
        }

        // Test 15: XCLAIM — reassign a pending entry from one consumer to another
        try {
            const stream = 'claims:test-xclaim';
            const group = 'g-xclaim';

            // Clean up any prior state
            await testUtils.redisClient.del(stream);

            const entryId = await testUtils.redisClient.xAdd(stream, '*', {
                claim_id: 'CLM-XCLM-001', event: 'claim_submitted'
            });

            try {
                await testUtils.redisClient.xGroupCreate(stream, group, '0', { MKSTREAM: true });
            } catch (e) { /* BUSYGROUP OK */ }

            // Consumer A reads — entry now in consumer A's pending list
            await testUtils.redisClient.xReadGroup(
                group, 'consumer-A',
                [{ key: stream, id: '>' }],
                { COUNT: 1, BLOCK: 100 }
            );

            // XCLAIM transfers ownership from consumer A to consumer B with min-idle-time=0
            await testUtils.redisClient.sendCommand([
                'XCLAIM', stream, group, 'consumer-B', '0', entryId
            ]);

            // Verify entry now belongs to consumer B via XPENDING
            const detail = await testUtils.redisClient.sendCommand([
                'XPENDING', stream, group, '-', '+', '10'
            ]);
            // detail is an array of [id, consumer, idle-ms, delivery-count]
            let ownedByB = false;
            if (Array.isArray(detail)) {
                for (const entry of detail) {
                    if (Array.isArray(entry) && entry[0] === entryId && entry[1] === 'consumer-B') {
                        ownedByB = true;
                        break;
                    }
                }
            }

            // Cleanup
            await testUtils.redisClient.del(stream);

            if (ownedByB) {
                testUtils.logTest('Lab 8', 'XCLAIM (ownership transferred A -> B)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 8', 'XCLAIM', false,
                    `detail=${JSON.stringify(detail)}`);
                failed++;
            }
        } catch (error) {
            testUtils.logTest('Lab 8', 'XCLAIM', false, error.message);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 8', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 9: Insurance Analytics (Sets & Sorted Sets)
 */
async function testLab9() {
    testUtils.logLabHeader(9, 'Insurance Analytics (Sets & Sorted Sets)');

    const labDir = path.join(process.cwd(), 'lab9-sets-analytics');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 9', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Test SET operations - SADD
        await testUtils.redisClient.sAdd('test:lab9:auto-customers', ['CUST-001', 'CUST-002', 'CUST-003']);
        await testUtils.redisClient.sAdd('test:lab9:home-customers', ['CUST-002', 'CUST-003', 'CUST-004']);

        const autoCount = await testUtils.redisClient.sCard('test:lab9:auto-customers');
        if (autoCount === 3) {
            testUtils.logTest('Lab 9', 'SADD/SCARD operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SADD/SCARD operations', false);
            failed++;
        }

        // Test 3: SISMEMBER operation
        const isMember = await testUtils.redisClient.sIsMember('test:lab9:auto-customers', 'CUST-001');
        const isNotMember = await testUtils.redisClient.sIsMember('test:lab9:auto-customers', 'CUST-999');

        if (isMember && !isNotMember) {
            testUtils.logTest('Lab 9', 'SISMEMBER operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SISMEMBER operation', false);
            failed++;
        }

        // Test 4: SMEMBERS operation
        const members = await testUtils.redisClient.sMembers('test:lab9:auto-customers');
        if (members.length === 3 && members.includes('CUST-001')) {
            testUtils.logTest('Lab 9', 'SMEMBERS operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SMEMBERS operation', false);
            failed++;
        }

        // Test 5: SINTER operation (intersection)
        const intersection = await testUtils.redisClient.sInter(['test:lab9:auto-customers', 'test:lab9:home-customers']);
        if (intersection.length === 2 && intersection.includes('CUST-002')) {
            testUtils.logTest('Lab 9', 'SINTER operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SINTER operation', false);
            failed++;
        }

        // Test 6: SUNION operation (union)
        const union = await testUtils.redisClient.sUnion(['test:lab9:auto-customers', 'test:lab9:home-customers']);
        if (union.length === 4) {
            testUtils.logTest('Lab 9', 'SUNION operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SUNION operation', false);
            failed++;
        }

        // Test 7: SDIFF operation (difference)
        const diff = await testUtils.redisClient.sDiff(['test:lab9:auto-customers', 'test:lab9:home-customers']);
        if (diff.length === 1 && diff.includes('CUST-001')) {
            testUtils.logTest('Lab 9', 'SDIFF operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'SDIFF operation', false);
            failed++;
        }

        // Test 8: Sorted Set - ZADD operation
        await testUtils.redisClient.zAdd('test:lab9:claim-amounts', [
            { score: 750, value: 'CLM-001' },
            { score: 1200, value: 'CLM-002' },
            { score: 500, value: 'CLM-003' },
            { score: 2000, value: 'CLM-004' }
        ]);

        const zcard = await testUtils.redisClient.zCard('test:lab9:claim-amounts');
        if (zcard === 4) {
            testUtils.logTest('Lab 9', 'ZADD/ZCARD operations', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZADD/ZCARD operations', false);
            failed++;
        }

        // Test 9: ZRANGE operation (ascending)
        const topClaims = await testUtils.redisClient.zRange('test:lab9:claim-amounts', 0, 2);
        if (topClaims.length === 3 && topClaims[0] === 'CLM-003') {
            testUtils.logTest('Lab 9', 'ZRANGE operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZRANGE operation', false);
            failed++;
        }

        // Test 10: ZREVRANGE operation (descending)
        const highestClaims = await testUtils.redisClient.zRange('test:lab9:claim-amounts', 0, 2, { REV: true });
        if (highestClaims.length === 3 && highestClaims[0] === 'CLM-004') {
            testUtils.logTest('Lab 9', 'ZREVRANGE operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZREVRANGE operation', false);
            failed++;
        }

        // Test 11: ZSCORE operation
        const score = await testUtils.redisClient.zScore('test:lab9:claim-amounts', 'CLM-002');
        if (score === 1200) {
            testUtils.logTest('Lab 9', 'ZSCORE operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZSCORE operation', false);
            failed++;
        }

        // Test 12: ZRANGEBYSCORE operation
        const midRangeClaims = await testUtils.redisClient.zRangeByScore('test:lab9:claim-amounts', 600, 1500);
        if (midRangeClaims.length === 2) {
            testUtils.logTest('Lab 9', 'ZRANGEBYSCORE operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZRANGEBYSCORE operation', false);
            failed++;
        }

        // Test 13: ZINCRBY operation
        await testUtils.redisClient.zIncrBy('test:lab9:claim-amounts', 100, 'CLM-001');
        const newScore = await testUtils.redisClient.zScore('test:lab9:claim-amounts', 'CLM-001');
        if (newScore === 850) {
            testUtils.logTest('Lab 9', 'ZINCRBY operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 9', 'ZINCRBY operation', false);
            failed++;
        }

        // Test 14: SREM — remove a member and verify SCARD decreases
        try {
            const key = 'test:lab9:srem';
            await testUtils.redisClient.del(key);
            await testUtils.redisClient.sAdd(key, ['m1', 'm2', 'm3']);
            await testUtils.redisClient.sRem(key, 'm2');
            const card = await testUtils.redisClient.sCard(key);
            if (card === 2) {
                testUtils.logTest('Lab 9', 'SREM (SADD 3, SREM 1, SCARD == 2)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 9', 'SREM', false, `SCARD=${card}`);
                failed++;
            }
            await testUtils.redisClient.del(key);
        } catch (error) {
            testUtils.logTest('Lab 9', 'SREM', false, error.message);
            failed++;
        }

        // Test 15: ZREM — remove a member and verify ZCARD decreases
        try {
            const key = 'test:lab9:zrem';
            await testUtils.redisClient.del(key);
            await testUtils.redisClient.zAdd(key, [
                { score: 1, value: 'a' },
                { score: 2, value: 'b' },
                { score: 3, value: 'c' }
            ]);
            await testUtils.redisClient.zRem(key, 'b');
            const card = await testUtils.redisClient.zCard(key);
            if (card === 2) {
                testUtils.logTest('Lab 9', 'ZREM (ZADD 3, ZREM 1, ZCARD == 2)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 9', 'ZREM', false, `ZCARD=${card}`);
                failed++;
            }
            await testUtils.redisClient.del(key);
        } catch (error) {
            testUtils.logTest('Lab 9', 'ZREM', false, error.message);
            failed++;
        }

        // Test 16: ZRANK — middle member at rank 1 (ascending score order)
        try {
            const key = 'test:lab9:zrank';
            await testUtils.redisClient.del(key);
            await testUtils.redisClient.zAdd(key, [
                { score: 10, value: 'low' },
                { score: 50, value: 'mid' },
                { score: 99, value: 'high' }
            ]);
            const rank = await testUtils.redisClient.zRank(key, 'mid');
            if (rank === 1) {
                testUtils.logTest('Lab 9', 'ZRANK (middle member rank = 1)', true);
                passed++;
            } else {
                testUtils.logTest('Lab 9', 'ZRANK', false, `rank=${rank}`);
                failed++;
            }
            await testUtils.redisClient.del(key);
        } catch (error) {
            testUtils.logTest('Lab 9', 'ZRANK', false, error.message);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 9', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 10: Advanced Caching Patterns
 */
async function testLab10() {
    testUtils.logLabHeader(10, 'Advanced Caching Patterns');

    const labDir = path.join(process.cwd(), 'lab10-advanced-caching-patterns');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 10', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if key files exist
        const keyFiles = [
            'redis-client.js',
            'test-cache-aside.js',
            'test-multi-level.js',
            'test-invalidation.js',
            'performance-test.js'
        ];

        for (const file of keyFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, file));
            if (exists) {
                testUtils.logTest('Lab 10', `${file} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 10', `${file} exists`, false);
                failed++;
            }
        }

        // Test 3: Test cache-aside pattern (basic)
        const cacheKey = 'test:lab10:policy:POL-001';
        const policyData = {
            policy_id: 'POL-001',
            type: 'auto',
            premium: '1200',
            customer_id: 'CUST-001'
        };

        // Simulate cache-aside: Check cache first
        let cachedPolicy = await testUtils.redisClient.get(cacheKey);

        if (!cachedPolicy) {
            // Cache miss - set the value
            await testUtils.redisClient.setEx(cacheKey, 300, JSON.stringify(policyData));
            testUtils.logTest('Lab 10', 'Cache-aside pattern (write)', true);
            passed++;
        }

        // Read from cache
        cachedPolicy = await testUtils.redisClient.get(cacheKey);
        const parsed = JSON.parse(cachedPolicy);

        if (parsed.policy_id === 'POL-001') {
            testUtils.logTest('Lab 10', 'Cache-aside pattern (read)', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Cache-aside pattern (read)', false);
            failed++;
        }

        // Test 4: Test cache invalidation
        await testUtils.redisClient.set('test:lab10:invalidate', 'old-value');
        await testUtils.redisClient.del('test:lab10:invalidate');
        const invalidated = await testUtils.redisClient.get('test:lab10:invalidate');

        if (invalidated === null) {
            testUtils.logTest('Lab 10', 'Cache invalidation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Cache invalidation', false);
            failed++;
        }

        // Test 5: Test pattern-based invalidation
        await testUtils.redisClient.mSet({
            'test:lab10:customer:001': 'data1',
            'test:lab10:customer:002': 'data2',
            'test:lab10:customer:003': 'data3'
        });

        // Get keys and delete
        const keysToDelete = await testUtils.redisClient.keys('test:lab10:customer:*');
        if (keysToDelete.length > 0) {
            await testUtils.redisClient.del(keysToDelete);
        }

        const remainingKeys = await testUtils.redisClient.keys('test:lab10:customer:*');
        if (remainingKeys.length === 0) {
            testUtils.logTest('Lab 10', 'Pattern-based invalidation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Pattern-based invalidation', false);
            failed++;
        }

        // Test 6: Test TTL-based expiration
        await testUtils.redisClient.setEx('test:lab10:ttl', 2, 'expires-soon');
        const ttl = await testUtils.redisClient.ttl('test:lab10:ttl');

        if (ttl > 0 && ttl <= 2) {
            testUtils.logTest('Lab 10', 'TTL-based expiration', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'TTL-based expiration', false);
            failed++;
        }

        // Test 7: Test write-through cache pattern
        const writeKey = 'test:lab10:writethrough';
        const writeData = { id: '123', value: 'data' };

        // Write to cache
        await testUtils.redisClient.set(writeKey, JSON.stringify(writeData));

        // Verify write
        const written = await testUtils.redisClient.get(writeKey);
        if (written && JSON.parse(written).id === '123') {
            testUtils.logTest('Lab 10', 'Write-through cache pattern', true);
            passed++;
        } else {
            testUtils.logTest('Lab 10', 'Write-through cache pattern', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 10', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Run all Day 2 tests
 */
async function runDay2Tests() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                          DAY 2 INTEGRATION TESTS                           ║');
    console.log('║                     JavaScript Integration (Labs 6-9)                      ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');

    const results = {
        totalPassed: 0,
        totalFailed: 0,
        labs: []
    };

    // Run all Day 2 core lab tests (Lab 10 is optional/take-home; run with --lab=10)
    const lab6 = await testLab6();
    results.labs.push({ lab: 6, ...lab6 });
    results.totalPassed += lab6.passed;
    results.totalFailed += lab6.failed;

    const lab7 = await testLab7();
    results.labs.push({ lab: 7, ...lab7 });
    results.totalPassed += lab7.passed;
    results.totalFailed += lab7.failed;

    const lab8 = await testLab8();
    results.labs.push({ lab: 8, ...lab8 });
    results.totalPassed += lab8.passed;
    results.totalFailed += lab8.failed;

    const lab9 = await testLab9();
    results.labs.push({ lab: 9, ...lab9 });
    results.totalPassed += lab9.passed;
    results.totalFailed += lab9.failed;

    return results;
}

module.exports = {
    runDay2Tests,
    testLab6,
    testLab7,
    testLab8,
    testLab9,
    testLab10
};

// Run tests if called directly
if (require.main === module) {
    runDay2Tests()
        .then(results => {
            testUtils.printTestSummary();
            process.exit(results.totalFailed === 0 ? 0 : 1);
        })
        .catch(error => {
            console.error('Error running Day 2 tests:', error);
            process.exit(1);
        });
}
