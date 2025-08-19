const client = require('../src/connection');

async function cleanupLab9() {
    console.log('🧹 Cleaning up Lab 9 data...');

    try {
        // Get all keys related to lab 9
        const keys = await client.keys('customers:*');
        const leaderboardKeys = await client.keys('leaderboard:*');
        const analyticsKeys = await client.keys('analytics:*');
        const riskKeys = await client.keys('risk_scores');

        const allKeys = [...keys, ...leaderboardKeys, ...analyticsKeys, ...riskKeys];

        if (allKeys.length > 0) {
            await client.del(...allKeys);
            console.log(`✅ Deleted ${allKeys.length} keys`);
        } else {
            console.log('ℹ️ No Lab 9 keys found to delete');
        }

    } catch (error) {
        console.error('❌ Cleanup failed:', error);
    } finally {
        client.quit();
    }
}

cleanupLab9();
