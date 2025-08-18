const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

async function displayDashboard() {
    await client.connect();
    
    console.clear();
    console.log('📊 Redis Cache Dashboard');
    console.log('=' . repeat(60));
    
    setInterval(async () => {
        const info = await client.info('all');
        const stats = parseRedisInfo(info);
        
        console.clear();
        console.log('📊 Redis Cache Dashboard - ' + new Date().toISOString());
        console.log('=' . repeat(60));
        
        // Performance Metrics
        console.log('\n⚡ Performance Metrics:');
        console.log(`  Hit Rate: ${calculateHitRate(stats)}%`);
        console.log(`  Commands/sec: ${stats.instantaneous_ops_per_sec || 0}`);
        console.log(`  Network In: ${stats.instantaneous_input_kbps || 0} KB/s`);
        console.log(`  Network Out: ${stats.instantaneous_output_kbps || 0} KB/s`);
        
        // Memory Metrics
        console.log('\n💾 Memory Metrics:');
        console.log(`  Used Memory: ${stats.used_memory_human || '0B'}`);
        console.log(`  Peak Memory: ${stats.used_memory_peak_human || '0B'}`);
        console.log(`  Evicted Keys: ${stats.evicted_keys || 0}`);
        console.log(`  Memory Fragmentation: ${stats.mem_fragmentation_ratio || 0}`);
        
        // Key Statistics
        const dbSize = await client.dbSize();
        console.log('\n🔑 Key Statistics:');
        console.log(`  Total Keys: ${dbSize}`);
        console.log(`  Expired Keys: ${stats.expired_keys || 0}`);
        
        console.log('\n[Press Ctrl+C to exit]');
        
    }, 2000);
}

function parseRedisInfo(info) {
    const stats = {};
    info.split('\r\n').forEach(line => {
        if (line && line.includes(':')) {
            const [key, value] = line.split(':');
            stats[key] = value;
        }
    });
    return stats;
}

function calculateHitRate(stats) {
    const hits = parseInt(stats.keyspace_hits || 0);
    const misses = parseInt(stats.keyspace_misses || 0);
    const total = hits + misses;
    if (total === 0) return 0;
    return ((hits / total) * 100).toFixed(2);
}

if (require.main === module) {
    displayDashboard().catch(console.error);
}
