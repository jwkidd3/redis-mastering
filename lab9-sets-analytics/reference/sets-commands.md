# Redis Sets and Sorted Sets Reference

## Set Commands

### Basic Set Operations
```bash
# Add members to set
SADD key member1 [member2 ...]

# Get all members
SMEMBERS key

# Check if member exists
SISMEMBER key member

# Remove members
SREM key member1 [member2 ...]

# Get set size
SCARD key

# Remove and return random member
SPOP key [count]

# Get random member without removing
SRANDMEMBER key [count]
```

### Set Operations
```bash
# Intersection of sets
SINTER key1 key2 [key3 ...]

# Union of sets
SUNION key1 key2 [key3 ...]

# Difference of sets
SDIFF key1 key2 [key3 ...]

# Store intersection result
SINTERSTORE destination key1 key2 [key3 ...]

# Store union result
SUNIONSTORE destination key1 key2 [key3 ...]

# Store difference result
SDIFFSTORE destination key1 key2 [key3 ...]
```

## Sorted Set Commands

### Basic Sorted Set Operations
```bash
# Add members with scores
ZADD key score1 member1 [score2 member2 ...]

# Get members by rank (ascending)
ZRANGE key start stop [WITHSCORES]

# Get members by rank (descending)
ZREVRANGE key start stop [WITHSCORES]

# Get members by score range
ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]

# Get members by score range (descending)
ZREVRANGEBYSCORE key max min [WITHSCORES] [LIMIT offset count]

# Get member score
ZSCORE key member

# Get member rank (0-based, ascending)
ZRANK key member

# Get member rank (0-based, descending)
ZREVRANK key member

# Remove members
ZREM key member1 [member2 ...]

# Remove members by rank range
ZREMRANGEBYRANK key start stop

# Remove members by score range
ZREMRANGEBYSCORE key min max

# Get sorted set size
ZCARD key

# Count members in score range
ZCOUNT key min max

# Increment member score
ZINCRBY key increment member
```

### Advanced Sorted Set Operations
```bash
# Intersection with weights
ZINTERSTORE destination numkeys key1 [key2 ...] [WEIGHTS weight1 [weight2 ...]] [AGGREGATE SUM|MIN|MAX]

# Union with weights
ZUNIONSTORE destination numkeys key1 [key2 ...] [WEIGHTS weight1 [weight2 ...]] [AGGREGATE SUM|MIN|MAX]

# Lexicographical range (when all scores are same)
ZRANGEBYLEX key min max [LIMIT offset count]
ZREVRANGEBYLEX key max min [LIMIT offset count]
ZREMRANGEBYLEX key min max
ZLEXCOUNT key min max
```

## JavaScript Redis Client Examples

### Sets with Node.js
```javascript
const redis = require('redis');
const client = redis.createClient();

// Add to set
await client.sadd('users:active', 'user1', 'user2', 'user3');

// Check membership
const isMember = await client.sismember('users:active', 'user1');

// Get all members
const members = await client.smembers('users:active');

// Set operations
const intersection = await client.sinter('users:active', 'users:premium');
const union = await client.sunion('users:active', 'users:premium');
const difference = await client.sdiff('users:active', 'users:premium');

// Store operation result
await client.sinterstore('users:active_premium', 'users:active', 'users:premium');
```

### Sorted Sets with Node.js
```javascript
// Add with scores
await client.zadd('leaderboard', 100, 'player1', 200, 'player2', 150, 'player3');

// Get top 10 players
const top10 = await client.zrevrange('leaderboard', 0, 9, 'WITHSCORES');

// Get players in score range
const midRange = await client.zrangebyscore('leaderboard', 100, 200, 'WITHSCORES');

// Get player rank and score
const rank = await client.zrevrank('leaderboard', 'player1');
const score = await client.zscore('leaderboard', 'player1');

// Increment score
const newScore = await client.zincrby('leaderboard', 10, 'player1');

// Get leaderboard statistics
const total = await client.zcard('leaderboard');
const count = await client.zcount('leaderboard', 100, 200);
```

## Analytics Use Cases

### Customer Segmentation
```javascript
// Create customer segments
await client.sadd('customers:premium', 'cust1', 'cust2');
await client.sadd('customers:active', 'cust1', 'cust3');
await client.sadd('customers:new', 'cust4', 'cust5');

// Find premium active customers
const premiumActive = await client.sinter('customers:premium', 'customers:active');

// Store frequently used intersection
await client.sinterstore('customers:premium_active', 'customers:premium', 'customers:active');
await client.expire('customers:premium_active', 3600); // Cache for 1 hour
```

### Performance Tracking
```javascript
// Agent performance leaderboard
await client.zadd('agents:sales', 15000, 'agent1', 12000, 'agent2', 18000, 'agent3');

// Get top 5 performers
const topAgents = await client.zrevrange('agents:sales', 0, 4, 'WITHSCORES');

// Get agents in performance range
const midPerformers = await client.zrangebyscore('agents:sales', 10000, 15000, 'WITHSCORES');

// Update performance scores
await client.zincrby('agents:sales', 500, 'agent1'); // Add $500 to agent1's sales
```

### Risk Analysis
```javascript
// Risk scoring system
await client.zadd('risk_scores', 250, 'cust1', 450, 'cust2', 750, 'cust3');

// Get high-risk customers (score > 600)
const highRisk = await client.zrangebyscore('risk_scores', 600, 1000, 'WITHSCORES');

// Get customer risk rank
const riskRank = await client.zrevrank('risk_scores', 'cust1');

// Count customers in risk ranges
const lowRiskCount = await client.zcount('risk_scores', 0, 300);
const mediumRiskCount = await client.zcount('risk_scores', 301, 600);
const highRiskCount = await client.zcount('risk_scores', 601, 1000);
```

## Performance Tips

### Memory Optimization
- Use appropriate data types for your use case
- Set TTL on temporary analytics results
- Use pipelining for bulk operations
- Consider using SCAN instead of KEYS for large datasets

### Query Optimization
- Store frequently used set operation results
- Use LIMIT with range queries for pagination
- Consider using smaller score ranges for better performance
- Use ZREVRANGE instead of ZRANGE + sorting when possible

### Monitoring
- Monitor memory usage with MEMORY USAGE command
- Use INFO memory to track overall memory consumption
- Monitor slow queries with SLOWLOG
- Track key expiration with TTL commands
EOF 
