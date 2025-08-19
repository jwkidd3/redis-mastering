#!/usr/bin/env node

const MultiLevelCache = require('./src/multi-level-cache');
const CacheAside = require('./src/cache-aside');
const SmartCacheInvalidator = require('./src/cache-invalidator');
const CacheMonitor = require('./src/cache-monitor');
const DataSources = require('./src/data-sources');

async function runCompletionTest() {
    console.log('🎯 Lab 10 Completion Test');
    console.log('========================\n');

    const tests = [];
    let passed = 0;

    // Test 1: Basic Connection
    try {
        const cache = new MultiLevelCache();
        await cache.init();
        await cache.client.ping();
        await cache.client.disconnect();
        tests.push('✅ Redis Connection');
        passed++;
    } catch (error) {
        tests.push('❌ Redis Connection: ' + error.message);
    }

    // Test 2: Cache-Aside Pattern
    try {
        const cache = new CacheAside();
        await cache.init();
        
        const data = await cache.get(
            'test:policy',
            () => DataSources.getPolicyById('12345'),
            60
        );
        
        if (data && data.id === '12345') {
            tests.push('✅ Cache-Aside Pattern');
            passed++;
        } else {
            tests.push('❌ Cache-Aside Pattern: Invalid data');
        }
        
        await cache.client.disconnect();
    } catch (error) {
        tests.push('❌ Cache-Aside Pattern: ' + error.message);
    }

    // Test 3: Multi-Level Cache
    try {
        const cache = new MultiLevelCache();
        await cache.init();
        
        // Test L1 and L2 caching
        await cache.get('test:customer', () => DataSources.getCustomerById('1001'));
        const stats = cache.getStats();
        
        if (stats.total > 0) {
            tests.push('✅ Multi-Level Cache');
            passed++;
        } else {
            tests.push('❌ Multi-Level Cache: No stats recorded');
        }
        
        await cache.client.disconnect();
    } catch (error) {
        tests.push('❌ Multi-Level Cache: ' + error.message);
    }

    // Test 4: Cache Invalidation
    try {
        const cache = new MultiLevelCache();
        await cache.init();
        
        const invalidator = new SmartCacheInvalidator(cache);
        
        // Set up test data
        await cache.get('test:policy:999', () => ({ id: '999', test: true }));
        
        // Test invalidation
        await invalidator.handlePolicyUpdate({ policyId: '999' });
        
        tests.push('✅ Cache Invalidation');
        passed++;
        
        await cache.client.disconnect();
    } catch (error) {
        tests.push('❌ Cache Invalidation: ' + error.message);
    }

    // Test 5: Performance Monitoring
    try {
        const cache = new MultiLevelCache();
        await cache.init();
        
        const monitor = new CacheMonitor(cache);
        monitor.recordOperation('hit', 50);
        
        const metrics = monitor.getMetrics();
        
        if (metrics.requests > 0 && metrics.avgLatency > 0) {
            tests.push('✅ Performance Monitoring');
            passed++;
        } else {
            tests.push('❌ Performance Monitoring: No metrics recorded');
        }
        
        await cache.client.disconnect();
    } catch (error) {
        tests.push('❌ Performance Monitoring: ' + error.message);
    }

    // Display results
    console.log('Test Results:');
    console.log('=============');
    tests.forEach(test => console.log(test));
    
    console.log(`\n📊 Score: ${passed}/5 tests passed`);
    
    if (passed === 5) {
        console.log('\n🎉 Congratulations! Lab 10 completed successfully!');
        console.log('You have mastered advanced Redis caching patterns.');
    } else {
        console.log('\n⚠️ Some tests failed. Review the implementation and try again.');
    }
    
    return passed === 5;
}

if (require.main === module) {
    runCompletionTest().catch(console.error);
}

module.exports = runCompletionTest;
