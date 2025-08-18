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
- What is Redis? (REmote DIctionary Server)
- Redis in insurance technology stack positioning
- Redis vs traditional SQL databases for insurance workloads
- Performance characteristics for claims processing and policy management
- Single-threaded architecture benefits for insurance transactions
- Memory management for customer data and policy caching
- Client-server communication (RESP protocol introduction)
- Insurance industry Redis use cases: session management, rate limiting, caching
- **Lab Callout Slide:** "Next: Lab 1 - Redis Environment & CLI Basics (45 minutes)"

### Content2: RESP Protocol & CLI for Insurance Data (45 min)
**File:** `content2.html` (reveal.js)
- RESP (Redis Serialization Protocol) deep dive
- Protocol data types: Simple Strings, Errors, Integers, Bulk Strings, Arrays
- Command structure for insurance data operations
- Redis CLI advanced features for policy and claims data
- Monitoring insurance system performance with CLI tools
- Redis Insight interface for insurance data visualization
- Performance monitoring for high-volume insurance transactions
- **Lab Callout Slide:** "Coming Up: Labs 2-3 - RESP Protocol & Insurance Data Operations (90 minutes)"

### Content3: Core Data Structures for Insurance Systems (45 min)
**File:** `content3.html` (reveal.js)
- String fundamentals for policy numbers and customer IDs
- Basic operations for insurance data (SET, GET, EXISTS, DEL)
- Numeric operations for premiums, deductibles, and claim amounts (INCR, DECR, INCRBY)
- String manipulation for policy document processing (APPEND, GETRANGE, SETRANGE)
- Batch operations for bulk policy updates (MSET, MGET)
- Key naming conventions for insurance entities (policies, claims, customers)
- TTL strategies for temporary insurance quotes and sessions
- Memory optimization for large policy databases
- **Lab Callout Slide:** "Final: Labs 4-5 - Insurance Data Management & Monitoring (90 minutes)"

## 🧪 Hands-on Labs (225 minutes - 70%)

### Lab 1: Redis Environment & CLI for Insurance Systems (45 minutes)
**File:** `lab1.md`
**Objective:** Master Redis environment setup and basic CLI navigation for insurance applications

**Activities:**
- Explore pre-configured Docker Redis environment for insurance workloads
- Navigate Redis Insight GUI with insurance data samples
- Execute basic Redis CLI commands with policy and claims data
- Test connection and basic operations with customer information
- Explore CLI help for insurance-specific command patterns
- Basic troubleshooting for insurance system connectivity

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
- Producer-consumer patterns for claims processing and underwriting
- Advanced list operations for insurance document processing workflows
- **Lab Callout Slide:** "Coming Up: Labs 7-8 - Customer Profiles & Claims Processing (90 minutes)"

### Content6: Set & Sorted Set Applications for Insurance Analytics (45 min)
**File:** `content6.html` (reveal.js)
- Set operations for policy coverage uniqueness and validation
- Set arithmetic for risk assessment and coverage analysis (intersection, union, difference)
- Advanced set operations for fraud detection and customer segmentation
- Sorted sets for agent performance rankings and premium calculations
- Range queries for risk scoring and policy pricing tiers
- Time-based scoring for claims urgency and processing priority
- Insurance analytics: customer lifetime value, risk scoring, agent leaderboards
- **Lab Callout Slide:** "Final: Labs 9-10 - Insurance Analytics & Advanced Patterns (90 minutes)"

## 🧪 Hands-on Labs (225 minutes - 70%)

### Lab 6: JavaScript Redis Client for Insurance Systems (45 minutes)
**File:** `lab6.md`
**Objective:** Establish JavaScript Redis development environment for insurance applications

**Activities:**
- Set up Node.js Redis client for insurance microservices environment
- Create connection management utilities for insurance system reliability
- Implement basic CRUD operations for policies, claims, and customers in JavaScript
- Error handling and connection testing for production insurance systems
- Environment configuration for insurance development and production
- Performance testing JavaScript operations with insurance data volumes

**Key Skills:**
- JavaScript Redis client setup for insurance systems
- Connection management for high-availability insurance applications
- Basic operations for insurance entities in JavaScript
- Error handling patterns for critical insurance operations

### Lab 7: Customer Profiles & Policy Management with Hashes (45 minutes)
**File:** `lab7.md`
**Objective:** Build customer and policy management system using Redis hashes

**Activities:**
- Customer registration and profile storage with comprehensive insurance data
- Policy creation and management with coverage details and premium information
- Nested customer preferences and insurance history handling
- Bulk policy operations for renewals and updates
- Hash field manipulation for claims history and risk assessment data

**Key Skills:**
- Hash operations for customer and policy data management
- Insurance data modeling with Redis hashes
- Customer and policy management system development

### Lab 8: Claims Processing Queues with Lists (45 minutes)
**File:** `lab8.md`
**Objective:** Implement claims processing and workflow system using Redis lists

**Activities:**
- Claims submission queue implementation with priority handling
- FIFO processing for standard claims, priority queues for urgent cases
- Blocking operations for real-time claims processing (BLPOP/BRPOP)
- Claims workflow monitoring and status tracking
- Error handling and dead letter queues for failed claim processing

**Key Skills:**
- Claims processing queue implementation
- Insurance workflow management with Redis lists
- Priority-based claims processing
- Real-time claims monitoring

### Lab 9: Insurance Analytics with Sets and Sorted Sets (45 minutes)
**File:** `lab9.md`
**Objective:** Build insurance analytics and reporting features using Redis sets and sorted sets

**Activities:**
- Customer segmentation and risk grouping with sets
- Agent performance leaderboards with sorted sets
- Policy coverage analysis using set intersections
- Premium calculation rankings and risk scoring systems
- Real-time insurance analytics dashboards and reporting

**Key Skills:**
- Insurance analytics with Redis data structures
- Customer segmentation and risk analysis
- Agent performance tracking and leaderboards
- Real-time insurance reporting systems

### Lab 10: Advanced Insurance Caching Patterns (45 minutes)
**File:** `lab10.md`
**Objective:** Implement sophisticated caching strategies for insurance applications

**Activities:**
- Quote calculation caching with TTL-based expiration
- Policy lookup caching for high-frequency customer portal access
- Claims processing cache-aside patterns for database offloading
- Multi-level caching for customer profiles and policy documents
- Cache invalidation strategies for policy updates and claims processing

**Key Skills:**
- Insurance-specific caching patterns
- Quote and policy caching optimization
- Claims processing performance optimization
- Insurance system cache management

---

# Day 3: Production & Advanced Topics
**Focus:** Production deployment, performance, and enterprise features for insurance systems  
**Learning Objective:** Deploy production-ready Redis systems for insurance applications with monitoring and scaling

## 📊 Presentation Sessions (140 minutes - 30%)

### Content7: Production Deployment & Security for Insurance Systems (50 min)
**File:** `content7.html` (reveal.js)
- Production deployment considerations for insurance application architecture
- Memory sizing and capacity planning for insurance data volumes
- Security best practices for sensitive insurance data and PII protection
- Network security and firewall configuration for insurance compliance
- SSL/TLS encryption setup for insurance data transmission
- Performance tuning guidelines for high-volume insurance transactions
- Scaling patterns and load balancing for insurance microservices
- Insurance industry compliance and Redis deployment (HIPAA, SOX, data residency)
- **Lab Callout Slide:** "Next: Lab 11 - Insurance Session Management & Security (45 minutes)"

### Content8: Persistence & High Availability for Insurance Operations (45 min)
**File:** `content8.html` (reveal.js)
- RDB snapshots: configuration and trade-offs for insurance data backup
- AOF (Append Only File): durability options for critical insurance transactions
- Hybrid persistence strategies for insurance business continuity
- Redis Sentinel for automatic failover in insurance systems
- Redis Cluster basics and data sharding for large insurance databases
- Backup and recovery procedures for insurance data protection
- Disaster recovery planning for insurance business continuity
- **Lab Callout Slide:** "Coming Up: Labs 13-14 - Insurance Production Config & Monitoring (90 minutes)"

### Content9: Performance & Monitoring for Insurance Applications (45 min)
**File:** `content9.html` (reveal.js)
- Advanced performance optimization for insurance transaction volumes
- Memory optimization for customer and policy data structures
- Common issues and debugging tools for insurance systems
- Slow query analysis for insurance database operations
- Monitoring with Redis Insight for insurance production environments
- Custom metrics and alerting for insurance business operations
- Microservices architecture patterns for insurance applications
- **Lab Callout Slide:** "Final: Lab 15 - Insurance Microservices Integration (45 minutes)"

## 🧪 Hands-on Labs (225 minutes - 70%)

### Lab 11: Insurance Session Management & Security (45 minutes)
**File:** `lab11.md`
**Objective:** Implement secure session management for insurance customer portal

**Activities:**
- Basic JWT session storage for customer portal login
- Session TTL configuration for insurance security requirements
- Simple role-based access (customer vs agent) validation
- Session cleanup and logout functionality
- Basic security monitoring for failed login attempts

**Key Skills:**
- Basic JWT session patterns for insurance
- Session TTL management for security
- Simple role-based access control

### Lab 12: Rate Limiting for Insurance APIs (45 minutes)
**File:** `lab12.md`
**Objective:** Implement basic rate limiting for insurance quote requests

**Activities:**
- Simple token bucket rate limiting for quote API
- Basic API quota tracking per customer
- Rate limit counter implementation with INCR
- Simple abuse detection with threshold alerts
- Rate limit status reporting and monitoring

**Key Skills:**
- Basic rate limiting implementation
- API quota management
- Simple abuse detection patterns

### Lab 13: Basic Production Configuration (45 minutes)
**File:** `lab13.md`
**Objective:** Configure Redis for basic production deployment

**Activities:**
- Enable RDB persistence for insurance data backup
- Configure basic AOF for transaction logging
- Set memory limits and eviction policies
- Configure basic authentication
- Simple backup script creation

**Key Skills:**
- Basic persistence configuration
- Memory management settings
- Simple backup strategies

### Lab 14: Insurance System Monitoring (45 minutes)
**File:** `lab14.md`
**Objective:** Set up basic monitoring for insurance Redis operations

**Activities:**
- Configure Redis Insight for production monitoring
- Set up basic performance metric collection
- Create simple health check endpoints
- Monitor key insurance metrics (policy lookups, claim submissions)
- Set up basic alerting for critical thresholds

**Key Skills:**
- Basic Redis monitoring setup
- Performance metrics collection
- Simple health checks

### Lab 15: Simple Insurance Microservices Pattern (45 minutes)
**File:** `lab15.md`
**Objective:** Implement basic cross-service caching pattern

**Activities:**
- Set up simple policy service with Redis caching
- Implement basic claims service with shared session
- Create simple service-to-service cache invalidation
- Basic event notification between services
- Simple service discovery pattern with Redis

**Key Skills:**
- Basic microservices caching patterns
- Simple cross-service communication
- Basic event-driven patterns

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
- `lab1.md` - Redis Environment & CLI for Insurance Systems *(CLI/Redis Insight focus)*
- `lab2.md` - RESP Protocol for Insurance Data Processing *(CLI monitoring and protocol analysis)*
- `lab3.md` - Insurance Data Operations with Strings *(Pure CLI operations)*
- `lab4.md` - Insurance Key Management & TTL Strategies *(CLI-based key management)*
- `lab5.md` - Advanced CLI Operations for Insurance Monitoring *(Advanced CLI features)*
- `lab6.md` - JavaScript Redis Client for Insurance Systems *(First JavaScript integration)*
- `lab7.md` - Customer Profiles & Policy Management *(JavaScript + Hashes)*
- `lab8.md` - Claims Processing Queues *(JavaScript + Lists)*
- `lab9.md` - Insurance Analytics with Sets *(JavaScript + Sets/Sorted Sets)*
- `lab10.md` - Advanced Insurance Caching Patterns *(JavaScript caching strategies)*
- `lab11.md` - Insurance Session Management & Security *(Production JavaScript apps)*
- `lab12.md` - Rate Limiting & API Protection for Insurance *(Advanced JavaScript patterns)*
- `lab13.md` - Production Configuration for Insurance Systems *(Production deployment)*
- `lab14.md` - Monitoring & Health Checks for Insurance Operations *(Production monitoring)*
- `lab15.md` - Insurance Microservices Integration *(Enterprise JavaScript patterns)*

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

1. **Master Redis fundamentals** - architecture, data structures, and operations for insurance systems
2. **Build production insurance applications** - customer portals, claims processing, policy management, and real-time analytics  
3. **Deploy Redis in insurance production** - security compliance, persistence, monitoring, and scaling for insurance workloads
4. **Integrate with insurance microservices** - distributed caching and event-driven patterns for insurance business processes
5. **Optimize performance** - memory usage, query optimization, and troubleshooting for high-volume insurance transactions
6. **Use modern tools** - Docker, Redis Insight, JavaScript/Node.js, and Visual Studio Code for insurance application development

This restructured course maintains the intensive hands-on focus while providing insurance industry-specific context, use cases, and real-world scenarios that insurance technology professionals will encounter in their daily work. From customer portal session management to claims processing queues, participants will build practical skills directly applicable to insurance technology environments.