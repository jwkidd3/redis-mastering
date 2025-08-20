const { getRedisClient } = require('../../config/redis-config');
require('dotenv').config({ path: './config/.env' });

class SecurityMonitor {
    constructor() {
        this.maxAttempts = parseInt(process.env.MAX_LOGIN_ATTEMPTS) || 5;
        this.lockoutDuration = parseInt(process.env.LOCKOUT_DURATION) || 300; // 5 minutes
        this.logTTL = parseInt(process.env.SECURITY_LOG_TTL) || 86400; // 24 hours
    }

    async recordLoginAttempt(userId, success, ipAddress = 'unknown') {
        const client = await getRedisClient();
        const attemptKey = `login_attempts:${userId}`;
        const lockKey = `account_lock:${userId}`;

        if (success) {
            // Clear failed attempts on successful login
            await client.del(attemptKey);
            console.log(`✅ Successful login: ${userId}`);
            
            // Log successful login
            await this.logSecurityEvent('login_success', {
                userId,
                ipAddress,
                timestamp: new Date().toISOString()
            });
        } else {
            // Increment failed attempts
            const attempts = await client.incr(attemptKey);
            await client.expire(attemptKey, this.lockoutDuration);

            console.log(`❌ Failed login attempt ${attempts}/${this.maxAttempts}: ${userId}`);

            // Log failed attempt
            await this.logSecurityEvent('login_failed', {
                userId,
                ipAddress,
                attempts,
                timestamp: new Date().toISOString()
            });

            // Lock account if max attempts reached
            if (attempts >= this.maxAttempts) {
                await client.setEx(lockKey, this.lockoutDuration, 'locked');
                console.log(`🔒 Account locked: ${userId} for ${this.lockoutDuration} seconds`);
                
                await this.logSecurityEvent('account_locked', {
                    userId,
                    ipAddress,
                    lockDuration: this.lockoutDuration,
                    timestamp: new Date().toISOString()
                });
            }

            return attempts;
        }
    }

    async isAccountLocked(userId) {
        const client = await getRedisClient();
        const lockKey = `account_lock:${userId}`;
        
        const isLocked = await client.exists(lockKey);
        if (isLocked) {
            const ttl = await client.ttl(lockKey);
            return { locked: true, remainingTime: ttl };
        }
        
        return { locked: false };
    }

    async logSecurityEvent(eventType, eventData) {
        const client = await getRedisClient();
        const logKey = `security_log:${new Date().toISOString().split('T')[0]}`;
        
        const event = {
            type: eventType,
            timestamp: new Date().toISOString(),
            ...eventData
        };

        await client.lPush(logKey, JSON.stringify(event));
        await client.expire(logKey, this.logTTL);
    }

    async getSecurityEvents(date, eventType = null) {
        const client = await getRedisClient();
        const logKey = `security_log:${date}`;
        
        const events = await client.lRange(logKey, 0, -1);
        let parsedEvents = events.map(event => JSON.parse(event));
        
        if (eventType) {
            parsedEvents = parsedEvents.filter(event => event.type === eventType);
        }
        
        return parsedEvents;
    }

    async getFailedLoginStats(date) {
        const events = await this.getSecurityEvents(date, 'login_failed');
        
        const stats = {
            totalFailedAttempts: events.length,
            uniqueUsers: new Set(events.map(e => e.userId)).size,
            uniqueIPs: new Set(events.map(e => e.ipAddress)).size,
            attemptsPerUser: {}
        };

        events.forEach(event => {
            const userId = event.userId;
            stats.attemptsPerUser[userId] = (stats.attemptsPerUser[userId] || 0) + 1;
        });

        return stats;
    }
}

module.exports = SecurityMonitor;
