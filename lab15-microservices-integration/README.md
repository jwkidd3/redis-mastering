# Lab 15: Simple Microservices Pattern

**Duration:** 45 minutes  
**Focus:** JavaScript-based microservices with Redis for caching and communication  
**Technologies:** Node.js, Express, Redis, Axios

## 📁 Project Structure

```
lab15-microservices-integration/
├── lab15.md                    # Complete lab instructions (START HERE)
├── services/
│   ├── policy-service/         # Policy management service
│   ├── claims-service/         # Claims processing service
│   └── customer-service/       # Customer management service
├── shared/
│   └── redis-client.js         # Shared Redis client with service discovery
├── src/
│   ├── service-discovery.js    # Service discovery implementation
│   └── monitor.js              # Service monitoring dashboard
├── tests/
│   └── test-integration.js     # Integration tests
├── scripts/
│   └── load-sample-data.sh     # Sample data loader
├── package.json                # Node.js dependencies
├── .env.example                # Environment configuration template
└── README.md                   # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-microservices-lab15 -p 6379:6379 redis:7-alpine
   ```

3. **Load Sample Data:**
   ```bash
   npm run load-data
   ```

4. **Start All Services:**
   ```bash
   # Option 1: Start all at once
   npm run start:all
   
   # Option 2: Start individually (in separate terminals)
   npm run start:policy
   npm run start:claims
   npm run start:customer
   ```

5. **Monitor Services:**
   ```bash
   npm run monitor
   ```

6. **Run Tests:**
   ```bash
   npm test
   ```

## 🔧 Service Endpoints

### Policy Service (Port 3001)
- `GET /api/policies/:id` - Get policy with caching
- `PUT /api/policies/:id` - Update policy and invalidate cache
- `GET /health` - Service health check

### Claims Service (Port 3002)
- `POST /api/claims` - Submit new claim
- `GET /api/claims/policy/:policyId` - Get claims for policy
- `GET /health` - Service health check

### Customer Service (Port 3003)
- `GET /api/customers/:id` - Get customer with caching
- `PUT /api/customers/:id` - Update customer
- `GET /health` - Service health check

## 📊 Key Features

- **Service Discovery:** Automatic service registration and discovery
- **Distributed Caching:** Cross-service cache with invalidation
- **Event-Driven Communication:** Pub/sub for service coordination
- **Queue Processing:** Asynchronous claim processing
- **Health Monitoring:** Service health checks and heartbeats
- **Session Sharing:** Cross-service session management

## 🎯 Learning Objectives

- ✅ Implement microservices with Redis integration
- ✅ Build distributed caching strategies
- ✅ Create service discovery patterns
- ✅ Implement event-driven architecture
- ✅ Develop inter-service communication
- ✅ Apply monitoring and observability

## 📚 Next Steps

After completing this lab, consider:
- Adding API Gateway for unified entry
- Implementing Circuit Breaker pattern
- Adding distributed tracing
- Using Redis Streams for event sourcing
- Implementing CQRS pattern
- Adding container orchestration

---

**Ready to start?** Open `lab15.md` and begin building your microservices architecture! 🚀
