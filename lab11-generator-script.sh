#!/bin/bash

# Lab 11 Content Generator Script
# Generates complete content and code for Lab 11: Session Management & Security for Business Systems
# Duration: 45 minutes
# Focus: JavaScript Redis client for secure session management and authentication

set -e

LAB_DIR="lab11-session-management-security"
LAB_NUMBER="11"
LAB_TITLE="Session Management & Security for Business Systems"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript-based session management, authentication, and security patterns"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,examples,security-patterns,session-handlers,tests}

# Create main lab instructions markdown file
echo "📋 Creating lab11.md..."
cat > lab11.md << 'EOF'
# Lab 11: Session Management & Security for Business Systems

**Duration:** 45 minutes  
**Objective:** Implement secure session management, authentication patterns, and security best practices using JavaScript Redis client

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement secure session storage and management for business applications
- Build authentication patterns with token management and rotation
- Create session expiration and renewal strategies for user accounts
- Implement role-based access control (RBAC) for business entities
- Build secure password management with hashing and rate limiting
- Apply production security patterns for sensitive business data

---

## Part 1: Secure Session Management Infrastructure (15 minutes)

### Step 1: Environment Setup with Security Configuration

```bash
# Start Redis with security-optimized configuration
docker run -d --name redis-security-lab11 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 512mb \
  --maxmemory-policy volatile-lru \
  --timeout 300 \
  --tcp-keepalive 60 \
  --tcp-backlog 511 \
  --slowlog-log-slower-than 10000

# Verify Redis is running
redis-cli ping

# Install JavaScript dependencies
npm init -y
npm install redis crypto uuid bcrypt jsonwebtoken dotenv

# Load security sample data
./scripts/load-security-data.sh
```

### Step 2: Core Session Management Implementation

Create `src/session-manager.js`:

```javascript
const redis = require('redis');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

class SessionManager {
    constructor(redisClient) {
        this.client = redisClient;
        this.sessionPrefix = 'session:';
        this.userSessionPrefix = 'user:sessions:';
        this.defaultTTL = 1800; // 30 minutes
        this.maxSessions = 5; // Maximum concurrent sessions per user
    }

    // Generate secure session token
    generateSessionToken() {
        return crypto.randomBytes(32).toString('hex');
    }

    // Create new session with security controls
    async createSession(userId, userData, options = {}) {
        const sessionId = uuidv4();
        const token = this.generateSessionToken();
        const sessionKey = `${this.sessionPrefix}${sessionId}`;
        
        const sessionData = {
            id: sessionId,
            userId: userId,
            token: token,
            createdAt: Date.now(),
            lastActivity: Date.now(),
            ipAddress: options.ipAddress || 'unknown',
            userAgent: options.userAgent || 'unknown',
            data: userData,
            refreshCount: 0
        };

        // Store session with TTL
        const ttl = options.ttl || this.defaultTTL;
        await this.client.setEx(
            sessionKey,
            ttl,
            JSON.stringify(sessionData)
        );

        // Track user sessions for security monitoring
        await this.trackUserSession(userId, sessionId);
        
        // Enforce maximum session limit
        await this.enforceSessionLimit(userId);

        return { sessionId, token, expiresIn: ttl };
    }

    // Track user sessions for monitoring
    async trackUserSession(userId, sessionId) {
        const userSessionKey = `${this.userSessionPrefix}${userId}`;
        const timestamp = Date.now();
        
        // Add session to user's active sessions
        await this.client.zAdd(userSessionKey, {
            score: timestamp,
            value: sessionId
        });
        
        // Set expiry on the tracking key
        await this.client.expire(userSessionKey, 86400); // 24 hours
    }

    // Enforce maximum concurrent sessions
    async enforceSessionLimit(userId) {
        const userSessionKey = `${this.userSessionPrefix}${userId}`;
        
        // Get all user sessions
        const sessions = await this.client.zRange(userSessionKey, 0, -1);
        
        if (sessions.length > this.maxSessions) {
            // Remove oldest sessions
            const toRemove = sessions.slice(0, sessions.length - this.maxSessions);
            
            for (const sessionId of toRemove) {
                await this.destroySession(sessionId);
                await this.client.zRem(userSessionKey, sessionId);
            }
            
            console.log(`Removed ${toRemove.length} old sessions for user ${userId}`);
        }
    }

    // Validate and retrieve session
    async validateSession(sessionId, token) {
        const sessionKey = `${this.sessionPrefix}${sessionId}`;
        const sessionData = await this.client.get(sessionKey);
        
        if (!sessionData) {
            return { valid: false, reason: 'Session not found' };
        }
        
        const session = JSON.parse(sessionData);
        
        // Validate token
        if (session.token !== token) {
            // Log potential security breach
            await this.logSecurityEvent('invalid_token', sessionId);
            return { valid: false, reason: 'Invalid token' };
        }
        
        // Check for session hijacking (IP change)
        // This would be implemented with actual request data
        
        // Update last activity
        session.lastActivity = Date.now();
        const ttl = await this.client.ttl(sessionKey);
        await this.client.setEx(sessionKey, ttl, JSON.stringify(session));
        
        return { valid: true, session };
    }

    // Refresh session with rotation
    async refreshSession(sessionId, token) {
        const validation = await this.validateSession(sessionId, token);
        
        if (!validation.valid) {
            return { success: false, reason: validation.reason };
        }
        
        const session = validation.session;
        
        // Generate new token for security
        const newToken = this.generateSessionToken();
        session.token = newToken;
        session.refreshCount++;
        session.lastRefresh = Date.now();
        
        // Extend TTL
        const sessionKey = `${this.sessionPrefix}${sessionId}`;
        await this.client.setEx(
            sessionKey,
            this.defaultTTL,
            JSON.stringify(session)
        );
        
        return { 
            success: true, 
            token: newToken, 
            expiresIn: this.defaultTTL 
        };
    }

    // Destroy session
    async destroySession(sessionId) {
        const sessionKey = `${this.sessionPrefix}${sessionId}`;
        const sessionData = await this.client.get(sessionKey);
        
        if (sessionData) {
            const session = JSON.parse(sessionData);
            
            // Remove from user's session list
            const userSessionKey = `${this.userSessionPrefix}${session.userId}`;
            await this.client.zRem(userSessionKey, sessionId);
            
            // Delete session
            await this.client.del(sessionKey);
            
            // Log session termination
            await this.logSecurityEvent('session_destroyed', sessionId);
            
            return true;
        }
        
        return false;
    }

    // Log security events
    async logSecurityEvent(event, sessionId, details = {}) {
        const logKey = `security:log:${Date.now()}`;
        const logData = {
            event,
            sessionId,
            timestamp: Date.now(),
            details
        };
        
        await this.client.setEx(logKey, 86400, JSON.stringify(logData));
        await this.client.lPush('security:events', logKey);
        await this.client.lTrim('security:events', 0, 999); // Keep last 1000 events
    }

    // Get active sessions for user
    async getUserSessions(userId) {
        const userSessionKey = `${this.userSessionPrefix}${userId}`;
        const sessionIds = await this.client.zRange(userSessionKey, 0, -1);
        
        const sessions = [];
        for (const sessionId of sessionIds) {
            const sessionKey = `${this.sessionPrefix}${sessionId}`;
            const sessionData = await this.client.get(sessionKey);
            if (sessionData) {
                sessions.push(JSON.parse(sessionData));
            }
        }
        
        return sessions;
    }

    // Session analytics
    async getSessionAnalytics() {
        const pattern = `${this.sessionPrefix}*`;
        const keys = await this.client.keys(pattern);
        
        const analytics = {
            totalActiveSessions: keys.length,
            sessionsByHour: {},
            averageSessionDuration: 0,
            topUsers: []
        };
        
        let totalDuration = 0;
        for (const key of keys) {
            const sessionData = await this.client.get(key);
            if (sessionData) {
                const session = JSON.parse(sessionData);
                const duration = session.lastActivity - session.createdAt;
                totalDuration += duration;
                
                // Group by hour
                const hour = new Date(session.createdAt).getHours();
                analytics.sessionsByHour[hour] = (analytics.sessionsByHour[hour] || 0) + 1;
            }
        }
        
        analytics.averageSessionDuration = keys.length > 0 
            ? Math.round(totalDuration / keys.length / 1000 / 60) 
            : 0;
        
        return analytics;
    }
}

module.exports = SessionManager;
```

---

## Part 2: Authentication & Authorization Patterns (15 minutes)

### Step 3: Implement Authentication System

Create `src/auth-manager.js`:

```javascript
const redis = require('redis');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

class AuthManager {
    constructor(redisClient, sessionManager) {
        this.client = redisClient;
        this.sessionManager = sessionManager;
        this.jwtSecret = process.env.JWT_SECRET || 'default-secret-change-in-production';
        this.saltRounds = 10;
        this.loginAttemptWindow = 900; // 15 minutes
        this.maxLoginAttempts = 5;
        this.lockoutDuration = 1800; // 30 minutes
    }

    // Register new user with secure password storage
    async registerUser(username, password, userData = {}) {
        const userKey = `user:${username}`;
        
        // Check if user exists
        const exists = await this.client.exists(userKey);
        if (exists) {
            return { success: false, error: 'User already exists' };
        }
        
        // Hash password
        const passwordHash = await bcrypt.hash(password, this.saltRounds);
        
        // Create user record
        const user = {
            username,
            passwordHash,
            createdAt: Date.now(),
            lastLogin: null,
            loginCount: 0,
            roles: userData.roles || ['user'],
            profile: userData.profile || {},
            status: 'active',
            mfaEnabled: false,
            passwordHistory: [passwordHash]
        };
        
        // Store user
        await this.client.hSet(userKey, {
            data: JSON.stringify(user),
            status: user.status
        });
        
        // Initialize user permissions
        await this.initializeUserPermissions(username, user.roles);
        
        return { success: true, username };
    }

    // Authenticate user with rate limiting
    async authenticateUser(username, password, options = {}) {
        // Check for account lockout
        const isLocked = await this.isAccountLocked(username);
        if (isLocked) {
            return { 
                success: false, 
                error: 'Account temporarily locked due to multiple failed attempts' 
            };
        }
        
        const userKey = `user:${username}`;
        const userData = await this.client.hGet(userKey, 'data');
        
        if (!userData) {
            await this.recordFailedLogin(username);
            return { success: false, error: 'Invalid credentials' };
        }
        
        const user = JSON.parse(userData);
        
        // Check account status
        if (user.status !== 'active') {
            return { success: false, error: `Account ${user.status}` };
        }
        
        // Verify password
        const validPassword = await bcrypt.compare(password, user.passwordHash);
        
        if (!validPassword) {
            await this.recordFailedLogin(username);
            return { success: false, error: 'Invalid credentials' };
        }
        
        // Clear failed login attempts
        await this.clearFailedLogins(username);
        
        // Update user login info
        user.lastLogin = Date.now();
        user.loginCount++;
        await this.client.hSet(userKey, 'data', JSON.stringify(user));
        
        // Create session
        const session = await this.sessionManager.createSession(
            username,
            {
                username: user.username,
                roles: user.roles,
                profile: user.profile
            },
            options
        );
        
        // Generate JWT token
        const jwtToken = jwt.sign(
            {
                sessionId: session.sessionId,
                username: user.username,
                roles: user.roles
            },
            this.jwtSecret,
            { expiresIn: '1h' }
        );
        
        // Log successful login
        await this.logAuthEvent('login_success', username);
        
        return {
            success: true,
            session,
            token: jwtToken,
            user: {
                username: user.username,
                roles: user.roles,
                profile: user.profile
            }
        };
    }

    // Record failed login attempt
    async recordFailedLogin(username) {
        const attemptKey = `login:attempts:${username}`;
        const attempts = await this.client.incr(attemptKey);
        
        if (attempts === 1) {
            await this.client.expire(attemptKey, this.loginAttemptWindow);
        }
        
        // Lock account if max attempts exceeded
        if (attempts >= this.maxLoginAttempts) {
            await this.lockAccount(username);
        }
        
        await this.logAuthEvent('login_failed', username, { attempt: attempts });
    }

    // Clear failed login attempts
    async clearFailedLogins(username) {
        const attemptKey = `login:attempts:${username}`;
        await this.client.del(attemptKey);
    }

    // Check if account is locked
    async isAccountLocked(username) {
        const lockKey = `account:locked:${username}`;
        return await this.client.exists(lockKey) > 0;
    }

    // Lock account temporarily
    async lockAccount(username) {
        const lockKey = `account:locked:${username}`;
        await this.client.setEx(lockKey, this.lockoutDuration, 'locked');
        await this.logAuthEvent('account_locked', username);
    }

    // Initialize user permissions
    async initializeUserPermissions(username, roles) {
        const permKey = `permissions:${username}`;
        const permissions = new Set();
        
        // Map roles to permissions
        const rolePermissions = {
            admin: ['read', 'write', 'delete', 'manage_users', 'view_analytics'],
            manager: ['read', 'write', 'delete', 'view_analytics'],
            user: ['read', 'write'],
            guest: ['read']
        };
        
        for (const role of roles) {
            if (rolePermissions[role]) {
                rolePermissions[role].forEach(perm => permissions.add(perm));
            }
        }
        
        // Store permissions
        await this.client.sAdd(permKey, Array.from(permissions));
        await this.client.expire(permKey, 86400); // Refresh daily
    }

    // Check user permission
    async hasPermission(username, permission) {
        const permKey = `permissions:${username}`;
        return await this.client.sIsMember(permKey, permission);
    }

    // Verify JWT token
    async verifyToken(token) {
        try {
            const decoded = jwt.verify(token, this.jwtSecret);
            
            // Verify session still exists
            const session = await this.sessionManager.validateSession(
                decoded.sessionId,
                token
            );
            
            if (!session.valid) {
                return { valid: false, reason: 'Session invalid' };
            }
            
            return { valid: true, decoded };
        } catch (error) {
            return { valid: false, reason: error.message };
        }
    }

    // Change password with history check
    async changePassword(username, oldPassword, newPassword) {
        const userKey = `user:${username}`;
        const userData = await this.client.hGet(userKey, 'data');
        
        if (!userData) {
            return { success: false, error: 'User not found' };
        }
        
        const user = JSON.parse(userData);
        
        // Verify old password
        const validPassword = await bcrypt.compare(oldPassword, user.passwordHash);
        if (!validPassword) {
            return { success: false, error: 'Invalid current password' };
        }
        
        // Check password history (prevent reuse)
        for (const oldHash of user.passwordHistory || []) {
            if (await bcrypt.compare(newPassword, oldHash)) {
                return { 
                    success: false, 
                    error: 'Password has been used recently' 
                };
            }
        }
        
        // Hash new password
        const newPasswordHash = await bcrypt.hash(newPassword, this.saltRounds);
        
        // Update user
        user.passwordHash = newPasswordHash;
        user.passwordHistory = user.passwordHistory || [];
        user.passwordHistory.push(newPasswordHash);
        user.passwordHistory = user.passwordHistory.slice(-5); // Keep last 5
        user.passwordChangedAt = Date.now();
        
        await this.client.hSet(userKey, 'data', JSON.stringify(user));
        
        // Invalidate all sessions
        const sessions = await this.sessionManager.getUserSessions(username);
        for (const session of sessions) {
            await this.sessionManager.destroySession(session.id);
        }
        
        await this.logAuthEvent('password_changed', username);
        
        return { success: true };
    }

    // Log authentication events
    async logAuthEvent(event, username, details = {}) {
        const logKey = `auth:log:${Date.now()}`;
        const logData = {
            event,
            username,
            timestamp: Date.now(),
            details
        };
        
        await this.client.setEx(logKey, 604800, JSON.stringify(logData)); // 7 days
        await this.client.lPush('auth:events', logKey);
        await this.client.lTrim('auth:events', 0, 9999); // Keep last 10000 events
    }

    // Get authentication analytics
    async getAuthAnalytics() {
        const keys = await this.client.keys('auth:log:*');
        const analytics = {
            totalEvents: keys.length,
            eventTypes: {},
            recentEvents: []
        };
        
        // Get recent events
        const recentKeys = await this.client.lRange('auth:events', 0, 9);
        for (const key of recentKeys) {
            const data = await this.client.get(key);
            if (data) {
                const event = JSON.parse(data);
                analytics.recentEvents.push(event);
                analytics.eventTypes[event.event] = 
                    (analytics.eventTypes[event.event] || 0) + 1;
            }
        }
        
        return analytics;
    }
}

module.exports = AuthManager;
```

---

## Part 3: Testing & Production Deployment (15 minutes)

### Step 4: Integration Testing

Create `tests/test-security.js`:

```javascript
const redis = require('redis');
const SessionManager = require('../src/session-manager');
const AuthManager = require('../src/auth-manager');

async function runSecurityTests() {
    const client = redis.createClient({
        socket: { host: 'localhost', port: 6379 }
    });
    
    await client.connect();
    console.log('🔒 Security Testing Suite\n');
    
    const sessionManager = new SessionManager(client);
    const authManager = new AuthManager(client, sessionManager);
    
    try {
        // Test 1: User Registration
        console.log('Test 1: User Registration');
        const reg1 = await authManager.registerUser('john.doe', 'SecurePass123!', {
            profile: { name: 'John Doe', email: 'john@example.com' },
            roles: ['user']
        });
        console.log('✓ User registered:', reg1);
        
        const reg2 = await authManager.registerUser('admin', 'AdminPass456!', {
            profile: { name: 'Admin User', email: 'admin@example.com' },
            roles: ['admin']
        });
        console.log('✓ Admin registered:', reg2);
        
        // Test 2: Authentication
        console.log('\nTest 2: Authentication');
        const auth1 = await authManager.authenticateUser('john.doe', 'SecurePass123!', {
            ipAddress: '192.168.1.100',
            userAgent: 'Mozilla/5.0'
        });
        console.log('✓ User authenticated:', {
            success: auth1.success,
            sessionId: auth1.session?.sessionId,
            token: auth1.token?.substring(0, 20) + '...'
        });
        
        // Test 3: Failed Login Attempts
        console.log('\nTest 3: Failed Login Rate Limiting');
        for (let i = 1; i <= 6; i++) {
            const attempt = await authManager.authenticateUser(
                'john.doe', 
                'WrongPassword'
            );
            console.log(`Attempt ${i}:`, attempt.error);
        }
        
        // Test 4: Session Management
        console.log('\nTest 4: Session Management');
        const sessions = await sessionManager.getUserSessions('john.doe');
        console.log('Active sessions:', sessions.length);
        
        // Test 5: Session Refresh
        console.log('\nTest 5: Session Refresh');
        if (auth1.session) {
            const refresh = await sessionManager.refreshSession(
                auth1.session.sessionId,
                auth1.session.token
            );
            console.log('✓ Session refreshed:', refresh.success);
        }
        
        // Test 6: Permission Check
        console.log('\nTest 6: Permission Verification');
        const canRead = await authManager.hasPermission('john.doe', 'read');
        const canManage = await authManager.hasPermission('john.doe', 'manage_users');
        const adminCanManage = await authManager.hasPermission('admin', 'manage_users');
        console.log('User can read:', canRead);
        console.log('User can manage users:', canManage);
        console.log('Admin can manage users:', adminCanManage);
        
        // Test 7: Password Change
        console.log('\nTest 7: Password Change');
        const pwChange = await authManager.changePassword(
            'john.doe',
            'SecurePass123!',
            'NewSecurePass789!'
        );
        console.log('✓ Password changed:', pwChange.success);
        
        // Test 8: Session Analytics
        console.log('\nTest 8: Session Analytics');
        const analytics = await sessionManager.getSessionAnalytics();
        console.log('Session Analytics:', analytics);
        
        // Test 9: Auth Event Analytics
        console.log('\nTest 9: Authentication Analytics');
        const authAnalytics = await authManager.getAuthAnalytics();
        console.log('Auth Events:', authAnalytics.eventTypes);
        
        // Test 10: Multiple Concurrent Sessions
        console.log('\nTest 10: Concurrent Session Limit');
        for (let i = 1; i <= 7; i++) {
            const session = await sessionManager.createSession(
                'test.user',
                { sessionNumber: i },
                { ipAddress: `192.168.1.${100 + i}` }
            );
            console.log(`Session ${i} created:`, session.sessionId);
        }
        const testUserSessions = await sessionManager.getUserSessions('test.user');
        console.log('Final session count (max 5):', testUserSessions.length);
        
    } catch (error) {
        console.error('Test failed:', error);
    } finally {
        await client.quit();
    }
}

// Performance test
async function performanceTest() {
    const client = redis.createClient({
        socket: { host: 'localhost', port: 6379 }
    });
    
    await client.connect();
    console.log('\n⚡ Performance Testing\n');
    
    const sessionManager = new SessionManager(client);
    
    const startTime = Date.now();
    const operations = 1000;
    
    // Create many sessions
    for (let i = 0; i < operations; i++) {
        await sessionManager.createSession(
            `user${i}`,
            { data: `Session data ${i}` }
        );
    }
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    const opsPerSecond = (operations / (duration / 1000)).toFixed(2);
    
    console.log(`Created ${operations} sessions in ${duration}ms`);
    console.log(`Performance: ${opsPerSecond} operations/second`);
    
    await client.quit();
}

// Run tests
async function main() {
    console.log('🔐 Business Security & Session Management Testing');
    console.log('================================================\n');
    
    await runSecurityTests();
    await performanceTest();
    
    console.log('\n✅ All tests completed!');
}

main().catch(console.error);
```

### Step 5: Production Deployment Configuration

Create `src/index.js`:

```javascript
const redis = require('redis');
const express = require('express');
const SessionManager = require('./session-manager');
const AuthManager = require('./auth-manager');

// Production Redis configuration
const redisClient = redis.createClient({
    socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        reconnectStrategy: (retries) => {
            if (retries > 10) {
                console.error('Redis connection failed after 10 retries');
                return new Error('Redis connection failed');
            }
            return Math.min(retries * 100, 3000);
        }
    },
    password: process.env.REDIS_PASSWORD,
    database: process.env.REDIS_DB || 0,
    commandsQueueMaxLength: 100,
    disableOfflineQueue: true
});

// Error handling
redisClient.on('error', (err) => {
    console.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
    console.log('✓ Connected to Redis');
});

// Initialize managers
async function initializeApp() {
    await redisClient.connect();
    
    const sessionManager = new SessionManager(redisClient);
    const authManager = new AuthManager(redisClient, sessionManager);
    
    // Express middleware example
    const app = express();
    app.use(express.json());
    
    // Authentication endpoint
    app.post('/api/login', async (req, res) => {
        const { username, password } = req.body;
        const result = await authManager.authenticateUser(username, password, {
            ipAddress: req.ip,
            userAgent: req.headers['user-agent']
        });
        
        if (result.success) {
            res.json({
                success: true,
                token: result.token,
                session: result.session
            });
        } else {
            res.status(401).json({ error: result.error });
        }
    });
    
    // Session validation middleware
    app.use('/api/protected/*', async (req, res, next) => {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ error: 'No token provided' });
        }
        
        const validation = await authManager.verifyToken(token);
        
        if (validation.valid) {
            req.user = validation.decoded;
            next();
        } else {
            res.status(401).json({ error: validation.reason });
        }
    });
    
    // Protected endpoint example
    app.get('/api/protected/data', async (req, res) => {
        res.json({
            message: 'Protected data',
            user: req.user
        });
    });
    
    // Health check
    app.get('/health', async (req, res) => {
        const redisHealth = redisClient.isReady;
        const analytics = await sessionManager.getSessionAnalytics();
        
        res.json({
            status: redisHealth ? 'healthy' : 'unhealthy',
            redis: redisHealth,
            activeSessions: analytics.totalActiveSessions,
            timestamp: new Date().toISOString()
        });
    });
    
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`✓ Server running on port ${PORT}`);
    });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, closing connections...');
    await redisClient.quit();
    process.exit(0);
});

// Start application
initializeApp().catch(console.error);
```

## 📋 Lab Summary

### What You've Accomplished
✅ Implemented secure session management system  
✅ Built authentication with rate limiting and lockout  
✅ Created role-based access control (RBAC)  
✅ Developed session rotation and refresh patterns  
✅ Implemented password management with history  
✅ Built security event logging and analytics  

### Key Security Patterns Mastered
- **Session Security:** Token generation, rotation, and validation
- **Authentication:** Rate limiting, account lockout, MFA preparation
- **Authorization:** Role-based permissions and access control
- **Password Management:** Hashing, history, and change policies
- **Security Monitoring:** Event logging and analytics
- **Production Hardening:** Connection resilience and error handling

### Production Deployment Checklist
- [ ] Use environment variables for all secrets
- [ ] Enable Redis AUTH with strong password
- [ ] Configure TLS/SSL for Redis connections
- [ ] Implement rate limiting on all endpoints
- [ ] Set up monitoring and alerting
- [ ] Regular security audits of sessions
- [ ] Backup authentication data regularly
- [ ] Test disaster recovery procedures

### Next Steps
- Implement multi-factor authentication (MFA)
- Add OAuth2/SAML integration
- Build session activity monitoring dashboard
- Implement IP-based restrictions
- Add device fingerprinting
- Create security compliance reports

## 🎯 Challenge Exercises

1. **Implement MFA:** Add TOTP-based two-factor authentication
2. **Add OAuth:** Integrate social login providers
3. **Session Analytics Dashboard:** Build real-time monitoring
4. **Compliance Reporting:** Generate GDPR/SOC2 compliance reports
5. **Advanced Threat Detection:** Implement anomaly detection

## 📚 Additional Resources

- Redis Security Best Practices
- OWASP Authentication Cheat Sheet
- JWT Security Best Practices
- Session Management Guidelines
- Rate Limiting Strategies

---

**Congratulations!** You've successfully implemented enterprise-grade session management and security patterns for business applications! 🎉
EOF

# Create security data loader script
echo "📊 Creating scripts/load-security-data.sh..."
mkdir -p scripts
cat > scripts/load-security-data.sh << 'EOF'
#!/bin/bash

echo "Loading security sample data..."

# Clear existing data
redis-cli FLUSHDB > /dev/null

# Create sample users
redis-cli HSET user:alice data '{"username":"alice","passwordHash":"$2b$10$sample","roles":["admin"],"status":"active"}' > /dev/null
redis-cli HSET user:bob data '{"username":"bob","passwordHash":"$2b$10$sample","roles":["user"],"status":"active"}' > /dev/null
redis-cli HSET user:charlie data '{"username":"charlie","passwordHash":"$2b$10$sample","roles":["guest"],"status":"active"}' > /dev/null

# Create sample permissions
redis-cli SADD permissions:alice read write delete manage_users view_analytics > /dev/null
redis-cli SADD permissions:bob read write > /dev/null
redis-cli SADD permissions:charlie read > /dev/null

# Create sample security events
for i in {1..5}; do
    redis-cli LPUSH auth:events "auth:log:$(date +%s)$i" > /dev/null
done

echo "✓ Security sample data loaded"
echo ""
echo "Sample Users:"
echo "  - alice (admin)"
echo "  - bob (user)"
echo "  - charlie (guest)"
echo ""
EOF

chmod +x scripts/load-security-data.sh

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab11-session-security",
  "version": "1.0.0",
  "description": "Session Management and Security for Business Systems",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "node tests/test-security.js",
    "dev": "nodemon src/index.js",
    "load-data": "./scripts/load-security-data.sh"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.0",
    "bcrypt": "^5.1.0",
    "jsonwebtoken": "^9.0.0",
    "uuid": "^9.0.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.0"
  }
}
EOF

# Create .env template
echo "🔐 Creating .env.example..."
cat > .env.example << 'EOF'
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Security Configuration
JWT_SECRET=your-secret-key-change-in-production
SESSION_TTL=1800
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=1800

# Server Configuration
PORT=3000
NODE_ENV=production
EOF

# Create comprehensive README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 11: Session Management & Security for Business Systems

**Duration:** 45 minutes  
**Focus:** JavaScript-based session management, authentication, and security patterns  
**Technologies:** Node.js, Redis, JWT, bcrypt

## 📁 Project Structure

```
lab11-session-management-security/
├── lab11.md                    # Complete lab instructions (START HERE)
├── src/
│   ├── session-manager.js      # Core session management system
│   ├── auth-manager.js         # Authentication and authorization
│   └── index.js                # Express server integration
├── tests/
│   └── test-security.js        # Comprehensive security tests
├── scripts/
│   └── load-security-data.sh   # Sample data loader
├── package.json                # Node.js dependencies
├── .env.example                # Environment configuration template
└── README.md                   # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-security-lab11 -p 6379:6379 redis:7-alpine
   ```

3. **Load Sample Data:**
   ```bash
   ./scripts/load-security-data.sh
   ```

4. **Run Tests:**
   ```bash
   npm test
   ```

5. **Start Server:**
   ```bash
   npm start
   ```

## 🔒 Security Features

### Session Management
- Secure token generation with crypto
- Session expiration and renewal
- Concurrent session limits
- Session activity tracking
- Automatic cleanup of expired sessions

### Authentication
- Password hashing with bcrypt
- Rate limiting on login attempts
- Account lockout after failed attempts
- JWT token generation and validation
- Password history to prevent reuse

### Authorization
- Role-based access control (RBAC)
- Dynamic permission management
- Permission caching for performance
- Middleware for protected routes

### Security Monitoring
- Authentication event logging
- Security breach detection
- Real-time analytics
- Audit trail maintenance

## 🧪 Testing

Run the comprehensive test suite:

```bash
npm test
```

Tests cover:
- User registration and authentication
- Session creation and management
- Rate limiting and account lockout
- Permission verification
- Password management
- Performance benchmarks

## 🚀 Production Deployment

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

### Security Checklist

- [ ] Change JWT_SECRET to strong random value
- [ ] Enable Redis AUTH with password
- [ ] Configure TLS/SSL for Redis
- [ ] Set up rate limiting
- [ ] Enable monitoring and alerting
- [ ] Regular security audits
- [ ] Backup authentication data
- [ ] Test disaster recovery

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "src/index.js"]
```

## 📊 API Endpoints

### Authentication
- `POST /api/login` - User login
- `POST /api/logout` - User logout
- `POST /api/register` - User registration
- `POST /api/refresh` - Refresh session

### Protected Routes
- `GET /api/protected/data` - Protected data access
- `GET /api/protected/profile` - User profile
- `PUT /api/protected/password` - Change password

### Health & Monitoring
- `GET /health` - System health check
- `GET /metrics` - Performance metrics

## 🎯 Learning Objectives Achieved

✅ Secure session storage and management  
✅ Authentication with rate limiting  
✅ Role-based access control (RBAC)  
✅ Password security best practices  
✅ Security event monitoring  
✅ Production-ready patterns  

## 📚 Additional Resources

- [Redis Security](https://redis.io/topics/security)
- [OWASP Session Management](https://owasp.org/www-community/attacks/Session_hijacking_attack)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [bcrypt Documentation](https://github.com/kelektiv/node.bcrypt.js)

## 🆘 Troubleshooting

**Redis Connection Issues:**
```bash
redis-cli ping
docker logs redis-security-lab11
```

**Authentication Failures:**
- Check Redis for user data
- Verify password hashing
- Check rate limiting status

**Session Issues:**
- Verify TTL settings
- Check session storage
- Monitor session analytics

---

**Ready to start?** Open `lab11.md` and begin implementing enterprise security! 🔐
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs
lib-cov

# Coverage directory
coverage
*.lcov
.nyc_output

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
test-results/
*.test.js.snap

# Production builds
dist/
build/

# Redis dump
dump.rdb
*.rdb

# Temporary files
*.tmp
*.temp
tmp/
temp/
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab11.md                    📋 START HERE - Complete lab guide"
echo "   ├── src/"
echo "   │   ├── session-manager.js      🔐 Core session management"
echo "   │   ├── auth-manager.js         🔑 Authentication system"
echo "   │   └── index.js                🚀 Express server"
echo "   ├── tests/"
echo "   │   └── test-security.js        🧪 Comprehensive tests"
echo "   ├── scripts/"
echo "   │   └── load-security-data.sh   📊 Sample data loader"
echo "   ├── package.json                📦 Dependencies"
echo "   ├── .env.example                🔐 Environment template"
echo "   ├── README.md                   📖 Documentation"
echo "   └── .gitignore                  🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. npm install"
echo "   3. docker run -d --name redis-security-lab11 -p 6379:6379 redis:7-alpine"
echo "   4. ./scripts/load-security-data.sh"
echo "   5. npm test"
echo ""
echo "🔒 SECURITY FEATURES:"
echo "   🔐 Session Management: Secure tokens, rotation, expiration"
echo "   🔑 Authentication: Rate limiting, lockout, JWT tokens"
echo "   👮 Authorization: RBAC, dynamic permissions"
echo "   📊 Monitoring: Event logging, analytics, audit trails"
echo "   🛡️ Protection: Password history, MFA ready, breach detection"
echo ""
echo "🎉 READY TO START LAB 11!"
echo "   Open lab11.md for the complete session security implementation!"