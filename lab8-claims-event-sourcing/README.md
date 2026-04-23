# Lab 8: Claims Event Sourcing with Redis Streams

**Duration:** 75 minutes
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
5. **Part D: Inspection, Acknowledgement & DLQ** (15min) - XREAD / XINFO / XPENDING / XACK + DLQ pattern
6. **Validation** (5min) - Completion verification

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

## Part D: Stream Inspection, Reliability, and Dead-Letter Queue (15 min)

Once events are flowing, production systems need to *observe* streams, confirm *every message gets processed*, and quarantine *poison-pill* events that keep crashing consumers. This section adds five operations that every event-sourced claim pipeline must support.

### D.1 — `XREAD` — Non-Group Streaming Read

`XREADGROUP` delivers messages to a single consumer in a group. `XREAD` is the simpler "tail the log" read — ideal for dashboards, ad-hoc debugging, or read-only audit views that should **not** compete with real consumers.

**Insurance use case:** A claims-operations dashboard tails `claims:events` and displays the latest 20 claims in real time. It never acknowledges anything — it just watches.

```redis
// Seed the stream with a few events
XADD claims:events * event claim_submitted claim_id CLM-5001 amount 2500
XADD claims:events * event claim_submitted claim_id CLM-5002 amount 780

// Read everything from the beginning (ID "0")
XREAD COUNT 10 STREAMS claims:events 0

// Tail "only new events after now" — blocks up to 5 seconds
XREAD BLOCK 5000 COUNT 10 STREAMS claims:events $
```

Expected: a list of `[stream_name, [[id, [field, value, ...]], ...]]`.

---

### D.2 — `XINFO STREAM` / `XINFO GROUPS` / `XINFO CONSUMERS` — Inspect a Stream

Whenever a consumer lags or a group misbehaves, the **first thing** to check is `XINFO`. These commands are the stream-equivalent of `SHOW PROCESSLIST` in SQL.

**Insurance use case:** On-call engineer receives a paging alert that claims are stalled. First troubleshooting step: `XINFO GROUPS claims:events` — is anyone consuming?

```redis
// High-level stream info (length, first/last entry, groups)
XINFO STREAM claims:events

// Per-consumer-group lag and last-delivered ID
XINFO GROUPS claims:events

// Per-consumer idle time and pending count (after a group is created)
XGROUP CREATE claims:events processors $ MKSTREAM
XINFO CONSUMERS claims:events processors
```

Look for `lag`, `last-delivered-id`, and per-consumer `idle` values.

---

### D.3 — `XPENDING` — List Unacknowledged Messages

Every message read via `XREADGROUP` sits in the **Pending Entries List (PEL)** until the consumer calls `XACK`. `XPENDING` reveals the PEL.

**Insurance use case:** Find claim events that a crashed `claim-processor` pod took delivery of but never acknowledged — these are candidates for re-delivery via `XCLAIM`.

```redis
// Send a claim and have a consumer read (but not ack) it
XADD claims:events * event claim_submitted claim_id CLM-5050 amount 9999
XREADGROUP GROUP processors worker-1 COUNT 10 STREAMS claims:events >

// Now inspect the PEL
XPENDING claims:events processors
// Expected: [count, smallest-id, largest-id, [[consumer, count], ...]]

// Drill into individual pending entries
XPENDING claims:events processors - + 10 worker-1
```

---

### D.4 — `XACK` — Acknowledge Successfully Processed Events

After a consumer finishes its work (writes to the policy DB, sends the email, etc.) it must `XACK` the message so it leaves the PEL. Without `XACK` messages stay pending forever.

**Insurance use case:** Once `claim-processor` confirms the payout was written to the ledger, it acknowledges the event so it isn't re-processed.

```redis
// Grab the next pending ID from the previous XREADGROUP output (replace <ID>)
// XACK claims:events processors <ID>

// Generic pattern
XREADGROUP GROUP processors worker-1 COUNT 1 STREAMS claims:events >
// ... process business logic ...
// XACK the returned ID
// XACK claims:events processors 1700000000000-0
```

After `XACK`, `XPENDING claims:events processors` will show **one fewer** pending entry.

---

### D.5 — Dead-Letter Queue (DLQ) Pattern

Some claim events are *poison pills* — malformed JSON, unsupported policy type, downstream dependency permanently gone. You do **not** want those stuck in the PEL retried forever. Standard industry pattern: after **N retries**, move the event into a `claims:dlq` stream and `XACK` it off the main stream so healthy processing can continue.

**Insurance use case:** A claim with a corrupted `policy_id` has failed processing 3 times; move it to `claims:dlq` for the on-call engineer to triage manually.

```redis
// Read an event as a consumer
XREADGROUP GROUP processors worker-1 COUNT 1 STREAMS claims:events >
// Suppose it fails — increment a retry counter keyed by the message id:
INCR claims:retries:CLM-5050
// If retries > 3 → move to DLQ and ack
XADD claims:dlq * original_id 1700000000000-0 reason "malformed_payload" claim_id CLM-5050 amount 9999
XACK claims:events processors 1700000000000-0
DEL claims:retries:CLM-5050

// Verify DLQ received the event
XLEN claims:dlq
// Expected: >= 1
XRANGE claims:dlq - + COUNT 5
```

**Why this pattern works:**
- The main stream never clogs — good events flow.
- The DLQ is a durable audit trail of *every* bad event.
- Operators can replay from the DLQ once the underlying bug is fixed: read from `claims:dlq`, re-publish to `claims:events`.

---

### Part D Summary Table

| Command / Pattern   | Purpose                                    | Insurance example                            |
|---------------------|--------------------------------------------|---------------------------------------------|
| `XREAD`             | Non-group tail read                        | Ops dashboard that mirrors the stream       |
| `XINFO STREAM`      | Stream length, first/last IDs, groups      | Health check                                |
| `XINFO GROUPS`      | Per-group lag and last-delivered ID        | On-call consumer lag triage                 |
| `XINFO CONSUMERS`   | Per-consumer pending & idle time           | Detect crashed worker pods                  |
| `XPENDING`          | List unacknowledged messages in PEL        | Inventory dropped events after a crash      |
| `XACK`              | Confirm successful processing              | Ledger write confirmed → ack the claim      |
| DLQ (`claims:dlq`)  | Quarantine poison-pill events after N tries| Malformed claim payload → manual triage     |

---

## Next Steps

- Lab 9: Redis Pub/Sub for notifications
- Advanced stream partitioning
- Claim workflow orchestration
- Document management integration
