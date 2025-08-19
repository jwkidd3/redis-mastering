const Redis = require('ioredis');

class InsuranceMonitoringDataLoader {
    constructor() {
        this.redis = new Redis({
            host: 'localhost',
            port: 6379,
            retryDelayOnFailover: 100
        });
    }
    
    async loadData() {
        console.log('📊 Loading insurance monitoring sample data...');
        
        try {
            // Clear existing data
            await this.redis.flushdb();
            
            // Load customer data
            await this.loadCustomerData();
            
            // Load policy data
            await this.loadPolicyData();
            
            // Load claims data
            await this.loadClaimsData();
            
            // Load session data
            await this.loadSessionData();
            
            // Load analytics data
            await this.loadAnalyticsData();
            
            // Load cache data
            await this.loadCacheData();
            
            // Initialize monitoring metrics
            await this.initializeMonitoringMetrics();
            
            console.log('✅ Insurance monitoring data loaded successfully!');
            
            // Display data summary
            await this.displayDataSummary();
            
        } catch (error) {
            console.error('❌ Failed to load monitoring data:', error);
        } finally {
            await this.redis.disconnect();
        }
    }
    
    async loadCustomerData() {
        const customers = [
            { id: 'CUST001', name: 'John Smith', tier: 'premium', policies: 3 },
            { id: 'CUST002', name: 'Sarah Wilson', tier: 'standard', policies: 2 },
            { id: 'CUST003', name: 'Mike Johnson', tier: 'premium', policies: 4 },
            { id: 'CUST004', name: 'Lisa Chen', tier: 'standard', policies: 1 },
            { id: 'CUST005', name: 'David Brown', tier: 'premium', policies: 2 }
        ];
        
        for (const customer of customers) {
            await this.redis.hset(`customer:${customer.id}`, {
                name: customer.name,
                tier: customer.tier,
                policies: customer.policies,
                last_login: new Date().toISOString(),
                status: 'active'
            });
            
            // Add to active customers set
            await this.redis.sadd('customers:active', customer.id);
            
            // Add tier classification
            await this.redis.sadd(`customers:${customer.tier}`, customer.id);
        }
        
        console.log('   • Customer data loaded');
    }
    
    async loadPolicyData() {
        const policies = [
            { id: 'POL001', type: 'auto', customer: 'CUST001', premium: 1200, status: 'active' },
            { id: 'POL002', type: 'home', customer: 'CUST001', premium: 850, status: 'active' },
            { id: 'POL003', type: 'life', customer: 'CUST001', premium: 450, status: 'active' },
            { id: 'POL004', type: 'auto', customer: 'CUST002', premium: 1100, status: 'active' },
            { id: 'POL005', type: 'home', customer: 'CUST002', premium: 920, status: 'active' },
            { id: 'POL006', type: 'auto', customer: 'CUST003', premium: 1350, status: 'active' },
            { id: 'POL007', type: 'home', customer: 'CUST003', premium: 1200, status: 'active' },
            { id: 'POL008', type: 'life', customer: 'CUST003', premium: 580, status: 'active' },
            { id: 'POL009', type: 'auto', customer: 'CUST004', premium: 950, status: 'active' },
            { id: 'POL010', type: 'auto', customer: 'CUST005', premium: 1250, status: 'active' }
        ];
        
        for (const policy of policies) {
            await this.redis.hset(`policy:${policy.id}`, {
                type: policy.type,
                customer: policy.customer,
                premium: policy.premium,
                status: policy.status,
                created: new Date().toISOString()
            });
            
            // Add to policy sets
            await this.redis.sadd('policies:active', policy.id);
            await this.redis.sadd(`policies:${policy.type}`, policy.id);
        }
        
        console.log('   • Policy data loaded');
    }
    
    async loadClaimsData() {
        const claims = [
            { id: 'CLM001', policy: 'POL001', amount: 2500, status: 'processing' },
            { id: 'CLM002', policy: 'POL002', amount: 8500, status: 'approved' },
            { id: 'CLM003', policy: 'POL004', amount: 1200, status: 'investigating' },
            { id: 'CLM004', policy: 'POL006', amount: 3200, status: 'pending' },
            { id: 'CLM005', policy: 'POL007', amount: 15000, status: 'processing' },
            { id: 'CLM006', policy: 'POL009', amount: 900, status: 'approved' }
        ];
        
        for (const claim of claims) {
            await this.redis.hset(`claim:${claim.id}`, {
                policy: claim.policy,
                amount: claim.amount,
                status: claim.status,
                submitted: new Date().toISOString()
            });
            
            // Add to processing queues based on status
            if (claim.status === 'pending' || claim.status === 'processing') {
                await this.redis.lpush('queue:claims:pending', claim.id);
            }
        }
        
        console.log('   • Claims data loaded');
    }
    
    async loadSessionData() {
        const sessions = [
            { id: 'sess_001', customer: 'CUST001', ttl: 3600 },
            { id: 'sess_002', customer: 'CUST002', ttl: 1800 },
            { id: 'sess_003', customer: 'CUST003', ttl: 7200 },
            { id: 'sess_004', customer: 'CUST004', ttl: 3600 },
            { id: 'sess_005', customer: 'CUST005', ttl: 1800 }
        ];
        
        for (const session of sessions) {
            await this.redis.setex(`session:${session.id}`, session.ttl, JSON.stringify({
                customer: session.customer,
                login_time: new Date().toISOString(),
                ip: `192.168.1.${Math.floor(Math.random() * 255)}`,
                user_agent: 'Insurance Portal v2.0'
            }));
        }
        
        console.log('   • Session data loaded');
    }
    
    async loadAnalyticsData() {
        // Daily analytics
        await this.redis.hset('analytics:daily', {
            policies_created: 3,
            claims_filed: 4,
            claims_processed: 2,
            customer_logins: 15,
            quotes_generated: 8,
            policies_renewed: 2,
            active_customers: 12
        });
        
        // Weekly analytics
        await this.redis.hset('analytics:weekly', {
            policies_created: 18,
            claims_filed: 25,
            claims_processed: 22,
            customer_logins: 89,
            quotes_generated: 45
        });
        
        // Monthly analytics
        await this.redis.hset('analytics:monthly', {
            policies_created: 67,
            claims_filed: 98,
            claims_processed: 92,
            customer_logins: 342,
            quotes_generated: 178
        });
        
        console.log('   • Analytics data loaded');
    }
    
    async loadCacheData() {
        // Cache statistics
        await this.redis.hset('cache:stats', {
            hits: 1250,
            misses: 150,
            hit_rate: 89.3,
            total_requests: 1400
        });
        
        // Sample cached data
        const cacheEntries = [
            { key: 'cache:customer:CUST001:profile', data: { name: 'John Smith', tier: 'premium' }, ttl: 600 },
            { key: 'cache:policy:POL001:details', data: { type: 'auto', premium: 1200 }, ttl: 300 },
            { key: 'cache:dashboard:summary', data: { total_policies: 10, active_claims: 4 }, ttl: 60 },
            { key: 'cache:analytics:kpis', data: { monthly_premium: 125000, satisfaction: 4.7 }, ttl: 900 }
        ];
        
        for (const entry of cacheEntries) {
            await this.redis.setex(entry.key, entry.ttl, JSON.stringify(entry.data));
        }
        
        console.log('   • Cache data loaded');
    }
    
    async initializeMonitoringMetrics() {
        // System metrics
        await this.redis.hset('metrics:system', {
            memory_usage: 45.2,
            cpu_usage: 23.1,
            disk_usage: 67.8,
            network_io: 156.7,
            last_updated: new Date().toISOString()
        });
        
        // Performance metrics
        await this.redis.hset('metrics:performance', {
            avg_response_time: 15.3,
            queries_per_second: 234.5,
            cache_hit_rate: 89.3,
            slow_queries: 2,
            last_updated: new Date().toISOString()
        });
        
        console.log('   • Monitoring metrics initialized');
    }
    
    async displayDataSummary() {
        console.log('\n📊 Data Summary:');
        console.log(`   • Customers: ${await this.redis.scard('customers:active')}`);
        console.log(`   • Active Policies: ${await this.redis.scard('policies:active')}`);
        console.log(`   • Pending Claims: ${await this.redis.llen('queue:claims:pending')}`);
        console.log(`   • Active Sessions: ${(await this.redis.keys('session:*')).length}`);
        console.log(`   • Cache Entries: ${(await this.redis.keys('cache:*')).length}`);
        console.log(`   • Total Keys: ${await this.redis.dbsize()}`);
        
        const memory = await this.redis.info('memory');
        const memUsed = memory.match(/used_memory_human:(.+)/)?.[1]?.trim();
        console.log(`   • Memory Usage: ${memUsed || 'N/A'}`);
        
        console.log('\n✅ Ready for Lab 14 monitoring exercises!');
    }
}

// Run the data loader
async function main() {
    const loader = new InsuranceMonitoringDataLoader();
    await loader.loadData();
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = InsuranceMonitoringDataLoader;
