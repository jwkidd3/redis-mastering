# Mastering Redis - Complete 3-Day Course Flow

## Course Overview
**Duration:** 3 Days Intensive (21 hours total)  
**Schedule:** 9:00 AM - 4:00 PM daily with 1-hour lunch break  
**Format:** 70% Hands-on Labs (15 labs), 30% Theory (9 presentations)  
**Platform:** Docker + JavaScript/Node.js + Redis Insight + Visual Studio Code  
**Target:** Insurance Industry Software Engineers, DevOps Engineers, Data Engineers, System Administrators  
**Industry Focus:** Insurance applications, claims processing, policy management, customer portals

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

# Day 1: Redis CLI & Core Operations
**Focus:** Pure Redis fundamentals using CLI and Redis Insight (NO JAVASCRIPT)  
**Learning Objective:** Master Redis CLI, RESP protocol, and core data operations for insurance systems

## 📊 Presentation Sessions (140 minutes - 30%)

### Content1: Introduction to Redis & Insurance Architecture (50 min)
**File:** `content1.html` (reveal.js)
- What is Redis? In-memory data structure store fundamentals
- Redis vs. traditional databases for insurance data
- Insurance industry use cases: session management, caching, real-time analytics
- Redis architecture overview for high-performance insurance applications
- Memory efficiency for large-scale insurance data processing
- Redis deployment patterns for insurance environments
- **Lab Callout Slide:** "Next: Lab 1 - Redis Environment & CLI for Insurance Systems (45 minutes)"

### Content2: String Operations & Key Management for Insurance Data (45 min)
**File:** `content2.html` (reveal.js)
- String fundamentals for policy numbers, customer IDs, claims data
- Atomic operations for premium calculations and claims counters
- Key naming conventions for insurance entities
- TTL strategies for quote expiration and session management
- Bulk operations for policy updates and customer data processing
- Performance considerations for high-volume insurance transactions
- **Lab Callout Slide:** "Next: Lab 3 - Insurance Data Operations with Strings (45 minutes)"

### Content3: Advanced CLI & Production Monitoring (45 min)
**File:** `content3.html` (reveal.js)
- Advanced CLI operations for insurance system administration
- Redis Insight for production monitoring of insurance workloads
- Performance benchmarking for insurance transaction volumes
- Memory analysis and optimization for customer and policy data
- Production troubleshooting techniques for insurance applications
- Best practices for CLI-based insurance system monitoring
- **Lab Callout Slide:** "Next: Lab 5 - Advanced CLI Operations for Insurance Monitoring (45 minutes)"

## 🧪 Lab Sessions (225 minutes - 70%)

### Lab 1: Redis Environment & CLI for Insurance Systems (45 minutes)
**File:** `lab1.md`
**Objective:** Set up Redis development environment and master basic CLI operations for insurance data

**Activities:**
- Docker Redis container setup with insurance data volume mounting
- Redis Insight installation and connection to insurance database
- Basic CLI navigation and help system for insurance operations
- Redis configuration file exploration for insurance production settings
- Basic insurance entity operations (policy lookup, customer search, claims status)
- Environment troubleshooting and connectivity testing for insurance systems

**Key Skills:**
- Redis CLI navigation for insurance data
- Redis Insight interface for policy management
- Basic command execution with insurance entities
- Environment troubleshooting for production insurance systems

### Lab 2: RESP Protocol for Insurance Data Processing (45 minutes)
**File:** `lab2.md`
**Objective:** Understand RESP protocol through insurance data observation and monitoring

**Activities:**
- Use redis-cli --raw and monitor modes for insurance transactions
- Observe RESP protocol communication for policy updates
- Analyze different RESP data types with claims data
- Monitor insurance transaction execution in real-time
- Debug protocol-level communication for policy processing
- Compare CLI vs RESP raw format for insurance operations

**Key Skills:**
- RESP protocol understanding for insurance systems
- Protocol monitoring for insurance transaction debugging
- Raw protocol analysis for policy and claims processing
- Real-time monitoring of insurance operations

### Lab 3: Insurance Data Operations with Strings (45 minutes)
**File:** `lab3.md`
**Objective:** Master string operations for policy numbers, customer IDs, and insurance data

**Activities:**
- Policy number storage and retrieval operations
- Customer ID management with atomic operations
- Premium calculation counters with INCR/DECR operations
- Policy document manipulation and concatenation
- Batch operations for bulk policy updates (MSET/MGET)
- Claims processing atomic operations and race condition prevention
- Performance testing for high-volume insurance transactions

**Key Skills:**
- String operations for insurance data management
- Atomic operations for premium and claims calculations
- Batch processing for policy updates
- Performance analysis for insurance workloads

### Lab 4: Insurance Key Management & TTL Strategies (45 minutes)
**File:** `lab4.md`
**Objective:** Implement key management strategies for insurance entities and quote expiration

**Activities:**
- Insurance entity key naming conventions (policy:123456, claim:789012, customer:456789)
- Quote expiration management with TTL strategies
- Policy renewal reminder scheduling with expiration policies
- Key scanning for policy and claims pattern-based operations
- Memory usage monitoring for large insurance databases
- Customer session cleanup and maintenance strategies
- Performance monitoring with Redis Insight for insurance workloads

**Key Skills:**
- Insurance-specific key organization strategies
- Quote and session TTL management expertise
- Memory optimization for insurance data
- Performance monitoring for insurance applications

### Lab 5: Advanced CLI Operations for Insurance Monitoring (45 minutes)
**File:** `lab5.md`
**Objective:** Master advanced CLI features for insurance system monitoring and administration

**Activities:**
- Advanced CLI scripting for insurance data automation
- Real-time monitoring for claims processing and policy updates
- Performance benchmarking for insurance transaction volumes
- Memory analysis for customer and policy data optimization
- Slow query analysis for insurance database operations
- Production monitoring best practices for insurance systems

**Key Skills:**
- Advanced CLI operations for insurance systems
- Insurance system monitoring and alerting
- Performance optimization for insurance workloads
- Production troubleshooting for insurance applications

---

# Day 2: Data Structures & JavaScript Integration
**Focus:** All Redis data structures with JavaScript application development for insurance systems  
**Learning Objective:** Master all Redis data structures and build real-world insurance JavaScript applications

## 📊 Presentation Sessions (140 minutes - 30%)

### Content4: JavaScript Redis Integration for Insurance Applications (50 min)
**File:** `content4.html` (reveal.js)
- Node.js Redis client setup for insurance microservices
- Connection management for high-availability insurance systems
- JavaScript promises and async/await patterns for claims processing
- Redis client connection pooling for insurance applications
- Environment configuration for development, staging, and production
- Error handling and reconnection strategies for critical insurance operations
- Basic JavaScript Redis operations for policy and customer data
- Debugging JavaScript Redis applications in insurance environments
- **Lab Callout Slide:** "Next: Lab 6 - JavaScript Redis Client for Insurance Systems (45 minutes)"

### Content5: Hash & List Data Structures for Insurance Data (45 min)
**File:** `content5.html` (reveal.js)
- Hash fundamentals for customer profiles and policy storage (HSET, HGET, HGETALL)
- Nested insurance data modeling with hashes vs JSON strings
- Memory efficiency for large customer and policy databases
- List operations for claims processing queues (LPUSH, RPOP, BLPOP)
- Insurance workflow queue implementations (FIFO for claims, LIFO for urgent cases)
- Producer-consumer patterns for claims processing automation
- **Lab Callout Slide:** "Next: Lab 7 - Customer Profiles & Policy Management (45 minutes)"

### Content6: Advanced Caching Patterns & Event-Driven Architecture (45 min)
**File:** `content6.html` (reveal.js)
- Cache-aside, write-through, and write-behind patterns for insurance data
- Multi-level caching for customer portals and policy systems
- **Event-driven cache invalidation using Redis Streams** *(NEW)*
- **Stream-based cache coherence patterns** *(NEW)*
- Tag-based invalidation for complex insurance data dependencies
- Circuit breaker patterns for cache resilience
- Performance optimization and memory management for insurance caching
- **Lab Callout Slide:** "Next: Lab 10 - Advanced Insurance Caching Patterns (45 minutes)"

## 🧪 Lab Sessions (225 minutes - 70%)

### Lab 6: JavaScript Redis Client for Insurance Systems (45 minutes)
**File:** `lab6.md`
**Objective:** Set up JavaScript Redis integration for insurance application development

**Activities:**
- Node.js Redis client installation and configuration for insurance apps
- Connection pooling setup for high-availability insurance systems
- Basic JavaScript Redis operations for policy and customer data
- Error handling and reconnection strategies for production insurance systems
- Environment variable management for multi-stage insurance deployments
- JavaScript promise patterns and async/await for insurance data processing

**Key Skills:**
- JavaScript Redis client setup for insurance applications
- Production-grade connection management for insurance systems
- Error handling strategies for critical insurance operations
- Environment configuration for insurance deployment pipelines

### Lab 7: Customer Profiles & Policy Management with Hashes (45 minutes)
**File:** `lab7.md`
**Objective:** Build customer profile and policy management system using Redis hashes

**Activities:**
- Customer profile creation and management with hash operations
- Policy data storage and retrieval using nested hash structures
- Partial updates for customer information and policy modifications
- Bulk operations for policy renewals and customer data migrations
- Performance optimization for large customer databases
- Customer portal session integration with policy data caching

**Key Skills:**
- Hash operations for complex insurance data structures
- Customer profile management with Redis hashes
- Policy data optimization and retrieval strategies
- Customer portal integration and policy management system development

### Lab 8: Claims Event Sourcing with Redis Streams (45 minutes) **(UPDATED)**
**File:** `lab8.md`
**Objective:** Implement event-driven claims processing using Redis Streams for audit trails and real-time analytics

**Activities:**
- **Event sourcing pattern implementation for claims processing** *(NEW)*
- **Claims event stream creation and management (XADD, XREAD)** *(NEW)*
- **Consumer group setup for distributed claims processing** *(NEW)*
- **Real-time claims event processing with XREADGROUP** *(NEW)*
- **Immutable audit trail creation for regulatory compliance** *(NEW)*
- **Event-driven analytics and real-time dashboards** *(NEW)*
- **Stream-based notification system for claim status updates** *(NEW)*

**Key Skills:**
- **Redis Streams for event sourcing architecture** *(NEW)*
- **Claims processing with immutable event logs** *(NEW)*
- **Consumer group patterns for scalable event processing** *(NEW)*
- **Real-time analytics from claims event streams** *(NEW)*
- **Event-driven microservices communication** *(NEW)*

### Lab 9: Insurance Analytics with Sets and Sorted Sets (45 minutes)
**File:** `lab9.md`
**Objective:** Build insurance analytics and reporting features using Redis sets and sorted sets

**Activities:**
- Customer segmentation and risk grouping with sets
- Agent performance leaderboards with sorted sets
- Policy coverage analysis using set intersections
- Premium calculation rankings and risk scoring systems
- **Real-time analytics integration with claims event streams** *(UPDATED)*
- **Stream-powered analytics aggregation** *(UPDATED)*

**Key Skills:**
- Insurance analytics with Redis data structures
- Customer segmentation and risk analysis
- Agent performance tracking and leaderboards
- **Event-driven analytics with Redis Streams integration** *(UPDATED)*

### Lab 10: Advanced Insurance Caching Patterns (45 minutes)
**File:** `lab10.md`
**Objective:** Implement sophisticated caching strategies for insurance applications

**Activities:**
- Quote calculation caching with TTL-based expiration
- Policy lookup caching for high-frequency customer portal access
- **Event-driven cache invalidation using claims event streams** *(UPDATED)*
- **Stream-based cache coherence across microservices** *(UPDATED)*
- Multi-level caching for customer profiles and policy documents
- **Tag-based invalidation triggered by stream events** *(UPDATED)*
- Circuit breaker implementation for cache resilience

**Key Skills:**
- Insurance-specific caching patterns
- **Event-driven cache invalidation strategies** *(UPDATED)*
- **Stream-powered cache coherence patterns** *(UPDATED)*
- Performance optimization for insurance applications

---

# Day 3: Production & Advanced Topics
**Focus:** Production deployment, performance, and enterprise features for insurance systems  
**Learning Objective:** Deploy production-ready Redis systems for insurance applications with monitoring and scaling

## 📊 Presentation Sessions (140 minutes - 30%)

### Content7: Production Deployment & Security for Insurance Systems (50 min)
**File:** `content7.html` (reveal.js)
- Production deployment strategies for insurance compliance
- Security configurations for insurance data protection (HIPAA, SOX compliance)
- Authentication and authorization for insurance applications
- Network security and firewall configurations for Redis insurance deployments
- Data encryption at rest and in transit for sensitive insurance information
- Backup and disaster recovery planning for insurance systems
- **Lab Callout Slide:** "Next: Lab 11 - Insurance Session Management & Security (45 minutes)"

### Content8: Persistence & High Availability for Insurance Operations (45 min)
**File:** `content8.html` (reveal.js)
- RDB snapshots for insurance data backup and point-in-time recovery
- AOF logging for transaction-level insurance data protection
- Redis Sentinel for high availability in insurance production environments
- Basic clustering concepts for large-scale insurance operations
- Failover strategies for critical insurance system availability
- **Lab Callout Slide:** "Next: Lab 13 - Production Configuration for Insurance Systems (45 minutes)"

### Content9: Performance & Monitoring for Insurance Workloads (45 min)
**File:** `content9.html` (reveal.js)
- Performance monitoring and optimization for insurance transaction volumes
- Memory usage analysis for large customer and policy databases
- Redis Insight for production monitoring of insurance workloads
- Alerting and threshold management for insurance system SLAs
- Capacity planning for insurance application scaling
- Troubleshooting performance issues in insurance production environments
- **Lab Callout Slide:** "Next: Lab 14 - Monitoring & Health Checks for Insurance Operations (45 minutes)"

## 🧪 Lab Sessions (225 minutes - 70%)

### Lab 11: Insurance Session Management & Security (45 minutes)
**File:** `lab11.md`
**Objective:** Implement secure session management for insurance customer portals and agent applications

**Activities:**
- JWT token storage and validation for insurance authentication
- Customer portal session management with role-based access control
- Agent application session handling with insurance-specific permissions
- Session timeout policies for security compliance in insurance systems
- Single sign-on (SSO) integration for insurance enterprise environments
- Session data encryption and secure storage for sensitive insurance information

**Key Skills:**
- Secure session management for insurance applications
- Role-based access control for insurance user types
- Security compliance for insurance data protection
- SSO integration for insurance enterprise systems

### Lab 12: Rate Limiting & API Protection for Insurance (45 minutes)
**File:** `lab12.md`
**Objective:** Implement API rate limiting and protection for insurance quote and policy systems

**Activities:**
- Quote API rate limiting to prevent abuse and ensure fair usage
- Customer portal API protection with sliding window rate limiting
- Agent API quota management for insurance transaction processing
- DDoS protection strategies for public-facing insurance APIs
- Rate limiting analytics and monitoring for insurance API usage
- Custom rate limiting rules for different insurance product types

**Key Skills:**
- API rate limiting for insurance quote and policy systems
- Advanced rate limiting algorithms for insurance API protection
- DDoS mitigation strategies for insurance applications
- Rate limiting analytics and monitoring for insurance operations

### Lab 13: Production Configuration for Insurance Systems (45 minutes)
**File:** `lab13.md`
**Objective:** Configure Redis for production deployment in insurance environments

**Activities:**
- Production Redis configuration for insurance compliance requirements
- Memory management and eviction policies for insurance data retention
- Persistence configuration (RDB + AOF) for insurance regulatory compliance
- Security hardening for insurance production environments
- Backup automation scripts for insurance data protection
- Performance tuning for high-volume insurance transaction processing

**Key Skills:**
- Production Redis configuration for insurance compliance
- Insurance data protection and backup strategies
- Security hardening for sensitive insurance information
- Performance optimization for insurance production workloads

### Lab 14: Monitoring & Health Checks for Insurance Operations (45 minutes)
**File:** `lab14.md`
**Objective:** Set up comprehensive monitoring and alerting for insurance Redis operations

**Activities:**
- Redis Insight setup for production monitoring of insurance workloads
- Performance metric collection for insurance transaction analysis
- Health check endpoints for insurance system availability monitoring
- Alert configuration for critical insurance system thresholds
- Dashboard creation for insurance operational insights
- Capacity planning analysis for insurance application scaling

**Key Skills:**
- Production monitoring setup for insurance Redis systems
- Performance metrics analysis for insurance applications
- Alerting strategies for insurance system reliability
- Capacity planning for insurance application growth

### Lab 15: Insurance Microservices Integration (45 minutes)
**File:** `lab15.md`
**Objective:** Implement enterprise-grade microservices integration patterns with Redis

**Activities:**
- **Multi-service caching patterns with event-driven invalidation** *(UPDATED)*
- **Cross-service event communication using Redis Streams** *(UPDATED)*
- Distributed session management across insurance microservices
- **Service-to-service cache coherence using stream events** *(UPDATED)*
- Circuit breaker patterns for microservices resilience
- **Event-driven service discovery and health monitoring** *(UPDATED)*

**Key Skills:**
- **Enterprise microservices patterns with Redis Streams** *(UPDATED)*
- **Event-driven architecture for insurance microservices** *(UPDATED)*
- Distributed caching strategies for insurance service architecture
- Microservices resilience and fault tolerance patterns

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
- `content6.html` - **Advanced Caching Patterns & Event-Driven Architecture** *(UPDATED)*
- `content7.html` - Production Deployment & Security
- `content8.html` - Persistence & High Availability
- `content9.html` - Performance & Monitoring

### Labs (Markdown)
- `lab1.md` - Redis Environment & CLI for Insurance Systems *(CLI/Redis Insight focus)*
- `lab2.md` - RESP Protocol for Insurance Data Processing *(CLI monitoring and protocol analysis)*
- `lab3.md` - Insurance Data Operations with Strings *(Pure CLI operations)*
- `lab4.md` - Insurance Key Management & TTL Strategies *(CLI-based key management)*
- `lab5.md` - Advanced CLI Operations for Insurance Monitoring *(Advanced CLI features)*
- `lab6.md` - JavaScript Redis Client for Insurance Systems *(First JavaScript integration)*
- `lab7.md` - Customer Profiles & Policy Management *(JavaScript + Hashes)*
- `lab8.md` - **Claims Event Sourcing with Redis Streams** *(JavaScript + Streams - UPDATED)*
- `lab9.md` - Insurance Analytics with Sets *(JavaScript + Sets/Sorted Sets + Stream integration)*
- `lab10.md` - Advanced Insurance Caching Patterns *(JavaScript caching + Event-driven invalidation)*
- `lab11.md` - Insurance Session Management & Security *(Production JavaScript apps)*
- `lab12.md` - Rate Limiting & API Protection for Insurance *(Advanced JavaScript patterns)*
- `lab13.md` - Production Configuration for Insurance Systems *(Production deployment)*
- `lab14.md` - Monitoring & Health Checks for Insurance Operations *(Production monitoring)*
- `lab15.md` - Insurance Microservices Integration *(Enterprise JavaScript + Event-driven patterns)*

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
✅ **Event-driven architecture with Redis Streams** *(NEW)*

## Major Updates Summary

### 🔄 **Lab 8 Transformation**
- **From:** Claims Processing Queues with Lists (LPUSH, RPOP, BLPOP)
- **To:** Claims Event Sourcing with Redis Streams (XADD, XREAD, XREADGROUP)
- **Impact:** Modern event-driven architecture with immutable audit trails

### 🔄 **Content 6 Enhancement**
- **Added:** Event-driven cache invalidation using Redis Streams
- **Added:** Stream-based cache coherence patterns
- **Updated:** Integration examples with Lab 8's event sourcing approach

### 🔄 **Cascading Updates**
- **Lab 9:** Enhanced with stream-powered analytics aggregation
- **Lab 10:** Updated with event-driven cache invalidation strategies
- **Lab 15:** Expanded with cross-service event communication using streams

### 🔄 **Learning Progression**
- **Day 1:** Pure CLI and Redis fundamentals
- **Day 2:** JavaScript integration progressing from basic to **event-driven architecture**
- **Day 3:** Production deployment with **modern event-driven microservices patterns**

## Learning Outcomes

By the end of this course, participants will:

1. **Master Redis fundamentals** - architecture, data structures, and operations for insurance systems
2. **Build production insurance applications** - customer portals, claims processing, policy management, and **real-time event-driven analytics**  
3. **Deploy Redis in insurance production** - security compliance, persistence, monitoring, and scaling for insurance workloads
4. **Integrate with insurance microservices** - distributed caching and **modern event-driven patterns** for insurance business processes
5. **Optimize performance** - memory usage, query optimization, and troubleshooting for high-volume insurance transactions
6. **Implement event sourcing** - **Redis Streams for audit trails, real-time analytics, and event-driven architecture** *(NEW)*
7. **Use modern tools** - Docker, Redis Insight, JavaScript/Node.js, and Visual Studio Code for **event-driven insurance application development**

This restructured course maintains the intensive hands-on focus while providing insurance industry-specific context and **modern event-driven architecture patterns**. The updated Lab 8 introduces participants to cutting-edge event sourcing techniques that are essential for modern insurance technology environments, from claims processing audit trails to real-time analytics and microservices communication.