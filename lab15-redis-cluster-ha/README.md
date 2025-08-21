# Lab 15: Redis Cluster with High Availability

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ installed
- At least 8GB RAM available
- Ports 9000-9005 and 3000 available

### Setup Instructions

1. **Navigate to lab directory:**
   ```bash
   cd lab15-redis-cluster-ha
   ```

2. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

3. **Start the Redis cluster containers:**
   ```bash
   docker compose up -d
   ```

4. **Wait for containers to be ready (about 10 seconds):**
   ```bash
   # Check that all 6 containers are running and healthy
   docker ps | grep redis-node
   ```

5. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

6. **Initialize the Redis cluster:**
   ```bash
   ./scripts/init-cluster.sh
   ```

7. **Verify cluster is operational:**
   ```bash
   # Should show cluster_state:ok
   docker exec redis-node-1 redis-cli -p 9000 cluster info
   
   # Should show 3 masters and 3 replicas
   docker exec redis-node-1 redis-cli -p 9000 cluster nodes
   ```

8. **Test the application:**
   ```bash
   # Test sharding functionality
   npm run test-sharding
   
   # Test hash tags for data co-location
   npm run test-hash-tags
   
   # Load sample insurance data
   npm run load-data
   ```

### Port Configuration
**Important:** This lab uses ports 9000-9005 instead of the typical 7000-7005 to avoid conflicts.

- **redis-node-1** (Master): Port 9000 → Replica on port 9004
- **redis-node-2** (Master): Port 9001 → Replica on port 9005  
- **redis-node-3** (Master): Port 9002 → Replica on port 9003

### Troubleshooting Setup

**If cluster initialization fails:**
```bash
# Stop containers and remove volumes
docker compose down -v

# Restart fresh
docker compose up -d
sleep 10
./scripts/init-cluster.sh
```

**If Node.js apps can't connect:**
- Verify cluster is running: `docker ps | grep redis-node`
- Check cluster state: `docker exec redis-node-1 redis-cli -p 9000 cluster info`
- Ensure ports 9000-9005 are not in use: `lsof -i :9000-9005`

## Lab Components

### Scripts
- `init-cluster.sh` - Initialize 6-node cluster (3 masters, 3 replicas)
- `show-slot-distribution.sh` - Display hash slot distribution
- `test-replication.sh` - Test master-replica replication
- `watch-failover.sh` - Monitor cluster during failover
- `simulate-partition.sh` - Simulate network partition

### Applications
- `src/cluster-client.js` - Cluster-aware Redis client
- `src/test-sharding.js` - Test data sharding across nodes
- `src/insurance-data-loader.js` - Load insurance test data
- `monitoring/dashboard.js` - Web-based cluster dashboard

### Testing
- `tests/chaos-test.js` - Chaos engineering tests
- `tests/run-tests.js` - Complete validation suite

## Common Commands

### Monitor Cluster
```bash
# Real-time cluster monitoring
./scripts/watch-failover.sh

# Monitor replication lag and health
npm run monitor-replication

# Web dashboard (http://localhost:3000)
npm run monitor
```

### Test Failover
```bash
# Kill a master node
docker stop redis-node-1

# Watch automatic failover
./scripts/watch-failover.sh

# Restart node
docker start redis-node-1
```

### Load Test Data
```bash
npm run load-data
```

### Run Tests
```bash
# Test sharding
npm run test-sharding

# Test hash tags
npm run test-hash-tags

# Run validation suite
npm test

# Chaos testing
npm run chaos-test
```

## Architecture

```
Port 9000 (Master-1) ← Replication → Port 9004 (Replica-1)
     ↓ Slots 0-5460
     
Port 9001 (Master-2) ← Replication → Port 9005 (Replica-2)
     ↓ Slots 5461-10922
     
Port 9002 (Master-3) ← Replication → Port 9003 (Replica-3)
     ↓ Slots 10923-16383
```

## Troubleshooting

### Cluster won't initialize
```bash
# Reset all nodes
docker-compose down -v
docker-compose up -d
./scripts/init-cluster.sh
```

### Node not responding
```bash
# Check node logs
docker logs redis-node-1

# Restart specific node
docker restart redis-node-1
```

### Connection errors
```bash
# Verify all nodes are running
docker ps | grep redis-node

# Check cluster state
docker exec redis-node-1 redis-cli -p 9000 cluster nodes
```

## Cleanup
```bash
# Stop cluster (preserves data)
docker-compose stop

# Complete cleanup (removes all data)
docker-compose down -v
```