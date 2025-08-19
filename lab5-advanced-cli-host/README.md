# Lab 5: Advanced CLI Operations with Client-Side Host Parameter

## 🎯 Overview

Master Redis CLI operations using client-side host parameters. Learn to specify Redis server connection details with each command using `-h` (host) and `-p` (port) parameters.

## ⚙️ Key Concept

This lab focuses on **client-side configuration** - you specify the Redis server details with each `redis-cli` command:

```bash
redis-cli -h <hostname> -p <port> <command>
```

**No Docker setup required** - you'll connect to an existing Redis server using connection details provided by your instructor.

## 🚀 Quick Start

1. **Get Redis server details from your instructor**
   - Hostname (e.g., `localhost`, `redis.company.com`)
   - Port (e.g., `6379`, `6380`)
   - Password (if required)

2. **Test connection:**
   ```bash
   redis-cli -h [hostname] -p [port] PING
   ```

3. **Open lab instructions:**
   ```bash
   code lab5.md
   ```

## 📁 Lab Structure

```
lab5-advanced-cli-host/
├── lab5.md                              📋 Complete lab instructions
├── examples/                            
│   ├── basic-host-examples.sh           💡 Basic connection examples
│   ├── business-operations-examples.sh  💼 Business scenario examples
│   └── output-formats-examples.sh       📊 Different output formats
├── reference/
│   ├── host-parameter-reference.md      📚 Complete parameter reference
│   └── common-commands-with-host.md     📖 Command examples
├── exercises/
│   ├── exercise1-basic-connections.md   🏋️ Basic connection practice
│   ├── exercise2-business-data.md       💼 Business operations practice
│   └── exercise3-monitoring.md          📊 Monitoring and performance
└── README.md                            📖 This file
```

## 🎯 Learning Objectives

- **Master host parameter syntax:** `-h hostname -p port`
- **Client-side connection management:** Specify server details per command
- **Flexible Redis connections:** Connect to any Redis server
- **Production scenarios:** Authentication, timeouts, error handling
- **Performance monitoring:** Latency testing and analysis
- **Redis Insight integration:** Configure GUI with connection details

## 💡 Key Commands Pattern

```bash
# Basic pattern
redis-cli -h <host> -p <port> <command>

# Examples
redis-cli -h localhost -p 6379 PING
redis-cli -h redis.company.com -p 6379 INFO server
redis-cli -h 10.0.1.100 -p 6380 KEYS "*"

# With authentication
redis-cli -h secure-redis.com -p 6379 -a password PING

# With timeouts
redis-cli -h remote-server.com -p 6379 --connect-timeout 10 PING
```

## 🔧 Quick Examples

```bash
# Run basic examples (update host/port in script first)
npm run examples-basic

# Run business operations examples  
npm run examples-business

# Run output format examples
npm run examples-formats
```

## 📚 Reference Materials

- `reference/host-parameter-reference.md` - Complete parameter guide
- `reference/common-commands-with-host.md` - Command examples
- `examples/` - Practical working examples
- `exercises/` - Structured practice exercises

## 🏋️ Practice Exercises

1. **Exercise 1:** Basic connections and data operations
2. **Exercise 2:** Business scenarios (customers, orders, analytics)  
3. **Exercise 3:** Monitoring and performance analysis

## ⚠️ Important Notes

- **No Docker setup required** - connects to existing Redis server
- **Update examples** - Replace `localhost:6379` with your server details
- **Ask instructor** - Get correct hostname and port for your environment
- **Practice authentication** - If server requires password

## 🔍 Troubleshooting

1. **Connection refused:** Check hostname and port
2. **Timeout:** Use `--connect-timeout` for slow networks
3. **Authentication:** Use `-a password` if required
4. **DNS issues:** Try IP address instead of hostname

## 🎯 Key Skills Developed

✅ **Client-side host configuration**  
✅ **Flexible Redis server connections**  
✅ **Production connection handling**  
✅ **Performance monitoring techniques**  
✅ **Error handling and troubleshooting**  
✅ **Redis Insight GUI integration**  

## 📝 Before You Start

1. Get Redis server connection details from instructor
2. Test basic connectivity: `redis-cli -h [host] -p [port] PING`
3. Update examples with your server details
4. Open `lab5.md` and begin!

## 🏆 Success Criteria

By the end of this lab, you should be able to:
- Connect to any Redis server using host parameters
- Handle connection errors gracefully
- Monitor Redis performance effectively
- Configure Redis Insight with connection details
- Use different output formats for various needs

Ready to master Redis CLI host parameters? Start with `lab5.md`!
