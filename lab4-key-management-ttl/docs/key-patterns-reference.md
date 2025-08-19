# Key Patterns Reference Guide - Remote Host Edition

## Remote Connection Setup

### Environment Variables
```bash
export REDIS_HOST="your-redis-host.com"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""  # if required
```

### Connection Commands
```bash
# Basic connection
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# With authentication
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD

# Test connection
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping
```

## Standard Hierarchical Patterns

### Policy Keys
```
policy:{type}:{number}:{attribute}

Examples:
- policy:auto:100001:details
- policy:auto:100001:customer  
- policy:auto:100001:status
- policy:auto:100001:premium
- policy:home:200001:coverage
- policy:life:300001:beneficiary
```

### Customer Keys
```
customer:{id}:{attribute}

Examples:
- customer:CUST001:name
- customer:CUST001:email
- customer:CUST001:phone
- customer:CUST001:tier
- customer:CUST001:agent
- customer:CUST001:join_date
```

### Claims Keys
```
claim:{id}:{attribute}

Examples:
- claim:CL001:policy
- claim:CL001:customer
- claim:CL001:amount
- claim:CL001:status
- claim:CL001:adjuster
- claim:CL001:description
```

### Agent Keys
```
agent:{id}:{attribute}

Examples:
- agent:AG001:name
- agent:AG001:territory
- agent:AG001:specialty
- agent:AG001:customers_count
```

## TTL-Based Patterns

### Quote Management
```
quote:{type}:{id}

TTL Guidelines:
- Auto quotes: 300 seconds (5 minutes)
- Home quotes: 600 seconds (10 minutes)  
- Life quotes: 1800 seconds (30 minutes)

Examples:
SETEX quote:auto:Q001 300 "quote_data"
SETEX quote:home:H001 600 "quote_data"
SETEX quote:life:L001 1800 "quote_data"
```

### Session Management
```
session:{type}:{id}:{device}

TTL Guidelines:
- Customer portal: 1800 seconds (30 minutes)
- Customer mobile: 7200 seconds (2 hours)
- Agent workstation: 28800 seconds (8 hours)
- Agent mobile: 14400 seconds (4 hours)

Examples:
SETEX session:customer:CUST001:portal 1800 "session_data"
SETEX session:agent:AG001:workstation 28800 "session_data"
```

### Temporal Data
```
metrics:daily:{date}:{metric}
report:weekly:{week}:{type}
analytics:monthly:{month}:{metric}

TTL Guidelines:
- Daily metrics: 86400 seconds (24 hours)
- Weekly reports: 604800 seconds (7 days)
- Monthly analytics: 2592000 seconds (30 days)

Examples:
SETEX metrics:daily:2024-01-15:quotes_generated 86400 "47"
SETEX report:weekly:2024-W03:sales_summary 604800 "summary_data"
SETEX analytics:monthly:2024-01:conversion_rate 2592000 "12.5%"
```

### Security Features
```
security:{feature}:{id}

TTL Guidelines:
- Failed logins: 900 seconds (15 minutes)
- Password resets: 600 seconds (10 minutes)
- Account lockouts: 1800 seconds (30 minutes)
- 2FA codes: 300 seconds (5 minutes)

Examples:
SETEX security:failed_login:CUST001 900 "attempt_count:3"
SETEX security:password_reset:CUST002:token_xyz789 600 "reset_pending"
SETEX security:lockout:CUST003 1800 "locked_too_many_attempts"
SETEX security:2fa:CUST001:code_123456 300 "pending_verification"
```

### Cache Patterns
```
cache:{entity}:{id}:{type}

TTL Guidelines:
- Customer profiles: 3600 seconds (1 hour)
- Policy summaries: 1800 seconds (30 minutes)
- Agent dashboards: 900 seconds (15 minutes)

Examples:
SETEX cache:customer:CUST001:profile 3600 "profile_json"
SETEX cache:policy:auto:100001:summary 1800 "summary_json"
SETEX cache:agent:AG001:dashboard 900 "dashboard_json"
```

## Remote Host Commands

### TTL Management
```bash
redis-cli -h $REDIS_HOST -p $REDIS_PORT SETEX key seconds value
redis-cli -h $REDIS_HOST -p $REDIS_PORT TTL key
redis-cli -h $REDIS_HOST -p $REDIS_PORT EXPIRE key seconds
redis-cli -h $REDIS_HOST -p $REDIS_PORT PERSIST key
```

### Key Discovery
```bash
redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS pattern
redis-cli -h $REDIS_HOST -p $REDIS_PORT SCAN cursor MATCH pattern COUNT count
redis-cli -h $REDIS_HOST -p $REDIS_PORT EXISTS key
redis-cli -h $REDIS_HOST -p $REDIS_PORT TYPE key
```

### Monitoring
```bash
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO keyspace
redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG SET notify-keyspace-events Ex
```

### Performance Analysis
```bash
redis-cli -h $REDIS_HOST -p $REDIS_PORT --latency-history
redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG GET 10
redis-cli -h $REDIS_HOST -p $REDIS_PORT CLIENT LIST
redis-cli -h $REDIS_HOST -p $REDIS_PORT MONITOR
```

## Best Practices for Remote Hosts

### Connection Management
1. **Use environment variables** for host configuration
2. **Test connectivity** before running scripts
3. **Handle authentication** properly if required
4. **Consider connection pooling** for frequent operations
5. **Monitor network latency** between client and remote host

### Security Considerations
1. **Use secure connections** (SSL/TLS) when available
2. **Store passwords securely** (not in scripts)
3. **Limit network access** to Redis port
4. **Monitor connection attempts** and failed authentications
5. **Use firewall rules** to restrict access

### Performance Optimization
1. **Use pipelining** for batch operations
2. **Monitor network latency** with --latency flag
3. **Batch commands** when possible to reduce round trips
4. **Use SCAN instead of KEYS** for large datasets
5. **Monitor memory usage** on remote host

### Production Deployment
1. **Use connection strings** for different environments
2. **Implement retry logic** for network failures
3. **Monitor connection health** continuously
4. **Set appropriate timeouts** for operations
5. **Log connection events** for troubleshooting
