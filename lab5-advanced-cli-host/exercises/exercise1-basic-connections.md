# Exercise 1: Basic Connections with Host Parameters

## Objective
Practice basic Redis CLI connections using host parameters.

## Instructions

**Note:** Replace `localhost:6379` with the Redis server details provided by your instructor.

### Task 1: Connection Testing
1. Test basic connectivity:
   ```bash
   redis-cli -h localhost -p 6379 PING
   ```
   Expected result: `PONG`

2. Get Redis server version:
   ```bash
   redis-cli -h localhost -p 6379 INFO server | grep redis_version
   ```

3. Check current database size:
   ```bash
   redis-cli -h localhost -p 6379 DBSIZE
   ```

### Task 2: Basic Data Operations
1. Create a test key:
   ```bash
   redis-cli -h localhost -p 6379 SET exercise1:test "Hello Redis"
   ```

2. Retrieve the value:
   ```bash
   redis-cli -h localhost -p 6379 GET exercise1:test
   ```

3. Check if key exists:
   ```bash
   redis-cli -h localhost -p 6379 EXISTS exercise1:test
   ```

4. Set a key with expiration:
   ```bash
   redis-cli -h localhost -p 6379 SETEX exercise1:temp "Temporary data" 60
   ```

5. Check TTL:
   ```bash
   redis-cli -h localhost -p 6379 TTL exercise1:temp
   ```

### Task 3: Cleanup
Remove the test keys:
```bash
redis-cli -h localhost -p 6379 DEL exercise1:test exercise1:temp
```

## Verification
- All commands should execute without errors
- PING should return PONG
- TTL should show decreasing values
- Keys should be successfully deleted

## Questions
1. What happens if you use the wrong port number?
2. How can you tell if Redis is not running?
3. What does TTL -1 mean?
