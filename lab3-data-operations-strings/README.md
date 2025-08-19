# Lab 3: Data Operations with Strings

**Duration:** 45 minutes  
**Focus:** Advanced string operations for policy management and premium calculations  
**Industry:** Data processing and customer management workflows

## 📁 Project Structure

```
lab3-data-operations-strings/
├── lab3.md                                # Complete lab instructions (START HERE)
├── scripts/
│   └── load-sample-data.sh               # Comprehensive data loader
├── docs/
│   ├── string-operations-reference.md    # Redis string operations reference
│   └── troubleshooting.md                # String operations troubleshooting
├── examples/
│   └── practical-examples.md             # Practical string examples
├── performance-tests/
│   └── string-operations-performance.sh  # Performance testing scripts
├── sample-data/                          # Sample data directory
└── README.md                             # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab3.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-lab3 -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-sample-data.sh`
4. **Test Connection:** `redis-cli ping`
5. **Follow Lab Exercises:** Execute string operations for data management

## 🎯 Lab Objectives

✅ Master policy number generation and validation using Redis strings  
✅ Perform atomic premium calculations with string numeric operations  
✅ Manage customer data efficiently with string concatenation and manipulation  
✅ Build document processing workflows with string operations  
✅ Optimize batch operations for policy updates and customer management  
✅ Implement race condition prevention for financial calculations

## 🏢 Data Focus

This lab uses comprehensive industry data optimized for string operations:

- **Policy Management:** Auto, Home, Life policy creation and updates
- **Customer Profiles:** Comprehensive customer information management
- **Premium Calculations:** Atomic financial operations and adjustments
- **Document Assembly:** Policy documents and email template processing
- **Activity Logging:** Customer interaction tracking and audit trails
- **Financial Reporting:** Daily revenue tracking and business metrics

## 🔧 Key String Operations Covered

```bash
# Policy Number Generation
INCR policy:counter:auto                    # Atomic counter
SET policy:AUTO-100001 "policy_data"        # Structured storage

# Premium Calculations  
INCRBY premium:AUTO-100001 150              # Risk adjustments
DECRBY premium:AUTO-100001 50               # Discounts

# Customer Data Management
APPEND customer:CUST001 " | Risk Score: 750" # Profile updates
MGET customer:CUST001 customer:CUST002      # Batch retrieval

# Document Assembly
APPEND document:AUTO-100001 "COVERAGE: Full Coverage Auto Policy\n"

# Financial Operations
INCRBY revenue:daily:2024-08-18 1200        # Revenue tracking
```

## 📊 Sample Data Highlights

The lab includes realistic data:

- **6 Comprehensive Policies:** AUTO-100001, AUTO-100002, HOME-200001, HOME-200002, LIFE-300001, LIFE-300002
- **6 Customer Profiles:** CUST001-CUST006 with complete contact and risk information
- **Premium Data:** Individual premiums with atomic calculation support
- **Document Fragments:** Policy coverage, exclusions, and terms sections
- **Activity Logs:** Customer interaction tracking with timestamps
- **Financial Metrics:** Revenue tracking and business intelligence data

## ⚡ Performance Testing

Run performance tests to compare different string operation patterns:

```bash
# Execute performance test suite
./performance-tests/string-operations-performance.sh

# Individual vs batch operations comparison
# Policy number generation performance
# Premium calculation efficiency
# Memory usage analysis
```

## 🆘 Troubleshooting

**Atomic Operations:**
```bash
# Test atomic operations
redis-cli INCR test:counter
redis-cli MULTI
redis-cli INCR premium:test
redis-cli EXEC
```

**String Length Issues:**
```bash
# Check string sizes
redis-cli STRLEN policy:AUTO-100001
redis-cli MEMORY USAGE customer:CUST001
```

**Numeric Operations:**
```bash
# Verify numeric values
redis-cli GET premium:AUTO-100001
redis-cli INCR premium:AUTO-100001
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 📚 Learning Resources

- **String Operations Reference:** `docs/string-operations-reference.md`
- **Practical Examples:** `examples/practical-examples.md`
- **Performance Testing:** `performance-tests/string-operations-performance.sh`
- **Troubleshooting Guide:** `docs/troubleshooting.md`

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. **Lab 1:** Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis
3. **Lab 3:** Data Operations with Strings ← *You are here*
4. **Lab 4:** Key Management & TTL Strategies
5. **Lab 5:** Advanced CLI Operations & Monitoring

## 🏆 Key Achievements

By completing this lab, you will have mastered:

- **Atomic Operations:** Race-condition-safe premium calculations
- **Policy Management:** Structured policy number generation and storage
- **Customer Data:** Efficient profile management with string manipulation
- **Document Processing:** Dynamic document assembly workflows
- **Financial Operations:** Daily revenue tracking and business metrics
- **Performance Optimization:** Batch operations vs individual commands

---

**Ready to start?** Open `lab3.md` and begin mastering Redis string operations for data management applications! 🚀
