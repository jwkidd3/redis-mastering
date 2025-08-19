# Lab 11: Customer Portal Session Management & Security

**Duration:** 45 minutes  
**Objective:** Implement secure session management for customer portal with JWT tokens and role-based access control

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement JWT-based session management for customer portals
- Configure session TTL for different security requirements
- Set up role-based access control (customer vs agent)
- Implement session cleanup and logout functionality
- Create basic security monitoring for failed login attempts
- Use Redis for secure session storage and management

---

## Part 1: Environment Setup (5 minutes)

### Step 1: Verify Connection and Setup

```bash
# Test Redis connection
redis-cli -h [instructor-provided-host] -p 6379 PING

# Clear any existing session data
redis-cli -h [instructor-provided-host] -p 6379 FLUSHALL

# Verify Node.js and npm
node --version
npm --version
```

### Step 2: Initialize Project

```bash
# Create project directory
mkdir customer-portal-sessions
cd customer-portal-sessions

# Initialize npm project
npm init -y

# Install required packages
npm install redis express jsonwebtoken bcrypt uuid dotenv cors helmet morgan
```

---

## Part 2: Basic JWT Session Implementation (15 minutes)

### Step 3: Create Session Management Service

Create `src/sessionManager.js`:

```javascript
const redis = require('redis');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

class SessionManager {
    constructor(redisHost, redisPort) {
        this.client = redis.createClient({
            host: redisHost,
            port: redisPort
        });
        this.JWT_SECRET = process.env.JWT_SECRET || 'portal-secret-key';
        this.connect();
    }

    async connect() {
        try {
            await this.client.connect();
            console.log('✅ Connected to Redis for session management');
        } catch (error) {
            console.error('❌ Redis connection failed:', error);
        }
    }

    // Generate JWT token with session info
    generateJWT(userId, userType, permissions = []) {
        const sessionId = uuidv4();
        const payload = {
            sessionId,
            userId,
            userType,
            permissions,
            loginTime: new Date().toISOString(),
            lastActivity: new Date().toISOString()
        };
        
        return {
            token: jwt.sign(payload, this.JWT_SECRET, { expiresIn: '8h' }),
            sessionId
        };
    }

    // Store session in Redis with appropriate TTL
    async createSession(userId, userType, deviceType = 'web') {
        const { token, sessionId } = this.generateJWT(userId, userType);
        
        // Different TTL based on user type and device
        let ttl;
        switch (userType) {
            case 'customer':
                ttl = deviceType === 'mobile' ? 7200 : 1800; // 2h mobile, 30min web
                break;
            case 'agent':
                ttl = deviceType === 'mobile' ? 14400 : 28800; // 4h mobile, 8h workstation
                break;
            default:
                ttl = 900; // 15 minutes default
        }

        const sessionKey = `session:${userType}:${userId}:${deviceType}:${sessionId}`;
        const sessionData = {
            userId,
            userType,
            deviceType,
            sessionId,
            createdAt: new Date().toISOString(),
            lastActivity: new Date().toISOString(),
            isActive: true
        };

        await this.client.setEx(sessionKey, ttl, JSON.stringify(sessionData));
        
        console.log(`🔐 Session created: ${sessionKey} (TTL: ${ttl}s)`);
        return { token, sessionId, ttl };
    }

    // Validate session and update activity
    async validateSession(token) {
        try {
            const decoded = jwt.verify(token, this.JWT_SECRET);
            const sessionKey = `session:${decoded.userType}:${decoded.userId}:*:${decoded.sessionId}`;
            
            // Find the actual key (since we used wildcard)
            const keys = await this.client.keys(sessionKey.replace('*', '*'));
            if (keys.length === 0) {
                return { valid: false, reason: 'Session not found' };
            }

            const sessionData = await this.client.get(keys[0]);
            if (!sessionData) {
                return { valid: false, reason: 'Session expired' };
            }

            const session = JSON.parse(sessionData);
            
            // Update last activity
            session.lastActivity = new Date().toISOString();
            const ttl = await this.client.ttl(keys[0]);
            await this.client.setEx(keys[0], ttl, JSON.stringify(session));

            return { 
                valid: true, 
                session: { ...decoded, ...session },
                remainingTTL: ttl
            };
        } catch (error) {
            return { valid: false, reason: error.message };
        }
    }

    // Logout and cleanup session
    async logout(token) {
        try {
            const decoded = jwt.verify(token, this.JWT_SECRET);
            const sessionKey = `session:${decoded.userType}:${decoded.userId}:*:${decoded.sessionId}`;
            
            const keys = await this.client.keys(sessionKey.replace('*', '*'));
            if (keys.length > 0) {
                await this.client.del(keys[0]);
                console.log(`🚪 Session logged out: ${keys[0]}`);
                return { success: true };
            }
            return { success: false, reason: 'Session not found' };
        } catch (error) {
            return { success: false, reason: error.message };
        }
    }
}

module.exports = SessionManager;
```

### Step 4: Test Basic Session Operations

Create `examples/basic-session-test.js`:

```javascript
const SessionManager = require('../src/sessionManager');

async function testBasicSessions() {
    console.log('🧪 Testing Basic Session Management...\n');
    
    const sessionMgr = new SessionManager('localhost', 6379); // Update with instructor host
    
    // Wait for connection
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    try {
        // Test customer session creation
        console.log('1. Creating customer sessions...');
        const customerSession = await sessionMgr.createSession('CUST001', 'customer', 'web');
        console.log(`   Customer Web Token: ${customerSession.token.substring(0, 50)}...`);
        console.log(`   Session ID: ${customerSession.sessionId}`);
        console.log(`   TTL: ${customerSession.ttl} seconds\n`);
        
        const customerMobile = await sessionMgr.createSession('CUST001', 'customer', 'mobile');
        console.log(`   Customer Mobile Token: ${customerMobile.token.substring(0, 50)}...`);
        console.log(`   TTL: ${customerMobile.ttl} seconds\n`);
        
        // Test agent session creation
        console.log('2. Creating agent sessions...');
        const agentSession = await sessionMgr.createSession('AG001', 'agent', 'workstation');
        console.log(`   Agent Token: ${agentSession.token.substring(0, 50)}...`);
        console.log(`   TTL: ${agentSession.ttl} seconds\n`);
        
        // Test session validation
        console.log('3. Validating sessions...');
        const validation = await sessionMgr.validateSession(customerSession.token);
        console.log(`   Customer session valid: ${validation.valid}`);
        if (validation.valid) {
            console.log(`   User: ${validation.session.userId} (${validation.session.userType})`);
            console.log(`   Remaining TTL: ${validation.remainingTTL} seconds\n`);
        }
        
        // Test logout
        console.log('4. Testing logout...');
        const logout = await sessionMgr.logout(customerSession.token);
        console.log(`   Logout successful: ${logout.success}\n`);
        
        // Test validation after logout
        const postLogoutValidation = await sessionMgr.validateSession(customerSession.token);
        console.log(`   Session valid after logout: ${postLogoutValidation.valid}`);
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

testBasicSessions();
```

**Run the test:**

```bash
node examples/basic-session-test.js
```

---

## Part 3: Role-Based Access Control (10 minutes)

### Step 5: Implement Role-Based Access

Create `src/accessControl.js`:

```javascript
const SessionManager = require('./sessionManager');

class AccessControl extends SessionManager {
    constructor(redisHost, redisPort) {
        super(redisHost, redisPort);
        
        // Define permissions for different roles
        this.rolePermissions = {
            customer: [
                'view_own_policies',
                'view_own_claims', 
                'submit_claim',
                'request_quote',
                'update_profile'
            ],
            agent: [
                'view_customer_policies',
                'view_customer_claims',
                'process_claims',
                'create_quotes',
                'update_customer_profile',
                'view_agent_dashboard'
            ],
            admin: [
                'view_all_data',
                'manage_users',
                'system_config',
                'generate_reports',
                'manage_agents'
            ]
        };
    }

    // Create session with role-based permissions
    async createRoleBasedSession(userId, userType, role, deviceType = 'web') {
        const permissions = this.rolePermissions[role] || [];
        const { token, sessionId } = this.generateJWT(userId, userType, permissions);
        
        let ttl;
        switch (userType) {
            case 'customer':
                ttl = deviceType === 'mobile' ? 7200 : 1800;
                break;
            case 'agent':
                ttl = deviceType === 'mobile' ? 14400 : 28800;
                break;
            case 'admin':
                ttl = 3600; // 1 hour for admin security
                break;
            default:
                ttl = 900;
        }

        const sessionKey = `session:${userType}:${userId}:${deviceType}:${sessionId}`;
        const sessionData = {
            userId,
            userType,
            role,
            permissions,
            deviceType,
            sessionId,
            createdAt: new Date().toISOString(),
            lastActivity: new Date().toISOString(),
            isActive: true
        };

        await this.client.setEx(sessionKey, ttl, JSON.stringify(sessionData));
        
        console.log(`🔐 Role-based session created: ${sessionKey}`);
        console.log(`   Role: ${role}`);
        console.log(`   Permissions: ${permissions.join(', ')}`);
        console.log(`   TTL: ${ttl}s`);
        
        return { token, sessionId, ttl, permissions };
    }

    // Check if user has specific permission
    async hasPermission(token, requiredPermission) {
        const validation = await this.validateSession(token);
        
        if (!validation.valid) {
            return { authorized: false, reason: validation.reason };
        }

        const hasPermission = validation.session.permissions?.includes(requiredPermission);
        
        return {
            authorized: hasPermission,
            userType: validation.session.userType,
            userId: validation.session.userId,
            permissions: validation.session.permissions
        };
    }

    // Middleware function for Express.js
    requirePermission(permission) {
        return async (req, res, next) => {
            const token = req.headers.authorization?.replace('Bearer ', '');
            
            if (!token) {
                return res.status(401).json({ error: 'No token provided' });
            }

            const authCheck = await this.hasPermission(token, permission);
            
            if (!authCheck.authorized) {
                return res.status(403).json({ 
                    error: 'Access denied', 
                    reason: authCheck.reason,
                    required: permission
                });
            }

            req.user = {
                userId: authCheck.userId,
                userType: authCheck.userType,
                permissions: authCheck.permissions
            };
            
            next();
        };
    }
}

module.exports = AccessControl;
```

### Step 6: Test Role-Based Access

Create `examples/rbac-test.js`:

```javascript
const AccessControl = require('../src/accessControl');

async function testRoleBasedAccess() {
    console.log('🧪 Testing Role-Based Access Control...\n');
    
    const ac = new AccessControl('localhost', 6379); // Update with instructor host
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    try {
        // Create sessions with different roles
        console.log('1. Creating role-based sessions...');
        
        const customerSession = await ac.createRoleBasedSession('CUST001', 'customer', 'customer', 'web');
        console.log();
        
        const agentSession = await ac.createRoleBasedSession('AG001', 'agent', 'agent', 'workstation');
        console.log();
        
        // Test permissions
        console.log('2. Testing customer permissions...');
        
        let permCheck = await ac.hasPermission(customerSession.token, 'view_own_policies');
        console.log(`   Customer can view own policies: ${permCheck.authorized}`);
        
        permCheck = await ac.hasPermission(customerSession.token, 'process_claims');
        console.log(`   Customer can process claims: ${permCheck.authorized}`);
        console.log();
        
        console.log('3. Testing agent permissions...');
        
        permCheck = await ac.hasPermission(agentSession.token, 'view_customer_policies');
        console.log(`   Agent can view customer policies: ${permCheck.authorized}`);
        
        permCheck = await ac.hasPermission(agentSession.token, 'process_claims');
        console.log(`   Agent can process claims: ${permCheck.authorized}`);
        
        permCheck = await ac.hasPermission(agentSession.token, 'view_own_policies');
        console.log(`   Agent can view own policies: ${permCheck.authorized}`);
        console.log();
        
        console.log('4. Permission details:');
        console.log(`   Customer permissions: ${customerSession.permissions.join(', ')}`);
        console.log(`   Agent permissions: ${agentSession.permissions.join(', ')}`);
        
    } catch (error) {
        console.error('❌ RBAC test failed:', error);
    }
}

testRoleBasedAccess();
```

**Run the test:**

```bash
node examples/rbac-test.js
```

---

## Part 4: Security Monitoring (10 minutes)

### Step 7: Implement Security Monitoring

Create `src/securityMonitor.js`:

```javascript
const redis = require('redis');

class SecurityMonitor {
    constructor(redisHost, redisPort) {
        this.client = redis.createClient({
            host: redisHost,
            port: redisPort
        });
        this.connect();
    }

    async connect() {
        try {
            await this.client.connect();
            console.log('✅ Security Monitor connected to Redis');
        } catch (error) {
            console.error('❌ Security Monitor Redis connection failed:', error);
        }
    }

    // Track failed login attempts
    async recordFailedLogin(userId, clientIP, reason) {
        const timestamp = new Date().toISOString();
        const failedLoginKey = `security:failed_login:${userId}`;
        
        // Get current failed attempts
        const currentData = await this.client.get(failedLoginKey);
        let failedAttempts = currentData ? JSON.parse(currentData) : { count: 0, attempts: [] };
        
        // Add new attempt
        failedAttempts.count += 1;
        failedAttempts.attempts.push({
            timestamp,
            clientIP,
            reason
        });
        
        // Keep only last 10 attempts
        if (failedAttempts.attempts.length > 10) {
            failedAttempts.attempts = failedAttempts.attempts.slice(-10);
        }
        
        // Set with 15-minute TTL (security lockout period)
        await this.client.setEx(failedLoginKey, 900, JSON.stringify(failedAttempts));
        
        console.log(`🚨 Failed login recorded for ${userId} (Count: ${failedAttempts.count})`);
        
        // Check if user should be locked out
        if (failedAttempts.count >= 5) {
            await this.lockoutUser(userId, '15 minutes');
            return { locked: true, attempts: failedAttempts.count };
        }
        
        return { locked: false, attempts: failedAttempts.count };
    }

    // Lock out user account
    async lockoutUser(userId, duration = '15 minutes') {
        const lockoutKey = `security:lockout:${userId}`;
        const lockoutData = {
            lockedAt: new Date().toISOString(),
            reason: 'Too many failed login attempts',
            duration,
            unlockInstructions: 'Contact support or wait for automatic unlock'
        };
        
        const ttl = duration === '15 minutes' ? 900 : 1800; // 15 or 30 minutes
        await this.client.setEx(lockoutKey, ttl, JSON.stringify(lockoutData));
        
        console.log(`🔒 User ${userId} locked out for ${duration}`);
    }

    // Check if user is locked out
    async isUserLockedOut(userId) {
        const lockoutKey = `security:lockout:${userId}`;
        const lockoutData = await this.client.get(lockoutKey);
        
        if (lockoutData) {
            const ttl = await this.client.ttl(lockoutKey);
            return { 
                locked: true, 
                data: JSON.parse(lockoutData),
                remainingTime: ttl
            };
        }
        
        return { locked: false };
    }

    // Record successful login (clear failed attempts)
    async recordSuccessfulLogin(userId, clientIP, deviceType) {
        // Clear failed login attempts
        const failedLoginKey = `security:failed_login:${userId}`;
        await this.client.del(failedLoginKey);
        
        // Record successful login for audit
        const loginKey = `security:login:${userId}:${Date.now()}`;
        const loginData = {
            timestamp: new Date().toISOString(),
            clientIP,
            deviceType,
            status: 'success'
        };
        
        // Keep login record for 7 days
        await this.client.setEx(loginKey, 604800, JSON.stringify(loginData));
        
        console.log(`✅ Successful login recorded for ${userId}`);
    }

    // Get security summary for user
    async getSecuritySummary(userId) {
        const failedKey = `security:failed_login:${userId}`;
        const lockoutKey = `security:lockout:${userId}`;
        
        const [failedData, lockoutData] = await Promise.all([
            this.client.get(failedKey),
            this.client.get(lockoutKey)
        ]);
        
        const summary = {
            userId,
            failedAttempts: failedData ? JSON.parse(failedData).count : 0,
            isLocked: !!lockoutData,
            lockoutData: lockoutData ? JSON.parse(lockoutData) : null
        };
        
        return summary;
    }
}

module.exports = SecurityMonitor;
```

### Step 8: Test Security Monitoring

Create `examples/security-test.js`:

```javascript
const SecurityMonitor = require('../src/securityMonitor');

async function testSecurityMonitoring() {
    console.log('🧪 Testing Security Monitoring...\n');
    
    const monitor = new SecurityMonitor('localhost', 6379); // Update with instructor host
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    try {
        const userId = 'CUST999';
        const clientIP = '192.168.1.100';
        
        console.log('1. Testing failed login tracking...');
        
        // Simulate failed login attempts
        for (let i = 1; i <= 3; i++) {
            const result = await monitor.recordFailedLogin(userId, clientIP, 'Invalid password');
            console.log(`   Attempt ${i}: Locked=${result.locked}, Count=${result.attempts}`);
        }
        console.log();
        
        console.log('2. Checking security status...');
        let summary = await monitor.getSecuritySummary(userId);
        console.log(`   Failed attempts: ${summary.failedAttempts}`);
        console.log(`   Is locked: ${summary.isLocked}`);
        console.log();
        
        console.log('3. Simulating more failed attempts (triggering lockout)...');
        for (let i = 4; i <= 6; i++) {
            const result = await monitor.recordFailedLogin(userId, clientIP, 'Invalid password');
            console.log(`   Attempt ${i}: Locked=${result.locked}, Count=${result.attempts}`);
        }
        console.log();
        
        console.log('4. Checking lockout status...');
        const lockoutStatus = await monitor.isUserLockedOut(userId);
        console.log(`   User locked: ${lockoutStatus.locked}`);
        if (lockoutStatus.locked) {
            console.log(`   Locked at: ${lockoutStatus.data.lockedAt}`);
            console.log(`   Remaining time: ${lockoutStatus.remainingTime} seconds`);
        }
        console.log();
        
        console.log('5. Simulating successful login...');
        await monitor.recordSuccessfulLogin(userId, clientIP, 'web');
        
        summary = await monitor.getSecuritySummary(userId);
        console.log(`   Failed attempts after success: ${summary.failedAttempts}`);
        
    } catch (error) {
        console.error('❌ Security test failed:', error);
    }
}

testSecurityMonitoring();
```

**Run the test:**

```bash
node examples/security-test.js
```

---

## Part 5: Integration and Redis Insight Monitoring (5 minutes)

### Step 9: Monitor Sessions in Redis Insight

1. **Open Redis Insight** and connect to your Redis server
2. **Navigate to Browser tab**
3. **Search for session keys:**
   - Pattern: `session:*`
   - Pattern: `security:*`
4. **Observe the key structure:**
   - Session data with TTL
   - Security monitoring data
   - Different TTL values based on user type

### Step 10: CLI Monitoring Commands

Use Redis CLI to monitor sessions:

```bash
# Connect to Redis
redis-cli -h [instructor-host] -p 6379

# View all session keys
KEYS session:*

# View all security keys  
KEYS security:*

# Check TTL on specific session
TTL session:customer:CUST001:web:*

# Monitor failed login attempts
GET security:failed_login:CUST999

# Check for locked accounts
KEYS security:lockout:*

# Real-time monitoring (in separate terminal)
MONITOR
```

---

## 🎯 Lab Summary

In this lab, you've implemented:

1. **JWT-based session management** with Redis storage
2. **Role-based access control** with configurable permissions
3. **Security monitoring** with failed login tracking and lockouts
4. **Session lifecycle management** with appropriate TTL values
5. **Real-time security monitoring** using Redis Insight and CLI

### Key Skills Developed:
- Customer portal session security patterns
- JWT token management with Redis
- Role-based access control implementation
- Security monitoring and threat detection
- Session cleanup and logout functionality

### Production Considerations:
- Use environment variables for sensitive configuration
- Implement proper JWT secret rotation
- Add rate limiting for login attempts
- Consider session replication for high availability
- Implement audit logging for compliance requirements

---

## 🔧 Troubleshooting

**Common Issues:**

1. **JWT verification fails**
   - Check JWT secret consistency
   - Verify token hasn't expired
   - Ensure proper token format

2. **Session not found**
   - Check TTL expiration
   - Verify session key pattern
   - Confirm Redis connection

3. **Permission denied**
   - Verify role configuration
   - Check permission assignments
   - Confirm session validation

**Next Steps:**
- Implement session refresh tokens
- Add multi-factor authentication
- Create admin dashboard for session monitoring
- Implement session analytics and reporting
