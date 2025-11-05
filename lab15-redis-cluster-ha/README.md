# Lab 15: Redis Cluster HA

**Duration:** 60 minutes
**Focus:** Redis Cluster setup, sharding, replication, and high availability
**Prerequisites:** Docker installed and running

## 🎯 Learning Objectives

- Set up a Redis Cluster with multiple nodes
- Understand hash slots and data sharding
- Implement automatic failover and replication
- Test cluster resilience and failover scenarios
- Monitor cluster health and performance

## 📁 Project Structure

```
lab15-redis-cluster-ha/
├── README.md                    # This file
├── docker-compose.yml           # 6-node cluster configuration
├── package.json                 # Node.js dependencies
├── scripts/
│   ├── setup-cluster.sh        # Cluster initialization (Mac/Linux)
│   ├── setup-cluster.ps1       # Cluster initialization (Windows)
│   ├── test-cluster.sh         # Cluster testing (Mac/Linux)
│   └── test-cluster.ps1        # Cluster testing (Windows)
├── src/                        # Cluster client code
├── tests/                      # Test scripts
└── monitoring/                 # Monitoring tools
```

## 🚀 Quick Start

### 1. Start Cluster Nodes

```bash
docker-compose up -d
```

### 2. Create Cluster

**Mac/Linux:**
```bash
./scripts/setup-cluster.sh
```

**Windows PowerShell:**
```powershell
.\scripts\setup-cluster.ps1
```

### 3. Verify Cluster

```bash
docker exec -it redis-node-1 redis-cli cluster info
```

### 4. Test Cluster Operations

**Mac/Linux:**
```bash
./scripts/test-cluster.sh
```

**Windows PowerShell:**
```powershell
.\scripts\test-cluster.ps1
```

## 🔧 Cluster Configuration

The cluster consists of 6 nodes:
- **3 Master nodes:** Handle read/write operations
- **3 Replica nodes:** Provide redundancy and failover

**Hash Slots:** 16,384 slots distributed across masters

## 📋 Key Operations

### Connect to Cluster

```javascript
const Redis = require('ioredis');

const cluster = new Redis.Cluster([
  { host: 'localhost', port: 7000 },
  { host: 'localhost', port: 7001 },
  { host: 'localhost', port: 7002 }
]);

// Set value (auto-routed to correct node)
await cluster.set('policy:12345', 'AUTO');

// Get value
const value = await cluster.get('policy:12345');
```

### Check Cluster Status

```bash
# Cluster info
redis-cli -c -p 7000 cluster info

# Node list
redis-cli -c -p 7000 cluster nodes

# Slot distribution
redis-cli -c -p 7000 cluster slots
```

### Test Failover

```bash
# Stop master node
docker stop redis-node-1

# Verify automatic failover
redis-cli -c -p 7001 cluster nodes

# Data still accessible
redis-cli -c -p 7001 get policy:12345
```

## 🎓 Exercises

### Exercise 1: Data Sharding

Store 1000 keys and observe distribution:

```javascript
// See: src/sharding-demo.js
for (let i = 0; i < 1000; i++) {
  await cluster.set(`policy:${i}`, `data-${i}`);
}

// Check which node stores each key
const info = await cluster.cluster('KEYSLOT', 'policy:500');
```

### Exercise 2: Failover Testing

1. Identify master nodes
2. Stop a master node
3. Verify replica promotion
4. Restart original master
5. Observe re-replication

### Exercise 3: Scaling

Add a new master node:

```bash
# See: scripts/add-master-node.sh
docker run -d --name redis-node-7 \
  --net redis-cluster-net \
  -p 7006:7006 \
  redis:7-alpine redis-server --cluster-enabled yes

redis-cli --cluster add-node new-node-ip:7006 existing-node-ip:7000
```

## 📊 Monitoring

### Cluster Health Check

```bash
# Using Node.js
node src/health-check.js

# Using redis-cli
redis-cli -c -p 7000 cluster info | grep cluster_state
```

### Performance Metrics

```bash
# Node stats
redis-cli -c -p 7000 INFO stats

# Slot distribution
redis-cli -c -p 7000 cluster slots
```

## 🧹 Cleanup

```bash
# Stop cluster
docker-compose down

# Remove volumes
docker-compose down -v
```

## 📚 Additional Resources

- **Redis Cluster Tutorial:** `https://redis.io/docs/manual/scaling/`
- **Cluster Spec:** `https://redis.io/docs/reference/cluster-spec/`
- **ioredis Cluster:** `https://github.com/redis/ioredis#cluster`

## ⚠️ Important Notes

- **Minimum Nodes:** Cluster requires at least 3 master nodes
- **Hash Slots:** All 16,384 slots must be assigned
- **Network:** All nodes must be able to reach each other
- **Client Support:** Use cluster-aware clients (ioredis, redis-py-cluster)
- **Production:** Use separate physical/virtual machines for nodes

## 🔍 Troubleshooting

**Problem:** Cluster creation fails
```bash
# Solution: Reset nodes
docker-compose down -v
docker-compose up -d
./scripts/setup-cluster.sh
```

**Problem:** Can't connect to cluster
```bash
# Solution: Check node connectivity
docker exec redis-node-1 redis-cli cluster nodes
```

**Problem:** Keys not found after failover
```bash
# Solution: Use cluster-aware client with retry logic
# See: src/cluster-client.js
```

## ✅ Lab Completion Checklist

- [ ] Cluster running with 6 nodes
- [ ] Cluster health status: `cluster_state:ok`
- [ ] Data successfully stored and retrieved
- [ ] Failover tested and verified
- [ ] Monitoring scripts executed
- [ ] Understood hash slots and sharding

**Time to complete:** ~60 minutes
