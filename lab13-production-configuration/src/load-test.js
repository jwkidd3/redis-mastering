const redis = require('redis');
const { performance } = require('perf_hooks');

async function loadTest() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });

    await client.connect();

    console.log('Starting production load test...\n');

    const operations = 10000;
    const data = JSON.stringify({
        id: 'TEST',
        payload: 'x'.repeat(1000),
        timestamp: Date.now()
    });

    // Write test
    const writeStart = performance.now();
    for (let i = 0; i < operations; i++) {
        await client.set(`loadtest:${i}`, data, { EX: 60 });
    }
    const writeEnd = performance.now();

    // Read test
    const readStart = performance.now();
    for (let i = 0; i < operations; i++) {
        await client.get(`loadtest:${i}`);
    }
    const readEnd = performance.now();

    // Results
    console.log('Load Test Results:');
    console.log('==================');
    console.log(`Write Operations: ${operations}`);
    console.log(`Write Time: ${(writeEnd - writeStart).toFixed(2)}ms`);
    console.log(`Write Ops/sec: ${(operations / ((writeEnd - writeStart) / 1000)).toFixed(0)}`);
    console.log(`Read Operations: ${operations}`);
    console.log(`Read Time: ${(readEnd - readStart).toFixed(2)}ms`);
    console.log(`Read Ops/sec: ${(operations / ((readEnd - readStart) / 1000)).toFixed(0)}`);

    // Cleanup
    for (let i = 0; i < operations; i++) {
        await client.del(`loadtest:${i}`);
    }

    await client.quit();
}

loadTest().catch(console.error);
