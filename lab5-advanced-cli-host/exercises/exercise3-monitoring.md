# Exercise 3: Monitoring and Performance with Host Parameters

## Objective
Learn to monitor Redis performance and analyze operations using host parameters.

## Instructions

**Note:** Replace `localhost:6379` with your Redis server details.

### Task 1: Server Information
1. Get comprehensive server information:
   ```bash
   redis-cli -h localhost -p 6379 INFO server
   redis-cli -h localhost -p 6379 INFO memory
   redis-cli -h localhost -p 6379 INFO stats
   ```

2. Check specific metrics:
   ```bash
   redis-cli -h localhost -p 6379 INFO stats | grep instantaneous_ops_per_sec
   redis-cli -h localhost -p 6379 INFO memory | grep used_memory_human
   redis-cli -h localhost -p 6379 INFO clients | grep connected_clients
   ```

### Task 2: Performance Testing
1. Create test data for performance analysis:
   ```bash
   redis-cli -h localhost -p 6379 EVAL "
   for i=1,1000 do
     redis.call('SET', 'perf:test:' .. i, 'value' .. i)
   end
   return 'Created 1000 keys'
   " 0
   ```

2. Test latency (run for 10 seconds, then press Ctrl+C):
   ```bash
   redis-cli -h localhost -p 6379 --latency
   ```

3. Check slow queries:
   ```bash
   redis-cli -h localhost -p 6379 SLOWLOG LEN
   redis-cli -h localhost -p 6379 SLOWLOG GET 5
   ```

### Task 3: Key Analysis
1. Count keys by pattern:
   ```bash
   redis-cli -h localhost -p 6379 KEYS "perf:test:*" | wc -l
   ```

2. Check database size:
   ```bash
   redis-cli -h localhost -p 6379 DBSIZE
   ```

3. Sample key types:
   ```bash
   redis-cli -h localhost -p 6379 TYPE perf:test:1
   redis-cli -h localhost -p 6379 TYPE perf:test:100
   ```

### Task 4: Real-time Monitoring
1. Start monitoring (run in background for 30 seconds):
   ```bash
   timeout 30s redis-cli -h localhost -p 6379 MONITOR &
   MONITOR_PID=$!
   ```

2. Generate activity:
   ```bash
   redis-cli -h localhost -p 6379 SET monitor:test1 "activity1"
   redis-cli -h localhost -p 6379 INCR monitor:counter
   redis-cli -h localhost -p 6379 LPUSH monitor:list "item1" "item2"
   redis-cli -h localhost -p 6379 HSET monitor:hash field1 "value1"
   ```

3. Wait for monitoring to complete (30 seconds)

### Task 5: Output Formats
1. Test different output formats:
   ```bash
   # Default format
   redis-cli -h localhost -p 6379 HSET format:test name "Test User" age "25"
   redis-cli -h localhost -p 6379 HGETALL format:test
   
   # CSV format
   redis-cli -h localhost -p 6379 --csv HGETALL format:test
   
   # Raw format
   redis-cli -h localhost -p 6379 --raw HGET format:test name
   ```

### Task 6: Cleanup
Remove performance test data:
```bash
redis-cli -h localhost -p 6379 EVAL "
local keys = redis.call('KEYS', 'perf:test:*')
for i=1,#keys do
  redis.call('DEL', keys[i])
end
return 'Deleted ' .. #keys .. ' keys'
" 0

redis-cli -h localhost -p 6379 DEL monitor:test1 monitor:counter monitor:list monitor:hash format:test
```

## Analysis Questions
1. What was the average latency to your Redis server?
2. How many operations per second is your Redis server handling?
3. What's the current memory usage?
4. Were there any slow queries detected?

## Performance Observations
Record your findings:
- Latency: _____ ms
- Memory usage: _____ MB
- Operations/sec: _____
- Connected clients: _____
- Slow queries: _____

## Bonus Challenge
Create a simple performance report using multiple INFO commands and format the output for easy reading.
