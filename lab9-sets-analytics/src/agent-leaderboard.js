const client = require('./connection');

class AgentLeaderboard {
    constructor() {
        this.leaderboards = {
            sales: 'leaderboard:sales',
            customer_satisfaction: 'leaderboard:satisfaction',
            policies_sold: 'leaderboard:policies',
            claims_processed: 'leaderboard:claims'
        };
    }

    async updateAgentScore(leaderboardType, agentId, score) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const result = await client.zadd(this.leaderboards[leaderboardType], score, agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score updated to ${score}`);
        return result;
    }

    async incrementAgentScore(leaderboardType, agentId, increment = 1) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const newScore = await client.zincrby(this.leaderboards[leaderboardType], increment, agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score incremented by ${increment}, new score: ${newScore}`);
        return parseFloat(newScore);
    }

    async getAgentRank(leaderboardType, agentId) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const rank = await client.zrevrank(this.leaderboards[leaderboardType], agentId);
        const finalRank = rank !== null ? rank + 1 : null;
        console.log(`Agent ${agentId} rank in ${leaderboardType}: ${finalRank || 'Not ranked'}`);
        return finalRank;
    }

    async getAgentScore(leaderboardType, agentId) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const score = await client.zscore(this.leaderboards[leaderboardType], agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score: ${score || 'No score'}`);
        return score ? parseFloat(score) : null;
    }

    async getTopPerformers(leaderboardType, count = 10) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const results = await client.zrevrange(
            this.leaderboards[leaderboardType],
            0,
            count - 1,
            'WITHSCORES'
        );

        const topPerformers = [];
        for (let i = 0; i < results.length; i += 2) {
            topPerformers.push({
                agentId: results[i],
                score: parseFloat(results[i + 1]),
                rank: (i / 2) + 1
            });
        }

        console.log(`Top ${count} performers in ${leaderboardType}:`, topPerformers);
        return topPerformers;
    }

    async getPerformersInRange(leaderboardType, minScore, maxScore) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const results = await client.zrangebyscore(
            this.leaderboards[leaderboardType],
            minScore,
            maxScore,
            'WITHSCORES'
        );

        const performers = [];
        for (let i = 0; i < results.length; i += 2) {
            performers.push({
                agentId: results[i],
                score: parseFloat(results[i + 1])
            });
        }

        console.log(`Performers with score ${minScore}-${maxScore} in ${leaderboardType}:`, performers);
        return performers;
    }

    async getLeaderboardStats(leaderboardType) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const count = await client.zcard(this.leaderboards[leaderboardType]);
        
        if (count === 0) {
            return { count: 0, minScore: null, maxScore: null };
        }

        const minScoreResult = await client.zrange(this.leaderboards[leaderboardType], 0, 0, 'WITHSCORES');
        const maxScoreResult = await client.zrevrange(this.leaderboards[leaderboardType], 0, 0, 'WITHSCORES');

        const stats = {
            count,
            minScore: minScoreResult.length > 1 ? parseFloat(minScoreResult[1]) : null,
            maxScore: maxScoreResult.length > 1 ? parseFloat(maxScoreResult[1]) : null
        };

        console.log(`${leaderboardType} leaderboard stats:`, stats);
        return stats;
    }
}

module.exports = AgentLeaderboard;
