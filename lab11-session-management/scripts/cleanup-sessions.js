const { getRedisClient } = require('../config/redis-config');

async function cleanupSessions() {
    console.log('🧹 Session Cleanup Utility');
    console.log('===========================');

    const client = await getRedisClient();

    try {
        console.log('\n1. Cleaning expired sessions...');
        const sessionKeys = await client.keys('portal:session:*');
        let expiredCount = 0;

        for (const key of sessionKeys) {
            const ttl = await client.ttl(key);
            if (ttl === -2) { // Key doesn't exist
                expiredCount++;
            } else if (ttl === -1) { // Key exists but no expiration
                await client.expire(key, 3600); // Set default expiration
                console.log(`   Set expiration for: ${key}`);
            }
        }

        console.log(`✅ Found ${expiredCount} expired sessions`);

        console.log('\n2. Cleaning orphaned active session lists...');
        const activeSessionKeys = await client.keys('active_sessions:*');
        let orphanedCount = 0;

        for (const key of activeSessionKeys) {
            const sessionIds = await client.sMembers(key);
            const validSessions = [];

            for (const sessionId of sessionIds) {
                const sessionExists = await client.exists(`portal:session:${sessionId}`);
                if (sessionExists) {
                    validSessions.push(sessionId);
                } else {
                    orphanedCount++;
                }
            }

            if (validSessions.length !== sessionIds.length) {
                await client.del(key);
                if (validSessions.length > 0) {
                    await client.sAdd(key, validSessions);
                    await client.expire(key, 3600);
                }
                console.log(`   Cleaned ${key}: removed ${sessionIds.length - validSessions.length} orphaned sessions`);
            }
        }

        console.log(`✅ Cleaned ${orphanedCount} orphaned session references`);

        console.log('\n3. Cleaning old security logs...');
        const securityLogKeys = await client.keys('security_log:*');
        let oldLogCount = 0;

        for (const key of securityLogKeys) {
            const date = key.split(':')[1];
            const logDate = new Date(date);
            const daysDiff = Math.floor((new Date() - logDate) / (1000 * 60 * 60 * 24));

            if (daysDiff > 30) { // Keep logs for 30 days
                await client.del(key);
                oldLogCount++;
                console.log(`   Deleted old log: ${key}`);
            }
        }

        console.log(`✅ Cleaned ${oldLogCount} old security logs`);

        console.log('\n4. Cleaning old access logs...');
        const accessLogKeys = await client.keys('access_log:*');
        let oldAccessLogCount = 0;

        for (const key of accessLogKeys) {
            const date = key.split(':')[1];
            const logDate = new Date(date);
            const daysDiff = Math.floor((new Date() - logDate) / (1000 * 60 * 60 * 24));

            if (daysDiff > 7) { // Keep access logs for 7 days
                await client.del(key);
                oldAccessLogCount++;
                console.log(`   Deleted old access log: ${key}`);
            }
        }

        console.log(`✅ Cleaned ${oldAccessLogCount} old access logs`);

        console.log('\n5. Final statistics...');
        const finalSessionCount = await client.keys('portal:session:*').then(keys => keys.length);
        const finalUserSessionCount = await client.keys('active_sessions:*').then(keys => keys.length);
        
        console.log(`   Active sessions: ${finalSessionCount}`);
        console.log(`   Users with sessions: ${finalUserSessionCount}`);

        console.log('\n🎉 Cleanup completed successfully!');

    } catch (error) {
        console.error('❌ Cleanup error:', error.message);
    }
}

cleanupSessions().catch(console.error);
