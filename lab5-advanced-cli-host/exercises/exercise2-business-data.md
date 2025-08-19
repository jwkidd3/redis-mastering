# Exercise 2: Business Data Operations with Host Parameters

## Objective
Practice real business scenarios using Redis with host parameters.

## Instructions

**Note:** Replace `localhost:6379` with your Redis server details.

### Task 1: Customer Management
1. Create a customer profile:
   ```bash
   redis-cli -h localhost -p 6379 HSET customer:EX001 name "Exercise Customer"
   redis-cli -h localhost -p 6379 HSET customer:EX001 email "customer@example.com"
   redis-cli -h localhost -p 6379 HSET customer:EX001 tier "premium"
   redis-cli -h localhost -p 6379 HSET customer:EX001 balance "5000"
   ```

2. Retrieve customer information:
   ```bash
   redis-cli -h localhost -p 6379 HGETALL customer:EX001
   redis-cli -h localhost -p 6379 HGET customer:EX001 tier
   ```

3. Update customer balance:
   ```bash
   redis-cli -h localhost -p 6379 HSET customer:EX001 balance "5500"
   ```

### Task 2: Order Processing
1. Add orders to processing queue:
   ```bash
   redis-cli -h localhost -p 6379 LPUSH orders:exercise "EX-ORDER-001"
   redis-cli -h localhost -p 6379 LPUSH orders:exercise "EX-ORDER-002"
   redis-cli -h localhost -p 6379 LPUSH orders:exercise "EX-ORDER-003"
   ```

2. Check queue status:
   ```bash
   redis-cli -h localhost -p 6379 LLEN orders:exercise
   redis-cli -h localhost -p 6379 LRANGE orders:exercise 0 -1
   ```

3. Process an order (move from queue):
   ```bash
   redis-cli -h localhost -p 6379 LPOP orders:exercise
   ```

### Task 3: Analytics
1. Create customer scores:
   ```bash
   redis-cli -h localhost -p 6379 ZADD exercise:scores 100 "EX001" 150 "EX002" 200 "EX003"
   ```

2. Get top customers:
   ```bash
   redis-cli -h localhost -p 6379 ZREVRANGE exercise:scores 0 -1 WITHSCORES
   ```

3. Get specific customer score:
   ```bash
   redis-cli -h localhost -p 6379 ZSCORE exercise:scores "EX001"
   ```

### Task 4: Session Management
1. Create user sessions:
   ```bash
   redis-cli -h localhost -p 6379 SETEX session:EX123 1800 "user:EX001"
   redis-cli -h localhost -p 6379 SETEX session:EX456 3600 "user:EX002"
   ```

2. Check active sessions:
   ```bash
   redis-cli -h localhost -p 6379 KEYS "session:*"
   redis-cli -h localhost -p 6379 TTL session:EX123
   ```

### Task 5: Cleanup
Remove all exercise data:
```bash
redis-cli -h localhost -p 6379 DEL customer:EX001
redis-cli -h localhost -p 6379 DEL orders:exercise
redis-cli -h localhost -p 6379 DEL exercise:scores
redis-cli -h localhost -p 6379 DEL session:EX123 session:EX456
```

## Verification Checklist
- [ ] Customer profile created successfully
- [ ] Customer data retrieved correctly
- [ ] Orders added to queue
- [ ] Order processed (removed from queue)
- [ ] Analytics scores created and retrieved
- [ ] Sessions created with proper TTL
- [ ] All data cleaned up

## Challenge Questions
1. How would you get all customers with "premium" tier?
2. What command would show all orders in the queue without removing them?
3. How can you increase a customer's score by 50 points?
