# Lab 4: Insurance Key Management & TTL Strategies

**Duration:** 45 minutes  
**Focus:** Advanced key organization patterns and TTL-based expiration strategies  
**Industry:** Insurance key management and session optimization

## 📁 Project Structure

```
lab4-insurance-key-management-ttl/
├── lab4.md                              # Complete lab instructions (START HERE)
├── scripts/
│   └── load-key-management-data.sh      # Comprehensive key management sample data
├── docs/
│   ├── key-patterns-reference.md        # Insurance key patterns and TTL reference
│   └── troubleshooting.md               # Key management troubleshooting guide
├── examples/
│   └── key-management-examples.md       # Practical key management examples
├── monitoring-tools/
│   └── key-ttl-monitor.sh               # TTL monitoring and analysis tool
├── key-patterns/                        # Key organization templates
├── sample-data/                         # Sample data directory
└── README.md                            # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab4.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-insurance-lab4 -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-key-management-data.sh`
4. **Test Connection:** `redis-cli ping`
5. **Monitor TTL:** `./monitoring-tools/key-ttl-monitor.sh`

## 🎯 Lab Objectives

✅ Design and implement insurance-specific key naming conventions  
✅ Create hierarchical key patterns for policy, customer, and claims organization  
✅ Implement sophisticated quote expiration management with TTL strategies  
✅ Build customer session management and cleanup automation  
✅ Monitor key expiration patterns and optimize memory usage  
✅ Apply key organization best practices for large-scale insurance databases

## 🗝️ Key Management Focus Areas

### **Hierarchical Key Organization:**
- **Policy Keys:** `policy:{type}:{number}:{attribute}`
- **Customer Keys:** `customer:{id}:{attribute}`
- **Claims Keys:** `claim:{id}:{attribute}`
- **Agent Keys:** `agent:{id}:{attribute}`

### **TTL Strategies by Business Function:**
- **Auto Quotes:** 5-minute TTL (quick decisions)
- **Home Quotes:** 10-minute TTL (property evaluation)
- **Life Quotes:** 30-minute TTL (medical considerations)
- **Customer Sessions:** 30-minute TTL (security balance)
- **Agent Sessions:** 8-hour TTL (work day duration)

### **Temporal Data Management:**
- **Daily Metrics:** 24-hour TTL with automatic cleanup
- **Weekly Reports:** 7-day TTL for business analysis
- **Monthly Data:** 30-day TTL for trend analysis
- **Security Events:** Variable TTL based on severity

## 🔧 Key Commands for Lab 4

```bash
# Hierarchical Key Creation
SET policy:auto:100001:details "policy_data"
SET policy:auto:100001:customer "CUST001"
SET customer:CUST001:profile "customer_data"

# TTL Management
SETEX quote:auto:Q001 300 "5-minute auto quote"
SETEX quote:home:Q001 600 "10-minute home quote"
SETEX quote:life:Q001 1800 "30-minute life quote"

# Session Management
SETEX session:customer:CUST001:portal 1800 "30-min session"
SETEX session:agent:AG001:workstation 28800 "8-hour session"

# TTL Monitoring
TTL quote:auto:Q001
KEYS policy:auto:*
SCAN 0 MATCH "customer:*" COUNT 10
```

## 📊 Sample Data Highlights

The lab includes comprehensive key management data:

- **Hierarchical Policies:** 6 policies with complete attribute breakdown
- **Customer Profiles:** 6 customers with full relationship mapping
- **Claims Data:** 2 claims with lifecycle progression examples
- **Active Quotes:** Multiple quote types with business-appropriate TTL
- **Session Management:** Customer, agent, and mobile sessions
- **Temporal Metrics:** Daily, weekly, and monthly data with TTL
- **Security Features:** Failed logins, password resets, and lockouts

## 🔍 Monitoring and Analysis

### TTL Distribution Monitoring
```bash
# Run comprehensive TTL analysis
./monitoring-tools/key-ttl-monitor.sh

# Continuous monitoring
./monitoring-tools/key-ttl-monitor.sh --watch

# Key pattern analysis
redis-cli KEYS "policy:*" | wc -l
redis-cli KEYS "quote:*" | wc -l
redis-cli KEYS "session:*" | wc -l
```

### Memory Optimization
```bash
# Check memory usage by pattern
redis-cli --bigkeys

# Compare storage methods
redis-cli MEMORY USAGE policy:auto:100001:details
redis-cli MEMORY USAGE customer:CUST001:profile

# Monitor memory trends
redis-cli INFO memory | grep used_memory_human
```

## 🆘 Troubleshooting

**TTL Issues:**
```bash
# Check TTL behavior
redis-cli SETEX test:ttl 60 "test"
redis-cli TTL test:ttl

# Monitor expiration events
redis-cli CONFIG SET notify-keyspace-events Ex
redis-cli PSUBSCRIBE '__keyevent@0__:expired'
```

**Key Pattern Issues:**
```bash
# Verify patterns
redis-cli KEYS "policy:*" | head -5
redis-cli SCAN 0 MATCH "customer:*" COUNT 10

# Check relationships
redis-cli GET policy:auto:100001:customer
redis-cli EXISTS customer:CUST001:profile
```

**Memory Usage:**
```bash
# Monitor memory
redis-cli INFO memory | grep used_memory_human
redis-cli --bigkeys | grep string
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 📚 Learning Resources

- **Key Patterns Reference:** `docs/key-patterns-reference.md`
- **Practical Examples:** `examples/key-management-examples.md`
- **TTL Monitoring Tool:** `monitoring-tools/key-ttl-monitor.sh`
- **Troubleshooting Guide:** `docs/troubleshooting.md`

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. **Lab 1:** Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis
3. **Lab 3:** Insurance Data Operations with Strings
4. **Lab 4:** Key Management & TTL Strategies ← *You are here*
5. **Lab 5:** Advanced CLI Operations & Monitoring

## 🏆 Key Achievements

By completing this lab, you will have mastered:

- **Hierarchical Organization:** Insurance-specific key naming conventions
- **TTL Strategies:** Business-appropriate expiration management
- **Session Management:** Secure and efficient user session handling
- **Memory Optimization:** Efficient key organization for large datasets
- **Lifecycle Management:** Key transitions through business processes
- **Production Monitoring:** TTL analysis and key health monitoring

---

**Ready to start?** Open `lab4.md` and begin mastering Redis key management for insurance applications! 🚀
