const Redis = require('ioredis');

class ProductionMonitoringDataLoader {
    constructor() {
        this.redis = new Redis({
            host: process.env.REDIS_HOST || 'localhost',
            port: process.env.REDIS_PORT || 6379,
            password: process.env.REDIS_PASSWORD,
            retryDelayOnFailover: 100
        });
    }
    
    async loadData() {
        console.log('🔄 Loading production monitoring data...');
        
        try {
            // Clear existing data
            await this.redis.flushdb();
            
            // Load business data for monitoring
            await this.loadBusinessData();
            
            // Initialize monitoring counters
            await this.initializeCounters();
            
            // Create sample sessions
            await this.createSampleSessions();
            
            // Load test cache data
            await this.loadCacheTestData();
            
            console.log('✅ Production monitoring data loaded successfully');
            
            // Display data summary
            await this.displayDataSummary();
            
        } catch (error) {
            console.error('❌ Failed to load monitoring data:', error.message);
            throw error;
        } finally {
            await this.redis.disconnect();
        }
    }
    
    async loadBusinessData() {
        console.log('📊 Loading business transaction data...');
        
        // Sample business entities
        const entities = [
            { id: 'ENT001', name: 'Policy Management', status: 'active', priority: 'high' },
            { id: 'ENT002', name: 'Claims Processing', status: 'active', priority: 'critical' },
            { id: 'ENT003', name: 'Customer Service', status: 'active', priority: 'medium' },
            { id: 'ENT004', name: 'Billing System', status: 'maintenance', priority: 'high' },
            { id: 'ENT005', name: 'Reporting Engine', status: 'active', priority: 'low' }
        ];
        
        for (const entity of entities) {
            await this.redis.hset(`entity:${entity.id}`, entity);
            await this.redis.sadd('entities:active', entity.id);
        }
        
        console.log(`   ✓ Loaded ${entities.length} business entities`);
    }
    
    async initializeCounters() {
        console.log('🔢 Initializing monitoring counters...');
        
        // Initialize cache statistics
        await this.redis.hset('cache:stats', {
            hits: Math.floor(Math.random() * 1000) + 500,
            misses: Math.floor(Math.random() * 200) + 50,
            lastReset: new Date().toISOString()
        });
        
        // Initialize business metrics
        await this.redis.set('metrics:transactions:total', Math.floor(Math.random() * 5000) + 1000);
        await this.redis.set('metrics:requests:total', Math.floor(Math.random() * 10000) + 5000);
        await this.redis.set('metrics:errors:total', Math.floor(Math.random() * 50) + 10);
        
        console.log('   ✓ Monitoring counters initialized');
    }
    
    async createSampleSessions() {
        console.log('👥 Creating sample user sessions...');
        
        const sessionCount = Math.floor(Math.random() * 50) + 20;
        
        for (let i = 0; i < sessionCount; i++) {
            const sessionId = `session:user_${1000 + i}`;
            const sessionData = {
                userId: `user_${1000 + i}`,
                startTime: new Date(Date.now() - Math.random() * 3600000).toISOString(),
                lastActivity: new Date().toISOString(),
                ipAddress: `192.168.1.${Math.floor(Math.random() * 254) + 1}`,
                userAgent: 'ProductionApp/1.0',
                authenticated: true
            };
            
            await this.redis.hset(sessionId, sessionData);
            await this.redis.expire(sessionId, 3600); // 1 hour expiry
        }
        
        console.log(`   ✓ Created ${sessionCount} active sessions`);
    }
    
    async loadCacheTestData() {
        console.log('💾 Loading cache test data...');
        
        // Load frequently accessed data
        const frequentData = [
            'config:app:version',
            'config:app:features',
            'config:db:settings',
            'config:api:endpoints',
            'config:ui:preferences'
        ];
        
        for (const key of frequentData) {
            await this.redis.set(key, JSON.stringify({
                value: `data_${key}`,
                lastModified: new Date().toISOString(),
                accessCount: Math.floor(Math.random() * 100) + 10
            }));
        }
        
        // Load business lookup data
        for (let i = 1; i <= 100; i++) {
            await this.redis.hset(`lookup:entity:${i}`, {
                id: i,
                name: `Entity ${i}`,
                type: ['policy', 'claim', 'customer'][i % 3],
                status: 'active',
                lastAccessed: new Date().toISOString()
            });
        }
        
        console.log('   ✓ Cache test data loaded');
    }
    
    async displayDataSummary() {
        console.log('\n📋 Data Summary:');
        
        // Count different data types
        const entityCount = await this.redis.scard('entities:active');
        const sessionCount = (await this.redis.keys('session:*')).length;
        const cacheKeys = await this.redis.keys('config:*');
        const lookupKeys = await this.redis.keys('lookup:*');
        
        console.log(`   • Business Entities: ${entityCount}`);
        console.log(`   • Active Sessions: ${sessionCount}`);
        console.log(`   • Configuration Cache: ${cacheKeys.length} keys`);
        console.log(`   • Lookup Data: ${lookupKeys.length} entries`);
        
        // Show cache efficiency
        const cacheStats = await this.redis.hgetall('cache:stats');
        const efficiency = cacheStats.hits && cacheStats.misses ? 
            ((parseInt(cacheStats.hits) / (parseInt(cacheStats.hits) + parseInt(cacheStats.misses))) * 100).toFixed(2) : 'N/A';
        console.log(`   • Cache Efficiency: ${efficiency}%`);
        
        // Show memory usage
        const memInfo = await this.redis.info('memory');
        const memUsed = memInfo.split('\r\n').find(line => line.startsWith('used_memory_human:'))?.split(':')[1]?.trim();
        console.log(`   • Memory Usage: ${memUsed || 'N/A'}`);
        
        console.log('\n✅ Ready for Lab 14 monitoring exercises!');
    }
}

// Run the data loader
async function main() {
    const loader = new ProductionMonitoringDataLoader();
    await loader.loadData();
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = ProductionMonitoringDataLoader;
