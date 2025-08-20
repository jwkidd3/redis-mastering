/**
 * Claims Analytics Service
 * Real-time analytics using Redis Streams
 */

const redisClient = require('../utils/redisClient');

class ClaimAnalytics {
    constructor() {
        this.streamName = 'claims:events';
    }

    async generateReport() {
        console.log('📊 Generating Claims Analytics Report');
        console.log('='.repeat(50));
        
        try {
            await redisClient.connect();
            const client = redisClient.getClient();
            
            // Get all events
            const events = await client.xRange(this.streamName, '-', '+');
            
            if (events.length === 0) {
                console.log('📭 No events found. Submit some claims first!');
                return;
            }
            
            const analytics = this.analyzeEvents(events);
            this.displayReport(analytics);
            
        } catch (error) {
            console.error('Failed to generate analytics:', error);
        } finally {
            await redisClient.disconnect();
        }
    }

    analyzeEvents(events) {
        const analytics = {
            totalEvents: events.length,
            eventTypes: {},
            claimsByStatus: {},
            amountStats: {
                total: 0,
                average: 0,
                max: 0,
                min: Infinity
            },
            timeRange: {
                first: null,
                last: null
            }
        };
        
        const amounts = [];
        const claimIds = new Set();
        
        events.forEach(event => {
            const data = event.message;
            const eventType = data.type;
            
            // Count event types
            analytics.eventTypes[eventType] = (analytics.eventTypes[eventType] || 0) + 1;
            
            // Track claims
            if (data.claim_id) {
                claimIds.add(data.claim_id);
            }
            
            // Analyze amounts
            if (data.amount) {
                const amount = parseFloat(data.amount);
                amounts.push(amount);
                analytics.amountStats.total += amount;
                analytics.amountStats.max = Math.max(analytics.amountStats.max, amount);
                analytics.amountStats.min = Math.min(analytics.amountStats.min, amount);
            }
            
            // Track statuses
            if (data.status) {
                analytics.claimsByStatus[data.status] = (analytics.claimsByStatus[data.status] || 0) + 1;
            }
            
            // Time range
            const timestamp = parseInt(event.id.split('-')[0]);
            if (!analytics.timeRange.first || timestamp < analytics.timeRange.first) {
                analytics.timeRange.first = timestamp;
            }
            if (!analytics.timeRange.last || timestamp > analytics.timeRange.last) {
                analytics.timeRange.last = timestamp;
            }
        });
        
        analytics.uniqueClaims = claimIds.size;
        
        if (amounts.length > 0) {
            analytics.amountStats.average = analytics.amountStats.total / amounts.length;
        }
        
        return analytics;
    }

    displayReport(analytics) {
        console.log('📈 CLAIMS ANALYTICS REPORT');
        console.log('='.repeat(50));
        
        // Overview
        console.log('\n📊 Overview:');
        console.log(`   Total Events: ${analytics.totalEvents}`);
        console.log(`   Unique Claims: ${analytics.uniqueClaims}`);
        
        // Time range
        if (analytics.timeRange.first) {
            const firstDate = new Date(analytics.timeRange.first);
            const lastDate = new Date(analytics.timeRange.last);
            console.log(`   Time Range: ${firstDate.toLocaleString()} - ${lastDate.toLocaleString()}`);
        }
        
        // Event types
        console.log('\n📝 Event Types:');
        Object.entries(analytics.eventTypes).forEach(([type, count]) => {
            console.log(`   ${type}: ${count}`);
        });
        
        // Claim statuses
        if (Object.keys(analytics.claimsByStatus).length > 0) {
            console.log('\n📋 Claim Statuses:');
            Object.entries(analytics.claimsByStatus).forEach(([status, count]) => {
                console.log(`   ${status}: ${count}`);
            });
        }
        
        // Amount statistics
        if (analytics.amountStats.total > 0) {
            console.log('\n💰 Amount Statistics:');
            console.log(`   Total: ${analytics.amountStats.total.toLocaleString()}`);
            console.log(`   Average: ${analytics.amountStats.average.toFixed(2)}`);
            console.log(`   Maximum: ${analytics.amountStats.max.toLocaleString()}`);
            console.log(`   Minimum: ${analytics.amountStats.min.toLocaleString()}`);
        }
        
        console.log('\n🎯 Recommendations:');
        this.generateRecommendations(analytics);
    }

    generateRecommendations(analytics) {
        const recommendations = [];
        
        // Check processing efficiency
        const submitted = analytics.eventTypes.claim_submitted || 0;
        const paid = analytics.eventTypes.claim_paid || 0;
        
        if (submitted > 0) {
            const completionRate = (paid / submitted) * 100;
            if (completionRate < 50) {
                recommendations.push('🔧 Consider optimizing claim processing - low completion rate');
            } else if (completionRate > 80) {
                recommendations.push('✅ Excellent claim processing efficiency!');
            }
        }
        
        // Check for high-value claims
        if (analytics.amountStats.max > 10000) {
            recommendations.push('⚠️ High-value claims detected - ensure proper review processes');
        }
        
        // Check event volume
        if (analytics.totalEvents > 100) {
            recommendations.push('📈 High event volume - consider stream partitioning');
        } else if (analytics.totalEvents < 10) {
            recommendations.push('📝 Low event volume - good for testing and learning');
        }
        
        // Default recommendation
        if (recommendations.length === 0) {
            recommendations.push('📊 System operating normally - continue monitoring');
        }
        
        recommendations.forEach(rec => console.log(`   ${rec}`));
    }
}

// Run analytics if called directly
if (require.main === module) {
    const analytics = new ClaimAnalytics();
    analytics.generateReport();
}

module.exports = ClaimAnalytics;
