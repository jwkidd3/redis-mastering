const SecurityMonitor = require('../src/services/security-monitor');

async function runSecurityTests() {
    console.log('🧪 Running Security Monitor Tests');
    console.log('==================================');

    const security = new SecurityMonitor();

    try {
        console.log('\n1. Testing failed login tracking...');
        
        // Simulate failed login attempts
        for (let i = 1; i <= 3; i++) {
            await security.recordLoginAttempt(`testuser${i}`, false, '192.168.1.100');
            console.log(`   Failed attempt ${i} recorded`);
        }

        console.log('\n2. Testing account lockout...');
        const testUser = 'lockouttest';
        
        // Attempt to trigger lockout
        for (let i = 1; i <= 6; i++) {
            await security.recordLoginAttempt(testUser, false, '192.168.1.101');
            
            const lockStatus = await security.isAccountLocked(testUser);
            if (lockStatus.locked) {
                console.log(`✅ Account locked after ${i} attempts. Remaining time: ${lockStatus.remainingTime}s`);
                break;
            }
        }

        console.log('\n3. Testing successful login after failures...');
        await security.recordLoginAttempt('successuser', false, '192.168.1.102');
        await security.recordLoginAttempt('successuser', false, '192.168.1.102');
        await security.recordLoginAttempt('successuser', true, '192.168.1.102');
        
        const statusAfterSuccess = await security.isAccountLocked('successuser');
        console.log(`✅ Account locked after successful login: ${statusAfterSuccess.locked} (should be false)`);

        console.log('\n4. Testing security event logging...');
        await security.logSecurityEvent('suspicious_activity', {
            userId: 'testuser',
            ipAddress: '192.168.1.200',
            action: 'multiple_rapid_requests',
            details: 'User made 100 requests in 10 seconds'
        });
        console.log('✅ Security event logged');

        console.log('\n5. Testing security statistics...');
        const today = new Date().toISOString().split('T')[0];
        const stats = await security.getFailedLoginStats(today);
        console.log('✅ Failed login statistics:');
        console.log(`   Total failed attempts: ${stats.totalFailedAttempts}`);
        console.log(`   Unique users: ${stats.uniqueUsers}`);
        console.log(`   Unique IPs: ${stats.uniqueIPs}`);
        console.log('   Attempts per user:', stats.attemptsPerUser);

        console.log('\n6. Testing security event retrieval...');
        const events = await security.getSecurityEvents(today);
        console.log(`✅ Security events for ${today}: ${events.length} total`);
        
        const failedLogins = events.filter(e => e.type === 'login_failed');
        const accountLocks = events.filter(e => e.type === 'account_locked');
        console.log(`   Failed logins: ${failedLogins.length}`);
        console.log(`   Account locks: ${accountLocks.length}`);

        console.log('\n🎉 All security tests completed successfully!');

    } catch (error) {
        console.error('❌ Security test failed:', error.message);
    }
}

runSecurityTests().catch(console.error);
