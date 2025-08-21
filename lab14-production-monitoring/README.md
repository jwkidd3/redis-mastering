# Lab 14: Production Monitoring - Quick Start Guide

## 🚀 Quick Setup

```bash
# 1. Install dependencies
npm install

# 2. Start Redis (if not running)
redis-server --daemonize yes

# 3. Load sample data
npm run load-data

# 4. Start monitoring servers
npm start
```

## 📊 Access Points

After starting the servers:

- **Health Check API:** http://localhost:3000/health
- **Monitoring Dashboard:** http://localhost:4000
- **Real-time Metrics:** http://localhost:4000/api/metrics/realtime

## 🧪 Test the System

```bash
# Test health endpoint
curl http://localhost:3000/health

# Test metrics endpoint
curl http://localhost:3000/metrics

# Test Redis info
curl http://localhost:3000/redis/info
```

## 📁 Project Structure

```
lab14-production-monitoring/
├── src/
│   └── main.js              # Main application with health checks
├── dashboards/
│   └── index.html           # Monitoring dashboard UI
├── scripts/
│   ├── setup.sh             # Setup script
│   ├── load-production-monitoring-data.js  # Data loader
│   └── test-monitoring.sh  # Test script
├── logs/                    # Application logs
├── package.json            # Dependencies
└── README.md              # This file
```

## 🎯 Key Features

1. **Health Checks**
   - Redis connectivity monitoring
   - Memory usage tracking
   - Performance metrics collection

2. **Real-time Dashboard**
   - Live metrics display
   - Auto-refresh every 30 seconds
   - Visual status indicators

3. **Monitoring Metrics**
   - Connected clients
   - Memory usage
   - Operations per second
   - Cache hit/miss ratio
   - Command statistics

## 🛠 Troubleshooting

### Redis Connection Issues
```bash
# Check if Redis is running
redis-cli ping

# If not, start Redis
redis-server --daemonize yes
```

### Port Already in Use
```bash
# Check what's using port 3000
lsof -i :3000

# Check what's using port 4000
lsof -i :4000

# Kill the process if needed
kill -9 <PID>
```

### Missing Dependencies
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## 📝 Lab Objectives

By completing this lab, you will:
- ✅ Set up production monitoring for Redis
- ✅ Create health check endpoints
- ✅ Build a real-time monitoring dashboard
- ✅ Collect and analyze performance metrics
- ✅ Monitor business-critical operations

## 🔍 What to Look For

When the system is running correctly:

1. Health endpoint returns JSON with status "healthy"
2. Dashboard shows real-time metrics
3. Memory usage and client connections are visible
4. No errors in the console logs

## 📚 Additional Resources

- [Redis INFO command](https://redis.io/commands/info/)
- [Redis monitoring best practices](https://redis.io/docs/management/optimization/monitoring/)
- [Express.js documentation](https://expressjs.com/)