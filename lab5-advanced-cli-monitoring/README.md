# Lab 5: Advanced CLI Operations & Monitoring

**Duration:** 45 minutes  
**Focus:** Advanced Redis CLI mastery and production operations  
**Platform:** Docker + Redis CLI + Redis Insight  
**Learning Objective:** Master advanced CLI features, monitoring, and production-ready operations

## 🎯 Overview

This is the final Day 1 lab focusing on advanced Redis CLI operations, comprehensive monitoring, and production-ready operational procedures. **NO JAVASCRIPT** - pure CLI and Redis Insight focus.

## 🐧 WSL Ubuntu Quick Start

**If you're using WSL Ubuntu:**

```bash
# One-command setup (recommended)
./quick-start.sh

# Or manual setup
./setup-wsl.sh
docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine
./scripts/load-production-data.sh
```

## 📋 Prerequisites

- Docker installed and running
- Redis Insight installed
- Completion of Labs 1-4
- Basic understanding of Redis CLI operations

## 🚀 Quick Start

1. **Start Redis:**
   ```bash
   docker run -d --name redis-lab5 -p 6379:6379 -v redis-lab5-data:/data redis:7-alpine redis-server --appendonly yes
   ```

2. **Load Production Data:**
   ```bash
   ./scripts/load-production-data.sh
   ```

3. **Start Monitoring:**
   ```bash
   ./scripts/production-monitor.sh
   ```

4. **Open Redis Insight:**
   - Connect to localhost:6379
   - Explore the comprehensive dataset

## 🔧 WSL Troubleshooting

If you encounter "file not found" errors:

```bash
# Run troubleshooting script
./troubleshoot-wsl.sh

# Manual fixes
sudo apt install -y redis-tools bc dos2unix
chmod +x scripts/*.sh
dos2unix scripts/*.sh
```

## 📂 Project Structure

```
lab5-advanced-cli-monitoring/
├── lab5.md                      📋 Complete lab instructions
├── setup-wsl.sh                 🐧 WSL Ubuntu setup
├── quick-start.sh               🚀 One-command setup
├── troubleshoot-wsl.sh          🔧 WSL troubleshooting
├── scripts/
│   ├── load-production-data.sh     📊 Data loader
│   ├── production-monitor.sh       📊 Real-time monitoring
│   └── [other scripts]             🛠️ Additional tools
├── monitoring/                  📊 Generated logs and alerts
├── analysis/                    📈 Generated reports
└── README.md                    📖 This file
```

## 🧪 Available Scripts

```bash
# WSL setup and troubleshooting
./setup-wsl.sh                   # Setup WSL environment
./quick-start.sh                 # One-command lab start
./troubleshoot-wsl.sh            # Diagnose WSL issues

# Lab operations
./scripts/load-production-data.sh    # Load sample data
./scripts/production-monitor.sh      # Real-time monitoring
```

## 🎓 Learning Outcomes

After completing Lab 5, you will have mastered:

- ✅ **Advanced CLI Operations** for production systems
- ✅ **Comprehensive Monitoring** and alerting
- ✅ **Redis Insight Mastery** for analysis and troubleshooting
- ✅ **Production Automation** and maintenance procedures
- ✅ **WSL Ubuntu Compatibility** for development environments

## 🏆 Day 1 Completion

**Congratulations!** Lab 5 completes Day 1 of the Redis Mastery course:

### ✅ Day 1 Labs Completed:
1. **Lab 1:** Redis Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis
3. **Lab 3:** Data Operations with Strings
4. **Lab 4:** Key Management & TTL Strategies
5. **Lab 5:** Advanced CLI Operations & Monitoring ← **Current**

### 🚀 Next: Day 2 - JavaScript Integration
- **Lab 6:** JavaScript Redis Client
- **Lab 7:** Customer Profiles & Policy Management with Hashes
- **Lab 8:** Claims Processing Queues with Lists
- **Lab 9:** Analytics with Sets and Sorted Sets
- **Lab 10:** Advanced Caching Patterns

---

**Excellent work completing Day 1! Redis CLI mastery achieved. Ready for JavaScript integration in Day 2! 🚀**
