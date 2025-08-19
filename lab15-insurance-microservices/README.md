# Lab 15: Insurance Microservices Integration

Complete implementation of enterprise-grade microservices architecture for insurance systems using Redis.

## 🎯 Learning Objectives

- ✅ Cross-service caching patterns
- ✅ Event-driven architecture with Redis pub/sub
- ✅ Service discovery and health monitoring  
- ✅ Distributed session management
- ✅ API Gateway with load balancing
- ✅ Cache coherence strategies

## 🚀 Quick Start

```bash
# 1. Setup the environment
npm run setup

# 2. Start all services (in separate terminals)
npm run start:policy     # Terminal 1
npm run start:claims     # Terminal 2  
npm run start:customer   # Terminal 3
npm run start:gateway    # Terminal 4

# 3. Verify integration
npm run verify

# 4. Run workflow tests
npm run test

# 5. Analyze performance
npm run analyze
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Policy Service │    │ Claims Service  │    │Customer Service │
│     :3001       │    │     :3002       │    │     :3003       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────┐
         │              API Gateway                    │
         │                :3000                        │
         └─────────────────────────────────────────────┘
                                 │
         ┌─────────────────────────────────────────────┐
         │                 Redis                       │
         │  Cache + Pub/Sub + Service Discovery        │
         └─────────────────────────────────────────────┘
```

## 📊 Key Features

### Distributed Caching
- Cross-service cache coordination
- Intelligent cache invalidation
- TTL management strategies

### Event-Driven Communication  
- Real-time pub/sub messaging
- Event sourcing for audit trails
- Asynchronous processing

### Service Discovery
- Dynamic service registration
- Health check automation
- Load balancing support

### Performance Optimization
- Sub-millisecond cache responses
- Connection pooling
- Request/response optimization

## 🧪 Testing

### Integration Tests
```bash
npm run verify
```

### Workflow Tests
```bash
npm run test
```

### Load Testing
```bash
npm run test:load
```

### Performance Analysis
```bash
npm run analyze
```

## 📈 Monitoring

Access monitoring endpoints:
- API Gateway: http://localhost:3000/health
- Policy Service: http://localhost:3001/health  
- Claims Service: http://localhost:3002/health
- Customer Service: http://localhost:3003/health

## 🎓 Skills Developed

✅ **Enterprise Architecture**: Scalable microservices design
✅ **Distributed Caching**: Redis integration patterns  
✅ **Event Processing**: Real-time communication
✅ **Service Integration**: Cross-service coordination
✅ **Performance Engineering**: Optimization strategies
✅ **Production Operations**: Monitoring and deployment

## 🏆 Course Completion

Congratulations! You've mastered Redis for enterprise microservices!

**What's Next:**
- Apply patterns to production systems
- Explore Redis Stack extensions
- Consider Redis Enterprise features
- Investigate Redis Cloud deployments
