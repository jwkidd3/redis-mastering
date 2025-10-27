# Redis Mastering Course - Testing Guide

## 🎯 Overview

This document describes the comprehensive integration testing strategy for the Redis Mastering Course. The test suite validates all 15 labs across 3 days, ensuring that every piece of runnable code works correctly with the actual course data.

## 📊 Test Suite Summary

| Metric | Value |
|--------|-------|
| **Total Labs** | 15 |
| **Total Test Cases** | 150+ |
| **Test Coverage** | 100% of runnable code |
| **Estimated Runtime** | 5-10 minutes |
| **Success Criteria** | All tests must pass |

## 🏗️ Architecture

### Test Organization

```
redis-mastering/
├── tests/
│   ├── README.md                    # Detailed test documentation
│   ├── test-utils.js                # Shared testing utilities
│   ├── run-all-tests.js            # Main orchestrator
│   ├── day1-labs-test.js           # Day 1 tests (Labs 1-5)
│   ├── day2-labs-test.js           # Day 2 tests (Labs 6-10)
│   ├── day3-labs-test.js           # Day 3 tests (Labs 11-15)
│   ├── setup-test-environment.sh    # Environment setup
│   ├── cleanup-test-environment.sh  # Cleanup script
│   └── results/                    # Test results storage
├── package.json                     # Root dependencies & scripts
└── TESTING.md                       # This file
```

### Test Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Test Runner (run-all-tests.js)            │
└───────────────┬─────────────────────────────────────────────┘
                │
                ├──────────────┬──────────────┬──────────────┐
                │              │              │              │
         ┌──────▼──────┐┌─────▼──────┐┌──────▼──────┐      │
         │  Day 1 Tests ││ Day 2 Tests││ Day 3 Tests │      │
         │  (Labs 1-5)  ││ (Labs 6-10)││ (Labs 11-15)│      │
         └──────┬───────┘└─────┬──────┘└──────┬──────┘      │
                │              │              │              │
         ┌──────▼──────────────▼──────────────▼──────┐      │
         │           Test Utils (test-utils.js)       │      │
         │   - Redis client management                │      │
         │   - Script execution                       │      │
         │   - Result logging                         │      │
         │   - Docker management                      │      │
         └──────┬─────────────────────────────────────┘      │
                │                                             │
         ┌──────▼─────────────────────────────────────┐      │
         │         Redis Server (localhost:6379)       │      │
         └────────────────────────────────────────────┘      │
                                                              │
         ┌────────────────────────────────────────────────────▼─┐
         │              Test Results & Reports                   │
         │  - Console output with colors                         │
         │  - JSON results files                                 │
         │  - Exit codes for CI/CD                               │
         └───────────────────────────────────────────────────────┘
```

## 🧪 Test Categories

### 1. Day 1: CLI & Core Operations

**Focus**: Command-line interface and fundamental Redis operations

- **Lab 1**: Environment setup and basic connectivity
- **Lab 2**: RESP protocol validation
- **Lab 3**: String data type operations
- **Lab 4**: Key management and expiration
- **Lab 5**: Advanced CLI features and monitoring

**Technologies Tested**:
- redis-cli commands
- Bash scripts
- Basic Redis data types
- TTL and expiration
- Monitoring commands

### 2. Day 2: JavaScript Integration

**Focus**: Node.js integration and advanced data structures

- **Lab 6**: JavaScript Redis client setup
- **Lab 7**: Hash operations for customer profiles
- **Lab 8**: Streams for event sourcing
- **Lab 9**: Sets and Sorted Sets for analytics
- **Lab 10**: Advanced caching patterns

**Technologies Tested**:
- Node.js redis client
- Hashes
- Streams with consumer groups
- Sets and Sorted Sets
- Caching strategies

### 3. Day 3: Production & Advanced

**Focus**: Production-ready features and clustering

- **Lab 11**: Session management and security
- **Lab 12**: Rate limiting and API protection
- **Lab 13**: Production configuration
- **Lab 14**: Monitoring and metrics
- **Lab 15**: Redis cluster high availability

**Technologies Tested**:
- Session storage
- Rate limiting algorithms
- Redis configuration
- Monitoring and metrics
- Redis Cluster
- Docker Compose

## 🚀 Quick Start

### Prerequisites Check

```bash
# Check Node.js version (need 18+)
node --version

# Check Redis availability
redis-cli ping

# Check Docker (for Lab 15)
docker --version
```

### Installation

```bash
# 1. Install all dependencies
npm install

# 2. Setup test environment
npm run test:setup
```

### Running Tests

```bash
# Run all tests
npm test

# Run specific day
npm run test:day1
npm run test:day2
npm run test:day3

# Run specific lab
node tests/run-all-tests.js --lab=7
```

## 📝 Test Writing Guidelines

### Standard Test Structure

```javascript
async function testLabX() {
    testUtils.logLabHeader(X, 'Lab Name');

    let passed = 0;
    let failed = 0;

    try {
        // 1. Initialize Redis client
        await testUtils.initRedisClient();

        // 2. Test lab structure
        const labExists = await testUtils.fileExists(labDir);
        if (labExists) {
            testUtils.logTest('Lab X', 'Lab structure', true);
            passed++;
        } else {
            testUtils.logTest('Lab X', 'Lab structure', false);
            failed++;
            return { passed, failed };
        }

        // 3. Test Redis operations
        await testUtils.redisClient.set('key', 'value');
        const value = await testUtils.redisClient.get('key');

        if (value === 'value') {
            testUtils.logTest('Lab X', 'Redis operation', true);
            passed++;
        } else {
            testUtils.logTest('Lab X', 'Redis operation', false);
            failed++;
        }

        // 4. Test lab-specific functionality
        // ... additional tests ...

    } catch (error) {
        testUtils.logTest('Lab X', 'Lab execution', false, error.message);
        failed++;
    } finally {
        // 5. Cleanup
        await testUtils.closeRedisClient();
    }

    return { passed, failed };
}
```

### Best Practices

1. **Descriptive Test Names**: Use clear, action-based names
   ```javascript
   testUtils.logTest('Lab 7', 'HSET/HGETALL operations', true);
   ```

2. **Proper Cleanup**: Always close connections in `finally` blocks
   ```javascript
   finally {
       await testUtils.closeRedisClient();
   }
   ```

3. **Error Handling**: Catch and log all errors with context
   ```javascript
   catch (error) {
       testUtils.logTest('Lab X', 'Operation', false, error.message);
   }
   ```

4. **Test Independence**: Each test should clean up its own data
   ```javascript
   await testUtils.redisClient.del('test:lab7:*');
   ```

5. **Meaningful Assertions**: Check actual values, not just existence
   ```javascript
   if (value === 'expected-value') { ... }
   ```

## 🔍 Debugging Tests

### Enable Verbose Mode

```bash
node tests/run-all-tests.js --verbose
```

### Check Individual Lab

```bash
# Test just Lab 7
node tests/run-all-tests.js --lab=7
```

### Manual Redis Verification

```bash
redis-cli

# Check keys
> KEYS *

# Get values
> GET key:name

# Check info
> INFO

# Monitor commands
> MONITOR
```

### Check Test Results Files

```bash
cat tests/results/test-results-*.json | jq .
```

## 📊 Interpreting Results

### Console Output

```
╔════════════════════════════════════════════════════════════════════════════╗
║                          DAY 1 INTEGRATION TESTS                           ║
║                      CLI & Core Operations (Labs 1-5)                      ║
╚════════════════════════════════════════════════════════════════════════════╝

================================================================================
Lab 1: Redis Environment & CLI Basics
================================================================================
  ✓ Redis server is running
  ✓ Setup script exists
  ✓ Execute setup script
  ✓ Basic SET/GET commands
  ✓ Test script exists
  ✓ Execute test script
```

- **✓** = Test passed (green)
- **✗** = Test failed (red)
- Indented lines show individual test results
- Failed tests show error messages

### Exit Codes

- **0**: All tests passed - Safe to proceed
- **1**: Tests failed - Investigation required

### JSON Results Format

```json
{
  "total": 150,
  "passed": 148,
  "failed": 2,
  "percentage": "98.67",
  "results": [
    {
      "lab": "Lab 7",
      "test": "HSET/HGETALL operations",
      "passed": true,
      "message": "",
      "timestamp": "2025-10-26T10:30:00.000Z"
    },
    {
      "lab": "Lab 8",
      "test": "XADD operation",
      "passed": false,
      "message": "Connection timeout",
      "timestamp": "2025-10-26T10:31:00.000Z"
    }
  ]
}
```

## 🔧 Common Issues & Solutions

### Issue: Redis Not Running

**Symptom**:
```
✗ Redis is not running on localhost:6379
```

**Solution**:
```bash
docker run -d -p 6379:6379 --name redis-test redis:latest
```

### Issue: Missing Dependencies

**Symptom**:
```
Error: Cannot find module 'redis'
```

**Solution**:
```bash
npm run test:setup
```

### Issue: Lab Files Not Found

**Symptom**:
```
✗ Lab directory exists: false
```

**Solution**:
- Ensure you're running from the course root directory
- Check that lab directories exist
- Verify file names match expected patterns

### Issue: Cluster Tests Failing

**Symptom**:
```
✗ Cluster connection: false
```

**Solution**:
```bash
cd lab15-redis-cluster-ha
docker-compose up -d
./setup-cluster.sh
```

## 🔄 CI/CD Integration

### Environment Variables

```bash
# Optional environment variables
export REDIS_HOST=localhost
export REDIS_PORT=6379
export TEST_TIMEOUT=30000
export SAVE_RESULTS=true
```

### GitHub Actions

```yaml
- name: Run Tests
  run: npm test

- name: Upload Results
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: tests/results/
```

### Success Criteria

Tests must pass in CI/CD before:
- Merging pull requests
- Releasing new course versions
- Deploying to training environments

## 📈 Maintenance

### Adding New Tests

When adding a new lab:

1. Add test function to appropriate day file
2. Add test to day's run function
3. Update test counts in documentation
4. Test locally before committing

### Updating Existing Tests

When modifying labs:

1. Update corresponding test cases
2. Run full test suite
3. Update documentation if behavior changes
4. Verify CI/CD passes

### Test Data Management

- Use prefixed keys: `test:lab#:*`
- Clean up test data in teardown
- Don't interfere with production keys
- Use separate Redis DB if needed

## 📚 Additional Resources

- **Detailed Test Docs**: `tests/README.md`
- **Test Utils API**: `tests/test-utils.js`
- **Redis Docs**: https://redis.io/docs/
- **Node Redis**: https://github.com/redis/node-redis

## 🎓 For Instructors

### Pre-Course Checklist

- [ ] Run full test suite: `npm test`
- [ ] Verify all tests pass
- [ ] Check Redis version compatibility
- [ ] Test on training environment
- [ ] Review failed test reports
- [ ] Update sample data if needed

### During Course

- Use tests to verify student setups
- Run specific lab tests after completion
- Share test results with students
- Use as debugging tool for student issues

### Post-Course

- Run tests before archiving materials
- Update tests for feedback received
- Maintain compatibility with Redis updates
- Document any known issues

## 📝 License

MIT License - See course root for details

---

**Test Suite Version**: 1.0.0
**Course Version**: 3-Day Intensive
**Last Updated**: October 2025
**Questions?** Contact the Redis Training Lab Team
