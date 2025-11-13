const SessionManager = require('../src/models/session');
const { getRedisClient } = require('../config/redis-config');

async function runSessionTests() {
    console.log('🧪 Running Session Management Tests');
    console.log('====================================');

    const sessionManager = new SessionManager();

    try {
        console.log('\n1. Testing session creation...');
        const sessionId = await sessionManager.createSession(
            'customer123', 
            'customer', 
            { 
                ipAddress: '192.168.1.100',
                userAgent: 'Mozilla/5.0 Test Browser',
                customerType: 'premium'
            }
        );
        console.log(`✅ Session created: ${sessionId}`);

        console.log('\n2. Testing session retrieval...');
        const session = await sessionManager.getSession(sessionId);
        console.log('✅ Session retrieved:', JSON.stringify(session, null, 2));

        console.log('\n3. Testing multiple sessions for user...');
        const sessionId2 = await sessionManager.createSession(
            'customer123', 
            'customer', 
            { ipAddress: '192.168.1.101' }
        );
        console.log(`✅ Second session created: ${sessionId2}`);

        console.log('\n4. Testing active sessions retrieval...');
        const activeSessions = await sessionManager.getUserActiveSessions('customer123');
        console.log(`✅ Active sessions found: ${activeSessions.length}`);
        activeSessions.forEach((session, index) => {
            console.log(`   Session ${index + 1}: ${session.sessionId} (IP: ${session.ipAddress})`);
        });

        console.log('\n5. Testing session destruction...');
        const destroyed = await sessionManager.destroySession(sessionId);
        console.log(`✅ Session destroyed: ${destroyed}`);

        console.log('\n6. Testing destroyed session retrieval...');
        const destroyedSession = await sessionManager.getSession(sessionId);
        console.log(`✅ Destroyed session result: ${destroyedSession === null ? 'null (expected)' : 'unexpected data'}`);

        console.log('\n7. Testing session cleanup...');
        await sessionManager.cleanupExpiredSessions();
        console.log('✅ Session cleanup completed');

        console.log('\n🎉 All session tests completed successfully!');

        // Close Redis connection
        await sessionManager.disconnect();
        process.exit(0);

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        // Close Redis connection on error
        try {
            await sessionManager.disconnect();
        } catch (disconnectError) {
            // Ignore disconnect errors
        }
        process.exit(1);
    }
}

runSessionTests().catch(console.error);
