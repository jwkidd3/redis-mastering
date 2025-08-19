const CustomerSegments = require('./customer-segments');
const SetAnalytics = require('./set-analytics');
const AgentLeaderboard = require('./agent-leaderboard');
const RiskScoring = require('./risk-scoring');

class AnalyticsDashboard {
    constructor() {
        this.segments = new CustomerSegments();
        this.setAnalytics = new SetAnalytics();
        this.leaderboard = new AgentLeaderboard();
        this.riskScoring = new RiskScoring();
    }

    async generateDashboard() {
        console.log('\n🔹 ANALYTICS DASHBOARD 🔹');
        console.log('='.repeat(50));

        try {
            // Customer segment overview
            console.log('\n📊 CUSTOMER SEGMENTS:');
            const segments = ['premium', 'standard', 'new', 'active', 'highrisk', 'lowrisk'];
            for (const segment of segments) {
                await this.segments.getSegmentSize(segment);
            }

            // High-value low-risk customers
            console.log('\n💎 HIGH-VALUE LOW-RISK CUSTOMERS:');
            await this.setAnalytics.findHighValueLowRiskCustomers();

            // Agent performance overview
            console.log('\n🏆 TOP PERFORMING AGENTS:');
            await this.leaderboard.getTopPerformers('sales', 5);

            // Risk distribution
            console.log('\n⚠️ RISK DISTRIBUTION:');
            const lowRisk = await this.riskScoring.getCustomersByRiskLevel('low');
            const mediumRisk = await this.riskScoring.getCustomersByRiskLevel('medium');
            const highRisk = await this.riskScoring.getCustomersByRiskLevel('high');
            
            console.log(`Risk Summary: Low(${lowRisk.length}) Medium(${mediumRisk.length}) High(${highRisk.length})`);

            // Top risk customers
            console.log('\n🚨 HIGHEST RISK CUSTOMERS:');
            await this.riskScoring.getHighestRiskCustomers(3);

        } catch (error) {
            console.error('Dashboard generation error:', error);
        }
    }

    async updateAnalytics(customerId, agentId, saleAmount, riskFactors) {
        console.log(`\n🔄 Updating analytics for Customer: ${customerId}, Agent: ${agentId}`);
        
        try {
            // Update agent performance
            await this.leaderboard.incrementAgentScore('sales', agentId, saleAmount);
            await this.leaderboard.incrementAgentScore('policies_sold', agentId, 1);

            // Update customer segments based on sale amount
            if (saleAmount > 5000) {
                await this.segments.addToSegment(customerId, 'premium');
                await this.segments.removeFromSegment(customerId, 'standard');
            } else {
                await this.segments.addToSegment(customerId, 'standard');
            }

            await this.segments.addToSegment(customerId, 'active');

            // Update risk scoring
            if (riskFactors) {
                const riskResult = await this.riskScoring.calculateRiskScore(customerId, riskFactors);
                
                if (riskResult.category === 'low') {
                    await this.segments.addToSegment(customerId, 'lowrisk');
                    await this.segments.removeFromSegment(customerId, 'highrisk');
                } else if (riskResult.category === 'high') {
                    await this.segments.addToSegment(customerId, 'highrisk');
                    await this.segments.removeFromSegment(customerId, 'lowrisk');
                }
            }

            console.log('✅ Analytics updated successfully');

        } catch (error) {
            console.error('Analytics update error:', error);
        }
    }
}

module.exports = AnalyticsDashboard;
