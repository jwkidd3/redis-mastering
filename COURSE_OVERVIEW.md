# Redis Mastering Course - Comprehensive Repository Overview

## Course Summary
- **Duration:** 3 Days Intensive (21 hours total)
- **Format:** 70% Hands-on Labs (15 labs), 30% Theory (9 presentations)
- **Platform:** Docker + JavaScript/Node.js + Redis Insight + Visual Studio Code
- **Industry Focus:** Insurance applications, claims processing, policy management
- **Target Audience:** Insurance software engineers, DevOps engineers, data engineers, system administrators

---

## Course Organization

### Presentation Sessions (9 Total)
**Reveal.js HTML Presentations:**
- `content1_presentation.html` - Introduction to Redis & Insurance Architecture (50 min)
- `content2_presentation.html` - String Operations & Key Management (45 min)
- `content3_presentation.html` - Advanced CLI & Production Monitoring (45 min)
- `content4_presentation.html` - JavaScript Redis Integration (50 min)
- `content5.html` - Hash & List Data Structures (45 min)
- `content6-presentation.html` - Advanced Caching Patterns & Event-Driven Architecture (45 min)
- `content7_presentation.html` - Production Deployment & Security (50 min)
- `content8_presentation.html` - Persistence & High Availability (45 min)
- `content9_presentation.html` - Performance & Monitoring (45 min)

---

## Laboratory Structure (15 Labs)

### DAY 1: Redis CLI & Core Operations (No JavaScript)

#### **Lab 1: Redis Environment & CLI Basics** (45 min)
**Location:** `/lab1-redis-cli-basics/`

**Objective:** Connect to Redis server and master basic CLI operations

**Files & Scripts:**
- `lab1.md` - Complete lab instructions
- `setup-lab.sh` - Environment setup script
- `test-lab.sh` - Testing and validation script
- `examples/getting-started.sh` - Getting started examples
- `docs/` - Additional documentation
- `reference/basic-commands.md` - Redis command reference

**Key Topics:**
- Docker Redis container setup
- Redis Insight installation and configuration
- Basic CLI navigation and help system
- Insurance-specific entity operations (policy lookup, customer search, claims status)

**Runnable Components:**
- Shell scripts for environment verification
- Redis CLI commands for data operations
- Redis Insight GUI connection testing

---

#### **Lab 2: RESP Protocol for Insurance Data Processing** (45 min)
**Location:** `/lab2-resp-protocol/`

**Objective:** Understand RESP protocol through insurance data observation and monitoring

**Files:**
- `lab2.md` - Protocol analysis exercises

**Key Topics:**
- RESP protocol structure and data types
- Protocol-level communication monitoring
- Raw protocol analysis with redis-cli
- Real-time transaction monitoring
- Insurance transaction debugging

**Runnable Components:**
- redis-cli --raw commands
- redis-cli --monitor mode
- Protocol trace analysis

---

#### **Lab 3: Insurance Data Operations with Strings** (45 min)
**Location:** `/lab3-data-operations-strings/`

**Objective:** Master string operations for policy numbers, customer IDs, and insurance data

**Files & Scripts:**
- `lab3.md` - Complete lab instructions
- `scripts/load-sample-data.sh` - Sample data loading
- `performance-tests/` - Performance testing scripts
- `examples/` - Example code snippets
- `docs/` - Additional documentation

**Key Topics:**
- Policy number storage and retrieval
- Customer ID management with atomic operations
- Premium calculation counters (INCR/DECR)
- Batch operations (MSET/MGET)
- Race condition prevention
- Performance testing for insurance workloads

**Runnable Components:**
- Shell scripts for data loading
- Performance testing scripts
- Sample CLI operations

---

#### **Lab 4: Insurance Key Management & TTL Strategies** (45 min)
**Location:** `/lab4-key-management-ttl/`

**Objective:** Implement key naming conventions and TTL strategies for insurance entities

**Files & Scripts:**
- `lab4.md` - Complete lab instructions
- `scripts/load-key-management-data.sh` - Sample data with TTL
- `monitoring-tools/key-ttl-monitor.sh` - TTL monitoring tools
- `docs/` - Documentation

**Key Topics:**
- Insurance entity key naming conventions (policy:123456, claim:789012, customer:456789)
- Quote expiration management with TTL
- Policy renewal reminder scheduling
- Key scanning for pattern-based operations
- Memory usage monitoring
- Customer session cleanup automation

**Runnable Components:**
- Shell scripts for key management
- Redis CLI commands for key scanning
- Monitoring and analysis scripts

---

#### **Lab 5: Advanced CLI Operations for Insurance Monitoring** (45 min)
**Location:** `/lab5-advanced-cli-monitoring/`

**Objective:** Master advanced CLI features for insurance system monitoring

**Files & Scripts:**
- `lab5.md` - Complete lab instructions
- `scripts/` - Various analysis and monitoring scripts:
  - `load-production-data.sh`
  - `production-monitor.sh`
  - `health-report.sh`
  - `performance-analysis.sh`
  - `setup-alerts.sh`
  - `test-alerts.sh`
  - `capacity-planning.sh`
  - `optimization-recommendations.sh`
- `analysis/trend-analysis.sh` - Trend analysis tools

**Key Topics:**
- Advanced CLI scripting and automation
- Performance benchmarking
- Memory analysis and optimization
- Slow query identification
- Production monitoring best practices
- Alert setup and testing

**Runnable Components:**
- Multiple shell scripts for analysis
- Production monitoring tools
- Alert testing infrastructure

---

### DAY 2: Data Structures & JavaScript Integration

#### **Lab 6: JavaScript Redis Client Setup** (45 min)
**Location:** `/lab6-javascript-redis-client/`

**Objective:** Establish Node.js Redis development environment and master basic JavaScript operations

**Files & Structure:**
- `lab6.md` - Complete lab instructions
- `package.json.template` - Node.js project template
- `docker-compose.yml` - Docker setup for Redis
- `Dockerfile` - Custom image configuration
- `SETUP.md` - Setup guide
- `scripts/` - Setup and verification scripts:
  - `setup-lab.sh`
  - `validate-setup.sh`
  - `quick-start.sh`
  - `reset-lab.sh`
  - `verify-completion.sh`
- `src/` - Source code templates
- `redis-js-client/` - Complete client implementation
- `docs/` - Documentation

**Key Topics:**
- Node.js Redis client installation and configuration
- Connection pooling for high-availability systems
- Basic CRUD operations for customer and policy data
- Error handling and connection testing
- Environment variable configuration
- Promise patterns and async/await

**Runnable Components:**
- Node.js scripts for client testing
- Docker compose setup
- Shell scripts for setup and validation
- Connection verification utilities

---

#### **Lab 7: Customer Profiles & Policy Management with Hashes** (45 min)
**Location:** `/lab7-customer-policy-hashes/`

**Objective:** Build customer and policy management system using Redis hashes with JavaScript

**Files & Structure:**
- `lab7.md` - Complete lab instructions
- `package.json` - Node.js dependencies
- `setup-lab.sh` - Lab setup script
- `test-connection.js` - Connection testing utility
- `src/` - Source code for hash operations
- `customer-policy-system/` - Complete policy management system
- `examples/` - Example implementations
- `reference/` - Reference documentation
- `docs/` - Additional documentation

**Key Topics:**
- Redis hashes for structured data storage
- Customer profile management
- Policy data operations
- Nested data structure handling
- Partial updates for customer information
- Bulk operations for policy renewals
- Customer portal session integration

**Sample Data:**
- Customer profiles with hashes
- Policy information with nested structures
- Policy management operations

**Runnable Components:**
- Node.js scripts for hash operations
- Connection testing utilities
- Policy management examples

---

#### **Lab 8: Claims Event Sourcing with Redis Streams** (45 min)
**Location:** `/lab8-claims-event-sourcing/`

**Objective:** Implement event-driven claims processing using Redis Streams for audit trails and real-time analytics

**Files & Structure:**
- `lab8.md` - Complete lab instructions
- `package.json` - Node.js dependencies with scripts:
  - `npm start` - Start main application
  - `npm run producer` - Submit claims to stream
  - `npm run consumer` - Process claims events
  - `npm run analytics` - View real-time analytics
  - `npm run load-data` - Load sample claims data
  - `npm run test:all` - Run all tests
  - `npm run validate` - Validate setup
- `src/` - Source code structure:
  - `app.js` - Main application
  - `models/claim.js` - Claim domain model
  - `services/claimProducer.js` - Event producer
  - `services/claimAnalytics.js` - Analytics service
  - `consumers/claimProcessor.js` - Stream consumer
  - `utils/redisClient.js` - Connection management
- `scripts/` - Utility scripts:
  - `load-sample-data.js` - Load test claims data
  - `setup-lab.sh` - Environment setup
  - `verify-completion.js` - Completion verification
- `tests/` - Test suite
- `validation/` - Setup validation scripts
- `config/` - Configuration files
- `docs/` - Architecture documentation

**Sample Data:**
Event sourcing example with sample claims:
```javascript
{
    customer_id: 'CUST-001',
    policy_number: 'POL-AUTO-001',
    amount: 750,
    description: 'Minor fender bender - rear bumper repair',
    incident_date: '2024-08-15T10:30:00Z'
},
// ... additional claims data
```

**Event Types:**
- `claim.submitted` - Initial claim creation
- `claim.assigned` - Assigned to adjuster
- `claim.document.uploaded` - Supporting docs
- `claim.investigated` - Investigation activities
- `claim.approved` - Approval decision
- `claim.rejected` - Denial with reasons
- `claim.payment.initiated` - Payment processing
- `claim.payment.completed` - Settlement

**Key Topics:**
- Event sourcing pattern implementation
- Redis Streams for immutable event logs
- Consumer groups for distributed processing
- Real-time event processing with XREADGROUP
- Audit trail creation for compliance
- Stream-based analytics and dashboards
- Event replay capabilities

**Runnable Components:**
- `npm run producer` - Submit claims
- `npm run consumer` - Process events
- `npm run analytics` - Real-time dashboard
- `npm run load-data` - Load sample claims
- `npm test` - Automated tests
- `npm run validate` - Setup validation

---

#### **Lab 9: Insurance Analytics with Sets and Sorted Sets** (45 min)
**Location:** `/lab9-sets-analytics/`

**Objective:** Build insurance analytics and reporting features using Redis sets and sorted sets

**Files & Structure:**
- `lab9.md` - Complete lab instructions
- `src/` - Source code for analytics:
  - Customer segmentation with sets
  - Agent performance leaderboards
  - Risk analysis systems
  - Analytics aggregation
- `scripts/` - Utility and data loading scripts
- `reference/` - Reference implementations

**Key Topics:**
- Customer segmentation with sets
- Agent performance leaderboards with sorted sets
- Policy coverage analysis using set operations
- Premium ranking and risk scoring
- Real-time analytics integration with streams
- Stream-powered analytics aggregation

**Runnable Components:**
- Node.js scripts for analytics
- Data loading and aggregation utilities

---

#### **Lab 10: Advanced Insurance Caching Patterns** (45 min)
**Location:** `/lab10-advanced-caching-patterns/`

**Objective:** Implement sophisticated caching strategies for insurance applications

**Files & Structure:**
- `lab10.md` - Complete lab instructions
- `package.json` - Node.js dependencies
- `src/` - Caching pattern implementations
- `examples/` - Example code
  - `docker-setup.js` - Docker integration
- `tests/` - Caching tests
- `reference/` - Reference implementations
- `test-completion.js` - Completion testing

**Key Topics:**
- Cache-aside pattern
- Write-through pattern
- Write-behind pattern
- Multi-level caching architecture
- TTL-based expiration
- Event-driven cache invalidation using streams
- Stream-based cache coherence
- Tag-based invalidation
- Circuit breaker pattern for resilience
- Cache stampede and thundering herd solutions

**Runnable Components:**
- Node.js caching implementations
- Docker setup utilities
- Completion testing scripts

---

### DAY 3: Production & Advanced Topics

#### **Lab 11: Insurance Session Management & Security** (45 min)
**Location:** `/lab11-session-management/`

**Objective:** Implement Redis-based session management with role-based access control

**Files & Structure:**
- `lab11.md` - Complete lab instructions
- `package.json` - Node.js dependencies
- `src/` - Session management code:
  - `models/session.js` - Session model
  - `services/rbac-service.js` - Role-based access control
  - `services/security-monitor.js` - Security monitoring
- `scripts/` - Operational scripts:
  - `setup-lab.sh` - Lab setup
  - `cleanup-sessions.js` - Session cleanup
  - `monitor-sessions.js` - Session monitoring
- `config/` - Configuration files
- `examples/` - Example implementations:
  - `basic-session-demo.js` - Session demo
- `tests/` - Test suite

**Key Topics:**
- Redis-based session storage
- JWT token management
- Customer portal session handling
- Agent application sessions
- Role-based access control (customer/agent/admin)
- Session timeout policies
- Single sign-on (SSO) integration
- Session encryption and security
- Security monitoring and failed login tracking
- Session analytics dashboards

**Runnable Components:**
- Node.js session management scripts
- Security monitoring utilities
- RBAC service implementation
- Session cleanup tools

---

#### **Lab 12: Rate Limiting & API Protection** (45 min)
**Location:** `/lab12-rate-limiting-api-protection/`

**Objective:** Implement comprehensive rate limiting and API protection for insurance APIs

**Files & Structure:**
- `lab12.md` - Complete lab instructions
- `package.json` - Node.js dependencies
- `src/` - Rate limiting code:
  - `server.js` - Express server with rate limiting
  - `middleware/rateLimitMiddleware.js` - Rate limiting middleware
  - `services/rateLimitService.js` - Rate limit algorithms
  - `routes/` - API routes:
    - `quotes.js` - Quote API with rate limits
    - `policies.js` - Policy API
    - `admin.js` - Admin routes
- `scripts/` - Operational scripts:
  - `monitor-limits.js` - Monitor rate limits
  - `reset-limits.js` - Reset rate limit counters
- `config/` - Configuration files
- `examples/` - Example implementations:
  - `test-rate-limits.js` - Rate limit testing
  - `load-test.js` - Load testing utility

**Key Topics:**
- Token bucket rate limiting using Redis sorted sets
- Sliding window rate limiting
- Customer tier-based rate limits
- Endpoint-specific rate limiting
- DDoS protection strategies
- Rate limiting analytics and monitoring
- Abuse pattern detection
- Express.js middleware integration

**Runnable Components:**
- Express.js server with rate limiting
- Rate limit testing scripts
- Load testing utilities
- Monitoring and reset scripts

---

#### **Lab 13: Production Configuration for Insurance Systems** (45 min)
**Location:** `/lab13-production-configuration/`

**Objective:** Configure Redis for production deployment with persistence, security, and backups

**Files & Structure:**
- `lab13.md` - Complete lab instructions
- `config/` - Configuration files:
  - `redis-production.conf` - Production configuration
- `scripts/` - Production scripts:
  - `validate-production-config.sh` - Config validation
  - `health-check.sh` - Health checking
  - `benchmark-production.sh` - Performance benchmarking
  - `load-insurance-production-data.sh` - Data loading
  - `backup-insurance-redis.sh` - Backup automation
  - `validate-backup.sh` - Backup validation
  - `test-backup-automation.sh` - Backup testing
  - `setup-monitoring.sh` - Monitoring setup
  - `generate-config-report.sh` - Configuration reporting
  - `lab-completion-summary.sh` - Completion summary
- `monitoring/` - Monitoring configuration:
  - `monitor-redis.sh` - Redis monitoring
- `examples/` - Example scripts:
  - `monitoring-script-example.sh`
- `docs/` - Documentation:
  - `production-deployment-guide.md`
- `monitoring/reports/` - Report templates:
  - `performance-report-template.md`

**Key Topics:**
- RDB persistence configuration
- AOF (Append Only File) configuration
- Memory management and eviction policies
- Authentication and basic security
- Automated backup scripts
- Production-ready configuration files
- Health check endpoints
- Capacity planning
- Performance tuning for insurance workloads
- Compliance and data retention strategies

**Runnable Components:**
- Multiple shell scripts for configuration and deployment
- Backup automation utilities
- Health checking and validation scripts
- Performance benchmarking tools
- Monitoring setup scripts

---

#### **Lab 14: Production Monitoring & Health Checks** (45 min)
**Location:** `/lab14-production-monitoring/`

**Objective:** Set up comprehensive monitoring for production Redis operations

**Files & Structure:**
- `lab14.md` - Complete lab instructions
- `package.json` - Node.js dependencies (Winston logging, Redis, Node-cron, Express)
- `src/` - Monitoring code
- `scripts/` - Operational scripts:
  - `setup.sh` - Setup script
  - `test-monitoring.sh` - Monitoring testing
  - `lab-completion-summary.sh` - Completion summary
- `dashboards/` - Dashboard configurations
- `logs/` - Log directory

**Key Topics:**
- Redis Insight configuration for production monitoring
- Performance metric collection
- Custom health check endpoints
- Business metric monitoring (data lookups, transactions, user sessions)
- Alert configuration and thresholds
- Dashboard creation for stakeholders
- Slowlog analysis
- Automated health reporting
- Compliance requirements tracking

**Runnable Components:**
- Node.js health check service
- Monitoring and alerting scripts
- Dashboard generators
- Log analysis utilities

---

#### **Lab 15: Redis Cluster with High Availability & Sharding** (45 min - Advanced)
**Location:** `/lab15-redis-cluster-ha/`

**Objective:** Build production-grade Redis Cluster with automatic sharding, replication, and high availability

**Files & Structure:**
- `lab15.md` - Complete lab instructions
- `package.json` - Node.js dependencies:
  - `npm run test` - Run tests
  - `npm start` - Start cluster client
  - `npm run monitor` - Monitor cluster
  - `npm run test-sharding` - Test sharding
  - `npm run test-hash-tags` - Test hash tags
  - `npm run load-data` - Load insurance data
  - `npm run simulate-partition` - Simulate network issues
- `docker-compose.yml` - 6-node cluster setup (3 masters, 3 replicas)
- `src/` - Cluster client implementations:
  - `cluster-client.js` - Main cluster client
  - `insurance-data-loader.js` - Data loading utility
  - `test-sharding.js` - Sharding tests
  - `test-hash-tags.js` - Hash tag tests
  - `test-cross-slot.js` - Cross-slot operation tests
- `scripts/` - Cluster management scripts:
  - `init-cluster.sh` - Initialize cluster
  - `add-master-node.sh` - Add master node
  - `add-replica-node.sh` - Add replica node
  - `remove-node.sh` - Remove node
  - `show-slot-distribution.sh` - Show slot allocation
  - `migrate-slots.sh` - Migrate slots
  - `benchmark-cluster.sh` - Benchmark cluster
  - `backup-cluster.sh` - Backup cluster
  - `restore-cluster.sh` - Restore cluster
  - `rolling-upgrade.sh` - Upgrade nodes
  - `rebalance-cluster.sh` - Rebalance slots
  - `test-replication.sh` - Test replication
  - `manual-failover.sh` - Manual failover
  - `watch-failover.sh` - Monitor failover
  - `simulate-node-failure.sh` - Simulate failures
  - `simulate-partition.sh` - Simulate network partition
  - `simulate-partition-docker.sh` - Docker-based partition simulation
- `monitoring/` - Monitoring tools:
  - `setup-alerts.sh` - Alert configuration
  - `simple-dashboard.js` - Dashboard
  - `simple-replication-monitor.js` - Replication monitoring
- `tests/` - Test suite
- `debug-connection.js` - Connection debugging
- `debug-replication.js` - Replication debugging
- `test-connection.js` - Connection testing
- `simple-test.js` - Simple tests

**Architecture:**
```
6-node Redis Cluster (16384 slots)
├── Master-1 (Port 9000, Slots 0-5461)
│   └── Replica-1 (Port 9003)
├── Master-2 (Port 9001, Slots 5462-10922)
│   └── Replica-2 (Port 9004)
└── Master-3 (Port 9002, Slots 10923-16383)
    └── Replica-3 (Port 9005)
```

**Key Topics:**
- Redis Cluster setup and initialization
- Hash slot allocation and sharding
- Master-replica replication
- Automatic failover and recovery
- Cluster scaling (adding/removing nodes)
- Cluster-aware client applications
- Split-brain scenarios and network partitions
- Hash tag usage for multi-key operations
- Cluster topology management
- Backup and restoration of clusters
- Rolling upgrades

**Runnable Components:**
- Docker compose cluster setup
- Multiple cluster management scripts
- Insurance data loader
- Sharding and hash tag tests
- Failover and chaos testing
- Monitoring and debugging utilities

---

## Data Files & Datasets

### Sample Insurance Data
Located throughout labs, primarily in:
- Lab 3: `scripts/load-sample-data.sh` - Policy and customer data
- Lab 4: `scripts/load-key-management-data.sh` - Key patterns with TTL
- Lab 5: `scripts/load-production-data.sh` - Production-scale data
- Lab 8: `scripts/load-sample-data.js` - Claims data (5 sample claims)
- Lab 13: `scripts/load-insurance-production-data.sh` - Production claims data
- Lab 15: `src/insurance-data-loader.js` - Cluster-wide insurance data

### Sample Claims Data Structure
```javascript
{
    customer_id: 'CUST-001',
    policy_number: 'POL-AUTO-001',
    amount: 750,
    description: 'Insurance claim details',
    incident_date: '2024-08-15T10:30:00Z'
}
```

### Database Files
- Lab 15: `dump.rdb` - Redis cluster persistence file

---

## Technology Stack

### Languages & Frameworks
- **JavaScript/Node.js** - Primary development language (Labs 6-15)
- **Bash/Shell Scripts** - Automation and deployment (Labs 1-5, 13-15)

### Libraries & Dependencies
- **redis** - Node.js Redis client (v4.6.0+)
- **ioredis** - Alternative Redis client for cluster support (v5.3.2+)
- **express** - Web framework (v4.18.0+)
- **dotenv** - Environment configuration
- **uuid** - Unique ID generation
- **cors** - Cross-origin resource sharing
- **helmet** - HTTP security headers
- **morgan** - HTTP request logging
- **node-cron** - Task scheduling
- **winston** - Logging library
- **faker** - Fake data generation
- **chalk** - Terminal colors
- **cli-table3** - Console table formatting

### Tools & Platforms
- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration
- **Redis Insight** - GUI client for Redis administration
- **Visual Studio Code** - IDE
- **redis-cli** - Command-line client
- **Node.js 18+** - JavaScript runtime

---

## Script Types by Category

### Setup & Configuration
- `setup-lab.sh` - Lab environment initialization
- `docker-compose.yml` - Container orchestration
- `package.json` - Node.js project configuration
- `.env` files - Environment variables

### Data Loading
- `load-sample-data.sh` (Lab 3, 4, 5)
- `load-sample-data.js` (Lab 8)
- `load-insurance-production-data.sh` (Lab 13)
- `insurance-data-loader.js` (Lab 15)

### Monitoring & Analysis
- `production-monitor.sh` - Real-time monitoring
- `health-report.sh` - Health checking
- `performance-analysis.sh` - Performance metrics
- `monitor-sessions.js` - Session monitoring
- `monitor-limits.js` - Rate limit monitoring
- `setup-alerts.sh` - Alert configuration

### Testing & Validation
- `test-lab.sh` (Lab 1)
- `test-completion.js` - Completion verification
- `test-rate-limits.js` - Rate limit testing
- `test-monitoring.sh` - Monitoring validation
- `test-sharding.js` - Sharding validation
- `chaos-test.js` - Failure scenario testing

### Cluster Management (Lab 15)
- `init-cluster.sh` - Initialize 6-node cluster
- `add-master-node.sh` - Add master to cluster
- `add-replica-node.sh` - Add replica
- `remove-node.sh` - Remove node
- `show-slot-distribution.sh` - View slot allocation
- `migrate-slots.sh` - Rebalance data
- `manual-failover.sh` - Trigger failover
- `simulate-node-failure.sh` - Test failure recovery
- `simulate-partition.sh` - Test network issues
- `rolling-upgrade.sh` - Upgrade nodes without downtime

### Backup & Recovery
- `backup-insurance-redis.sh` - Create backups
- `validate-backup.sh` - Verify backups
- `backup-cluster.sh` - Cluster backups
- `restore-cluster.sh` - Restore cluster

---

## Overall Course Organization

### Learning Progression
1. **Day 1:** CLI fundamentals, string operations, key management, advanced monitoring
2. **Day 2:** JavaScript integration, hashes, lists, event sourcing with streams, sets/sorted sets, caching
3. **Day 3:** Session management, rate limiting, production configuration, monitoring, clustering

### Key Skills Built
- Redis CLI mastery
- RESP protocol understanding
- All Redis data structures
- JavaScript/Node.js integration
- Event sourcing patterns
- Production deployment
- High availability and clustering
- Monitoring and operations

### Industry Applications
- Claims processing (event sourcing in Lab 8)
- Customer management (hashes in Lab 7)
- Policy management (strings in Lab 3)
- Session management (Lab 11)
- API protection (rate limiting in Lab 12)
- Real-time analytics (streams, sets, sorted sets)
- High-availability systems (clustering in Lab 15)

---

## File Organization Summary

```
redis-mastering/
├── course_flow.md                           # Course structure document
├── README.md                                # Main README (Lab 8 example)
├── docs/streams-architecture.md             # Architecture documentation
├── content[1-9]*.html                       # 9 Presentation files
├── lab15-presentation.html                  # Cluster presentation
│
├── lab1-redis-cli-basics/                   # CLI Fundamentals
│   ├── lab1.md
│   ├── setup-lab.sh / test-lab.sh
│   ├── examples/
│   ├── docs/
│   └── reference/
│
├── lab2-resp-protocol/                      # RESP Protocol
│   └── lab2.md
│
├── lab3-data-operations-strings/            # String Operations
│   ├── lab3.md
│   ├── scripts/ (data loading)
│   ├── performance-tests/
│   ├── examples/
│   └── docs/
│
├── lab4-key-management-ttl/                 # Key Management
│   ├── lab4.md
│   ├── scripts/ (key management scripts)
│   ├── monitoring-tools/
│   └── docs/
│
├── lab5-advanced-cli-monitoring/            # Advanced CLI
│   ├── lab5.md
│   ├── scripts/ (9 monitoring/analysis scripts)
│   └── analysis/
│
├── lab6-javascript-redis-client/            # JavaScript Setup
│   ├── lab6.md
│   ├── package.json.template
│   ├── docker-compose.yml / Dockerfile
│   ├── scripts/ (5 setup/validation scripts)
│   ├── src/
│   ├── redis-js-client/
│   └── docs/
│
├── lab7-customer-policy-hashes/             # Hash Operations
│   ├── lab7.md
│   ├── package.json
│   ├── setup-lab.sh / test-connection.js
│   ├── src/
│   ├── customer-policy-system/
│   ├── examples/
│   ├── reference/
│   └── docs/
│
├── lab8-claims-event-sourcing/              # Event Sourcing (Streams)
│   ├── lab8.md
│   ├── package.json (8 npm scripts)
│   ├── scripts/ (load-sample-data.js, setup, verify)
│   ├── src/ (app, consumers, models, services, utils)
│   ├── tests/
│   ├── validation/
│   ├── config/
│   └── docs/
│
├── lab9-sets-analytics/                     # Sets & Analytics
│   ├── lab9.md
│   ├── src/
│   ├── scripts/
│   └── reference/
│
├── lab10-advanced-caching-patterns/         # Caching Patterns
│   ├── lab10.md
│   ├── package.json
│   ├── src/
│   ├── examples/ (docker-setup.js)
│   ├── tests/
│   ├── reference/
│   └── test-completion.js
│
├── lab11-session-management/                # Session Management
│   ├── lab11.md
│   ├── package.json
│   ├── scripts/ (setup-lab.sh, cleanup, monitor)
│   ├── src/ (models, services)
│   ├── config/
│   ├── examples/
│   └── tests/
│
├── lab12-rate-limiting-api-protection/      # Rate Limiting
│   ├── lab12.md
│   ├── package.json
│   ├── scripts/ (monitor-limits, reset-limits)
│   ├── src/ (server, middleware, services, routes)
│   ├── config/
│   └── examples/
│
├── lab13-production-configuration/          # Production Config
│   ├── lab13.md
│   ├── config/
│   ├── scripts/ (12 production scripts)
│   ├── monitoring/
│   ├── examples/
│   └── docs/
│
├── lab14-production-monitoring/             # Monitoring
│   ├── lab14.md
│   ├── package.json
│   ├── scripts/ (setup, test-monitoring, summary)
│   ├── src/
│   ├── dashboards/
│   ├── logs/
│   └── node_modules/
│
└── lab15-redis-cluster-ha/                  # Clustering
    ├── lab15.md
    ├── package.json (12 npm scripts)
    ├── docker-compose.yml
    ├── scripts/ (16 cluster scripts)
    ├── src/ (6 cluster implementation files)
    ├── monitoring/
    ├── tests/
    ├── debug-*.js files
    ├── simple-test.js
    ├── dump.rdb
    └── node_modules/
```

---

## Summary Statistics

- **Total Labs:** 15
- **CLI-only Labs:** 5 (Labs 1-5)
- **JavaScript Labs:** 10 (Labs 6-15)
- **Shell Scripts:** 50+
- **JavaScript Source Files:** 30+
- **Data Loaders:** 5+
- **Test Suites:** Multiple per lab
- **Documentation Files:** 20+
- **Presentation Files:** 10 (HTML)

