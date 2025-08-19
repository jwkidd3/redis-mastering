const MultiLevelCache = require('../src/multi-level-cache');
const CacheAside = require('../src/cache-aside');
const DataSources = require('../src/data-sources');

class PerformanceBenchmark {
    constructor() {
        this.results = {};
    }

    // Benchmark cache-aside vs multi-level
    async benchmarkCachePatterns() {
        console.log('🏁 Benchmarking Cache Patterns\n');

        const testData = Array.from({ length: 100 }, (_, i) => `test:${i}`);
        
        // Benchmark Cache-Aside
        const cacheAside = new CacheAside();
        await cacheAside.init();
        
        console.log('Testing Cache-Aside Pattern...');
        const cacheAsideStart = Date.now();
        
        for (const key of testData) {
            await cacheAside.get(key, () => ({ id: key, data: Math.random() }), 300);
        }
        
        // Second pass (should hit cache)
        for (const key of testData) {
            await cacheAside.get(key, () => ({ id: key, data: Math.random() }), 300);
        }
        
        const cacheAsideDuration = Date.now() - cacheAsideStart;
        await cacheAside.client.disconnect();
        
        // Benchmark Multi-Level Cache
        const multiLevel = new MultiLevelCache();
        await multiLevel.init();
        
        console.log('Testing Multi-Level Cache...');
        const multiLevelStart = Date.now();
        
        for (const key of testData) {
            await multiLevel.get(key, () => ({ id: key, data: Math.random() }), { memoryTtl: 60, redisTtl: 300 });
        }
        
        // Second pass (should hit L1 cache)
        for (const key of testData) {
            await multiLevel.get(key, () => ({ id: key, data: Math.random() }), { memoryTtl: 60, redisTtl: 300 });
        }
        
        const multiLevelDuration = Date.now() - multiLevelStart;
        const multiLevelStats = multiLevel.getStats();
        await multiLevel.client.disconnect();
        
        this.results.cachePatterns = {
            cacheAside: {
                duration: cacheAsideDuration,
                avgPerOperation: cacheAsideDuration / (testData.length * 2)
            },
            multiLevel: {
                duration: multiLevelDuration,
                avgPerOperation: multiLevelDuration / (testData.length * 2),
                stats: multiLevelStats
            },
            improvement: `${((cacheAsideDuration / multiLevelDuration) * 100 - 100).toFixed(1)}%`
        };

        console.log('\n📊 Cache Pattern Benchmark Results:');
        console.log(`Cache-Aside: ${cacheAsideDuration}ms (${this.results.cachePatterns.cacheAside.avgPerOperation.toFixed(2)}ms/op)`);
        console.log(`Multi-Level: ${multiLevelDuration}ms (${this.results.cachePatterns.multiLevel.avgPerOperation.toFixed(2)}ms/op)`);
        console.log(`Improvement: ${this.results.cachePatterns.improvement}`);
    }

    // Benchmark different TTL strategies
    async benchmarkTTLStrategies() {
        console.log('\n🕐 Benchmarking TTL Strategies\n');

        const cache = new MultiLevelCache();
        await cache.init();

        const strategies = [
            { name: 'Short TTL (30s)', memoryTtl: 30, redisTtl: 60 },
            { name: 'Medium TTL (5m)', memoryTtl: 300, redisTtl: 600 },
            { name: 'Long TTL (30m)', memoryTtl: 1800, redisTtl: 3600 }
        ];

        const results = {};

        for (const strategy of strategies) {
            console.log(`Testing ${strategy.name}...`);
            
            const start = Date.now();
            const testKey = `ttl:test:${strategy.memoryTtl}`;
            
            // Multiple requests to same key
            for (let i = 0; i < 50; i++) {
                await cache.get(
                    testKey,
                    () => DataSources.getPolicyById('12345'),
                    strategy
                );
            }
            
            const duration = Date.now() - start;
            results[strategy.name] = {
                duration,
                avgPerOperation: duration / 50
            };
            
            // Clear cache for next test
            await cache.invalidate(testKey);
        }

        await cache.client.disconnect();

        this.results.ttlStrategies = results;

        console.log('\n📊 TTL Strategy Results:');
        Object.entries(results).forEach(([name, data]) => {
            console.log(`${name}: ${data.duration}ms (${data.avgPerOperation.toFixed(2)}ms/op)`);
        });
    }

    // Benchmark concurrent access patterns
    async benchmarkConcurrency() {
        console.log('\n🔀 Benchmarking Concurrent Access\n');

        const cache = new MultiLevelCache();
        await cache.init();

        const concurrencyLevels = [1, 5, 10, 20];
        const results = {};

        for (const level of concurrencyLevels) {
            console.log(`Testing ${level} concurrent requests...`);
            
            const start = Date.now();
            
            const promises = Array.from({ length: level }, async (_, i) => {
                const key = `concurrent:${i % 5}`; // Simulate some cache hits
                return cache.get(
                    key,
                    () => DataSources.getCustomerById(`100${i}`),
                    { memoryTtl: 60, redisTtl: 300 }
                );
            });

            await Promise.all(promises);
            
            const duration = Date.now() - start;
            results[`${level} concurrent`] = {
                duration,
                avgPerOperation: duration / level,
                requestsPerSecond: (level / duration * 1000).toFixed(2)
            };
        }

        await cache.client.disconnect();

        this.results.concurrency = results;

        console.log('\n📊 Concurrency Benchmark Results:');
        Object.entries(results).forEach(([name, data]) => {
            console.log(`${name}: ${data.duration}ms (${data.avgPerOperation.toFixed(2)}ms/op, ${data.requestsPerSecond} req/s)`);
        });
    }

    // Generate comprehensive report
    generateReport() {
        console.log('\n📋 COMPREHENSIVE PERFORMANCE REPORT');
        console.log('=====================================\n');

        console.log('🎯 Cache Pattern Performance:');
        if (this.results.cachePatterns) {
            const cp = this.results.cachePatterns;
            console.log(`  • Cache-Aside Pattern: ${cp.cacheAside.avgPerOperation.toFixed(2)}ms/operation`);
            console.log(`  • Multi-Level Cache: ${cp.multiLevel.avgPerOperation.toFixed(2)}ms/operation`);
            console.log(`  • Performance Improvement: ${cp.improvement}`);
            console.log(`  • Multi-Level Hit Rate: ${cp.multiLevel.stats.hitRate}`);
        }

        console.log('\n⏰ TTL Strategy Analysis:');
        if (this.results.ttlStrategies) {
            Object.entries(this.results.ttlStrategies).forEach(([name, data]) => {
                console.log(`  • ${name}: ${data.avgPerOperation.toFixed(2)}ms/operation`);
            });
        }

        console.log('\n🔀 Concurrency Performance:');
        if (this.results.concurrency) {
            Object.entries(this.results.concurrency).forEach(([name, data]) => {
                console.log(`  • ${name}: ${data.requestsPerSecond} requests/second`);
            });
        }

        console.log('\n💡 Recommendations:');
        this.generateRecommendations();
    }

    // Generate performance recommendations
    generateRecommendations() {
        const recommendations = [];

        if (this.results.cachePatterns) {
            const improvement = parseFloat(this.results.cachePatterns.improvement);
            if (improvement > 50) {
                recommendations.push('✅ Multi-level caching shows excellent performance gains');
            } else if (improvement > 20) {
                recommendations.push('🔧 Consider optimizing memory cache size for better performance');
            } else {
                recommendations.push('⚠️ Evaluate if multi-level caching is worth the complexity');
            }
        }

        if (this.results.concurrency) {
            const concurrency = this.results.concurrency;
            const highConcurrency = concurrency['20 concurrent'];
            if (highConcurrency && parseFloat(highConcurrency.requestsPerSecond) > 100) {
                recommendations.push('✅ Cache handles high concurrency well');
            } else {
                recommendations.push('🔧 Consider connection pooling for better concurrency handling');
            }
        }

        recommendations.push('💾 Monitor memory usage in production environments');
        recommendations.push('📊 Implement cache hit rate monitoring (target: >80%)');
        recommendations.push('🔄 Use appropriate TTL values based on data volatility');

        recommendations.forEach(rec => console.log(`  ${rec}`));
    }

    // Run all benchmarks
    async runAll() {
        console.log('🚀 Starting Comprehensive Performance Benchmark\n');
        
        try {
            await this.benchmarkCachePatterns();
            await this.benchmarkTTLStrategies();
            await this.benchmarkConcurrency();
            
            this.generateReport();
            
            console.log('\n✅ Benchmark completed successfully!');
        } catch (error) {
            console.error('❌ Benchmark failed:', error);
        }
    }
}

// CLI usage
if (require.main === module) {
    const benchmark = new PerformanceBenchmark();
    benchmark.runAll().catch(console.error);
}

module.exports = PerformanceBenchmark;
