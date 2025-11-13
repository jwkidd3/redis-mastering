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

        const result = await client.zAdd(this.leaderboards[leaderboardType], { score, value: agentId });
        console.log(`Agent ${agentId} ${leaderboardType} score updated to ${score}`);
        return result;
    }

    async incrementAgentScore(leaderboardType, agentId, increment = 1) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const newScore = await client.zIncrBy(this.leaderboards[leaderboardType], increment, agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score incremented by ${increment}, new score: ${newScore}`);
        return parseFloat(newScore);
    }

    async getAgentRank(leaderboardType, agentId) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const rank = await client.zRevRank(this.leaderboards[leaderboardType], agentId);
        const finalRank = rank !== null ? rank + 1 : null;
        console.log(`Agent ${agentId} rank in ${leaderboardType}: ${finalRank || 'Not ranked'}`);
        return finalRank;
    }

    async getAgentScore(leaderboardType, agentId) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const score = await client.zScore(this.leaderboards[leaderboardType], agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score: ${score || 'No score'}`);
        return score ? parseFloat(score) : null;
    }

    async getTopPerformers(leaderboardType, count = 10) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const results = await client.zRevRangeWithScores(
            this.leaderboards[leaderboardType],
            0,
            count - 1
        );

        const topPerformers = [];
        let rank = 1;
        for (const item of results) {
            topPerformers.push({
                agentId: item.value,
                score: item.score,
                rank: rank++
            });
        }

        console.log(`Top ${count} performers in ${leaderboardType}:`, topPerformers);
        return topPerformers;
    }

    async getPerformersInRange(leaderboardType, minScore, maxScore) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const results = await client.zRangeByScoreWithScores(
            this.leaderboards[leaderboardType],
            minScore,
            maxScore
        );

        const performers = [];
        for (const item of results) {
            performers.push({
                agentId: item.value,
                score: item.score
            });
        }

        console.log(`Performers with score ${minScore}-${maxScore} in ${leaderboardType}:`, performers);
        return performers;
    }

    async getLeaderboardStats(leaderboardType) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const count = await client.zCard(this.leaderboards[leaderboardType]);

        if (count === 0) {
            return { count: 0, minScore: null, maxScore: null };
        }

        const minScoreResult = await client.zRangeWithScores(this.leaderboards[leaderboardType], 0, 0);
        const maxScoreResult = await client.zRevRangeWithScores(this.leaderboards[leaderboardType], 0, 0);

        const stats = {
            count,
            minScore: minScoreResult.length > 0 ? minScoreResult[0].score : null,
            maxScore: maxScoreResult.length > 0 ? maxScoreResult[0].score : null
        };

        console.log(`${leaderboardType} leaderboard stats:`, stats);
        return stats;
    }
}

module.exports = AgentLeaderboard;
