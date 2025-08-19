const client = require('./connection');

class RiskScoring {
    constructor() {
        this.riskKey = 'risk_scores';
        this.riskCategories = {
            low: { min: 0, max: 300 },
            medium: { min: 301, max: 700 },
            high: { min: 701, max: 1000 }
        };
    }

    async calculateRiskScore(customerId, factors) {
        let score = 0;

        // Age factor (higher age = lower risk for auto, opposite for health)
        if (factors.age) {
            score += Math.max(0, 100 - factors.age);
        }

        // Claim history factor
        if (factors.claimCount) {
            score += factors.claimCount * 50;
        }

        // Credit score factor (inverse relationship)
        if (factors.creditScore) {
            score += Math.max(0, 850 - factors.creditScore) / 2;
        }

        // Driving record factor
        if (factors.violations) {
            score += factors.violations * 75;
        }

        // Policy type factor
        if (factors.policyType === 'high_risk') {
            score += 100;
        } else if (factors.policyType === 'standard') {
            score += 50;
        }

        // Ensure score is within bounds
        score = Math.min(1000, Math.max(0, Math.round(score)));

        // Store risk score
        await client.zadd(this.riskKey, score, customerId);
        
        const category = this.getRiskCategory(score);
        console.log(`Customer ${customerId} risk score: ${score} (${category})`);
        
        return { score, category };
    }

    getRiskCategory(score) {
        for (const [category, range] of Object.entries(this.riskCategories)) {
            if (score >= range.min && score <= range.max) {
                return category;
            }
        }
        return 'unknown';
    }

    async getCustomersByRiskLevel(level) {
        if (!this.riskCategories[level]) {
            throw new Error(`Invalid risk level: ${level}`);
        }

        const range = this.riskCategories[level];
        const results = await client.zrangebyscore(
            this.riskKey,
            range.min,
            range.max,
            'WITHSCORES'
        );

        const customers = [];
        for (let i = 0; i < results.length; i += 2) {
            customers.push({
                customerId: results[i],
                riskScore: parseFloat(results[i + 1]),
                riskLevel: level
            });
        }

        console.log(`${level} risk customers:`, customers);
        return customers;
    }

    async getHighestRiskCustomers(count = 10) {
        const results = await client.zrevrange(this.riskKey, 0, count - 1, 'WITHSCORES');
        
        const customers = [];
        for (let i = 0; i < results.length; i += 2) {
            const score = parseFloat(results[i + 1]);
            customers.push({
                customerId: results[i],
                riskScore: score,
                riskLevel: this.getRiskCategory(score),
                rank: (i / 2) + 1
            });
        }

        console.log(`Top ${count} highest risk customers:`, customers);
        return customers;
    }

    async updateRiskScore(customerId, newScore) {
        newScore = Math.min(1000, Math.max(0, Math.round(newScore)));
        await client.zadd(this.riskKey, newScore, customerId);
        
        const category = this.getRiskCategory(newScore);
        console.log(`Customer ${customerId} risk score updated to: ${newScore} (${category})`);
        
        return { score: newScore, category };
    }

    async getCustomerRiskProfile(customerId) {
        const score = await client.zscore(this.riskKey, customerId);
        
        if (score === null) {
            console.log(`Customer ${customerId} not found in risk database`);
            return null;
        }

        const numericScore = parseFloat(score);
        const rank = await client.zrevrank(this.riskKey, customerId);
        const category = this.getRiskCategory(numericScore);

        const profile = {
            customerId,
            riskScore: numericScore,
            riskLevel: category,
            rank: rank + 1
        };

        console.log(`Customer ${customerId} risk profile:`, profile);
        return profile;
    }
}

module.exports = RiskScoring;
