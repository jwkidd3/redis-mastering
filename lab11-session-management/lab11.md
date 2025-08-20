# Lab 11: Customer Portal Session Management

**Duration:** 45 minutes  
**Objective:** Implement Redis-based session management for customer portals with role-based access control and security monitoring

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement Redis-based session management for customer portals
- Configure session TTL and cleanup strategies
- Set up role-based access control (customer vs agent vs admin)
- Implement security monitoring for failed login attempts
- Create session analytics and monitoring dashboards
- Use Redis Insight to monitor active sessions in real-time

---

## Part 1: Environment Setup (5 minutes)

### Step 1: Verify Connection and Setup

```bash
# Test Redis connection with instructor-provided details
redis-cli -h [instructor-provided-host] -p 6379 PING

# Setup lab environment
./scripts/setup-lab.sh

# Update environment with Redis connection details
nano config/.env
```

### Step 2: Test Basic Connection

```bash
# Run basic tests
npm test
```

**Expected Output:**
- ✅ Session created successfully
- ✅ Session retrieved with correct data
- ✅ Session destruction working

---

## Part 2: Session Management Implementation (15 minutes)

### Step 3: Understanding Session Structure

Open Redis Insight and examine the session keys created during testing:

1. **Session Keys**: `portal:session:[uuid]` 
   - Contains user data, role, timestamps
   - Automatic TTL expiration

2. **Active Session Sets**: `active_sessions:[userId]`
   - Tracks all sessions for a user
   - Used for multi-device session management

### Step 4: Creating Customer Sessions

```javascript
// In Redis Insight command line or via examples/basic-session-demo.js
node examples/basic-session-demo.js
```

**Monitor in Redis Insight:**
1. Watch new keys appear in real-time
2. Examine hash structure of session data
3. Monitor TTL countdown

### Step 5: Session Security Features

```bash
# Test security monitoring
npm run test-security
```

**Observe:**
- Failed login attempt tracking
- Account lockout after max attempts
- Security event logging

---

## Part 3: Role-Based Access Control (10 minutes)

### Step 6: Understanding RBAC Implementation

```bash
# Test role-based permissions
npm run test-rbac
```

**Role Hierarchy:**
- **Customer**: Read own policies/claims, create claims
- **Agent**: Read customer data, process claims, create policies  
- **Admin**: Full access to all data and user management

### Step 7: Access Logging and Monitoring

```javascript
// View access logs in Redis Insight
LRANGE access_log:2024-08-20 0 -1
```

**Exercise:** Try these Redis Insight commands:

```redis
# View all active sessions
KEYS portal:session:*

# Check user's active sessions
SMEMBERS active_sessions:CUST001

# View security events
LRANGE security_log:2024-08-20 0 -1

# Check failed login attempts
GET login_attempts:testuser

# Check if account is locked
EXISTS account_lock:testuser
```

---

## Part 4: Real-Time Monitoring (10 minutes)

### Step 8: Session Monitoring Dashboard

```bash
# Start real-time session monitor
npm run monitor
```

**Monitor Features:**
- Active session count
- User distribution by role
- Memory usage tracking
- Security event summary

### Step 9: Session Analytics

Create custom queries in Redis Insight:

```redis
# Count sessions by role
EVAL "
local sessions = redis.call('KEYS', 'portal:session:*')
local roles = {}
for i=1,#sessions do
    local role = redis.call('HGET', sessions[i], 'userRole')
    if role then
        roles[role] = (roles[role] or 0) + 1
    end
end
return roles
" 0

# Find longest active sessions
EVAL "
local sessions = redis.call('KEYS', 'portal:session:*')
local longest = {}
for i=1,#sessions do
    local created = redis.call('HGET', sessions[i], 'createdAt')
    local userId = redis.call('HGET', sessions[i], 'userId')
    local ttl = redis.call('TTL', sessions[i])
    table.insert(longest, {sessions[i], created, userId, ttl})
end
return longest
" 0
```

---

## Part 5: Advanced Security Features (5 minutes)

### Step 10: Implementing Session Hijacking Protection

```javascript
// Test session security features
const session = await sessionManager.getSession(sessionId);

// Verify IP address hasn't changed
if (session.ipAddress !== currentIP) {
    // Log suspicious activity
    await security.logSecurityEvent('ip_change_detected', {
        sessionId,
        originalIP: session.ipAddress,
        newIP: currentIP
    });
}
```

### Step 11: Session Cleanup and Maintenance

```bash
# Run session cleanup
node scripts/cleanup-sessions.js
```

**Cleanup Process:**
- Removes expired sessions
- Cleans orphaned active session lists
- Archives old security logs
- Optimizes memory usage

---

## Practical Exercises

### Exercise 1: Multi-Device Session Management
1. Create multiple sessions for the same user
2. Monitor active sessions in Redis Insight
3. Implement selective session termination

### Exercise 2: Security Incident Response
1. Simulate multiple failed login attempts
2. Monitor account lockout in real-time
3. Analyze security event patterns

### Exercise 3: Performance Optimization
1. Monitor session creation/retrieval performance
2. Optimize Redis memory usage
3. Implement session compression for large payloads

---

## Redis Insight Commands Reference

```redis
# Session Management
HGETALL portal:session:[session-id]      # View session details
SMEMBERS active_sessions:[user-id]       # User's active sessions
TTL portal:session:[session-id]          # Check session expiration

# Security Monitoring
LRANGE security_log:YYYY-MM-DD 0 -1     # Daily security events
GET login_attempts:[user-id]             # Failed login count
EXISTS account_lock:[user-id]            # Check account lock status

# Access Control
LRANGE access_log:YYYY-MM-DD 0 -1       # Daily access attempts
KEYS portal:session:*                    # All active sessions

# Performance Monitoring
INFO memory                              # Redis memory usage
DBSIZE                                   # Total keys in database
CLIENT LIST                              # Connected clients
```

---

## Key Takeaways

1. **Session Security**: Always implement TTL and proper cleanup
2. **RBAC**: Define clear permission boundaries for different user types
3. **Monitoring**: Track security events and access patterns
4. **Performance**: Use Redis efficiently with proper key naming and expiration
5. **Multi-Device**: Handle multiple concurrent sessions per user
6. **Incident Response**: Implement automated security measures

---

## Troubleshooting

**Common Issues:**
- **Sessions not expiring**: Check TTL settings in configuration
- **Permission denied**: Verify role permissions in RBAC service
- **Memory usage high**: Run cleanup scripts regularly
- **Connection errors**: Verify Redis host configuration in .env

**Debug Commands:**
```bash
# Check configuration
cat config/.env

# Test Redis connection
redis-cli -h [host] -p 6379 PING

# View recent logs
node scripts/monitor-sessions.js
```

🎉 **Congratulations!** You've successfully implemented a complete session management system with Redis.
