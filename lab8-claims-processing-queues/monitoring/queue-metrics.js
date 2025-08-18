import { createClient } from 'redis';

async function collectMetrics() {
    const client = createClient({ url: 'redis://localhost:6379' });
    await client.connect();
    
    const metrics = {
        timestamp: new Date().toISOString(),
        queues: {},
        processing: {},
        errors: {}
    };
    
    // Collect queue depths
    const queueKeys = [
        'claims:queue:pending',
        'claims:queue:urgent',
        'claims:queue:high',
        'claims:queue:normal',
        'claims:queue:low',
        'claims:queue:reliable:pending',
        'claims:queue:reliable:processing',
        'claims:queue:reliable:dlq'
    ];
    
    for (const key of queueKeys) {
        metrics.queues[key] = await client.lLen(key);
    }
    
    // Collect processing metrics
    metrics.processing.completed = await client.get('claims:metrics:completed:total') || 0;
    metrics.processing.dlqTotal = await client.get('claims:metrics:dlq:total') || 0;
    
    await client.quit();
    return metrics;
}

// Export metrics in different formats
if (import.meta.url === `file://${process.argv[1]}`) {
    collectMetrics()
        .then(metrics => console.log(JSON.stringify(metrics, null, 2)))
        .catch(console.error);
}

export { collectMetrics };
