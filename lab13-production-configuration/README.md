# Lab 13: Production Configuration for Business Systems

## Overview
This lab provides hands-on experience configuring Redis for production deployment with persistence, security, and performance optimization.

## Quick Start

1. **Start Production Redis**
```bash
docker run -d --name redis-prod-lab13 \
  -p 6379:6379 \
  -v $(pwd)/config:/usr/local/etc/redis \
  -v $(pwd)/data:/data/redis \
  redis:7-alpine redis-server /usr/local/etc/redis/redis-production.conf
```

2. **Verify Configuration**
```bash
npm run verify
```

3. **Run Health Check**
```bash
./scripts/health-check.sh
```

4. **Test Backup**
```bash
npm run backup
```

## Key Features

### Persistence
- RDB snapshots for point-in-time recovery
- AOF logging for transaction durability
- Hybrid RDB-AOF for optimal recovery

### Security
- Password authentication
- ACL user management
- Command renaming
- Network binding restrictions

### Performance
- Memory management with eviction policies
- Connection pooling
- Slow query logging
- Latency monitoring

### Operations
- Automated backup scripts
- Health monitoring
- Load testing utilities
- Restore procedures

## Configuration Files

- `config/redis-production.conf` - Main production configuration
- `config/redis-security.conf` - Security-focused configuration
- `scripts/backup-redis.sh` - Automated backup script
- `scripts/restore-redis.sh` - Restore from backup
- `scripts/health-check.sh` - Health monitoring

## NPM Scripts

- `npm start` - Run production verification
- `npm run test-memory` - Test memory configuration
- `npm run setup-security` - Configure security
- `npm run backup` - Execute backup
- `npm run monitor` - Start monitoring dashboard
- `npm run load-test` - Run performance test

## Production Checklist

- [ ] Persistence configured (RDB + AOF)
- [ ] Memory limits and eviction policy set
- [ ] Authentication enabled
- [ ] ACL users configured
- [ ] Backup automation in place
- [ ] Monitoring configured
- [ ] Health checks scheduled
- [ ] Load testing completed

## Troubleshooting

### Connection Issues
```bash
redis-cli ping
docker logs redis-prod-lab13
```

### Memory Issues
```bash
redis-cli INFO memory
redis-cli MEMORY DOCTOR
```

### Persistence Issues
```bash
redis-cli LASTSAVE
redis-cli INFO persistence
```

## Resources

- [Redis Persistence Documentation](https://redis.io/docs/management/persistence/)
- [Redis Security Documentation](https://redis.io/docs/management/security/)
- [Redis Configuration Documentation](https://redis.io/docs/management/config/)
