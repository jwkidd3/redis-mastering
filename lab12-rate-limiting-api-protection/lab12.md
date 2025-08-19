# Lab 12: Rate Limiting & API Protection for API Services

**Duration:** 45 minutes  
**Objective:** Implement comprehensive rate limiting and API protection for API services using Redis

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement token bucket rate limiting using Redis sorted sets
- Create customer-tier based rate limiting strategies
- Build endpoint-specific rate limits for different API operations  
- Detect and prevent abuse patterns
- Monitor rate limiting effectiveness in production
- Integrate rate limiting middleware with Express.js applications

---

## Part 1: Environment Setup (5 minutes)

### Step 1: Initialize the Project

```bash
# Navigate to lab directory
cd lab12-rate-limiting-api-protection

# Install dependencies
npm install

# Create .env file with your Redis connection details
cp .env.example .env
# Edit .env with your Redis host information
```

### Step 2: Configure Redis Connection

Update `.env` file with your Redis server details:

```env
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=

PORT=3000
NODE_ENV=development
```

### Step 3: Test Redis Connection

```bash
# Test Redis connectivity
node -e "
const redisClient = require('./config/redis');
redisClient.connect().then(() => {
    console.log('✅ Redis connected successfully');
    process.exit(0);
}).catch(err => {
    console.error('❌ Redis connection failed:', err.message);
    process.exit(1);
});
"
```

---

## Part 2: Understanding Rate Limiting Algorithms (10 minutes)

### Step 1: Examine Token Bucket Implementation

Open `src/services/rateLimitService.js` and review the token bucket algorithm:

```javascript
// Key concepts in the implementation:
// 1. Use Redis sorted sets to store request timestamps
// 2. Remove old requests outside the time window
// 3. Count current requests in window
// 4. Allow or deny based on limit
// 5. Set expiration to prevent memory leaks
```

### Step 2: Understand Customer Tier-Based Limiting

Review the tier-based limits in the service:

```javascript
const limits = {
    'premium': 500,    // Premium customers get higher limits
    'standard': 100,   // Standard tier
    'basic': 50,       // Basic tier
    'trial': 20        // Trial users are most restricted
};
```

### Step 3: Examine Endpoint-Specific Limits

Look at how different API endpoints have different limits:

```javascript
const endpointLimits = {
    '/api/quotes': 50,     // Quote generation is expensive
    '/api/policies': 100,  // Policy operations
    '/api/claims': 75,     // Claims processing
    '/api/payments': 25,   // Payment processing is heavily limited
    '/api/reports': 10     // Resource-intensive reports
};
```

---

## Part 3: Running the Rate-Limited API Server (10 minutes)

### Step 1: Start the API Server

```bash
# Start the server
npm start
```

You should see:
```
✅ Server initialized successfully
🚀 Server running on port 3000
🛡️ Rate limiting active on all API endpoints
```

### Step 2: Test Health Check Endpoint

```bash
# Test the health endpoint (no rate limiting)
curl http://localhost:3000/health
```

### Step 3: Test Basic Rate Limiting

```bash
# Make a quote request
curl -X POST http://localhost:3000/api/quotes/auto \
  -H "Content-Type: application/json" \
  -H "X-Customer-ID: CUST001" \
  -H "X-Customer-Tier: standard" \
  -d '{
    "customerId": "CUST001",
    "vehicleInfo": {
      "year": 2020,
      "make": "Toyota",
      "model": "Camry"
    },
    "coverage": "full"
  }'
```

Look for rate limit headers in the response:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1640995200
X-RateLimit-Type: customer
```

---

## Part 4: Testing Rate Limiting Scenarios (15 minutes)

### Step 1: Test Customer Rate Limiting

```bash
# Run the automated rate limit test
npm run test
```

This will:
- Make multiple requests up to the customer limit
- Show which requests succeed vs. get rate limited
- Display timing and behavior patterns

### Step 2: Test Different Customer Tiers

```bash
# Test premium customer (higher limits)
curl -X POST http://localhost:3000/api/quotes/auto \
  -H "X-Customer-ID: PREMIUM001" \
  -H "X-Customer-Tier: premium" \
  -d '{"customerId": "PREMIUM001", "vehicleInfo": {"year": 2023, "make": "BMW"}, "coverage": "full"}'

# Test basic customer (lower limits)  
curl -X POST http://localhost:3000/api/quotes/auto \
  -H "X-Customer-ID: BASIC001" \
  -H "X-Customer-Tier: basic" \
  -d '{"customerId": "BASIC001", "vehicleInfo": {"year": 2018, "make": "Honda"}, "coverage": "basic"}'
```

### Step 3: Test Endpoint-Specific Rate Limits

```bash
# Test life quotes (most restrictive - 3 per minute)
for i in {1..5}; do
  echo "Request $i:"
  curl -X POST http://localhost:3000/api/quotes/life \
    -H "X-Customer-ID: CUST_TEST_$i" \
    -H "X-Customer-Tier: standard" \
    -d '{"customerId": "CUST_TEST_'$i'", "personalInfo": {"age": 35}, "coverage": "250000"}' \
    -w "\nStatus: %{http_code}\n\n"
  sleep 1
done
```

### Step 4: Test Load Performance

```bash
# Run load test to see rate limiting under pressure
npm run load-test

# Or run with custom parameters
node examples/load-test.js --concurrency 5 --duration 15 --endpoint /quotes/auto
```

---

## Part 5: Monitoring and Administration (5 minutes)

### Step 1: Monitor Rate Limits

```bash
# Monitor current rate limit status
npm run monitor
```

### Step 2: Check Rate Limit Status via API

```bash
# Get rate limit status for a customer
curl -H "X-API-Key: test_api_key_12345" \
     -H "X-Customer-ID: CUST001" \
     http://localhost:3000/api/rate-limit/status
```

### Step 3: Admin Functions

```bash
# Reset rate limits for a customer (admin only)
curl -X POST http://localhost:3000/api/admin/rate-limits/reset \
  -H "X-Admin-Key: admin_key_12345" \
  -H "Content-Type: application/json" \
  -d '{"customerId": "CUST001", "bucketType": "customer"}'

# Get rate limit statistics
curl -H "X-Admin-Key: admin_key_12345" \
     http://localhost:3000/api/admin/rate-limits/stats

# Check suspicious activity
curl -H "X-Admin-Key: admin_key_12345" \
     http://localhost:3000/api/admin/security/suspicious
```

### Step 4: Redis Insight Monitoring

1. Open **Redis Insight**
2. Connect to your Redis server
3. Navigate to **CLI** tab
4. Run these commands to inspect rate limiting data:

```redis
# View all rate limit keys
KEYS rate_limit:*

# Check specific customer's rate limit data
ZRANGE rate_limit:customer:CUST001 0 -1 WITHSCORES

# View rate limit violations
KEYS violations:*

# Check suspicious activity markers
KEYS suspicious:*

# Monitor memory usage of rate limiting keys
MEMORY USAGE rate_limit:customer:CUST001
```

---

## Part 6: Understanding Abuse Detection (Optional - if time permits)

### Step 1: Trigger Abuse Detection

Create a script to trigger abuse detection:

```bash
# Create a test script to trigger multiple violations
cat > test-abuse.sh << 'EOF'
#!/bin/bash
echo "🚨 Testing abuse detection..."

# Make many requests quickly to trigger violations
for i in {1..20}; do
  curl -X POST http://localhost:3000/api/quotes/life \
    -H "X-Customer-ID: ABUSIVE_CUSTOMER" \
    -H "X-Customer-Tier: trial" \
    -d '{"customerId": "ABUSIVE_CUSTOMER", "personalInfo": {"age": 35}, "coverage": "100000"}' \
    -s -o /dev/null -w "Request $i: %{http_code}\n"
  sleep 0.1
done
