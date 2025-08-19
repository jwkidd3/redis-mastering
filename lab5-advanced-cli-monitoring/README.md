# Lab 5: Advanced CLI Operations & Monitoring

**Duration:** 45 minutes  
**Platform:** Docker + Redis CLI + Redis Insight  
**WSL Ubuntu Compatible:** ✅

## 🐧 WSL Ubuntu Quick Start

**Run this first if using WSL Ubuntu:**

```bash
# Setup WSL environment
./setup-wsl.sh

# Start Redis
docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine

# Load data
./scripts/load-production-data.sh

# Start monitoring
./scripts/production-monitor.sh
```

## 📂 Project Structure

```
lab5-advanced-cli-monitoring/
├── lab5.md                      📋 Lab instructions
├── setup-wsl.sh                 🐧 WSL setup
├── scripts/
│   ├── load-production-data.sh     📊 Data loader
│   ├── production-monitor.sh       📊 Real-time monitoring
│   ├── performance-analysis.sh     ⚡ Performance testing
│   ├── health-report.sh            🏥 Health diagnostics
│   ├── capacity-planning.sh        📈 Capacity planning
│   └── check-alerts.sh             🚨 Alert checking
├── monitoring/                  📊 Logs and alerts
├── analysis/                    📈 Generated reports
└── docs/                        📚 Troubleshooting
```

## 🛠️ Available Commands

```bash
# WSL setup
./setup-wsl.sh                      # Fix WSL environment

# Data and monitoring
./scripts/load-production-data.sh    # Load sample data
./scripts/production-monitor.sh      # Real-time dashboard
./scripts/performance-analysis.sh    # Performance testing
./scripts/health-report.sh           # Health diagnostics
./scripts/capacity-planning.sh       # Capacity planning
./scripts/check-alerts.sh            # Check alerts
```

## 🔧 Troubleshooting

### Script won't run
```bash
chmod +x scripts/*.sh
sed -i 's/\r$//' scripts/*.sh
```

### Redis not found
```bash
sudo apt install redis-tools
```

### Docker issues
1. Start Docker Desktop
2. Enable WSL integration
3. Test: `docker ps`

## 🎯 Learning Objectives

- ✅ Advanced CLI operations
- ✅ Production monitoring
- ✅ Performance analysis
- ✅ Capacity planning
- ✅ Alert systems
- ✅ WSL compatibility

---

**Ready for Day 2 JavaScript integration! 🚀**
