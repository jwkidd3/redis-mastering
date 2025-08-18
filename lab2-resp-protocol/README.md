# Lab 2: RESP Protocol for Business Data Processing

## Overview
This lab focuses on understanding and analyzing the Redis Serialization Protocol (RESP) for business data operations. You'll learn to monitor, debug, and optimize Redis communications.

## Quick Start

1. **Setup Environment**
```bash
# Start Redis
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Load sample data
./scripts/load-business-data.sh
```

2. **Start Monitoring**
```bash
# Terminal 1
redis-cli monitor

# Terminal 2 - Execute commands
redis-cli SET test "value"
```

3. **Follow Lab Instructions**
Open `lab2.md` for complete 45-minute guided exercises.

## Lab Structure

```
lab2-resp-protocol/
├── lab2.md                    # Main lab instructions
├── scripts/
│   ├── load-business-data.sh  # Sample data loader
│   └── simulate-business-load.sh # Load generator
├── docs/
│   ├── resp-reference.md      # RESP protocol guide
│   └── troubleshooting.md     # Common issues & solutions
├── protocol-samples/          # Example RESP communications
└── README.md                  # This file
```

## Learning Objectives

- Master RESP protocol structure
- Monitor real-time Redis communications
- Analyze protocol efficiency
- Debug communication issues
- Optimize command patterns

## Key Commands

- `redis-cli monitor` - Real-time protocol monitoring
- `redis-cli --latency-history` - Latency analysis
- `redis-cli SLOWLOG GET` - Slow query analysis
- `redis-cli CLIENT LIST` - Connection analysis

## Prerequisites

- Docker installed and running
- Redis CLI available
- Basic Redis command knowledge
- Completed Lab 1

## Duration

45 minutes

## Support

If you encounter issues, check `docs/troubleshooting.md` first.
