# Redis Mastering Course - Test Quick Reference

## 🚀 Quick Commands

```bash
# === SETUP ===
npm install                    # Install all dependencies
npm run test:setup            # Setup test environment

# === RUN TESTS ===
npm test                      # Run ALL tests (15 labs)
npm run test:day1            # Run Day 1 tests (Labs 1-5)
npm run test:day2            # Run Day 2 tests (Labs 6-10)
npm run test:day3            # Run Day 3 tests (Labs 11-15)

# === SPECIFIC LAB ===
node tests/run-all-tests.js --lab=1    # Lab 1
node tests/run-all-tests.js --lab=7    # Lab 7
node tests/run-all-tests.js --lab=15   # Lab 15

# === OPTIONS ===
node tests/run-all-tests.js --verbose  # Verbose output
node tests/run-all-tests.js --no-save  # Don't save results
node tests/run-all-tests.js --help     # Show help

# === CLEANUP ===
npm run test:cleanup          # Clean test environment
```

## 📊 Test Coverage

| Day | Labs | Focus Area | Tests |
|-----|------|------------|-------|
| 1 | 1-5 | CLI & Core Operations | 35+ |
| 2 | 6-10 | JavaScript Integration | 60+ |
| 3 | 11-15 | Production & Advanced | 55+ |
| **Total** | **15** | **All Labs** | **150+** |

## ✅ Pre-Test Checklist

```bash
# 1. Check Node.js version
node --version              # Need 18+

# 2. Start Redis
docker run -d -p 6379:6379 redis:latest

# 3. Verify Redis
redis-cli ping             # Should return PONG

# 4. Setup tests
npm run test:setup

# 5. Run tests
npm test
```

## 🔍 Individual Lab Tests

```bash
# Day 1: CLI & Core
node tests/run-all-tests.js --lab=1   # Redis Environment & CLI
node tests/run-all-tests.js --lab=2   # RESP Protocol
node tests/run-all-tests.js --lab=3   # String Operations
node tests/run-all-tests.js --lab=4   # Key Management & TTL
node tests/run-all-tests.js --lab=5   # Advanced CLI Operations

# Day 2: JavaScript Integration
node tests/run-all-tests.js --lab=6   # JavaScript Redis Client
node tests/run-all-tests.js --lab=7   # Customer Profiles & Hashes
node tests/run-all-tests.js --lab=8   # Claims Event Sourcing (Streams)
node tests/run-all-tests.js --lab=9   # Insurance Analytics (Sets/Sorted Sets)
node tests/run-all-tests.js --lab=10  # Advanced Caching Patterns

# Day 3: Production & Advanced
node tests/run-all-tests.js --lab=11  # Session Management & Security
node tests/run-all-tests.js --lab=12  # Rate Limiting & API Protection
node tests/run-all-tests.js --lab=13  # Production Configuration
node tests/run-all-tests.js --lab=14  # Production Monitoring
node tests/run-all-tests.js --lab=15  # Redis Cluster HA
```

## 🐛 Troubleshooting Commands

```bash
# Check Redis connection
redis-cli ping

# Check Redis info
redis-cli INFO

# Check keys in Redis
redis-cli KEYS *

# Check Docker containers
docker ps

# Start Redis with Docker
docker run -d -p 6379:6379 --name redis-test redis:latest

# Stop and remove Redis container
docker stop redis-test && docker rm redis-test

# Check test results
ls -la tests/results/
cat tests/results/test-results-*.json

# Manual cleanup
redis-cli FLUSHALL
```

## 📁 Important Files

```
redis-mastering/
├── package.json                    # Dependencies & scripts
├── TESTING.md                      # Full testing guide
├── TEST_SUITE_SUMMARY.md          # Implementation summary
├── TEST_QUICK_REFERENCE.md        # This file
└── tests/
    ├── README.md                  # Detailed test docs
    ├── run-all-tests.js          # Main test runner
    ├── day1-labs-test.js         # Day 1 tests
    ├── day2-labs-test.js         # Day 2 tests
    ├── day3-labs-test.js         # Day 3 tests
    ├── test-utils.js             # Test utilities
    ├── setup-test-environment.sh  # Setup script
    └── cleanup-test-environment.sh # Cleanup script
```

## 🎯 Common Use Cases

### Before Course Delivery
```bash
npm run test:setup
npm test
# Verify all tests pass
```

### After Lab Completion
```bash
# Student completed Lab 7
node tests/run-all-tests.js --lab=7
```

### Debugging Specific Day
```bash
# Issues with Day 2 labs
npm run test:day2 --verbose
```

### Quick Smoke Test
```bash
# Just verify basics work
npm run test:day1
```

### Full Validation
```bash
# Complete validation before archiving
npm run test:setup
npm test
npm run test:cleanup
```

## 💡 Pro Tips

1. **Always setup first**: `npm run test:setup`
2. **Run tests from root**: Don't cd into labs
3. **Check Redis first**: `redis-cli ping`
4. **Use verbose for debugging**: `--verbose` flag
5. **Save results for records**: Auto-saved to `tests/results/`
6. **Cleanup after**: `npm run test:cleanup`

## 📊 Understanding Output

### Success (✓)
```
  ✓ Redis server is running
  ✓ Setup script exists
  ✓ Basic SET/GET commands
```

### Failure (✗)
```
  ✗ Redis server is running: Connection refused
  ✗ Setup script exists: File not found
```

### Summary
```
Total Tests: 150
Passed: 148
Failed: 2
Success Rate: 98.67%
```

## 🔄 CI/CD Quick Setup

### GitHub Actions
```yaml
- run: npm run test:setup
- run: npm test
```

### GitLab CI
```yaml
script:
  - npm run test:setup
  - npm test
```

### Jenkins
```groovy
sh 'npm run test:setup'
sh 'npm test'
```

## 📞 Help & Documentation

- **Full Docs**: `tests/README.md`
- **Testing Guide**: `TESTING.md`
- **Implementation**: `TEST_SUITE_SUMMARY.md`
- **This Reference**: `TEST_QUICK_REFERENCE.md`

## 🎓 For Instructors

```bash
# Pre-course validation
npm run test:setup && npm test

# During course - verify lab
node tests/run-all-tests.js --lab=<number>

# Post-course cleanup
npm run test:cleanup
```

## 🎯 Exit Codes

- **0** = All tests passed ✅
- **1** = Tests failed or error ❌

Use in scripts:
```bash
npm test && echo "Ready!" || echo "Fix issues!"
```

## 📈 Metrics

```bash
# View last test results
cat tests/results/test-results-*.json | tail -1 | jq .

# Count passed tests
cat tests/results/test-results-*.json | tail -1 | jq .passed

# Get success rate
cat tests/results/test-results-*.json | tail -1 | jq .percentage
```

---

**💾 Save this file for quick reference during course delivery!**

**Questions?** See `tests/README.md` or `TESTING.md`
