# Lab 14: Monitoring & Health Checks for Business Operations

## Overview
This lab implements comprehensive monitoring, health checks, and alerting for production Redis operations with a focus on business metrics.

## Quick Start

1. **Start Redis with monitoring configuration:**
```bash
docker run -d --name redis-monitoring-lab14 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --latency-monitor-threshold 100 \
  --slowlog-log-slower-than 10000
```

2. **Install dependencies:**
```bash
npm install
```

3. **Load sample data:**
```bash
./scripts/load-sample-data.sh
```

4. **Start monitoring dashboard:**
```bash
npm run dashboard
```

5. **Access monitoring interfaces:**
- Dashboard: http://localhost:3001
- Health Check: http://localhost:3000/health
- Metrics: http://localhost:3001/metrics
- Alerts: http://localhost:3001/api/alerts

## Available Scripts

- `npm start` - Start the main application
- `npm run health` - Run health check server
- `npm run metrics` - Run metrics collector
- `npm run dashboard` - Start monitoring dashboard
- `npm run stress-test` - Run stress test for monitoring
- `npm test` - Test all monitoring components

## Components

### Health Check System
- Basic and detailed health endpoints
- Readiness and liveness probes
- Memory and performance health checks
- Business metrics monitoring

### Metrics Collector
- Prometheus-compatible metrics
- Business operation tracking
- Performance histograms
- System resource gauges

### Monitoring Dashboard
- Real-time statistics display
- Queue status monitoring
- Performance metrics visualization
- Alert management
- Slow query tracking

## API Endpoints

### Health Checks
- `GET /health` - Basic health status
- `GET /health/detailed` - Detailed health information
- `GET /ready` - Readiness probe
- `GET /live` - Liveness probe

### Monitoring APIs
- `GET /metrics` - Prometheus metrics
- `GET /api/stats` - Real-time statistics
- `GET /api/alerts` - Active alerts
- `GET /api/performance` - Performance data

## Alert Thresholds

- **Memory Usage:** Warning at 75%, Critical at 90%
- **Queue Length:** Warning when pending claims > 100
- **Slow Queries:** Info alert when detected
- **Connection Issues:** Critical when Redis unavailable

## Troubleshooting

**Port conflicts:**
```bash
# Check what's using port 3001
lsof -i :3001

# Kill the process
kill -9 <PID>
```

**Redis connection issues:**
```bash
# Verify Redis is running
docker ps | grep redis

# Test connection
redis-cli ping
```

**Metrics not updating:**
- Check auto-collection is started
- Verify operations are being tracked
- Check browser console for errors

## Production Deployment

1. Configure environment variables
2. Set up proper authentication
3. Enable TLS for Redis connection
4. Configure alert notifications
5. Integrate with monitoring platforms (Prometheus/Grafana)

## Learning Resources

- [Redis Monitoring Guide](https://redis.io/docs/management/monitoring/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Health Check Patterns](https://microservices.io/patterns/observability/health-check-api.html)
