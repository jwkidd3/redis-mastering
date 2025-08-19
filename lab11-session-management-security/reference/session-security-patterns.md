# Session Security Patterns Reference

## Session TTL Guidelines

### Customer Sessions
- **Web Portal**: 30 minutes (1800 seconds)
  - Reason: Higher security for web-based access
  - Pattern: `session:customer:{id}:web:{sessionId}`

- **Mobile App**: 2 hours (7200 seconds)
  - Reason: Better user experience on mobile
  - Pattern: `session:customer:{id}:mobile:{sessionId}`

### Agent Sessions
- **Workstation**: 8 hours (28800 seconds)
  - Reason: Full workday coverage
  - Pattern: `session:agent:{id}:workstation:{sessionId}`

- **Mobile/Field**: 4 hours (14400 seconds)
  - Reason: Field work sessions
  - Pattern: `session:agent:{id}:mobile:{sessionId}`

## Security Monitoring Patterns

### Failed Login Tracking
- **Key Pattern**: `security:failed_login:{userId}`
- **TTL**: 15 minutes (900 seconds)
- **Threshold**: 5 attempts trigger lockout

### Account Lockout
- **Key Pattern**: `security:lockout:{userId}`
- **TTL**: 15-30 minutes based on severity
- **Data**: Lockout reason and unlock instructions

### Audit Logging
- **Key Pattern**: `security:login:{userId}:{timestamp}`
- **TTL**: 7 days (604800 seconds)
- **Purpose**: Compliance and forensic analysis

## JWT Security Best Practices

1. **Secret Management**
   - Use environment variables
   - Rotate secrets regularly
   - Use strong, random keys

2. **Token Expiration**
   - Set appropriate expiration times
   - Implement refresh token patterns
   - Handle token renewal gracefully

3. **Payload Security**
   - Minimize sensitive data in JWT
   - Use session ID for Redis lookup
   - Validate all claims

## Role-Based Access Patterns

### Customer Permissions
- `view_own_policies`
- `view_own_claims`
- `submit_claim`
- `request_quote`
- `update_profile`

### Agent Permissions
- `view_customer_policies`
- `view_customer_claims`
- `process_claims`
- `create_quotes`
- `update_customer_profile`
- `view_agent_dashboard`

### Permission Checking
```javascript
// Check single permission
const hasAccess = await accessControl.hasPermission(token, 'view_customer_policies');

// Middleware for route protection
app.get('/api/customer/:id', 
  accessControl.requirePermission('view_customer_policies'),
  customerController.getCustomer
);
```

## Production Deployment Considerations

1. **High Availability**
   - Redis Sentinel for failover
   - Session replication across nodes
   - Load balancer session affinity

2. **Security Hardening**
   - SSL/TLS for Redis connections
   - Network security groups
   - Regular security audits

3. **Monitoring and Alerting**
   - Failed login rate monitoring
   - Session creation/destruction rates
   - Security incident alerting

4. **Compliance**
   - Session data encryption
   - Audit trail maintenance
   - Data retention policies
