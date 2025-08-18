# Lab 1: Redis Environment & CLI for Insurance Systems

**Duration:** 45 minutes  
**Focus:** Redis CLI, Redis Insight, and insurance data operations  
**Industry:** Insurance applications and workflows

## 📁 Project Structure

```
lab1-redis-insurance-cli/
├── lab1.md                           # Complete lab instructions (START HERE)
├── redis-insurance.conf              # Redis config optimized for insurance
├── scripts/
│   └── load-insurance-sample-data.sh # Insurance sample data loader
├── docs/
│   └── troubleshooting.md            # Troubleshooting guide
├── examples/                         # CLI command examples
├── insurance-data/                   # Sample insurance datasets
└── README.md                         # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab1.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-insurance-sample-data.sh`
4. **Test Connection:** `redis-cli ping`
5. **Open Redis Insight:** Launch from applications menu

## 🏢 Insurance Data Focus

This lab uses realistic insurance industry data:

- **Policies:** Auto, Home, Life, Renters insurance
- **Customers:** Customer profiles with contact information
- **Claims:** Various claim types with status tracking
- **Agents:** Agent performance and commission data
- **Quotes:** Temporary quotes with realistic TTL expiration
- **Metrics:** Daily counters for business operations

## 🎯 Lab Objectives

✅ Master Redis CLI navigation with insurance data  
✅ Understand RESP protocol for insurance operations  
✅ Use Redis Insight for insurance data visualization  
✅ Implement key patterns for insurance entities  
✅ Practice TTL management for quotes and sessions  
✅ Monitor performance for insurance workloads

## 📝 Key Insurance Patterns Covered

- **Policy Management:** `policy:INS001`, `policy:INS002`
- **Customer Data:** `customer:CUST001`, `customer:CUST002`
- **Claims Processing:** `claim:CLM001`, `claim:CLM002`
- **Agent Tracking:** `agent:AG001`, `agent:AG002`
- **Quote Expiration:** `quote:AUTO:Q001` (with TTL)
- **Business Metrics:** `daily:policies_created`, `premium:collected`

## 🔧 Commands Quick Reference

```bash
# Environment Setup
docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine
./scripts/load-insurance-sample-data.sh

# Basic Operations
redis-cli ping
redis-cli KEYS policy:*
redis-cli GET policy:INS001
redis-cli INCR daily:policies_created

# Monitoring
redis-cli monitor
redis-cli INFO memory
redis-cli DBSIZE
```

## 🆘 Troubleshooting

**Connection Issues:**
```bash
# Check Redis status
docker ps | grep redis
redis-cli ping

# Restart if needed
docker restart redis-insurance
```

**Data Issues:**
```bash
# Reload sample data
./scripts/load-insurance-sample-data.sh

# Verify data
redis-cli KEYS "*" | wc -l
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 🎓 Learning Path

This lab is part of the Redis for Insurance series:

1. **Lab 1:** Environment & CLI Basics ← *You are here*
2. **Lab 2:** RESP Protocol for Insurance Data
3. **Lab 3:** Insurance Data Operations with Strings
4. **Lab 4:** Insurance Key Management & TTL
5. **Lab 5:** Advanced CLI Operations for Insurance

---

**Ready to start?** Open `lab1.md` and begin exploring Redis with insurance data! 🚀
