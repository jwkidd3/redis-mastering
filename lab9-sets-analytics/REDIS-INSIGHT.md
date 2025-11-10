# Lab 9: Insurance Analytics - Redis Insight Workbench Commands

This guide contains all Redis commands for Lab 9 (Sets & Sorted Sets Analytics) that can be executed directly in **Redis Insight Workbench**.

## 🚀 Overview

This lab uses **Sets** for customer segmentation and **Sorted Sets** for risk scoring and leaderboards. All commands can be run in Redis Insight Workbench!

---

## Part 1: Customer Segmentation with Sets

### Create Customer Segments

```redis
// Premium customers
SADD customers:premium C001 C002 C003 C004 C005

// High-risk customers
SADD customers:high_risk C002 C005 C007 C008

// Standard customers
SADD customers:standard C006 C009 C010 C011

// Young drivers (under 25)
SADD customers:young_driver C003 C007 C012

// Senior drivers (65+)
SADD customers:senior C001 C006 C013
```

### Query Segments

```redis
// Check if customer is premium
SISMEMBER customers:premium C001
SISMEMBER customers:premium C999

// Get all premium customers
SMEMBERS customers:premium

// Count customers in each segment
SCARD customers:premium
SCARD customers:high_risk
SCARD customers:standard

// Check all segments a customer belongs to
SISMEMBER customers:premium C002
SISMEMBER customers:high_risk C002
SISMEMBER customers:young_driver C002
```

---

## Part 2: Set Operations (Analytics)

### Find Overlaps (Intersection)

```redis
// Premium customers who are also high-risk
SINTER customers:premium customers:high_risk

// Young drivers who are premium
SINTER customers:young_driver customers:premium

// Count high-risk premium customers
SINTERCARD 2 customers:premium customers:high_risk
```

**Expected Output:**
```
1) "C002"
2) "C005"
(integer) 2
```

### Combine Segments (Union)

```redis
// All premium or standard customers
SUNION customers:premium customers:standard

// All customers (all segments)
SUNION customers:premium customers:standard customers:high_risk

// Count unique customers across segments
SUNIONSTORE temp:all_customers customers:premium customers:standard
SCARD temp:all_customers
DEL temp:all_customers
```

### Find Differences (Diff)

```redis
// Premium customers who are NOT high-risk (safe premium)
SDIFF customers:premium customers:high_risk

// High-risk customers who are NOT premium
SDIFF customers:high_risk customers:premium

// Standard customers who are NOT young drivers
SDIFF customers:standard customers:young_driver
```

**Expected Output:**
```
1) "C001"
2) "C003"
3) "C004"
```

---

## Part 3: Risk Scoring with Sorted Sets

### Add Customers with Risk Scores

```redis
// Add customers with risk scores (0-100)
ZADD risk:scores 25 "CUST001" 85 "CUST002" 45 "CUST003"
ZADD risk:scores 92 "CUST004" 15 "CUST005" 68 "CUST006"
ZADD risk:scores 73 "CUST007" 38 "CUST008" 55 "CUST009"
ZADD risk:scores 88 "CUST010"

// Check total customers in leaderboard
ZCARD risk:scores
```

**Expected Output:**
```
(integer) 3
(integer) 3
(integer) 3
(integer) 1
(integer) 10
```

### Query Risk Leaderboard (Highest Risk First)

```redis
// Top 5 highest risk customers
ZREVRANGE risk:scores 0 4 WITHSCORES

// Top 10 highest risk
ZREVRANGE risk:scores 0 9 WITHSCORES

// Bottom 5 (lowest risk)
ZRANGE risk:scores 0 4 WITHSCORES

// Get specific customer's score
ZSCORE risk:scores "CUST002"
ZSCORE risk:scores "CUST005"
```

**Expected Output:**
```
 1) "CUST004"
 2) "92"
 3) "CUST010"
 4) "88"
 5) "CUST002"
 6) "85"
 7) "CUST007"
 8) "73"
 9) "CUST006"
10) "68"
"85"
"15"
```

### Risk Range Queries

```redis
// Find all low-risk customers (score 0-30)
ZRANGEBYSCORE risk:scores 0 30 WITHSCORES

// Find all medium-risk customers (score 31-70)
ZRANGEBYSCORE risk:scores 31 70 WITHSCORES

// Find all high-risk customers (score 71-100)
ZRANGEBYSCORE risk:scores 71 100 WITHSCORES

// Count customers in each range
ZCOUNT risk:scores 0 30      // Low risk
ZCOUNT risk:scores 31 70     // Medium risk
ZCOUNT risk:scores 71 100    // High risk
```

**Expected Output:**
```
1) "CUST005"
2) "15"
3) "CUST001"
4) "25"
1) "CUST008"
2) "38"
...
(integer) 2
(integer) 4
(integer) 4
```

### Customer Rankings

```redis
// Get customer's rank (lowest risk = rank 0)
ZRANK risk:scores "CUST005"    // Should be 0 (lowest)
ZRANK risk:scores "CUST004"    // Should be 9 (highest)

// Get customer's reverse rank (highest risk = rank 0)
ZREVRANK risk:scores "CUST004"  // Should be 0 (highest)
ZREVRANK risk:scores "CUST005"  // Should be 9 (lowest)
```

**Expected Output:**
```
(integer) 0
(integer) 9
(integer) 0
(integer) 9
```

### Update Risk Scores

```redis
// Increase risk score (accident reported)
ZINCRBY risk:scores 10 "CUST001"
ZSCORE risk:scores "CUST001"   // Should be 35 now

// Decrease risk score (safe driving bonus)
ZINCRBY risk:scores -5 "CUST002"
ZSCORE risk:scores "CUST002"   // Should be 80 now

// Set new score (replace existing)
ZADD risk:scores 50 "CUST003"
ZSCORE risk:scores "CUST003"   // Should be 50 now
```

---

## Part 4: Premium Calculation with Sorted Sets

### Policy Premiums Leaderboard

```redis
// Add policies with annual premiums
ZADD premiums:auto 1200 "POL001" 1800 "POL002" 950 "POL003"
ZADD premiums:auto 2500 "POL004" 1100 "POL005" 3200 "POL006"

// Find top 3 highest premiums
ZREVRANGE premiums:auto 0 2 WITHSCORES

// Find policies with premium $1000-$2000
ZRANGEBYSCORE premiums:auto 1000 2000 WITHSCORES

// Calculate total premium revenue
// Note: Redis doesn't have SUM, but you can see all values
ZRANGE premiums:auto 0 -1 WITHSCORES
```

---

## Part 5: Claims Frequency with Sorted Sets

### Track Claim Counts

```redis
// Add customers with claim counts
ZADD claims:count 0 "CUST001" 2 "CUST002" 1 "CUST003"
ZADD claims:count 5 "CUST004" 0 "CUST005" 3 "CUST006"

// Find customers with most claims
ZREVRANGE claims:count 0 4 WITHSCORES

// Find customers with NO claims
ZRANGEBYSCORE claims:count 0 0 WITHSCORES

// Find customers with 3+ claims
ZRANGEBYSCORE claims:count 3 100 WITHSCORES

// Increment claim count (new claim filed)
ZINCRBY claims:count 1 "CUST001"
ZSCORE claims:count "CUST001"
```

---

## Part 6: Complex Analytics

### Combine Sets and Sorted Sets

```redis
// First, create segments
SADD segment:premium C001 C002 C003
SADD segment:high_risk C002 C004 C005

// Get premium customers list
SMEMBERS segment:premium

// Check their risk scores
ZSCORE risk:scores "CUST001"
ZSCORE risk:scores "CUST002"
ZSCORE risk:scores "CUST003"

// Find premium customers who are low risk (manual query)
// 1. Get premium customers: SMEMBERS segment:premium
// 2. For each, check: ZSCORE risk:scores "CUST..."
// 3. Filter where score < 40
```

### Customer 360 View

```redis
// For a specific customer, get all data:
SET customer:C001:name "John Smith"
SET customer:C001:age 35
SADD segment:premium C001
ZADD risk:scores 25 "C001"
ZADD premiums:auto 1200 "C001"
ZADD claims:count 0 "C001"

// Query all data for customer C001
GET customer:C001:name
GET customer:C001:age
SISMEMBER segment:premium C001
ZSCORE risk:scores "C001"
ZSCORE premiums:auto "C001"
ZSCORE claims:count "C001"
```

---

## 🎓 Exercises

### Exercise 1: Market Segmentation

```redis
// 1. Create customer segments
SADD customers:premium C001 C002 C003 C004 C005
SADD customers:standard C006 C007 C008 C009 C010
SADD customers:high_risk C002 C003 C007 C011
SADD customers:commercial C012 C013 C014

// 2. Find premium high-risk customers
SINTER customers:premium customers:high_risk

// 3. Find standard customers who are NOT high-risk
SDIFF customers:standard customers:high_risk

// 4. Count total unique customers
SUNIONSTORE temp:all customers:premium customers:standard customers:commercial
SCARD temp:all
DEL temp:all
```

### Exercise 2: Risk Analysis

```redis
// 1. Add 10 customers with risk scores
ZADD risk:scores 15 "C001" 45 "C002" 78 "C003" 92 "C004" 23 "C005"
ZADD risk:scores 67 "C006" 34 "C007" 88 "C008" 55 "C009" 12 "C010"

// 2. Find top 3 highest risk
ZREVRANGE risk:scores 0 2 WITHSCORES

// 3. Count customers by risk level
ZCOUNT risk:scores 0 30      // Low
ZCOUNT risk:scores 31 70     // Medium
ZCOUNT risk:scores 71 100    // High

// 4. Update risk scores (simulate incidents)
ZINCRBY risk:scores 15 "C001"   // Accident
ZINCRBY risk:scores -10 "C004"  // Safe driving reward
```

### Exercise 3: Premium Leaderboard

```redis
// 1. Add policies with premiums
ZADD premiums:all 1200 "AUTO001" 1800 "AUTO002" 3500 "HOME001"
ZADD premiums:all 950 "AUTO003" 2200 "HOME002" 4500 "LIFE001"

// 2. Find highest premium policies
ZREVRANGE premiums:all 0 2 WITHSCORES

// 3. Find affordable policies (< $2000)
ZRANGEBYSCORE premiums:all 0 2000 WITHSCORES

// 4. Count policies by price range
ZCOUNT premiums:all 0 1500
ZCOUNT premiums:all 1501 3000
ZCOUNT premiums:all 3001 10000
```

---

## 🔍 Using Browser Tab for Visualization

After creating sets and sorted sets:

1. **Switch to Browser Tab**
2. **Find your keys:**
   - `customers:premium` → Type: set
   - `risk:scores` → Type: zset (sorted set)
3. **Click on a set:**
   - See all members
   - Add/remove members through GUI
4. **Click on a sorted set:**
   - See members with scores
   - Sorted by score automatically
   - Edit scores through GUI

---

## ✅ Lab Completion Checklist

Using Redis Insight Workbench:

- [ ] Created multiple customer segment sets
- [ ] Used SINTER to find overlapping segments
- [ ] Used SUNION to combine segments
- [ ] Used SDIFF to find exclusive segments
- [ ] Created risk scoring sorted set
- [ ] Queried top/bottom risk customers
- [ ] Filtered customers by risk range
- [ ] Updated risk scores with ZINCRBY
- [ ] Created premium leaderboard
- [ ] Visualized data in Browser tab
- [ ] Completed all exercises

---

## 🎯 Key Redis Commands Used

### Set Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `SADD` | Add members to set | `SADD key member1 member2` |
| `SMEMBERS` | Get all members | `SMEMBERS key` |
| `SISMEMBER` | Check membership | `SISMEMBER key member` |
| `SCARD` | Count members | `SCARD key` |
| `SINTER` | Intersection | `SINTER key1 key2` |
| `SUNION` | Union | `SUNION key1 key2` |
| `SDIFF` | Difference | `SDIFF key1 key2` |

### Sorted Set Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `ZADD` | Add with score | `ZADD key score member` |
| `ZRANGE` | Get by rank (asc) | `ZRANGE key 0 10 WITHSCORES` |
| `ZREVRANGE` | Get by rank (desc) | `ZREVRANGE key 0 10 WITHSCORES` |
| `ZRANGEBYSCORE` | Get by score range | `ZRANGEBYSCORE key 0 50` |
| `ZSCORE` | Get member's score | `ZSCORE key member` |
| `ZRANK` | Get rank (asc) | `ZRANK key member` |
| `ZREVRANK` | Get rank (desc) | `ZREVRANK key member` |
| `ZINCRBY` | Increment score | `ZINCRBY key amount member` |
| `ZCOUNT` | Count in range | `ZCOUNT key min max` |
| `ZCARD` | Total members | `ZCARD key` |

---

## 💡 Tips

1. **Use WITHSCORES** to see both members and their scores
2. **ZREVRANGE** for "top N" queries (leaderboards)
3. **ZRANGEBYSCORE** for "show me customers with score X-Y"
4. **SINTER** for "customers who are BOTH premium AND high-risk"
5. **SDIFF** for "customers who are premium but NOT high-risk"
6. **Browser Tab** to visualize sets and sorted sets graphically

---

## 📚 Next Steps

- Practice segmentation with larger datasets
- Combine sets and sorted sets for complex analytics
- Use sorted sets for any ranking/leaderboard scenario
- Explore Redis Insight's visual set operations
