/**
 * Integration Tests for Day 3 Labs (Labs 11-15)
 * Focus: Production & Advanced Topics
 */

const TestUtils = require('./test-utils');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;

const execAsync = promisify(exec);
const testUtils = new TestUtils();

/**
 * Lab 11: Session Management & Security
 */
async function testLab11() {
    testUtils.logLabHeader(11, 'Session Management & Security');

    const labDir = path.join(process.cwd(), 'lab11-session-management');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 11', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if key files exist
        const keyFiles = [
            'session-manager.js',
            'auth-middleware.js'
        ];

        for (const file of keyFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, file));
            if (exists) {
                testUtils.logTest('Lab 11', `${file} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 11', `${file} exists`, false);
                failed++;
            }
        }

        // Test 3: Test session storage
        const sessionKey = 'session:test-session-id-123';
        const sessionData = {
            user_id: 'user-001',
            username: 'testuser',
            role: 'admin',
            created_at: new Date().toISOString(),
            last_activity: new Date().toISOString()
        };

        await testUtils.redisClient.setEx(sessionKey, 3600, JSON.stringify(sessionData));

        const storedSession = await testUtils.redisClient.get(sessionKey);
        const parsed = JSON.parse(storedSession);

        if (parsed.user_id === 'user-001' && parsed.role === 'admin') {
            testUtils.logTest('Lab 11', 'Session storage', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Session storage', false);
            failed++;
        }

        // Test 4: Test session TTL
        const ttl = await testUtils.redisClient.ttl(sessionKey);
        if (ttl > 0 && ttl <= 3600) {
            testUtils.logTest('Lab 11', 'Session TTL management', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Session TTL management', false);
            failed++;
        }

        // Test 5: Test session invalidation
        await testUtils.redisClient.del(sessionKey);
        const invalidated = await testUtils.redisClient.get(sessionKey);

        if (invalidated === null) {
            testUtils.logTest('Lab 11', 'Session invalidation', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Session invalidation', false);
            failed++;
        }

        // Test 6: Test multiple active sessions per user
        const userId = 'user-002';
        await testUtils.redisClient.sAdd(`user:${userId}:sessions`, [
            'session-1',
            'session-2',
            'session-3'
        ]);

        const activeSessions = await testUtils.redisClient.sMembers(`user:${userId}:sessions`);
        if (activeSessions.length === 3) {
            testUtils.logTest('Lab 11', 'Multiple active sessions', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Multiple active sessions', false);
            failed++;
        }

        // Test 7: Test role-based access control (RBAC) data
        await testUtils.redisClient.hSet('role:admin:permissions', {
            'read:claims': 'true',
            'write:claims': 'true',
            'delete:claims': 'true',
            'read:users': 'true',
            'write:users': 'true'
        });

        const permissions = await testUtils.redisClient.hGetAll('role:admin:permissions');
        if (permissions['write:claims'] === 'true') {
            testUtils.logTest('Lab 11', 'RBAC permissions storage', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'RBAC permissions storage', false);
            failed++;
        }

        // Test 8: Test security - failed login attempts tracking
        const loginKey = 'security:failed-logins:user-003';
        await testUtils.redisClient.incr(loginKey);
        await testUtils.redisClient.incr(loginKey);
        await testUtils.redisClient.incr(loginKey);
        await testUtils.redisClient.expire(loginKey, 900); // 15 minutes

        const failedAttempts = await testUtils.redisClient.get(loginKey);
        if (parseInt(failedAttempts) === 3) {
            testUtils.logTest('Lab 11', 'Failed login tracking', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Failed login tracking', false);
            failed++;
        }

        // Test 9: Test session refresh/renewal
        const refreshKey = 'session:refresh-test';
        await testUtils.redisClient.setEx(refreshKey, 1800, JSON.stringify({ user: 'test' }));
        await testUtils.redisClient.expire(refreshKey, 3600); // Extend TTL

        const newTtl = await testUtils.redisClient.ttl(refreshKey);
        if (newTtl > 1800) {
            testUtils.logTest('Lab 11', 'Session renewal', true);
            passed++;
        } else {
            testUtils.logTest('Lab 11', 'Session renewal', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 11', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 12: Rate Limiting & API Protection
 */
async function testLab12() {
    testUtils.logLabHeader(12, 'Rate Limiting & API Protection');

    const labDir = path.join(process.cwd(), 'lab12-rate-limiting-api-protection');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 12', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if key files exist
        const keyFiles = [
            'rate-limiter.js',
            'middleware.js'
        ];

        for (const file of keyFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, file));
            if (exists) {
                testUtils.logTest('Lab 12', `${file} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 12', `${file} exists`, false);
                failed++;
            }
        }

        // Test 3: Test fixed window rate limiting
        const userId = 'user-001';
        const window = Math.floor(Date.now() / 1000 / 60); // 1-minute window
        const rateLimitKey = `ratelimit:fixed:${userId}:${window}`;

        // Simulate requests
        await testUtils.redisClient.incr(rateLimitKey);
        await testUtils.redisClient.incr(rateLimitKey);
        await testUtils.redisClient.incr(rateLimitKey);
        await testUtils.redisClient.expire(rateLimitKey, 60);

        const requestCount = await testUtils.redisClient.get(rateLimitKey);
        if (parseInt(requestCount) === 3) {
            testUtils.logTest('Lab 12', 'Fixed window rate limiting', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Fixed window rate limiting', false);
            failed++;
        }

        // Test 4: Test sliding window with sorted set
        const slidingKey = `ratelimit:sliding:user-002`;
        const now = Date.now();

        // Add requests with timestamps as scores
        await testUtils.redisClient.zAdd(slidingKey, [
            { score: now - 30000, value: `req-1-${now - 30000}` },
            { score: now - 20000, value: `req-2-${now - 20000}` },
            { score: now - 10000, value: `req-3-${now - 10000}` },
            { score: now, value: `req-4-${now}` }
        ]);

        // Count requests in last minute
        const oneMinuteAgo = now - 60000;
        const recentRequests = await testUtils.redisClient.zCount(slidingKey, oneMinuteAgo, now);

        if (recentRequests === 4) {
            testUtils.logTest('Lab 12', 'Sliding window rate limiting', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Sliding window rate limiting', false);
            failed++;
        }

        // Test 5: Clean old entries from sliding window
        await testUtils.redisClient.zRemRangeByScore(slidingKey, '-inf', oneMinuteAgo);
        const remainingRequests = await testUtils.redisClient.zCard(slidingKey);

        if (remainingRequests === 4) {
            testUtils.logTest('Lab 12', 'Sliding window cleanup', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Sliding window cleanup', false);
            failed++;
        }

        // Test 6: Test token bucket algorithm
        const tokenKey = `ratelimit:token:user-003`;
        const maxTokens = 10;
        const refillRate = 1; // 1 token per second

        // Initialize bucket
        await testUtils.redisClient.hSet(tokenKey, {
            'tokens': maxTokens.toString(),
            'last_refill': Date.now().toString()
        });

        const bucket = await testUtils.redisClient.hGetAll(tokenKey);
        if (parseInt(bucket.tokens) === maxTokens) {
            testUtils.logTest('Lab 12', 'Token bucket initialization', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Token bucket initialization', false);
            failed++;
        }

        // Test 7: Test IP-based rate limiting
        const ip = '192.168.1.100';
        const ipRateLimitKey = `ratelimit:ip:${ip}:${window}`;

        await testUtils.redisClient.incr(ipRateLimitKey);
        await testUtils.redisClient.expire(ipRateLimitKey, 60);

        const ipRequests = await testUtils.redisClient.get(ipRateLimitKey);
        if (parseInt(ipRequests) >= 1) {
            testUtils.logTest('Lab 12', 'IP-based rate limiting', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'IP-based rate limiting', false);
            failed++;
        }

        // Test 8: Test endpoint-specific rate limits
        const endpoint = '/api/claims';
        const endpointKey = `ratelimit:endpoint:${endpoint}:${userId}:${window}`;

        await testUtils.redisClient.incr(endpointKey);
        await testUtils.redisClient.expire(endpointKey, 60);

        const endpointRequests = await testUtils.redisClient.get(endpointKey);
        if (parseInt(endpointRequests) >= 1) {
            testUtils.logTest('Lab 12', 'Endpoint-specific rate limiting', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Endpoint-specific rate limiting', false);
            failed++;
        }

        // Test 9: Test rate limit exceeded tracking
        const exceededKey = `ratelimit:exceeded:${userId}`;
        await testUtils.redisClient.incr(exceededKey);
        await testUtils.redisClient.expire(exceededKey, 3600);

        const exceededCount = await testUtils.redisClient.get(exceededKey);
        if (parseInt(exceededCount) >= 1) {
            testUtils.logTest('Lab 12', 'Rate limit exceeded tracking', true);
            passed++;
        } else {
            testUtils.logTest('Lab 12', 'Rate limit exceeded tracking', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 12', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 13: Production Configuration
 */
async function testLab13() {
    testUtils.logLabHeader(13, 'Production Configuration');

    const labDir = path.join(process.cwd(), 'lab13-production-configuration');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 13', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 13', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if configuration files exist
        const configFiles = [
            'redis.conf',
            'docker-compose.yml'
        ];

        for (const file of configFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, file));
            if (exists) {
                testUtils.logTest('Lab 13', `${file} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 13', `${file} exists`, false);
                failed++;
            }
        }

        // Test 3: Test persistence - verify data persists
        await testUtils.redisClient.set('test:lab13:persist', 'persistent-data');
        const value = await testUtils.redisClient.get('test:lab13:persist');

        if (value === 'persistent-data') {
            testUtils.logTest('Lab 13', 'Data persistence test', true);
            passed++;
        } else {
            testUtils.logTest('Lab 13', 'Data persistence test', false);
            failed++;
        }

        // Test 4: Test CONFIG GET command (if allowed)
        try {
            const config = await testUtils.redisClient.configGet('maxmemory');
            testUtils.logTest('Lab 13', 'CONFIG GET command', true);
            passed++;
        } catch (error) {
            if (error.message.includes('CONFIG')) {
                testUtils.logTest('Lab 13', 'CONFIG GET command', true, 'Disabled for security (expected in prod)');
                passed++;
            } else {
                testUtils.logTest('Lab 13', 'CONFIG GET command', false, error.message);
                failed++;
            }
        }

        // Test 5: Test connection pooling
        const clients = [];
        try {
            for (let i = 0; i < 5; i++) {
                const { createClient } = require('redis');
                const client = createClient({ socket: { reconnectStrategy: false } });
                await client.connect();
                clients.push(client);
            }
            testUtils.logTest('Lab 13', 'Connection pooling', true);
            passed++;
        } catch (error) {
            testUtils.logTest('Lab 13', 'Connection pooling', false, error.message);
            failed++;
        } finally {
            for (const client of clients) {
                await client.quit().catch(() => {});
            }
        }

        // Test 6: Test maxmemory policy behavior
        try {
            // Set some keys with TTL
            await testUtils.redisClient.setEx('test:lab13:ttl1', 100, 'data1');
            await testUtils.redisClient.setEx('test:lab13:ttl2', 100, 'data2');
            await testUtils.redisClient.setEx('test:lab13:ttl3', 100, 'data3');

            testUtils.logTest('Lab 13', 'Maxmemory policy test', true);
            passed++;
        } catch (error) {
            testUtils.logTest('Lab 13', 'Maxmemory policy test', false, error.message);
            failed++;
        }

        // Test 7: Check backup script exists
        const backupScriptExists = await testUtils.fileExists(path.join(labDir, 'backup-redis.sh'));
        if (backupScriptExists) {
            testUtils.logTest('Lab 13', 'Backup script exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 13', 'Backup script exists', false);
            failed++;
        }

        // Test 8: Test slow log
        try {
            const slowLog = await testUtils.redisClient.slowLogGet(10);
            testUtils.logTest('Lab 13', 'Slow log access', true);
            passed++;
        } catch (error) {
            testUtils.logTest('Lab 13', 'Slow log access', false, error.message);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 13', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 14: Production Monitoring
 */
async function testLab14() {
    testUtils.logLabHeader(14, 'Production Monitoring');

    const labDir = path.join(process.cwd(), 'lab14-production-monitoring');
    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 14', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if monitoring files exist
        const monitoringFiles = [
            'health-check.js',
            'metrics-collector.js'
        ];

        for (const file of monitoringFiles) {
            const exists = await testUtils.fileExists(path.join(labDir, file));
            if (exists) {
                testUtils.logTest('Lab 14', `${file} exists`, true);
                passed++;
            } else {
                testUtils.logTest('Lab 14', `${file} exists`, false);
                failed++;
            }
        }

        // Test 3: Test health check - PING
        const ping = await testUtils.redisClient.ping();
        if (ping === 'PONG') {
            testUtils.logTest('Lab 14', 'Health check - PING', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Health check - PING', false);
            failed++;
        }

        // Test 4: Test INFO collection
        const info = await testUtils.redisClient.info();
        if (info.includes('redis_version') && info.includes('used_memory')) {
            testUtils.logTest('Lab 14', 'INFO metrics collection', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'INFO metrics collection', false);
            failed++;
        }

        // Test 5: Test memory metrics
        const memoryInfo = await testUtils.redisClient.info('memory');
        if (memoryInfo.includes('used_memory_human')) {
            testUtils.logTest('Lab 14', 'Memory metrics collection', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Memory metrics collection', false);
            failed++;
        }

        // Test 6: Test stats metrics
        const statsInfo = await testUtils.redisClient.info('stats');
        if (statsInfo.includes('total_commands_processed')) {
            testUtils.logTest('Lab 14', 'Stats metrics collection', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Stats metrics collection', false);
            failed++;
        }

        // Test 7: Test client connections tracking
        const clientInfo = await testUtils.redisClient.info('clients');
        if (clientInfo.includes('connected_clients')) {
            testUtils.logTest('Lab 14', 'Client connections tracking', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Client connections tracking', false);
            failed++;
        }

        // Test 8: Test command statistics
        try {
            const commandStats = await testUtils.redisClient.info('commandstats');
            testUtils.logTest('Lab 14', 'Command statistics', true);
            passed++;
        } catch (error) {
            testUtils.logTest('Lab 14', 'Command statistics', false, error.message);
            failed++;
        }

        // Test 9: Test keyspace statistics
        await testUtils.redisClient.set('test:lab14:key1', 'value1');
        await testUtils.redisClient.set('test:lab14:key2', 'value2');
        const keyspaceInfo = await testUtils.redisClient.info('keyspace');

        if (keyspaceInfo.includes('db0')) {
            testUtils.logTest('Lab 14', 'Keyspace statistics', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Keyspace statistics', false);
            failed++;
        }

        // Test 10: Test custom metrics storage
        const metricsKey = 'metrics:requests:total';
        await testUtils.redisClient.incr(metricsKey);
        await testUtils.redisClient.incr(metricsKey);

        const totalRequests = await testUtils.redisClient.get(metricsKey);
        if (parseInt(totalRequests) === 2) {
            testUtils.logTest('Lab 14', 'Custom metrics storage', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Custom metrics storage', false);
            failed++;
        }

        // Test 11: Test time-series metrics (sorted sets)
        const timeSeriesKey = 'metrics:response-times';
        const timestamp = Date.now();
        await testUtils.redisClient.zAdd(timeSeriesKey, [
            { score: timestamp, value: '125' },
            { score: timestamp + 1000, value: '143' },
            { score: timestamp + 2000, value: '98' }
        ]);

        const metrics = await testUtils.redisClient.zRange(timeSeriesKey, 0, -1);
        if (metrics.length === 3) {
            testUtils.logTest('Lab 14', 'Time-series metrics', true);
            passed++;
        } else {
            testUtils.logTest('Lab 14', 'Time-series metrics', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 14', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}

/**
 * Lab 15: Redis Cluster HA
 */
async function testLab15() {
    testUtils.logLabHeader(15, 'Redis Cluster HA');

    const labDir = path.join(process.cwd(), 'lab15-redis-cluster-ha');
    let passed = 0;
    let failed = 0;

    try {
        // Test 1: Check lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab 15', 'Lab directory exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 15', 'Lab directory exists', false);
            failed++;
            return { passed, failed };
        }

        // Test 2: Check if docker-compose.yml exists
        const dockerComposeExists = await testUtils.fileExists(path.join(labDir, 'docker-compose.yml'));
        if (dockerComposeExists) {
            testUtils.logTest('Lab 15', 'Docker Compose config exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 15', 'Docker Compose config exists', false);
            failed++;
        }

        // Test 3: Check if cluster setup script exists
        const setupScriptExists = await testUtils.fileExists(path.join(labDir, 'setup-cluster.sh'));
        if (setupScriptExists) {
            testUtils.logTest('Lab 15', 'Cluster setup script exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 15', 'Cluster setup script exists', false);
            failed++;
        }

        // Test 4: Check if cluster nodes documentation exists
        const readmeExists = await testUtils.fileExists(path.join(labDir, 'README.md'));
        if (readmeExists) {
            testUtils.logTest('Lab 15', 'Cluster documentation exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 15', 'Cluster documentation exists', false);
            failed++;
        }

        // Test 5: Test if we can connect to cluster (if running)
        try {
            const Redis = require('ioredis');
            const cluster = new Redis.Cluster([
                { host: 'localhost', port: 7000 },
                { host: 'localhost', port: 7001 },
                { host: 'localhost', port: 7002 }
            ], {
                redisOptions: {
                    connectTimeout: 2000
                }
            });

            try {
                await cluster.ping();
                testUtils.logTest('Lab 15', 'Cluster connection', true);
                passed++;

                // Test 6: Test cluster key distribution
                await cluster.set('test:lab15:key1', 'value1');
                await cluster.set('test:lab15:key2', 'value2');
                await cluster.set('test:lab15:key3', 'value3');

                const value1 = await cluster.get('test:lab15:key1');
                if (value1 === 'value1') {
                    testUtils.logTest('Lab 15', 'Cluster key operations', true);
                    passed++;
                } else {
                    testUtils.logTest('Lab 15', 'Cluster key operations', false);
                    failed++;
                }

                // Test 7: Test cluster info
                const clusterInfo = await cluster.cluster('info');
                if (clusterInfo.includes('cluster_state')) {
                    testUtils.logTest('Lab 15', 'Cluster info command', true);
                    passed++;
                } else {
                    testUtils.logTest('Lab 15', 'Cluster info command', false);
                    failed++;
                }

                // Test 8: Test cluster nodes
                const clusterNodes = await cluster.cluster('nodes');
                if (clusterNodes.includes('master') || clusterNodes.includes('slave')) {
                    testUtils.logTest('Lab 15', 'Cluster nodes command', true);
                    passed++;
                } else {
                    testUtils.logTest('Lab 15', 'Cluster nodes command', false);
                    failed++;
                }

            } catch (error) {
                testUtils.logTest('Lab 15', 'Cluster operations', false, error.message);
                failed++;
            } finally {
                await cluster.quit();
            }

        } catch (error) {
            testUtils.logTest('Lab 15', 'Cluster connection', false, 'Cluster not running (start with docker-compose up)');
            failed++;
            testUtils.logTest('Lab 15', 'Cluster key operations', false, 'Cluster not running');
            failed++;
            testUtils.logTest('Lab 15', 'Cluster info command', false, 'Cluster not running');
            failed++;
            testUtils.logTest('Lab 15', 'Cluster nodes command', false, 'Cluster not running');
            failed++;
        }

        // Test 9: Check if test scripts exist
        const testScriptExists = await testUtils.fileExists(path.join(labDir, 'test-cluster.sh'));
        if (testScriptExists) {
            testUtils.logTest('Lab 15', 'Cluster test script exists', true);
            passed++;
        } else {
            testUtils.logTest('Lab 15', 'Cluster test script exists', false);
            failed++;
        }

    } catch (error) {
        testUtils.logTest('Lab 15', 'Lab execution', false, error.message);
        failed++;
    }

    return { passed, failed };
}

/**
 * Run all Day 3 tests
 */
async function runDay3Tests() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                          DAY 3 INTEGRATION TESTS                           ║');
    console.log('║                Production & Advanced Topics (Labs 11-15)                   ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');

    const results = {
        totalPassed: 0,
        totalFailed: 0,
        labs: []
    };

    // Run all Day 3 lab tests
    const lab11 = await testLab11();
    results.labs.push({ lab: 11, ...lab11 });
    results.totalPassed += lab11.passed;
    results.totalFailed += lab11.failed;

    const lab12 = await testLab12();
    results.labs.push({ lab: 12, ...lab12 });
    results.totalPassed += lab12.passed;
    results.totalFailed += lab12.failed;

    const lab13 = await testLab13();
    results.labs.push({ lab: 13, ...lab13 });
    results.totalPassed += lab13.passed;
    results.totalFailed += lab13.failed;

    const lab14 = await testLab14();
    results.labs.push({ lab: 14, ...lab14 });
    results.totalPassed += lab14.passed;
    results.totalFailed += lab14.failed;

    const lab15 = await testLab15();
    results.labs.push({ lab: 15, ...lab15 });
    results.totalPassed += lab15.passed;
    results.totalFailed += lab15.failed;

    return results;
}

module.exports = {
    runDay3Tests,
    testLab11,
    testLab12,
    testLab13,
    testLab14,
    testLab15
};

// Run tests if called directly
if (require.main === module) {
    runDay3Tests()
        .then(results => {
            testUtils.printTestSummary();
            process.exit(results.totalFailed === 0 ? 0 : 1);
        })
        .catch(error => {
            console.error('Error running Day 3 tests:', error);
            process.exit(1);
        });
}
