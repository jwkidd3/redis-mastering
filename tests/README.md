# Redis Mastering Course - Comprehensive Integration Test Suite

This directory contains comprehensive integration tests for all 15 labs across the 3-day Redis Mastering Course. These tests validate that all runnable code in every lab works correctly with the actual data used in the course.

## 📋 Table of Contents

- [Overview](#overview)
- [Test Coverage](#test-coverage)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running Tests](#running-tests)
- [Test Structure](#test-structure)
- [Test Results](#test-results)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)

## 🎯 Overview

The integration test suite provides:

- **Comprehensive Coverage**: Tests all 15 labs across 3 days
- **Real Data Testing**: Uses the actual insurance data from the course
- **Automated Validation**: Verifies all Redis operations, scripts, and integrations
- **Detailed Reporting**: Provides clear pass/fail status with detailed error messages
- **Flexible Execution**: Run all tests, specific days, or individual labs

### Test Statistics

- **Total Labs Tested**: 15
- **Total Test Cases**: 150+
- **Estimated Run Time**: 5-10 minutes (all tests)
- **Test Types**: CLI operations, JavaScript integration, production features

## 🧪 Test Coverage

### Day 1: CLI & Core Operations (Labs 1-5)

**Lab 1: Redis Environment & CLI Basics**
- Redis server connectivity
- Setup and test scripts execution
- Basic SET/GET commands
- CLI environment validation

**Lab 2: RESP Protocol**
- Simple string responses (PING)
- Integer responses (INCR)
- Bulk string responses (GET)
- Array responses (LRANGE)

**Lab 3: String Operations**
- Sample data loading
- SET/GET operations
- SETNX (set if not exists)
- INCR/DECR operations
- MGET/MSET bulk operations
- APPEND operations

**Lab 4: Key Management & TTL**
- Key pattern matching (KEYS)
- TTL operations (EXPIRE, TTL)
- SETEX operations
- EXISTS operations
- DEL operations
- PERSIST operations
- TYPE operations

**Lab 5: Advanced CLI Operations**
- Monitoring scripts validation
- INFO command
- DBSIZE command
- MEMORY USAGE command
- SCAN operations (production-safe)
- Pipeline operations

### Day 2: JavaScript Integration (Labs 6-10)

**Lab 6: JavaScript Redis Client Setup**
- Lab structure validation
- Redis client configuration
- Connection testing
- Basic JavaScript operations

**Lab 7: Customer Profiles & Hashes**
- HSET/HGETALL operations
- HGET single field retrieval
- HMGET multiple fields
- HINCRBY operations
- HEXISTS field checking
- HDEL field deletion
- HLEN field count
- HKEYS field listing
- HVALS value listing
- Customer service validation

**Lab 8: Claims Event Sourcing (Streams)**
- XADD stream operations
- XLEN stream length
- XRANGE message retrieval
- Multiple event types
- Consumer group creation (XGROUP CREATE)
- XREADGROUP operations
- Event producer/consumer validation

**Lab 9: Insurance Analytics (Sets & Sorted Sets)**
- SADD/SCARD set operations
- SISMEMBER membership checking
- SMEMBERS set listing
- SINTER set intersection
- SUNION set union
- SDIFF set difference
- ZADD/ZCARD sorted set operations
- ZRANGE ascending retrieval
- ZREVRANGE descending retrieval
- ZSCORE score retrieval
- ZRANGEBYSCORE range queries
- ZINCRBY score increment

**Lab 10: Advanced Caching Patterns**
- Cache-aside pattern (read/write)
- Cache invalidation
- Pattern-based invalidation
- TTL-based expiration
- Write-through cache pattern
- Performance test validation

### Day 3: Production & Advanced (Labs 11-15)

**Lab 11: Session Management & Security**
- Session storage
- Session TTL management
- Session invalidation
- Multiple active sessions
- RBAC permissions storage
- Failed login tracking
- Session renewal

**Lab 12: Rate Limiting & API Protection**
- Fixed window rate limiting
- Sliding window rate limiting
- Sliding window cleanup
- Token bucket algorithm
- IP-based rate limiting
- Endpoint-specific limits
- Rate limit exceeded tracking

**Lab 13: Production Configuration**
- Configuration files validation
- Data persistence
- CONFIG GET operations
- Connection pooling
- Maxmemory policy testing
- Backup script validation
- Slow log access

**Lab 14: Production Monitoring**
- Health check (PING)
- INFO metrics collection
- Memory metrics
- Stats metrics
- Client connections tracking
- Command statistics
- Keyspace statistics
- Custom metrics storage
- Time-series metrics

**Lab 15: Redis Cluster HA**
- Cluster configuration validation
- Cluster setup scripts
- Cluster connection testing
- Key distribution across cluster
- Cluster info commands
- Cluster nodes inspection
- Test script validation

## 📦 Prerequisites

### Required Software

1. **Node.js**: Version 18.0.0 or higher
   ```bash
   node --version  # Should be >= 18.0.0
   ```

2. **Redis**: Version 6.0 or higher
   ```bash
   redis-server --version  # Should be >= 6.0
   ```

3. **npm**: Version 8.0.0 or higher
   ```bash
   npm --version  # Should be >= 8.0.0
   ```

4. **Docker**: Required for Lab 15 cluster tests
   ```bash
   docker --version
   docker-compose --version
   ```

### Redis Server

Ensure Redis is running on `localhost:6379`:

**Option 1: Using Docker**
```bash
docker run -d -p 6379:6379 --name redis-test redis:latest
```

**Option 2: Using Local Redis**
```bash
redis-server
```

**Verify Connection**
```bash
redis-cli ping
# Should return: PONG
```

## 🚀 Installation

### 1. Install Root Dependencies

From the course root directory:

```bash
npm install
```

### 2. Run Test Setup Script

This will install dependencies for all labs and prepare the test environment:

```bash
npm run test:setup
```

Or manually:

```bash
bash tests/setup-test-environment.sh
```

The setup script will:
- Check prerequisites (Node.js, Redis, Docker)
- Verify Redis connection
- Install root dependencies
- Install dependencies for all labs with Node.js code
- Clean any existing test data
- Create test results directory

## 🎮 Running Tests

### Quick Start

```bash
# Run all tests (all 15 labs)
npm test

# Run Day 1 tests only (Labs 1-5)
npm run test:day1

# Run Day 2 tests only (Labs 6-10)
npm run test:day2

# Run Day 3 tests only (Labs 11-15)
npm run test:day3
```

### Advanced Options

```bash
# Run specific lab
node tests/run-all-tests.js --lab=7

# Run specific day with verbose output
node tests/run-all-tests.js --day=2 --verbose

# Run all tests without saving results
node tests/run-all-tests.js --no-save

# Show help
node tests/run-all-tests.js --help
```

### Individual Test Files

You can also run day-specific test files directly:

```bash
# Day 1 tests only
node tests/day1-labs-test.js

# Day 2 tests only
node tests/day2-labs-test.js

# Day 3 tests only
node tests/day3-labs-test.js
```

## 📁 Test Structure

```
tests/
├── README.md                    # This file
├── test-utils.js                # Shared test utilities and helpers
├── setup-test-environment.sh    # Setup script
├── cleanup-test-environment.sh  # Cleanup script
├── run-all-tests.js            # Main test runner
├── day1-labs-test.js           # Day 1 integration tests (Labs 1-5)
├── day2-labs-test.js           # Day 2 integration tests (Labs 6-10)
├── day3-labs-test.js           # Day 3 integration tests (Labs 11-15)
└── results/                    # Test results (JSON files)
    └── test-results-*.json     # Timestamped test results
```

### Test Utilities (`test-utils.js`)

The `TestUtils` class provides:

- Redis client initialization and management
- Redis server health checking
- Script execution (bash and Node.js)
- File existence checking
- Test result logging and formatting
- Docker container management
- Test summary generation

### Test Organization

Each day's test file contains:
- Individual test functions for each lab
- A main function to run all tests for that day
- Detailed test logging with pass/fail status
- Error handling and reporting

## 📊 Test Results

### Console Output

Tests provide real-time console output with:
- ✓ Green checkmarks for passed tests
- ✗ Red X marks for failed tests
- Detailed error messages for failures
- Summary statistics

Example output:
```
================================================================================
Lab 7: Customer Profiles & Hashes
================================================================================
  ✓ Lab directory exists
  ✓ HSET/HGETALL operations
  ✓ HGET operation
  ✓ HMGET operation
  ✓ HINCRBY operation
  ✓ HEXISTS operation
  ✓ HDEL operation
  ✓ HLEN operation
  ✓ HKEYS operation
  ✓ HVALS operation
  ✓ Customer service file exists
```

### JSON Results

Test results are automatically saved to `tests/results/` with timestamps:

```json
{
  "total": 150,
  "passed": 145,
  "failed": 5,
  "percentage": "96.67",
  "results": [
    {
      "lab": "Lab 7",
      "test": "HSET/HGETALL operations",
      "passed": true,
      "message": "",
      "timestamp": "2025-10-26T10:30:00.000Z"
    }
  ]
}
```

### Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed or error occurred

This makes the test suite CI/CD friendly.

## 🔧 Troubleshooting

### Common Issues

**1. Redis Connection Refused**
```
Error: Redis is not running on localhost:6379
```
**Solution**: Start Redis server
```bash
docker run -d -p 6379:6379 redis:latest
# or
redis-server
```

**2. Lab Dependencies Not Installed**
```
Error: Cannot find module 'redis'
```
**Solution**: Run setup script
```bash
npm run test:setup
```

**3. Permission Denied on Scripts**
```
Error: Permission denied: ./setup-lab.sh
```
**Solution**: Make scripts executable
```bash
chmod +x tests/*.sh
find . -name "*.sh" -type f -exec chmod +x {} \;
```

**4. Docker Not Running (Lab 15)**
```
Error: Cannot connect to Docker daemon
```
**Solution**: Start Docker Desktop or Docker service
```bash
# macOS/Windows: Start Docker Desktop
# Linux:
sudo systemctl start docker
```

**5. Port Already in Use**
```
Error: Address already in use :::6379
```
**Solution**: Stop existing Redis instance
```bash
docker stop $(docker ps -q --filter ancestor=redis)
# or
pkill redis-server
```

**6. Test Timeout**
```
Error: Script execution timed out
```
**Solution**: Check if Redis is responsive
```bash
redis-cli ping
redis-cli INFO
```

### Debug Mode

Enable verbose output for detailed debugging:
```bash
node tests/run-all-tests.js --verbose
```

### Manual Verification

Test individual Redis operations:
```bash
redis-cli
> PING
> SET test:key "test value"
> GET test:key
> DEL test:key
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      redis:
        image: redis:latest
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm run test:setup

      - name: Run integration tests
        run: npm test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: tests/results/
```

### GitLab CI Example

```yaml
test:
  image: node:18
  services:
    - redis:latest
  variables:
    REDIS_HOST: redis
    REDIS_PORT: 6379
  before_script:
    - npm run test:setup
  script:
    - npm test
  artifacts:
    when: always
    paths:
      - tests/results/
    reports:
      junit: tests/results/*.xml
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh 'docker run -d -p 6379:6379 redis:latest'
                sh 'npm run test:setup'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'tests/results/*.json'
            junit 'tests/results/*.xml'
        }
    }
}
```

## 🧹 Cleanup

After running tests, clean up the test environment:

```bash
npm run test:cleanup
```

Or manually:
```bash
bash tests/cleanup-test-environment.sh
```

This will:
- Flush all Redis databases
- Stop Docker containers used in tests
- Clean temporary test data

## 📝 Writing New Tests

To add tests for new labs:

1. Choose the appropriate day test file
2. Add a new test function:
```javascript
async function testLabX() {
    testUtils.logLabHeader(X, 'Lab Name');

    let passed = 0;
    let failed = 0;

    try {
        await testUtils.initRedisClient();

        // Your test code here

    } catch (error) {
        testUtils.logTest('Lab X', 'Lab execution', false, error.message);
        failed++;
    } finally {
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}
```

3. Add the test to the day's run function
4. Update the test runner if needed

## 📚 Additional Resources

- [Redis Documentation](https://redis.io/docs/)
- [Node Redis Client](https://github.com/redis/node-redis)
- [ioredis Client](https://github.com/luin/ioredis)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)

## 🤝 Contributing

When adding new labs or tests:

1. Follow the existing test structure
2. Use descriptive test names
3. Add proper error handling
4. Update this README
5. Test locally before committing

## 📄 License

MIT License - See course root for details

---

**Created for**: Redis Mastering Course (3-Day Intensive)
**Test Suite Version**: 1.0.0
**Last Updated**: October 2025
**Maintained by**: Redis Training Lab Team
