// auth-middleware.js - Authentication middleware using Redis sessions
const SessionManager = require('./session-manager');

class AuthMiddleware {
    constructor() {
        this.sessionManager = new SessionManager();
        this.failedLoginKey = 'failed_logins';
        this.maxFailedAttempts = 5;
        this.lockoutDuration = 900; // 15 minutes
    }

    async connect() {
        await this.sessionManager.connect();
    }

    async disconnect() {
        await this.sessionManager.disconnect();
    }

    // Middleware function
    async authenticate(req, res, next) {
        const sessionId = req.headers['x-session-id'] || req.cookies?.sessionId;

        if (!sessionId) {
            return res.status(401).json({ error: 'No session provided' });
        }

        const session = await this.sessionManager.getSession(sessionId);

        if (!session) {
            return res.status(401).json({ error: 'Invalid session' });
        }

        // Attach session to request
        req.session = session;
        req.sessionId = sessionId;

        next();
    }

    // Track failed login attempts
    async trackFailedLogin(userId) {
        const client = this.sessionManager.client;
        const key = `${this.failedLoginKey}:${userId}`;

        const count = await client.incr(key);
        await client.expire(key, this.lockoutDuration);

        return count;
    }

    // Check if user is locked out
    async isLockedOut(userId) {
        const client = this.sessionManager.client;
        const key = `${this.failedLoginKey}:${userId}`;

        const count = await client.get(key);
        return count && parseInt(count) >= this.maxFailedAttempts;
    }

    // Clear failed login attempts
    async clearFailedLogins(userId) {
        const client = this.sessionManager.client;
        const key = `${this.failedLoginKey}:${userId}`;
        await client.del(key);
    }
}

module.exports = AuthMiddleware;
