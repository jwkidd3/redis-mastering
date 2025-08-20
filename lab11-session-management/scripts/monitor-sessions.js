const { getRedisClient } = require('../config/redis-config');

async function monitorSessions() {
    console.log('📊 Redis Session Monitor');
    console.log('========================');

    const client = await getRedisClient();

    try {
        // Get all session keys
        const sessionKeys = await client.keys('portal:session:*');
        console.log(`\n🔍 Found ${sessionKeys.length} active sessions`);

        // Get active session lists
        const userSessionKeys = await client.keys('active_sessions:*');
        console.log(`📋 Found ${userSessionKeys.length} users with active sessions`);

        // Detailed session info
        console.log('\n📋 Active Sessions Detail:');
        for (const key of sessionKeys.slice(0, 10)) { // Show first 10
            const sessionData = await client.hGetAll(key);
            const sessionId = key.replace('portal:session:', '');
            const ttl = await client.ttl(key);
            
            console.log(`\n   Session: ${sessionId.substring(0, 8)}...`);
            console.log(`   User: ${sessionData.userId} (${sessionData.userRole})`);
            console.log(`   IP: ${sessionData.ipAddress}`);
            console.log(`   Created: ${sessionData.createdAt}`);
            console.log(`   TTL: ${ttl}s`);
        }

        // Security logs
        const today = new Date().toISOString().split('T')[0];
        const securityLogKey = `security_log:${today}`;
        const logCount = await client.lLen(securityLogKey);
        console.log(`\n🛡️  Security events today: ${logCount}`);

        // Access logs
        const accessLogKey = `access_log:${today}`;
        const accessLogCount = await client.lLen(accessLogKey);
        console.log(`📝 Access log entries today: ${accessLogCount}`);

        // Memory usage
        const info = await client.info('memory');
        const memoryInfo = info.split('\r\n').find(line => line.startsWith('used_memory_human:'));
        console.log(`\n💾 Redis memory usage: ${memoryInfo ? memoryInfo.split(':')[1] : 'unknown'}`);

        console.log('\n✅ Monitoring complete');

    } catch (error) {
        console.error('❌ Monitoring error:', error.message);
    }
}

// Run monitoring every 30 seconds if called directly
if (require.main === module) {
    monitorSessions();
    setInterval(monitorSessions, 30000);
}

module.exports = monitorSessions;
