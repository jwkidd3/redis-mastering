const redis = require('redis');

async function stressTest() {
    const client = redis.createClient({
        socket: { host: 'localhost', port: 6379 }
    });
    
    await client.connect();
    console.log('Starting stress test for monitoring...\n');
    
    const operations = [
        // Policy lookups
        async () => {
            const types = ['AUTO', 'HOME', 'LIFE', 'HEALTH'];
            const id = Math.floor(Math.random() * 9999);
            const type = types[Math.floor(Math.random() * types.length)];
            await client.get(`policy:${type}:${id}`);
            await client.incr('metrics:policy:lookups:minute');
        },
        
        // Claim submissions
        async () => {
            const claim = {
                id: `CLM-${Date.now()}`,
                type: ['AUTO', 'HOME', 'HEALTH'][Math.floor(Math.random() * 3)],
                amount: Math.floor(Math.random() * 50000),
                priority: ['low', 'normal', 'high'][Math.floor(Math.random() * 3)]
            };
            await client.lPush('claims:pending', JSON.stringify(claim));
            await client.incr('metrics:claims:submissions:minute');
        },
        
        // Session operations
        async () => {
            const sessionId = `session:user${Math.floor(Math.random() * 100)}`;
            await client.setEx(sessionId, 3600, JSON.stringify({
                userId: `U${Math.floor(Math.random() * 100)}`,
                loginTime: new Date().toISOString()
            }));
        },
        
        // Cache operations
        async () => {
            const key = `cache:data:${Math.floor(Math.random() * 1000)}`;
            await client.setEx(key, 300, JSON.stringify({ data: 'cached' }));
        }
    ];
    
    // Run stress test
    const duration = 30000; // 30 seconds
    const startTime = Date.now();
    let operationCount = 0;
    
    console.log(`Running stress test for ${duration/1000} seconds...`);
    
    while (Date.now() - startTime < duration) {
        const operation = operations[Math.floor(Math.random() * operations.length)];
        await operation();
        operationCount++;
        
        // Small delay to control rate
        if (operationCount % 100 === 0) {
            await new Promise(resolve => setTimeout(resolve, 10));
        }
    }
    
    console.log(`\nStress test completed!`);
    console.log(`Total operations: ${operationCount}`);
    console.log(`Operations per second: ${(operationCount / (duration/1000)).toFixed(2)}`);
    
    await client.quit();
}

// Run if executed directly
if (require.main === module) {
    stressTest().catch(console.error);
}

module.exports = { stressTest };
