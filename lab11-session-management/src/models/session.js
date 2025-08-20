const { getRedisClient } = require('../../config/redis-config');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config({ path: './config/.env' });

class SessionManager {
    constructor() {
        this.prefix = process.env.SESSION_PREFIX || 'portal:session:';
        this.ttl = parseInt(process.env.SESSION_TTL) || 3600;
    }

    async createSession(userId, userRole, userData = {}) {
        const client = await getRedisClient();
        const sessionId = uuidv4();
        const sessionKey = `${this.prefix}${sessionId}`;
        
        const sessionData = {
            userId,
            userRole,
            createdAt: new Date().toISOString(),
            lastAccessed: new Date().toISOString(),
            ipAddress: userData.ipAddress || 'unknown',
            userAgent: userData.userAgent || 'unknown',
            ...userData
        };

        // Store session data
        await client.hSet(sessionKey, sessionData);
        await client.expire(sessionKey, this.ttl);

        // Track active sessions for user
        await client.sAdd(`active_sessions:${userId}`, sessionId);
        await client.expire(`active_sessions:${userId}`, this.ttl);

        console.log(`✅ Session created: ${sessionId} for user: ${userId} (${userRole})`);
        return sessionId;
    }

    async getSession(sessionId) {
        const client = await getRedisClient();
        const sessionKey = `${this.prefix}${sessionId}`;
        
        const sessionData = await client.hGetAll(sessionKey);
        
        if (Object.keys(sessionData).length === 0) {
            return null;
        }

        // Update last accessed time
        await client.hSet(sessionKey, 'lastAccessed', new Date().toISOString());
        await client.expire(sessionKey, this.ttl);

        return sessionData;
    }

    async destroySession(sessionId) {
        const client = await getRedisClient();
        const sessionKey = `${this.prefix}${sessionId}`;
        
        // Get session data to find userId
        const sessionData = await client.hGetAll(sessionKey);
        
        if (sessionData.userId) {
            // Remove from active sessions
            await client.sRem(`active_sessions:${sessionData.userId}`, sessionId);
        }

        // Delete session
        const result = await client.del(sessionKey);
        console.log(`🗑️  Session destroyed: ${sessionId}`);
        
        return result > 0;
    }

    async getUserActiveSessions(userId) {
        const client = await getRedisClient();
        const sessionIds = await client.sMembers(`active_sessions:${userId}`);
        
        const sessions = [];
        for (const sessionId of sessionIds) {
            const sessionData = await this.getSession(sessionId);
            if (sessionData) {
                sessions.push({ sessionId, ...sessionData });
            }
        }
        
        return sessions;
    }

    async cleanupExpiredSessions() {
        const client = await getRedisClient();
        const pattern = `${this.prefix}*`;
        
        let cursor = '0';
        let cleanedCount = 0;
        
        do {
            const reply = await client.scan(cursor, {
                MATCH: pattern,
                COUNT: 100
            });
            
            cursor = reply.cursor;
            const keys = reply.keys;
            
            for (const key of keys) {
                const ttl = await client.ttl(key);
                if (ttl === -1) { // No expiration set
                    await client.expire(key, this.ttl);
                }
            }
            
        } while (cursor !== '0');
        
        console.log(`🧹 Cleanup completed. Processed sessions.`);
        return cleanedCount;
    }
}

module.exports = SessionManager;
