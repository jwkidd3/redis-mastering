# Lab 8: Claims Event Sourcing with Redis Streams

**Duration:** 45 minutes
**Focus:** Event-driven architecture with Redis Streams
**Prerequisites:** Lab 7 completed

## 🎯 Learning Objectives

- Implement event sourcing patterns
- Create immutable audit trails with Streams
- Build scalable real-time processing systems
- Use consumer groups for distributed processing

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Claims API    │    │  Redis Streams   │    │   Consumers     │
│   (Producer)    │───▶│  claims:events   │───▶│  (Processors)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   Analytics &    │
                       │   Monitoring     │
                       └──────────────────┘
```

## Key Components

### 1. Claim Model (`src/models/claim.js`)
- Event sourcing implementation
- Immutable claim lifecycle tracking
- Business logic for claim operations

### 2. Producer Service (`src/services/claimProducer.js`)
- REST API for claim submission
- HTTP endpoints for claim management
- Event publishing to Redis Streams

### 3. Consumer Service (`src/consumers/claimProcessor.js`)
- Event-driven claim processing
- Consumer group implementation
- Dead letter queue handling

### 4. Validation System (`validation/`)
- Environment setup validation
- Runtime health checks
- Completion verification

## Event Types

| Event Type | Description | Triggers |
|------------|-------------|----------|
| `claim_submitted` | New claim created | API submission |
| `claim_status_updated` | Status change | Manual/auto review |
| `claim_paid` | Payment processed | Approval completion |
| `claim_rejected` | Claim denied | Review decision |

## Redis Streams Commands Used

- `XADD` - Add events to stream
- `XREAD` - Read stream events
- `XGROUP CREATE` - Create consumer groups
- `XREADGROUP` - Read as consumer
- `XINFO` - Stream/consumer information
- `XPENDING` - Unacknowledged messages

## Lab Flow

1. **Setup** (10min) - Environment validation and configuration
2. **Streams Basics** (10min) - Understanding Redis Streams concepts
3. **Implementation** (15min) - Building event sourcing system
4. **Advanced Operations** (10min) - Analytics and scaling
5. **Validation** (5min) - Completion verification

## Success Criteria

- [ ] Environment properly configured
- [ ] Claims can be submitted and tracked
- [ ] Event sourcing captures full lifecycle
- [ ] Consumer groups process events
- [ ] Analytics provide insights
- [ ] Error handling works correctly

## Common Issues

1. **Stream not found** - Events not yet published
2. **Consumer group exists** - Group already created
3. **Connection errors** - Redis configuration issues
4. **Permission errors** - Script execution permissions

## Next Steps

- Lab 9: Redis Pub/Sub for notifications
- Advanced stream partitioning
- Claim workflow orchestration
- Document management integration
