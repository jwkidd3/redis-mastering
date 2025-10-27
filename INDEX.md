# Redis Mastering Course - Complete Index

Welcome! This file serves as your entry point to the entire Redis Mastering course repository.

## Quick Navigation

### Documentation Files
Start here to understand the course:

1. **[COURSE_OVERVIEW.md](./COURSE_OVERVIEW.md)** - Comprehensive course documentation
   - Detailed breakdown of all 15 labs
   - File structures and technologies
   - Runnable code inventory
   - Learning objectives and outcomes

2. **[LABS_QUICK_REFERENCE.md](./LABS_QUICK_REFERENCE.md)** - Quick reference guide
   - Lab overview table
   - Runnable commands by lab
   - npm scripts summary
   - Troubleshooting tips
   - Completion checklist

3. **[course_flow.md](./course_flow.md)** - Detailed course schedule
   - Day-by-day breakdown
   - Presentation schedule
   - Time distribution
   - Learning progression

### Lab Instructions
Each lab has a dedicated markdown file with full instructions:

**Day 1: CLI Only (No JavaScript)**
- [Lab 1: Redis Environment & CLI Basics](./lab1-redis-cli-basics/lab1.md)
- [Lab 2: RESP Protocol](./lab2-resp-protocol/lab2.md)
- [Lab 3: Data Operations with Strings](./lab3-data-operations-strings/lab3.md)
- [Lab 4: Key Management & TTL](./lab4-key-management-ttl/lab4.md)
- [Lab 5: Advanced CLI Operations](./lab5-advanced-cli-monitoring/lab5.md)

**Day 2: JavaScript Integration**
- [Lab 6: JavaScript Redis Client](./lab6-javascript-redis-client/lab6.md)
- [Lab 7: Customer Profiles & Hashes](./lab7-customer-policy-hashes/lab7.md)
- [Lab 8: Claims Event Sourcing (Streams)](./lab8-claims-event-sourcing/lab8.md)
- [Lab 9: Insurance Analytics](./lab9-sets-analytics/lab9.md)
- [Lab 10: Advanced Caching Patterns](./lab10-advanced-caching-patterns/lab10.md)

**Day 3: Production & Advanced**
- [Lab 11: Session Management & Security](./lab11-session-management/lab11.md)
- [Lab 12: Rate Limiting & API Protection](./lab12-rate-limiting-api-protection/lab12.md)
- [Lab 13: Production Configuration](./lab13-production-configuration/lab13.md)
- [Lab 14: Production Monitoring](./lab14-production-monitoring/lab14.md)
- [Lab 15: Redis Cluster HA](./lab15-redis-cluster-ha/lab15.md)

### Presentation Slides
Reveal.js presentations for theory sessions:

- `content1_presentation.html` - Introduction to Redis & Architecture
- `content2_presentation.html` - String Operations & Key Management
- `content3_presentation.html` - Advanced CLI & Production Monitoring
- `content4_presentation.html` - JavaScript Redis Integration
- `content5.html` - Hash & List Data Structures
- `content6-presentation.html` - Advanced Caching & Event-Driven Architecture
- `content7_presentation.html` - Production Deployment & Security
- `content8_presentation.html` - Persistence & High Availability
- `content9_presentation.html` - Performance & Monitoring
- `lab15-presentation.html` - Clustering & High Availability

## By Topic

### Redis Data Structures
- **Strings** → Lab 3
- **Hashes** → Lab 7
- **Lists** → Lab 6 (basics), Lab 8 (with streams)
- **Sets** → Lab 9
- **Sorted Sets** → Lab 9
- **Streams** → Lab 8 (primary focus)

### Use Cases
- **Event Sourcing** → Lab 8
- **Session Management** → Lab 11
- **Rate Limiting** → Lab 12
- **Caching** → Lab 10
- **Analytics** → Lab 9
- **Clustering** → Lab 15

### Technology Stacks
- **CLI/Bash** → Labs 1-5, 13, 15
- **JavaScript/Node.js** → Labs 6-15
- **Docker** → Labs 6, 15
- **Express.js** → Lab 12, 14
- **Redis Insight** → All labs

### Production Topics
- **Persistence** → Lab 13
- **High Availability** → Lab 13, 15
- **Security** → Lab 11, 13
- **Monitoring** → Lab 5, 14
- **Backups** → Lab 13, 15
- **Clustering** → Lab 15

## Course Statistics

- **Total Duration:** 21 hours (3 days)
- **Labs:** 15 (675 minutes)
- **Presentations:** 9 (420 minutes)
- **Lab Type:** 70% hands-on, 30% theory
- **Primary Languages:** JavaScript/Node.js + Bash
- **Docker Environments:** 6+ configurations

## Getting Started

### For First-Time Users
1. Read `COURSE_OVERVIEW.md` for complete context
2. Check `LABS_QUICK_REFERENCE.md` for command examples
3. Start with Lab 1 in `lab1-redis-cli-basics/`

### For Specific Topics
Use the "By Topic" section above to jump to relevant labs

### For Quick Commands
See `LABS_QUICK_REFERENCE.md` for runnable commands by lab

## Key Features

### Event-Driven Architecture (Lab 8)
The course features modern event-driven patterns using Redis Streams:
```bash
npm run producer          # Submit claims
npm run consumer          # Process events
npm run analytics         # Real-time dashboard
```

### Production-Grade Cluster (Lab 15)
6-node Redis Cluster with automatic sharding and failover:
```bash
docker compose up
./scripts/init-cluster.sh
npm run monitor
```

### Insurance Industry Focus
All examples use insurance domain concepts:
- Customers, Policies, Claims
- Premium calculations
- Real-time analytics
- Compliance and audit trails

## Repository Structure

```
redis-mastering/
├── INDEX.md                          # This file
├── COURSE_OVERVIEW.md                # Complete documentation
├── LABS_QUICK_REFERENCE.md           # Quick reference guide
├── course_flow.md                    # Course schedule
├── content[1-9]*.html                # Presentation slides
│
├── lab[1-5]-*-cli-*/                 # Day 1: CLI-only labs
├── lab[6-10]-*-javascript-*/         # Day 2: JavaScript labs
└── lab[11-15]-*-production-*/        # Day 3: Production labs

Each lab contains:
  ├── lab*.md                         # Lab instructions
  ├── scripts/                        # Executable scripts
  ├── src/                            # Source code (if JavaScript)
  ├── config/                         # Configuration files
  ├── tests/                          # Test suites
  ├── examples/                       # Example implementations
  ├── docs/                           # Additional documentation
  └── package.json                    # Node.js config (if applicable)
```

## Common Tasks

### Run a Lab
```bash
cd lab8-claims-event-sourcing
npm install
npm run validate
npm run load-data
npm run producer        # Terminal 1
npm run consumer        # Terminal 2
npm run analytics       # Terminal 3
```

### Setup Production Configuration
```bash
cd lab13-production-configuration
./scripts/validate-production-config.sh
./scripts/backup-insurance-redis.sh
./scripts/health-check.sh
```

### Initialize Redis Cluster
```bash
cd lab15-redis-cluster-ha
npm install
docker compose up
./scripts/init-cluster.sh
npm run test-sharding
```

### View Comprehensive Documentation
```bash
# Full course overview
cat COURSE_OVERVIEW.md

# Quick reference
cat LABS_QUICK_REFERENCE.md

# Specific lab instructions
cat lab8-claims-event-sourcing/lab8.md
```

## Support Resources

### Documentation
- Each lab includes detailed instructions in `lab*.md`
- Architecture documentation in `docs/` directories
- Code examples in `examples/` directories
- Reference implementations in `reference/` directories

### Tools
- **Redis Insight** - GUI for all labs
- **redis-cli** - Command-line interface
- **Docker Compose** - Containerized environments
- **Node.js** - JavaScript runtime

### Troubleshooting
See `LABS_QUICK_REFERENCE.md` for:
- Connection troubleshooting
- Node.js issues
- Docker issues
- Common error solutions

## Course Learning Path

1. **Master Fundamentals** (Day 1 - 225 min)
   - CLI operations and RESP protocol
   - String operations and key management
   - Advanced monitoring techniques

2. **Build Applications** (Day 2 - 225 min)
   - JavaScript integration
   - Data structures (hashes, lists, sets, streams)
   - Event-driven architecture
   - Caching patterns

3. **Go Production** (Day 3 - 225 min)
   - Session management and security
   - API protection and rate limiting
   - Production configuration
   - Monitoring and clustering

## Contact & Versions

- **Course Version:** 3.0 (Event-Driven Architecture Enhanced)
- **Last Updated:** October 26, 2024
- **Redis Version:** 7.0+
- **Node.js Version:** 18.0+
- **Docker:** Latest stable

---

**Ready to get started?** 

Start with [COURSE_OVERVIEW.md](./COURSE_OVERVIEW.md) for a comprehensive understanding, then jump to any lab using the links above!
