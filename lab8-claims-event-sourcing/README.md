# Lab 8: Claims Event Sourcing with Redis Streams

A comprehensive Redis Streams implementation for event-driven claims processing with complete monitoring, testing, and validation capabilities.

## 🚀 Quick Start

```bash
# 1. Validate environment
./validation/validate-environment.sh

# 2. Install dependencies
npm install

# 3. Test Redis connection
npm run test-connection

# 4. Load sample data
npm run load-data

# 5. Run all tests
npm test

# 6. Start monitoring
npm run monitor-processing
```

## 📁 Project Structure

```
lab8-claims-event-sourcing/
├── src/
│   ├── models/                    # Domain models
│   ├── services/                  # Core services
│   ├── consumers/                 # Event consumers
│   └── utils/                     # Utilities
├── scripts/                       # Utility scripts
├── tests/                         # Test suites
├── validation/                    # Validation tools
├── monitoring/                    # Monitoring tools
├── docs/                         # Documentation
└── examples/                     # Example implementations
```

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific test categories
npm run test:streams
npm run test:consumers
npm run test:analytics
npm run test:recovery

# Performance testing
npm run benchmark
npm run load-test
npm run memory-test
```

## 📊 Monitoring

```bash
# Real-time processing monitor
npm run monitor-processing

# Stream health monitoring
npm run monitor-streams

# Consumer lag checking
npm run check-consumer-lag

# Generate analytics reports
npm run generate-report
```

## 🔧 Configuration

Set environment variables for Redis connection:

```bash
export REDIS_HOST=your-redis-host
export REDIS_PORT=6379
export REDIS_PASSWORD=your-password
```

## 🎯 Learning Objectives

- Event sourcing with Redis Streams
- Consumer group implementation
- Real-time analytics processing
- Stream monitoring and troubleshooting
- Production-ready error handling
- Performance optimization techniques

## 📖 Additional Resources

- [Redis Streams Documentation](https://redis.io/topics/streams-intro)
- [Event Sourcing Patterns](https://martinfowler.com/eaaDev/EventSourcing.html)
- [CQRS with Redis](https://redis.io/topics/patterns)

## 🆘 Support

- Check `docs/troubleshooting.md` for common issues
- Run `npm run diagnose` for automated diagnostics
- Review error logs in `logs/` directory
