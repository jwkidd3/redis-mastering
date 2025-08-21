# Lab 15: Redis Cluster with High Availability, Sharding & Replication

## Overview
In this advanced lab, you'll build a production-grade Redis Cluster with automatic sharding, replication, and high availability. You'll learn how to handle node failures, data redistribution, and cluster scaling while maintaining zero downtime for your insurance application.

## Learning Objectives
By completing this lab, you will:
- Deploy a 6-node Redis Cluster (3 masters, 3 replicas)
- Configure automatic sharding across master nodes
- Implement master-replica replication for high availability
- Test automatic failover and recovery scenarios
- Monitor cluster health and performance metrics
- Scale the cluster by adding/removing nodes
- Implement cluster-aware client applications
- Handle split-brain scenarios and network partitions

## Prerequisites
- Completed Labs 1-14
- Docker and Docker Compose installed
- Node.js 18+ installed
- Basic understanding of distributed systems
- 8GB RAM available for the cluster

## Lab Duration
- **Estimated Time**: 3-4 hours
- **Difficulty Level**: Advanced

## Architecture Overview
```
┌─────────────────────────────────────────────────────────┐
│                   Redis Cluster (16384 slots)           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  │  Master-1    │    │  Master-2    │    │  Master-3    │
│  │  Port: 9000  │    │  Port: 9001  │    │  Port: 9002  │
│  │  Slots:      │    │  Slots:      │    │  Slots:      │
│  │  0-5461      │    │  5462-10922  │    │  10923-16383 │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
│         │                   │                   │
│         │ Replication       │ Replication      │ Replication
│         ↓                   ↓                   ↓
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  │  Replica-1   │    │  Replica-2   │    │  Replica-3   │
│  │  Port: 9003  │    │  Port: 9004  │    │  Port: 9005  │
│  └──────────────┘    └──────────────┘    └──────────────┘
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Part 1: Cluster Setup and Configuration

### Step 1.0: Install Dependencies
```bash
cd lab15-redis-cluster-ha

# Install Node.js dependencies for testing and monitoring
npm install

# Make scripts executable
chmod +x scripts/*.sh
```

### Step 1.1: Review Docker Compose Configuration
```bash
cat docker-compose.yml
```

The configuration creates 6 Redis nodes with:
- Cluster mode enabled on ports 9000-9005
- Persistent storage volumes
- Custom network (172.21.0.0/16) for inter-node communication
- Resource limits and health checks

### Step 1.2: Start Redis Nodes
```bash
# Start all Redis instances
docker compose up -d

# Verify all nodes are running and healthy
docker ps | grep redis-node

# Wait for health checks to pass (about 10 seconds)
sleep 10

# Check logs for any issues
docker compose logs --tail=10
```

### Step 1.3: Initialize the Cluster
```bash
# Run cluster initialization script
./scripts/init-cluster.sh

# This script will:
# - Create cluster with 3 masters and 3 replicas
# - Assign hash slots evenly across masters
# - Configure replication between master-replica pairs
```

### Step 1.4: Verify Cluster Status
```bash
# Check cluster info
docker exec -it redis-node-1 redis-cli -p 9000 cluster info

# Check node configuration
docker exec -it redis-node-1 redis-cli -p 9000 cluster nodes

# Expected output shows:
# - 3 master nodes with slot assignments
# - 3 replica nodes with master associations
# - All nodes in "connected" state
```

## Part 2: Understanding Sharding and Hash Slots

### Step 2.1: Hash Slot Distribution
Redis Cluster uses 16384 hash slots distributed across master nodes:

```bash
# View slot assignments
./scripts/show-slot-distribution.sh

# Test key-to-slot mapping
docker exec -it redis-node-1 redis-cli -p 9000 --cluster check localhost:9000
```

### Step 2.2: Test Data Sharding
```bash
# Run sharding test script
node src/test-sharding.js

# This demonstrates:
# - How keys are distributed across shards
# - CRC16 hash slot calculation
# - Automatic redirection to correct shard
```

### Step 2.3: Hash Tags for Co-location
```bash
# Test hash tags to keep related data together
node src/test-hash-tags.js

# Examples:
# - {customer:123}:profile and {customer:123}:policies
# - Both keys land on the same shard due to hash tag
```

## Part 3: Replication and High Availability

### Step 3.1: Test Replication
```bash
# Write to master, read from replica
./scripts/test-replication.sh

# Monitor replication lag in real-time
npm run monitor-replication
```

### Step 3.2: Simulate Master Failure
```bash
# Kill master node 1
docker stop redis-node-1

# Watch automatic failover (takes ~5-15 seconds)
./scripts/watch-failover.sh

# Replica-1 should promote to master
# Verify new topology
docker exec -it redis-node-2 redis-cli -p 9001 cluster nodes
```

### Step 3.3: Recover Failed Node
```bash
# Restart the failed node
docker start redis-node-1

# Node rejoins as replica of new master
./scripts/verify-recovery.sh
```

### Step 3.4: Test Split-Brain Scenarios
```bash
# Simulate network partition
./scripts/simulate-partition.sh

# Observe cluster behavior:
# - Minority partition stops accepting writes
# - Majority partition continues operating
# - Automatic recovery when partition heals
```

## Part 4: Cluster Operations

### Step 4.1: Adding Nodes (Scale Out)
```bash
# Add a new master node
./scripts/add-master-node.sh 9006

# Add a new replica node
./scripts/add-replica-node.sh 9007 9006

# Rebalance slots across all masters
./scripts/rebalance-cluster.sh
```

### Step 4.2: Removing Nodes (Scale In)
```bash
# Migrate slots away from node
./scripts/migrate-slots.sh 9006

# Remove node from cluster
./scripts/remove-node.sh 9006
```

### Step 4.3: Manual Failover
```bash
# Perform controlled failover for maintenance
./scripts/manual-failover.sh 9004

# This allows graceful master switch without data loss
```

## Part 5: Insurance Application Integration

### Step 5.1: Cluster-Aware Client Setup
```javascript
// src/cluster-client.js
const Redis = require('ioredis');

const cluster = new Redis.Cluster([
  { port: 9000, host: '127.0.0.1' },
  { port: 9001, host: '127.0.0.1' },
  { port: 9002, host: '127.0.0.1' }
], {
  redisOptions: {
    password: process.env.REDIS_PASSWORD
  },
  enableReadyCheck: true,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
  retryDelayOnClusterDown: 300
});
```

### Step 5.2: Implement Insurance Operations
```bash
# Run insurance data loader
node src/insurance-data-loader.js

# This distributes:
# - Customer records across shards
# - Policy data with hash tags for co-location
# - Claims with proper partitioning
```

### Step 5.3: Test Application Resilience
```bash
# Run application with chaos testing
node tests/chaos-test.js

# This script:
# - Randomly kills nodes
# - Generates load during failures
# - Verifies zero data loss
# - Measures availability metrics
```

## Part 6: Monitoring and Observability

### Step 6.1: Cluster Health Dashboard
```bash
# Start monitoring dashboard
node monitoring/dashboard.js

# Open browser to http://localhost:3000
# View real-time metrics:
# - Node status and roles
# - Slot distribution
# - Replication lag
# - Operations per second
# - Memory usage per shard
```

### Step 6.2: Set Up Alerts
```bash
# Configure alerting rules
./monitoring/setup-alerts.sh

# Alerts for:
# - Node failures
# - High memory usage
# - Replication lag > 1 second
# - Cluster state changes
```

### Step 6.3: Performance Benchmarking
```bash
# Run cluster benchmark
./scripts/benchmark-cluster.sh

# Compare with single instance:
# - Throughput increase
# - Latency distribution
# - Scaling efficiency
```

## Part 7: Advanced Scenarios

### Step 7.1: Cross-Slot Operations
```bash
# Test multi-key operations
node src/test-cross-slot.js

# Learn limitations and workarounds:
# - Using hash tags
# - Lua scripting constraints
# - Transaction boundaries
```

### Step 7.2: Backup and Recovery
```bash
# Backup entire cluster
./scripts/backup-cluster.sh

# Restore cluster from backup
./scripts/restore-cluster.sh

# Verify data integrity
./scripts/verify-backup.sh
```

### Step 7.3: Rolling Upgrades
```bash
# Perform zero-downtime Redis upgrade
./scripts/rolling-upgrade.sh

# Process:
# 1. Upgrade replicas first
# 2. Failover masters to upgraded replicas
# 3. Upgrade former masters
# 4. Rebalance if needed
```

## Part 8: Production Best Practices

### Step 8.1: Optimization
Review and apply optimization settings:
- `cluster-node-timeout`: Failure detection time
- `cluster-replica-validity-factor`: Replica promotion rules
- `cluster-migration-barrier`: Minimum replicas for migration
- `cluster-require-full-coverage`: Availability vs consistency

### Step 8.3: Disaster Recovery Plan
```bash
# Test DR procedures
./scripts/test-disaster-recovery.sh

# Scenarios covered:
# - Complete datacenter failure
# - Corrupted node recovery
# - Split cluster merge
# - Point-in-time recovery
```

## Lab Validation

### Verify Your Implementation
```bash
# Run comprehensive validation suite
npm test

# This validates:
# ✓ Cluster properly initialized with 6 nodes
# ✓ Hash slots evenly distributed
# ✓ Replication working correctly
# ✓ Automatic failover functional
# ✓ Client handles redirections
# ✓ Data properly sharded
# ✓ No data loss during failures
# ✓ Monitoring and alerts configured
```

### Performance Metrics to Achieve
- [ ] Cluster handles 100,000 ops/second
- [ ] Failover completes within 15 seconds
- [ ] 99.99% availability during chaos testing
- [ ] Even data distribution (±10% across shards)
- [ ] Replication lag < 100ms under load

## Troubleshooting Guide

### Common Issues and Solutions

1. **Cluster initialization fails**
   ```bash
   # Check node connectivity
   ./scripts/test-connectivity.sh
   
   # Verify ports are not in use
   netstat -an | grep 900[0-5]
   ```

2. **Nodes not joining cluster**
   ```bash
   # Reset cluster state
   ./scripts/reset-cluster.sh
   
   # Reinitialize
   ./scripts/init-cluster.sh
   ```

3. **Uneven slot distribution**
   ```bash
   # Force rebalance
   ./scripts/force-rebalance.sh
   ```

4. **Client connection errors**
   ```bash
   # Verify cluster state
   docker exec -it redis-node-1 redis-cli -p 9000 cluster info
   
   # Check client configuration
   node src/test-connection.js
   ```

## Cleanup

```bash
# Stop cluster but preserve data
docker-compose stop

# Complete cleanup (removes data)
./scripts/cleanup-lab.sh

# Remove Docker volumes
docker volume prune
```

## Summary

Congratulations! You've successfully built and managed a production-grade Redis Cluster with:

✅ **Automatic Sharding**: Data distributed across multiple nodes  
✅ **High Availability**: Automatic failover with zero data loss  
✅ **Replication**: Master-replica pairs for redundancy  
✅ **Scalability**: Dynamic node addition/removal  
✅ **Resilience**: Handling network partitions and node failures  
✅ **Monitoring**: Real-time cluster health visibility  
✅ **Production Readiness**: Security, backups, and DR procedures  

## Key Takeaways

1. **Hash Slots**: Redis uses 16384 slots for consistent data distribution
2. **CAP Theorem**: Redis Cluster favors availability and partition tolerance
3. **Failover Time**: Typically 5-15 seconds for automatic failover
4. **Client Complexity**: Applications need cluster-aware clients
5. **Operational Overhead**: More complex than standalone or sentinel setups
6. **Use Cases**: Best for large-scale, high-throughput applications

## Next Steps

- Explore Redis Enterprise for additional features
- Implement geo-distributed clusters
- Study Redis Cluster vs other distributed databases
- Design cluster topology for your specific use case
- Plan capacity for production workloads

## Additional Resources

- [Redis Cluster Specification](https://redis.io/docs/reference/cluster-spec/)
- [Redis Cluster Tutorial](https://redis.io/docs/manual/scaling/)
- [Production Deployment Best Practices](./docs/production-deployment.md)
- [Cluster Troubleshooting Guide](./docs/troubleshooting.md)