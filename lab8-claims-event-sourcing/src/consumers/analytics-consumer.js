const redisClient = require('../utils/redis-client');

class AnalyticsConsumer {
    constructor() {
        this.client = null;
        this.streamName = 'claims:events';
        this.groupName = 'analytics';
        this.consumerName = `analytics-${Date.now()}`;
        this.running = false;
    }

    async init() {
        this.client = await redisClient.connect();
        
        // Create consumer group
        try {
            await this.client.xGroupCreate(this.streamName, this.groupName, '0', {
                MKSTREAM: true
            });
        } catch (error) {
            if (!error.message.includes('BUSYGROUP')) {
                throw error;
            }
        }
        
        console.log(`📊 Analytics Consumer initialized: ${this.consumerName}`);
    }

    async start() {
        this.running = true;
        console.log('🚀 Starting analytics consumer...');
        
        while (this.running) {
            try {
                const messages = await this.client.xReadGroup(
                    this.groupName,
                    this.consumerName,
                    [{ key: this.streamName, id: '>' }],
                    { COUNT: 10, BLOCK: 1000 }
                );

                if (messages && messages.length > 0) {
                    for (const stream of messages) {
                        for (const message of stream.messages) {
                            await this.processAnalytics(message);
                        }
                    }
                }
            } catch (error) {
                console.error('❌ Analytics error:', error.message);
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
    }

    async processAnalytics(message) {
        try {
            const { id, message: fields } = message;
            const eventType = fields.eventType;
            const data = JSON.parse(fields.data);
            const timestamp = new Date(fields.timestamp);

            // Update various analytics
            await this.updateEventCounters(eventType, data, timestamp);
            await this.updateAmountAnalytics(eventType, data, timestamp);
            await this.updateProcessingTimes(eventType, data, timestamp);
            await this.updateLeaderboards(eventType, data, timestamp);

            // Acknowledge message
            await this.client.xAck(this.streamName, this.groupName, id);

        } catch (error) {
            console.error('❌ Error processing analytics:', error.message);
        }
    }

    async updateEventCounters(eventType, data, timestamp) {
        const hour = timestamp.getHours();
        const day = timestamp.toISOString().split('T')[0];
        
        // Hourly event counters
        await this.client.hIncrBy(`analytics:hourly:${day}`, eventType, 1);
        await this.client.hIncrBy(`analytics:hourly:${day}:${hour}`, eventType, 1);
        
        // Daily counters by claim type
        if (data.type) {
            await this.client.hIncrBy(`analytics:daily:${day}`, `${data.type}:${eventType}`, 1);
        }
        
        // Real-time counters
        await this.client.hIncrBy('analytics:realtime', eventType, 1);
        await this.client.expire('analytics:realtime', 3600); // 1 hour TTL
    }

    async updateAmountAnalytics(eventType, data, timestamp) {
        if (data.amount && (eventType === 'claim.submitted' || eventType === 'claim.approved')) {
            const day = timestamp.toISOString().split('T')[0];
            
            // Daily amount totals
            await this.client.hIncrByFloat(`analytics:amounts:${day}`, eventType, data.amount);
            
            // Amount distribution (for histograms)
            const bucket = this.getAmountBucket(data.amount);
            await this.client.hIncrBy(`analytics:amounts:distribution:${day}`, bucket, 1);
            
            // Type-specific amounts
            if (data.type) {
                await this.client.hIncrByFloat(`analytics:amounts:${day}`, `${data.type}:${eventType}`, data.amount);
            }
        }
    }

    async updateProcessingTimes(eventType, data, timestamp) {
        if (eventType === 'claim.approved' || eventType === 'claim.rejected') {
            if (data.processingTimeHours) {
                const day = timestamp.toISOString().split('T')[0];
                
                // Add to processing time sorted set (for percentile calculations)
                await this.client.zAdd(`analytics:processing_times:${day}`, [
                    { score: data.processingTimeHours, value: data.id }
                ]);
                
                // Update average processing time
                const currentAvg = await this.client.hGet(`analytics:processing:${day}`, 'average_hours') || 0;
                const currentCount = await this.client.hGet(`analytics:processing:${day}`, 'count') || 0;
                
                const newCount = parseInt(currentCount) + 1;
                const newAvg = (parseFloat(currentAvg) * currentCount + data.processingTimeHours) / newCount;
                
                await this.client.hSet(`analytics:processing:${day}`, {
                    average_hours: newAvg.toFixed(2),
                    count: newCount
                });
            }
        }
    }

    async updateLeaderboards(eventType, data, timestamp) {
        if (data.assignedTo && (eventType === 'claim.approved' || eventType === 'claim.rejected')) {
            // Adjuster performance leaderboard
            await this.client.zIncrBy('leaderboard:adjusters:resolved', 1, data.assignedTo);
            
            if (eventType === 'claim.approved' && data.amount) {
                await this.client.zIncrBy('leaderboard:adjusters:approved_amount', data.amount, data.assignedTo);
            }
        }
        
        if (data.type) {
            // Claims by type leaderboard
            await this.client.zIncrBy('leaderboard:claim_types', 1, data.type);
        }
    }

    getAmountBucket(amount) {
        if (amount <= 1000) return '0-1000';
        if (amount <= 5000) return '1001-5000';
        if (amount <= 10000) return '5001-10000';
        if (amount <= 25000) return '10001-25000';
        if (amount <= 50000) return '25001-50000';
        return '50000+';
    }

    async getAnalyticsSummary() {
        const summary = {};
        
        // Real-time counters
        summary.realtime = await this.client.hGetAll('analytics:realtime');
        
        // Today's analytics
        const today = new Date().toISOString().split('T')[0];
        summary.today = await this.client.hGetAll(`analytics:daily:${today}`);
        summary.amounts_today = await this.client.hGetAll(`analytics:amounts:${today}`);
        
        // Leaderboards
        summary.top_adjusters = await this.client.zRevRange('leaderboard:adjusters:resolved', 0, 4, {
            WITHSCORES: true
        });
        
        summary.claim_types = await this.client.zRevRange('leaderboard:claim_types', 0, -1, {
            WITHSCORES: true
        });
        
        return summary;
    }

    async stop() {
        this.running = false;
    }

    async shutdown() {
        await this.stop();
        await redisClient.disconnect();
        console.log('📊 Analytics consumer shut down');
    }
}

if (require.main === module) {
    (async () => {
        const analytics = new AnalyticsConsumer();
        await analytics.init();
        
        process.on('SIGINT', async () => {
            console.log('\n📊 Shutting down analytics consumer...');
            await analytics.shutdown();
            process.exit(0);
        });
        
        await analytics.start();
    })();
}

module.exports = AnalyticsConsumer;
