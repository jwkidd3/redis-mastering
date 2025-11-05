// metrics-collector.js - Collect Redis metrics for monitoring
const redis = require('redis');

class MetricsCollector {
    constructor() {
        this.client = null;
    }

    async connect() {
        this.client = redis.createClient({
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379
            }
        });
        await this.client.connect();
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    async collectMetrics() {
        const metrics = {
            timestamp: new Date().toISOString(),
            server: await this.getServerMetrics(),
            memory: await this.getMemoryMetrics(),
            stats: await this.getStatsMetrics(),
            clients: await this.getClientMetrics(),
            keyspace: await this.getKeyspaceMetrics()
        };

        return metrics;
    }

    async getServerMetrics() {
        const info = await this.client.info('server');
        return {
            redis_version: this.parseField(info, 'redis_version'),
            uptime_in_seconds: this.parseField(info, 'uptime_in_seconds'),
            uptime_in_days: this.parseField(info, 'uptime_in_days')
        };
    }

    async getMemoryMetrics() {
        const info = await this.client.info('memory');
        return {
            used_memory: this.parseField(info, 'used_memory'),
            used_memory_human: this.parseField(info, 'used_memory_human'),
            used_memory_peak: this.parseField(info, 'used_memory_peak'),
            used_memory_peak_human: this.parseField(info, 'used_memory_peak_human'),
            maxmemory: this.parseField(info, 'maxmemory'),
            maxmemory_human: this.parseField(info, 'maxmemory_human'),
            mem_fragmentation_ratio: this.parseField(info, 'mem_fragmentation_ratio')
        };
    }

    async getStatsMetrics() {
        const info = await this.client.info('stats');
        return {
            total_connections_received: this.parseField(info, 'total_connections_received'),
            total_commands_processed: this.parseField(info, 'total_commands_processed'),
            instantaneous_ops_per_sec: this.parseField(info, 'instantaneous_ops_per_sec'),
            rejected_connections: this.parseField(info, 'rejected_connections'),
            expired_keys: this.parseField(info, 'expired_keys'),
            evicted_keys: this.parseField(info, 'evicted_keys'),
            keyspace_hits: this.parseField(info, 'keyspace_hits'),
            keyspace_misses: this.parseField(info, 'keyspace_misses')
        };
    }

    async getClientMetrics() {
        const info = await this.client.info('clients');
        return {
            connected_clients: this.parseField(info, 'connected_clients'),
            blocked_clients: this.parseField(info, 'blocked_clients')
        };
    }

    async getKeyspaceMetrics() {
        const info = await this.client.info('keyspace');
        const keyspace = {};

        const lines = info.split('\r\n');
        for (const line of lines) {
            if (line.startsWith('db')) {
                const [db, stats] = line.split(':');
                keyspace[db] = stats;
            }
        }

        return keyspace;
    }

    parseField(info, field) {
        const lines = info.split('\r\n');
        for (const line of lines) {
            if (line.startsWith(field + ':')) {
                return line.split(':')[1];
            }
        }
        return null;
    }

    async storeMetrics(metrics) {
        const key = `metrics:${Date.now()}`;
        await this.client.set(key, JSON.stringify(metrics));
        await this.client.expire(key, 86400); // Keep for 24 hours
        return key;
    }
}

async function collectAndStore() {
    const collector = new MetricsCollector();

    try {
        await collector.connect();
        const metrics = await collector.collectMetrics();

        console.log('=== Redis Metrics ===');
        console.log(JSON.stringify(metrics, null, 2));

        await collector.storeMetrics(metrics);
        console.log('\n✓ Metrics stored in Redis');

    } finally {
        await collector.disconnect();
    }
}

if (require.main === module) {
    collectAndStore();
}

module.exports = MetricsCollector;
