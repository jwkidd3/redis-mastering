# Mastering Redis 

## Course Overview
**Duration:** 3 Days Intensive (21 hours total)  
**Schedule:** 9:00 AM - 4:00 PM daily with 1-hour lunch break  
**Format:** 70% Hands-on Labs (15 labs), 30% Theory (9 presentations)  
**Platform:** Docker + JavaScript/Node.js + Redis Insight + Visual Studio Code  
**Target:** Software Engineers, DevOps Engineers, Data Engineers, System Administrators

---

# Daily Structure Template

Each day follows this consistent 7-hour format:

## Morning Block (3.5 hours)
- **Theory Session** (45-50 minutes)
- **Lab** (45 minutes) 
- **15-minute break**
- **Lab** (45 minutes)
- **Lab** (45 minutes)

## Lunch Break (1 hour)
- **12:00 PM - 1:00 PM**

## Afternoon Block (3.5 hours)
- **Theory Session** (40-50 minutes)
- **Lab** (45 minutes)
- **15-minute break**
- **Theory Session** (35-45 minutes)
- **Lab** (45 minutes)

---

# Day 1: Redis Fundamentals
**Focus:** Core concepts, architecture, and string operations  
**Learning Objective:** Master Redis basics and build first caching applications

## 📊 Presentation Sessions (140 minutes - 30%)

### Content1: Introduction to Redis & Architecture (50 min)
**File:** `content1.html` (reveal.js)
- What is Redis? (REmote DIctionary Server)
- NoSQL database landscape positioning
- Redis vs traditional SQL databases and other NoSQL solutions
- Performance characteristics and use cases
- Single-threaded architecture benefits and considerations
- Memory management and optimization strategies
- Client-server communication (RESP protocol)
- Redis ecosystem and community overview
- **Lab Callout Slide:** "Next: Lab 1 - Redis Environment & CLI Basics (45 minutes)"

### Content2: String Operations & Key Management (45 min)
**File:** `content2.html` (reveal.js)
- String fundamentals and binary safety
- Basic operations (SET, GET, EXISTS, DEL)
- Numeric operations (INCR, DECR, INCRBY)
- String manipulation (APPEND, GETRANGE, SETRANGE)
- Batch operations (MSET, MGET)
- Key naming best practices and patterns
- TTL and expiration strategies
- Performance considerations for string operations
- **Lab Callout Slide:** "Coming Up: Labs 2-3 - String Operations & Key Patterns (90 minutes)"

### Content3: Basic Caching & Web Integration (45 min)
**File:** `content3.html` (reveal.js)
- Introduction to caching concepts
- Cache-aside pattern implementation
- Cache invalidation strategies
- TTL management and expiration policies
- Node.js Redis client setup and best practices
- Express.js integration patterns
- Connection pooling and error handling
- Basic web application architecture with Redis
- **Lab Callout Slide:** "Ahead: Labs 4-5 - Caching & Web API Integration (90 minutes)"

## 🧪 Hands-on Labs (225 minutes - 70%)

### Lab 1: Redis Environment & CLI Basics (45 minutes)
**File:** `lab1.md`
**Objective:** Master Redis environment setup and basic command-line operations

**Activities:**
- Explore pre-configured Docker Redis environment
- Navigate Redis Insight GUI interface
- Execute basic Redis CLI commands
- Observe RESP protocol communication
- Test JavaScript client connections
- Perform basic performance benchmarking

**Key Skills:**
- Redis CLI navigation
- Redis Insight usage
- RESP protocol understanding
- Connection testing

### Lab 2: String Operations & Counters (45 minutes)
**File:** `lab2.md`
**Objective:** Implement string operations and atomic counters

**Activities:**
- Basic string CRUD operations
- Implement page view counters with INCR
- String manipulation and concatenation
- Atomic increment/decrement operations
- Batch operations with MSET/MGET

**Key Skills:**
- String operations mastery
- Atomic counter implementation
- Batch processing patterns

### Lab 3: Key Management & Patterns (45 minutes)
**File:** `lab3.md`
**Objective:** Establish key naming conventions and management strategies

**Activities:**
- Implement key naming conventions
- Pattern-based key operations
- TTL management and expiration
- Memory usage monitoring
- Key scanning and cleanup

**Key Skills:**
- Key organization strategies
- TTL management
- Memory optimization

### Lab 4: Basic Caching Implementation (45 minutes)
**File:** `lab4.md`
**Objective:** Build fundamental caching system with cache-aside pattern

**Activities:**
- Implement cache-aside pattern
- Build simple caching layer
- TTL-based expiration strategies
- Cache hit/miss monitoring
- Performance measurement

**Key Skills:**
- Cache-aside pattern
- Expiration strategies
- Performance monitoring

### Lab 5: Web API Integration (45 minutes)
**File:** `lab5.md`
**Objective:** Integrate Redis with Express.js web application

**Activities:**
- Set up Express.js application
- Integrate Redis client
- Build caching middleware
- Create basic API endpoints
- Implement error handling

**Key Skills:**
- Express.js Redis integration
- Middleware development
- API endpoint creation

---

# Day 2: Data Structures & Applications
**Focus:** Advanced data structures and complex application patterns  
**Learning Objective:** Master all Redis data structures and build real-world applications

## 📊 Presentation Sessions (140 minutes - 30%)

### Content4: Hash & List Data Structures (50 min)
**File:** `content4.html` (reveal.js)
- Hash fundamentals and field operations (HSET, HGET, HGETALL)
- Nested data modeling with hashes vs JSON strings
- Memory efficiency and performance considerations
- List operations and blocking commands (LPUSH, RPOP, BLPOP)
- Queue implementations (FIFO, LIFO)
- Producer-consumer patterns
- Advanced list operations and use cases
- **Lab Callout Slide:** "Next: Lab 6 - User Profiles with Hashes (45 minutes)"

### Content5: Set & Sorted Set Data Structures (45 min)
**File:** `content5.html` (reveal.js)
- Set operations and uniqueness guarantees
- Set arithmetic (intersection, union, difference)
- Advanced set operations and performance
- Sorted sets with scores and ranking systems
- Range queries and leaderboard patterns
- Time-based scoring and expiration
- Social network and gaming applications
- **Lab Callout Slide:** "Coming Up: Labs 8-9 - Social Features & Leaderboards (90 minutes)"

### Content6: Advanced Caching Patterns (45 min)
**File:** `content6.html` (reveal.js)
- Cache-aside, write-through, and write-behind patterns
- Multi-level caching architecture
- Cache invalidation strategies and challenges
- Performance optimization techniques
- Cache warming and preloading
- Monitoring and debugging caching systems
- Real-world caching best practices
- **Lab Callout Slide:** "Final: Lab 10 - Advanced Caching Patterns (45 minutes)"

## 🧪 Hands-on Labs (225 minutes - 70%)

### Lab 6: User Profiles with Hashes (45 minutes)
**File:** `lab6.md`
**Objective:** Build user management system using Redis hashes

**Activities:**
- User registration with hash storage
- Profile data management
- Nested preferences handling
- Bulk profile operations
- Hash field manipulation

**Key Skills:**
- Hash operations mastery
- User data modeling
- Profile management systems

### Lab 7: Message Queues with Lists (45 minutes)
**File:** `lab7.md`
**Objective:** Implement message queue system using Redis lists

**Activities:**
- Basic producer-consumer queue
- FIFO and LIFO queue patterns
- Blocking operations (BLPOP/BRPOP)
- Queue monitoring and health checks
- Error handling patterns

**Key Skills:**
- Queue implementation
- Producer-consumer patterns
- Blocking operations

### Lab 8: Social Features with Sets (45 minutes)
**File:** `lab8.md`
**Objective:** Build social networking features using Redis sets

**Activities:**
- Friend/follower relationships
- Set intersection for mutual friends
- Tag-based content discovery
- User groups and communities
- Set operations performance

**Key Skills:**
- Set operations mastery
- Social graph modeling
- Relationship management

### Lab 9: Leaderboards with Sorted Sets (45 minutes)
**File:** `lab9.md`
**Objective:** Create real-time leaderboard system with sorted sets

**Activities:**
- Gaming leaderboard implementation
- Multi-dimensional rankings
- Time-based scoring systems
- Range queries and pagination
- Real-time score updates

**Key Skills:**
- Sorted set operations
- Ranking systems
- Real-time updates

### Lab 10: Advanced Caching Patterns (45 minutes)
**File:** `lab10.md`
**Objective:** Implement sophisticated caching strategies

**Activities:**
- Multi-pattern caching system
- Cache invalidation testing
- Performance optimization
- Cache warming automation
- Advanced debugging with Redis Insight

**Key Skills:**
- Advanced caching patterns
- Performance optimization
- System debugging

---

# Day 3: Production & Advanced Topics
**Focus:** Production deployment, performance, and enterprise features  
**Learning Objective:** Deploy production-ready Redis systems with monitoring and scaling

## 📊 Presentation Sessions (140 minutes - 30%)

### Content7: Production Deployment & Security (50 min)
**File:** `content7.html` (reveal.js)
- Production deployment considerations and architecture
- Memory sizing and capacity planning strategies
- Security best practices and authentication methods
- Network security and firewall configuration
- SSL/TLS encryption setup
- Performance tuning guidelines and optimization
- Scaling patterns and load balancing
- Production troubleshooting workflows
- **Lab Callout Slide:** "Next: Lab 11 - Session Management & Security (45 minutes)"

### Content8: Persistence & High Availability (45 min)
**File:** `content8.html` (reveal.js)
- RDB snapshots: configuration, trade-offs, and optimization
- AOF (Append Only File): durability options and performance
- Hybrid persistence strategies and best practices
- Redis Sentinel for automatic failover
- Redis Cluster basics and data sharding strategies
- Backup and recovery procedures
- Disaster recovery planning
- **Lab Callout Slide:** "Coming Up: Labs 13-14 - Production Config & Monitoring (90 minutes)"

### Content9: Performance & Monitoring (45 min)
**File:** `content9.html` (reveal.js)
- Advanced performance optimization techniques
- Memory optimization and data structure selection
- Common issues and debugging tools
- Slow query analysis and optimization
- Monitoring with Redis Insight in production
- Custom metrics and alerting systems
- Microservices architecture patterns
- **Lab Callout Slide:** "Final: Lab 15 - Microservices Integration (45 minutes)"

## 🧪 Hands-on Labs (225 minutes - 70%)

### Lab 11: Session Management & Security (45 minutes)
**File:** `lab11.md`
**Objective:** Implement secure session management system

**Activities:**
- JWT-based session storage
- Token security and validation
- Session hijacking prevention
- Multi-device session handling
- Session analytics and monitoring

**Key Skills:**
- Secure session patterns
- JWT implementation
- Security best practices

### Lab 12: Rate Limiting & API Protection (45 minutes)
**File:** `lab12.md`
**Objective:** Build rate limiting and API protection systems

**Activities:**
- Token bucket rate limiting algorithm
- API quota management
- Sliding window counters
- Abuse detection and prevention
- Rate limit monitoring

**Key Skills:**
- Rate limiting algorithms
- API protection patterns
- Abuse prevention

### Lab 13: Production Configuration (45 minutes)
**File:** `lab13.md`
**Objective:** Configure Redis for production deployment

**Activities:**
- Persistence configuration (RDB + AOF)
- Memory optimization settings
- Security configuration
- Performance tuning
- Backup strategy implementation

**Key Skills:**
- Production configuration
- Performance tuning
- Backup strategies

### Lab 14: Monitoring & Health Checks (45 minutes)
**File:** `lab14.md`
**Objective:** Implement comprehensive monitoring system

**Activities:**
- Performance metrics collection
- Health check endpoints
- Alerting system setup
- Dashboard creation in Redis Insight
- Automated monitoring scripts

**Key Skills:**
- System monitoring
- Alerting implementation
- Dashboard creation

### Lab 15: Microservices Integration (45 minutes)
**File:** `lab15.md`
**Objective:** Build microservices architecture with Redis

**Activities:**
- Cross-service caching patterns
- Event-driven architecture
- Service discovery with Redis
- Distributed session sharing
- Inter-service communication

**Key Skills:**
- Microservices patterns
- Distributed architecture
- Event-driven design

---

# Course Summary

## Time Distribution

| Day | Theory | Labs | Total |
|-----|--------|------|-------|
| Day 1 | 140 min (30%) | 225 min (70%) | 365 min |
| Day 2 | 140 min (30%) | 225 min (70%) | 365 min |
| Day 3 | 140 min (30%) | 225 min (70%) | 365 min |
| **Total** | **420 min (30%)** | **675 min (70%)** | **1095 min** |

**Daily Schedule:** 6 hours 5 minutes + breaks = 7 hours total per day

## File Structure

### Presentations (Reveal.js)
- `content1.html` - Introduction to Redis & Architecture
- `content2.html` - String Operations & Key Management  
- `content3.html` - Basic Caching & Web Integration
- `content4.html` - Hash & List Data Structures
- `content5.html` - Set & Sorted Set Data Structures
- `content6.html` - Advanced Caching Patterns
- `content7.html` - Production Deployment & Security
- `content8.html` - Persistence & High Availability
- `content9.html` - Performance & Monitoring

### Labs (Markdown)
- `lab1.md` - Redis Environment & CLI Basics
- `lab2.md` - String Operations & Counters
- `lab3.md` - Key Management & Patterns
- `lab4.md` - Basic Caching Implementation
- `lab5.md` - Web API Integration
- `lab6.md` - User Profiles with Hashes
- `lab7.md` - Message Queues with Lists
- `lab8.md` - Social Features with Sets
- `lab9.md` - Leaderboards with Sorted Sets
- `lab10.md` - Advanced Caching Patterns
- `lab11.md` - Session Management & Security
- `lab12.md` - Rate Limiting & API Protection
- `lab13.md` - Production Configuration
- `lab14.md` - Monitoring & Health Checks
- `lab15.md` - Microservices Integration

## Key Requirements Met

✅ **5 labs per day maximum**  
✅ **45 minutes maximum per lab**  
✅ **70% lab time, 30% presentation time**  
✅ **Reveal.js presentations with callout slides for lab timing**  
✅ **Markdown format labs**  
✅ **Docker execution platform**  
✅ **JavaScript coding language**  
✅ **Visual Studio Code development environment**  
✅ **RESP protocol and Redis Insight integration**  
✅ **Cross-platform compatibility (Windows/Mac)**  
✅ **Professional presentation styling**  
✅ **Progressive skill building**  
✅ **Real-world application focus**

## Learning Outcomes

By the end of this course, participants will:

1. **Master Redis fundamentals** - architecture, data structures, and operations
2. **Build production applications** - caching, sessions, queues, and real-time features  
3. **Deploy Redis in production** - security, persistence, monitoring, and scaling
4. **Integrate with microservices** - distributed caching and event-driven patterns
5. **Optimize performance** - memory usage, query optimization, and troubleshooting
6. **Use modern tools** - Docker, Redis Insight, JavaScript/Node.js, and Visual Studio Code

This restructured course maintains the intensive hands-on focus while providing better pacing, clearer learning objectives, and more manageable lab sessions that build comprehensive Redis expertise from fundamentals through production deployment.


Docker command to run redis:  
docker run -d --name redis-server -p 6379:6379 redis  

docker-compose commands to run a cluster:  
TBD  
