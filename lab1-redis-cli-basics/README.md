# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes  
**Focus:** Remote Redis connection and basic CLI operations  
**Platform:** Redis CLI + Redis Insight (remote server access)

## 🏗️ Project Structure

```
lab1-redis-cli-basics/
├── lab1.md                           # Complete lab instructions (START HERE)
├── reference/
│   └── basic-commands.md            # Redis commands reference
├── examples/
│   ├── getting-started.sh           # Practical examples script
│   └── connection-examples.md       # Connection scenarios
├── docs/
│   └── troubleshooting.md          # Comprehensive troubleshooting
└── README.md                        # This file
```

## 🚀 Quick Start

1. **Get server details from instructor:**
   - Hostname (e.g., `redis-server.training.com`)
   - Port (usually `6379`)
   - Password (if required)

2. **Test connection:**
   ```bash
   redis-cli -h [hostname] -p [port] PING
   ```

3. **Follow lab instructions:**
   Open `lab1.md` for complete guidance

4. **Configure Redis Insight:**
   Add database connection with provided details

## 📋 Prerequisites

- **Redis CLI installed** on your machine
- **Redis Insight installed** and ready
- **Network access** to training Redis server
- **Basic command-line knowledge**
- **Connection details** from instructor

## 🎯 Learning Objectives

After completing this lab, you will:
- **Connect to remote Redis** using host parameters
- **Execute basic commands** with proper syntax
- **Navigate Redis Insight** for data visualization
- **Understand Redis fundamentals** through hands-on practice
- **Use both CLI and GUI tools** effectively

## 🔧 Key Commands Learned

### Connection
```bash
redis-cli -h hostname -p port PING              # Test connection
redis-cli -h hostname -p port                   # Interactive session
redis-cli -h hostname -p port -a password       # With authentication
```

### Basic Operations
```bash
SET key value                    # Store data
GET key                         # Retrieve data
EXISTS key                      # Check existence
INCR counter                    # Increment number
KEYS pattern                    # Find keys
INFO server                     # Server information
```

## 📊 What You'll Practice

- **Remote connections** with host parameters
- **String operations** for data storage
- **Numeric operations** for counters
- **Key management** with TTL and expiration
- **Information commands** for server stats
- **GUI navigation** in Redis Insight

## 🆘 Troubleshooting

Common issues and solutions:

1. **Connection failed:** Check hostname, port, and network
2. **Authentication required:** Use `-a password` parameter
3. **Command not found:** Verify Redis CLI installation
4. **Timeout:** Check network connectivity and server status

See `docs/troubleshooting.md` for detailed solutions.

## 📖 Reference Materials

- **`reference/basic-commands.md`** - Complete command reference
- **`examples/connection-examples.md`** - Connection scenarios
- **`examples/getting-started.sh`** - Practical examples script
- **`docs/troubleshooting.md`** - Problem-solving guide

## 🏁 Success Criteria

By the end of this lab, you should:
- [ ] Successfully connect to Redis server via CLI
- [ ] Execute basic string and numeric operations
- [ ] Configure and use Redis Insight GUI
- [ ] Understand host parameter syntax
- [ ] Be comfortable with fundamental Redis commands

## ⏭️ Next Steps

**Lab 2 Preview:** Advanced RESP protocol monitoring and performance analysis

This gentle introduction builds foundation skills for more advanced Redis operations in subsequent labs.

## 💡 Quick Tips

- **Always use your server hostname** instead of localhost
- **Keep interactive sessions open** for easier command execution
- **Use Redis Insight browser** to visualize your data
- **Check TTL regularly** to understand key expiration
- **Ask instructor** if connection issues persist

## 🌟 Key Takeaway

Redis CLI with host parameters (`-h` and `-p`) allows you to connect to any Redis server from any location - this is fundamental for real-world Redis usage!
