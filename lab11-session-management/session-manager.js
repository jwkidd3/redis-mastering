// session-manager.js - Session management using Redis
const redis = require('redis');
const crypto = require('crypto');

class SessionManager {
    constructor() {
        this.client = null;
        this.defaultTTL = 3600; // 1 hour
    }

    async connect() {
        this.client = redis.createClient();
        await this.client.connect();
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    generateSessionId() {
        return crypto.randomBytes(32).toString('hex');
    }

    async createSession(userId, sessionData = {}) {
        const sessionId = this.generateSessionId();
        const key = `session:${sessionId}`;

        const data = {
            user_id: userId,
            created_at: new Date().toISOString(),
            ...sessionData
        };

        await this.client.hSet(key, data);
        await this.client.expire(key, this.defaultTTL);

        return sessionId;
    }

    async getSession(sessionId) {
        const key = `session:${sessionId}`;
        const session = await this.client.hGetAll(key);
        return Object.keys(session).length > 0 ? session : null;
    }

    async updateSession(sessionId, updates) {
        const key = `session:${sessionId}`;
        await this.client.hSet(key, updates);
    }

    async deleteSession(sessionId) {
        const key = `session:${sessionId}`;
        await this.client.del(key);
    }

    async renewSession(sessionId, ttl = null) {
        const key = `session:${sessionId}`;
        await this.client.expire(key, ttl || this.defaultTTL);
    }

    async getSessionTTL(sessionId) {
        const key = `session:${sessionId}`;
        return await this.client.ttl(key);
    }
}

module.exports = SessionManager;
