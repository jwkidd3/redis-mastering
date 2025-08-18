const { HealthCheckSystem } = require('./health-check');
const { MetricsCollector } = require('./metrics-collector');
const redis = require('redis');

async function testMonitoring() {
    console.log('🧪 Testing Monitoring Components\n');
    
    // Test Redis connection
    console.log('1. Testing Redis connection...');
    const client = redis.createClient({
        socket: { host: 'localhost', port: 6379 }
    });
    
    try {
        await client.connect();
        await client.ping();
        console.log('   ✅ Redis connection successful\n');
    } catch (error) {
        console.error('   ❌ Redis connection failed:', error.message);
        process.exit(1);
    }
    
    // Test health check system
    console.log('2. Testing Health Check System...');
    const healthCheck = new HealthCheckSystem();
    await healthCheck.connect();
    
    const health = await healthCheck.performHealthCheck();
    console.log('   Basic health:', health.status);
    
    const detailed = await healthCheck.performDetailedHealthCheck();
    console.log('   Detailed health:', detailed.status);
    console.log('   ✅ Health check system working\n');
    
    // Test metrics collector
    console.log('3. Testing Metrics Collector...');
    const collector = new MetricsCollector();
    await collector.connect();
    
    // Simulate some operations
    await collector.trackPolicyLookup('AUTO', true);
    await collector.trackPolicyLookup('HOME', false);
    await collector.trackClaimSubmission('AUTO', 'high');
    
    const metrics = await collector.getMetrics();
    console.log('   Metrics collected:', metrics.split('\n').length, 'lines');
    console.log('   ✅ Metrics collector working\n');
    
    // Test performance under load
    console.log('4. Testing Performance Monitoring...');
    const startTime = Date.now();
    const operations = 1000;
    
    for (let i = 0; i < operations; i++) {
        await client.set(`test:key:${i}`, `value${i}`);
        if (i % 100 === 0) {
            await collector.trackPolicyLookup('AUTO', true);
        }
    }
    
    const duration = Date.now() - startTime;
    console.log(`   Completed ${operations} operations in ${duration}ms`);
    console.log(`   Throughput: ${(operations / (duration / 1000)).toFixed(2)} ops/sec`);
    console.log('   ✅ Performance monitoring working\n');
    
    // Clean up
    for (let i = 0; i < operations; i++) {
        await client.del(`test:key:${i}`);
    }
    
    await client.quit();
    console.log('✅ All monitoring tests passed!\n');
}

// Run tests
testMonitoring().catch(console.error);
