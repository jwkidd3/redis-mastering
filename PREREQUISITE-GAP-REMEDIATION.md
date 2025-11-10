# Prerequisite Gap Remediation Plan

## Executive Summary

**Analysis Date:** November 10, 2025
**Overall Coverage:** 84.4% (173/205 knowledge items)
**Critical Finding:** 32 gaps across 8 labs where students use commands/concepts not yet taught
**Priority:** HIGH - Pedagogical integrity issue

---

## Coverage Analysis

```
Total knowledge items in labs:     205
Covered by presentations:          173
Gaps (not pre-taught):             32
Coverage rate:                     84.4%
```

### Gap Distribution by Day

| Day | Labs Affected | Total Gaps | Severity |
|-----|---------------|------------|----------|
| Day 1 | 4 labs | 10 gaps | Medium |
| Day 2 | 3 labs | 19 gaps | **CRITICAL** |
| Day 3 | 3 labs | 3 gaps | Low |

---

## Critical Gaps Requiring Immediate Remediation

### 🚨 PRIORITY 1: Lab 9 - Sets & Sorted Sets Analytics (17 gaps)

**Lab Location:** `lab9-sets-analytics`
**When Executed:** Day 2, after Content 5
**Severity:** CRITICAL

#### Missing Commands - SET Operations:
- `SADD` - Add members to a set
- `SCARD` - Get set cardinality
- `SDIFF` - Set difference
- `SINTER` - Set intersection
- `SISMEMBER` - Check set membership
- `SMEMBERS` - Get all set members
- `SREM` - Remove member from set
- `SUNION` - Set union

#### Missing Commands - SORTED SET Operations:
- `ZADD` - Add members to sorted set
- `ZCARD` - Get sorted set cardinality
- `ZINCRBY` - Increment score
- `ZRANGE` - Get range by index
- `ZRANGEBYSCORE` - Get range by score
- `ZRANK` - Get member rank
- `ZREM` - Remove member
- `ZREVRANGE` - Get range in reverse
- `ZSCORE` - Get member score

**Impact:** Students encounter 17 commands they've never seen before in a single lab. This is pedagogically unsound and will cause confusion and frustration.

**Recommended Fix:** Add comprehensive SET and SORTED SET coverage to Content 5 (content5.html)

---

### 🚨 PRIORITY 2: Lab 2 - RESP Protocol Deep Dive (6 gaps)

**Lab Location:** `lab2-resp-protocol`
**When Executed:** Day 1, after Content 2
**Severity:** HIGH

#### Missing Commands - HASH Operations:
- `HGET` - Get hash field value
- `HGETALL` - Get all hash fields and values
- `HMGET` - Get multiple hash field values
- `HMSET` - Set multiple hash fields

#### Missing Commands - SORTED SET Operations:
- `ZADD` - Add to sorted set
- `ZRANGE` - Get sorted set range

**Impact:** Lab 2 is designed to teach RESP protocol by examining various data types, but students haven't learned hash or sorted set commands yet.

**Recommended Fix:** Add hash and sorted set basics to Content 2 (content2_presentation.html) OR modify Lab 2 to only use strings and basic commands.

---

## All Gaps by Lab

### Day 1 Gaps

#### Lab 1: Redis Environment & CLI Basics
**Missing:** `SETEX`
**Severity:** Low
**Fix:** Add SETEX to Content 1 string operations section

#### Lab 2: RESP Protocol Deep Dive
**Missing:** `HGET`, `HGETALL`, `HMGET`, `HMSET`, `ZADD`, `ZRANGE`
**Severity:** High (6 commands)
**Fix:** Add to Content 2 OR restructure lab to use only taught commands

#### Lab 4: Key Management & TTL
**Missing:** `PSETEX`, `SETEX`
**Severity:** Low
**Fix:** Add to Content 3 TTL operations section

#### Lab 5: Advanced CLI & Monitoring
**Missing:** `LASTSAVE`, `SADD`, `ZADD`
**Severity:** Medium
**Fix:** Add to Content 3 persistence/monitoring section

### Day 2 Gaps

#### Lab 9: Sets & Sorted Sets Analytics
**Missing:** 17 SET and SORTED SET commands (see Priority 1 above)
**Severity:** CRITICAL
**Fix:** Add comprehensive coverage to Content 5

#### Lab 8: Claims Event Sourcing (Streams)
**Note:** No command gaps, but concepts are covered

#### Lab 10: Advanced Caching Patterns
**Note:** No gaps - proper prerequisite coverage

### Day 3 Gaps

#### Lab 11: Session Management
**Missing:** `SMEMBERS`
**Severity:** Low
**Fix:** Add to Content 7 or ensure Content 5 coverage

#### Lab 12: Rate Limiting & API Protection
**Missing:** `ZRANGE`
**Severity:** Low
**Fix:** Add to Content 7 or ensure Content 5 coverage

#### Lab 13: Production Configuration
**Missing:** `LASTSAVE`
**Severity:** Low
**Fix:** Add to Content 7 production operations section

---

## Detailed Remediation Recommendations

### 📋 Content 1 Enhancement (content1_presentation.html)

**Current Duration:** 50 minutes
**Additional Time Needed:** +3 minutes

**Add Slide After String Operations:**

```html
<section>
    <h2>String Operations with Expiration</h2>
    <h3>SETEX - Set with Expiration</h3>

    <pre><code class="language-redis">
# Set key with value and TTL in seconds
SETEX session:12345 3600 "user_data"

# Equivalent to:
SET session:12345 "user_data"
EXPIRE session:12345 3600

# Atomic operation - safer than two commands
    </code></pre>

    <div class="notes">
        <p>SETEX combines SET and EXPIRE into a single atomic operation</p>
        <p>Use case: Session tokens, temporary caches, rate limiting</p>
        <p>TTL is in seconds (use PSETEX for milliseconds)</p>
    </div>
</section>
```

**Impact:** Covers SETEX gap for Lab 1

---

### 📋 Content 2 Enhancement (content2_presentation.html)

**Current Duration:** 45 minutes
**Additional Time Needed:** +8 minutes OR restructure Lab 2

**Option A: Add Hash & Sorted Set Basics (Recommended)**

```html
<section>
    <h2>Introduction to Hashes</h2>
    <h3>Field-Value Storage</h3>

    <pre><code class="language-redis">
# Set single hash field
HSET user:1000 name "John Doe"

# Set multiple fields
HMSET user:1000 email "john@example.com" age "30"

# Get single field
HGET user:1000 name

# Get multiple fields
HMGET user:1000 name email

# Get all fields and values
HGETALL user:1000
    </code></pre>

    <div class="notes">
        <p>Hashes are perfect for representing objects</p>
        <p>More memory efficient than multiple string keys</p>
        <p>Field-level operations without loading entire object</p>
    </div>
</section>

<section>
    <h2>Introduction to Sorted Sets</h2>
    <h3>Scored Members</h3>

    <pre><code class="language-redis">
# Add members with scores
ZADD leaderboard 100 "player1"
ZADD leaderboard 250 "player2" 175 "player3"

# Get range by rank
ZRANGE leaderboard 0 -1

# Get range with scores
ZRANGE leaderboard 0 -1 WITHSCORES
    </code></pre>

    <div class="notes">
        <p>Sorted sets maintain order by score</p>
        <p>Use cases: leaderboards, priority queues, time series</p>
        <p>O(log N) insert and lookup</p>
    </div>
</section>
```

**Option B: Simplify Lab 2 (Alternative)**
Modify `lab2-resp-protocol/README.md` to only demonstrate RESP protocol with string commands (GET, SET, DEL, etc.) and remove hash/sorted set examples until after they're taught.

**Recommendation:** Option A - teaches foundational concepts needed for rest of course

---

### 📋 Content 3 Enhancement (content3_presentation.html)

**Current Duration:** 45 minutes
**Additional Time Needed:** +5 minutes

**Add to TTL Operations Section:**

```html
<section>
    <h2>Advanced Expiration Commands</h2>

    <pre><code class="language-redis">
# SETEX - Set with seconds TTL
SETEX key 60 "value"

# PSETEX - Set with milliseconds TTL
PSETEX key 60000 "value"

# Use case: High-precision rate limiting
PSETEX ratelimit:api:user123 100 "1"
    </code></pre>

    <div class="notes">
        <p>PSETEX provides millisecond precision for TTL</p>
        <p>Critical for rate limiting and high-frequency operations</p>
    </div>
</section>

<section>
    <h2>Persistence Commands</h2>

    <pre><code class="language-redis">
# Check last successful save
LASTSAVE
# Returns Unix timestamp

# Useful for monitoring backup status
# Example: Check if backup is older than 1 hour
    </code></pre>

    <div class="notes">
        <p>LASTSAVE shows when RDB snapshot was last created</p>
        <p>Essential for production monitoring</p>
        <p>Used in Lab 5 monitoring scripts</p>
    </div>
</section>
```

**Impact:** Covers PSETEX, SETEX, LASTSAVE gaps for Labs 4, 5, 13

---

### 📋 Content 5 Enhancement (content5.html) - CRITICAL

**Current Duration:** 45 minutes
**Additional Time Needed:** +15-20 minutes
**Priority:** HIGHEST

**Add Complete SET and SORTED SET Module:**

```html
<section>
    <h2>Redis Sets - Unordered Collections</h2>
    <h3>Set Fundamentals</h3>

    <pre><code class="language-redis">
# Add members to set
SADD tags:article:1 "redis" "database" "nosql"

# Check membership
SISMEMBER tags:article:1 "redis"  # Returns 1 (true)

# Get all members
SMEMBERS tags:article:1

# Get set size
SCARD tags:article:1

# Remove member
SREM tags:article:1 "nosql"
    </code></pre>

    <div class="notes">
        <p>Sets store unique, unordered values</p>
        <p>O(1) add, remove, and membership testing</p>
        <p>Perfect for tags, unique visitors, relationships</p>
    </div>
</section>

<section>
    <h2>Set Operations - Union, Intersection, Difference</h2>

    <pre><code class="language-redis">
SADD skills:john "redis" "javascript" "python"
SADD skills:jane "redis" "python" "golang"

# Intersection - common skills
SINTER skills:john skills:jane
# Returns: "redis", "python"

# Union - all unique skills
SUNION skills:john skills:jane
# Returns: "redis", "javascript", "python", "golang"

# Difference - john's unique skills
SDIFF skills:john skills:jane
# Returns: "javascript"
    </code></pre>

    <div class="notes">
        <p>Set operations are atomic and fast</p>
        <p>Use cases: friend recommendations, common interests, access control</p>
    </div>
</section>

<section>
    <h2>Sorted Sets - Ranked Collections</h2>
    <h3>Sorted Set Fundamentals</h3>

    <pre><code class="language-redis">
# Add members with scores
ZADD leaderboard 1000 "player1"
ZADD leaderboard 2500 "player2" 1750 "player3"

# Get member score
ZSCORE leaderboard "player2"  # Returns 2500

# Increment score
ZINCRBY leaderboard 100 "player1"  # Now 1100

# Get set size
ZCARD leaderboard

# Remove member
ZREM leaderboard "player3"
    </code></pre>

    <div class="notes">
        <p>Sorted sets maintain members in score order</p>
        <p>Unique members, but scores can be duplicated</p>
        <p>O(log N) operations</p>
    </div>
</section>

<section>
    <h2>Sorted Set Ranges</h2>

    <pre><code class="language-redis">
# Get by rank (index)
ZRANGE leaderboard 0 9          # Top 10 players
ZREVRANGE leaderboard 0 9       # Top 10 (highest first)

# Get with scores
ZRANGE leaderboard 0 9 WITHSCORES

# Get by score range
ZRANGEBYSCORE leaderboard 1000 2000

# Get player rank
ZRANK leaderboard "player1"      # 0-based rank
ZREVRANK leaderboard "player1"   # Rank from highest
    </code></pre>

    <div class="notes">
        <p>ZRANGE returns by index position (0-based)</p>
        <p>ZRANGEBYSCORE returns by score range</p>
        <p>ZREVRANGE/ZREVRANK for descending order</p>
        <p>Use cases: leaderboards, time-series data, priority queues</p>
    </div>
</section>

<section>
    <h2>Real-World Use Case: Insurance Analytics</h2>

    <pre><code class="language-redis">
# Track claim amounts by state
ZADD claims:by:state 1250000 "CA" 890000 "TX" 2100000 "NY"

# Top 5 states by claim volume
ZREVRANGE claims:by:state 0 4 WITHSCORES

# States with claims over $1M
ZRANGEBYSCORE claims:by:state 1000000 +inf

# Track unique claimants
SADD claimants:active "claimant:1001" "claimant:1002"
SCARD claimants:active  # Count active claimants
    </code></pre>

    <div class="notes">
        <p>This prepares students for Lab 9 analytics scenarios</p>
        <p>Combines sets and sorted sets for real insights</p>
    </div>
</section>
```

**Impact:** Completely resolves Lab 9's 17 command gaps (CRITICAL fix)

---

### 📋 Content 7 Enhancement (content7_presentation.html)

**Current Duration:** 50 minutes
**Additional Time Needed:** +2 minutes

**Add Quick Reference Slide:**

```html
<section>
    <h2>Essential Production Commands - Quick Review</h2>

    <div class="two-column">
        <div>
            <h3>Session Management</h3>
            <pre><code class="language-redis">
# Get all active sessions
SMEMBERS sessions:active

# Covered in Day 2, Content 5
            </code></pre>
        </div>

        <div>
            <h3>Rate Limiting</h3>
            <pre><code class="language-redis">
# Check request timestamps
ZRANGE ratelimit:user:123 0 -1

# Covered in Day 2, Content 5
            </code></pre>
        </div>
    </div>

    <div class="notes">
        <p>These commands were taught in Day 2</p>
        <p>Quick reminder for production context</p>
    </div>
</section>
```

**Impact:** Reinforces SMEMBERS, ZRANGE for Labs 11, 12 (minor gaps)

---

## Implementation Priority & Timeline

### Phase 1: Critical Fixes (Week 1)
**Effort:** 20-25 hours

1. **Content 5 Enhancement** (CRITICAL)
   - Add complete SET module (4-5 slides)
   - Add complete SORTED SET module (5-6 slides)
   - Add real-world analytics examples (2 slides)
   - **Time:** 12-15 hours (development + testing)
   - **Resolves:** 17 gaps in Lab 9

2. **Content 2 Enhancement** (HIGH)
   - Add hash basics (2 slides)
   - Add sorted set introduction (1-2 slides)
   - **Time:** 5-6 hours
   - **Resolves:** 6 gaps in Lab 2

### Phase 2: Medium Fixes (Week 2)
**Effort:** 8-10 hours

3. **Content 3 Enhancement** (MEDIUM)
   - Add PSETEX/SETEX slides (1 slide)
   - Add LASTSAVE slide (1 slide)
   - **Time:** 3-4 hours
   - **Resolves:** 6 gaps in Labs 4, 5, 13

4. **Content 1 Enhancement** (LOW)
   - Add SETEX slide (1 slide)
   - **Time:** 2 hours
   - **Resolves:** 1 gap in Lab 1

### Phase 3: Reinforcement (Week 2)
**Effort:** 3-5 hours

5. **Content 7 Enhancement** (LOW)
   - Add review/reference slides
   - **Time:** 2-3 hours
   - **Resolves:** 2 gaps in Labs 11, 12 (minor)

---

## Total Effort Estimation

| Phase | Presentations | Slides to Add | Hours | Priority |
|-------|---------------|---------------|-------|----------|
| 1 | Content 2, 5 | 13-15 slides | 20-25 | CRITICAL |
| 2 | Content 1, 3 | 3-4 slides | 8-10 | MEDIUM |
| 3 | Content 7 | 1-2 slides | 3-5 | LOW |
| **Total** | **5 files** | **17-21 slides** | **31-40 hours** | - |

---

## Alternative Approach: Lab Restructuring

Instead of enhancing presentations, labs could be modified to only use taught commands:

### Lab 2 Restructuring Option
- Remove hash and sorted set examples from RESP protocol lab
- Focus only on string operations (GET, SET, DEL, INCR, etc.)
- Move hash/sorted set RESP examples to later labs
- **Effort:** 3-4 hours
- **Trade-off:** Less comprehensive RESP coverage in Day 1

### Lab 9 Restructuring Option
- NOT RECOMMENDED - Lab 9's entire purpose is sets/sorted sets analytics
- Would require complete lab rewrite
- Better to enhance Content 5 instead

---

## Recommended Approach

**HYBRID STRATEGY:**

1. **Enhance Content 2** - Add hash/sorted set basics (CRITICAL for course flow)
2. **Enhance Content 5** - Add comprehensive SET/SORTED SET coverage (CRITICAL for Lab 9)
3. **Enhance Content 3** - Add SETEX, PSETEX, LASTSAVE (fills remaining gaps)
4. **Simplify Lab 1** - Remove SETEX requirement OR add quick note referencing Content 1
5. **Add reference cards** to Labs 11, 12 for SMEMBERS, ZRANGE (already taught in Content 5)

**Total Effort:** 25-30 hours
**Result:** 100% prerequisite coverage
**Timeline:** 2 weeks

---

## Success Criteria

After remediation, the course must achieve:

- ✅ **100% prerequisite coverage** - All commands taught before use
- ✅ **No gaps in critical labs** - Labs 2 and 9 fully supported
- ✅ **Logical progression** - Concepts build naturally day-to-day
- ✅ **Adequate practice time** - New content doesn't compress lab time
- ✅ **Validation** - Re-run analysis tool confirms 0 gaps

---

## Validation Plan

After implementing fixes:

1. **Re-run prerequisite analysis:**
   ```bash
   node /tmp/analyze-prerequisites.js
   ```
   Expected: "✅ NO GAPS FOUND"

2. **Manual review:**
   - Verify all SET commands taught before Lab 9
   - Verify hash commands taught before Lab 2
   - Verify TTL variants taught before Labs 4, 5

3. **Student testing:**
   - Pilot with 2-3 students
   - Track questions about "commands we haven't learned yet"
   - Adjust if confusion remains

---

## Presentation File Mapping

| Presentation File | Enhancement Needed | Slides to Add | Gaps Resolved |
|-------------------|-------------------|---------------|---------------|
| content1_presentation.html | SETEX coverage | 1 slide | Lab 1 (1 gap) |
| content2_presentation.html | Hash & sorted set intro | 3-4 slides | Lab 2 (6 gaps) |
| content3_presentation.html | PSETEX, LASTSAVE | 2 slides | Labs 4, 5, 13 (6 gaps) |
| content5.html | Full SET/SORTED SET module | 11-13 slides | Lab 9 (17 gaps) |
| content7_presentation.html | Review slides | 1-2 slides | Labs 11, 12 (2 gaps) |

---

## Risk Assessment

### Risks of NOT Fixing:

1. **Student Confusion** (HIGH RISK)
   - Students will be frustrated using commands they haven't learned
   - Especially critical in Lab 9 with 17 unknown commands
   - May require excessive instructor intervention

2. **Course Credibility** (MEDIUM RISK)
   - Poor pedagogical design reflects badly on course quality
   - May receive negative feedback/reviews
   - Contradicts adult learning principles

3. **Learning Outcomes** (MEDIUM RISK)
   - Students may memorize commands without understanding
   - Miss foundational concepts for sets/sorted sets
   - Harder to troubleshoot without conceptual foundation

### Risks of Fixing:

1. **Time Extension** (LOW RISK)
   - Adding 25-30 minutes across 4 presentations
   - Mitigation: Compress less critical content, tighten transitions
   - Day 2 may need to extend by 10-15 minutes

2. **Development Effort** (LOW RISK)
   - 25-30 hours is reasonable for this level of enhancement
   - Slides follow existing template/format
   - Examples can reuse insurance domain already established

---

## Conclusion

The prerequisite analysis revealed **32 gaps across 8 labs**, resulting in an **84.4% coverage rate**. While this is above failing, it represents a significant pedagogical issue that will impact student experience and learning outcomes.

**The most critical gap is Lab 9 (Sets & Sorted Sets Analytics)** where students encounter 17 commands they've never seen before. This must be resolved by enhancing Content 5 with comprehensive SET and SORTED SET coverage.

**Recommended Action:** Implement the hybrid strategy focusing on Content 2 and Content 5 enhancements as Phase 1 (critical fixes), followed by Phase 2 (medium priority fixes) to achieve 100% prerequisite coverage.

**Expected Outcome:** After remediation, students will have proper foundational knowledge before each lab, improving learning outcomes, reducing instructor burden, and enhancing course credibility.

---

## Appendix: Full Gap List

### Day 1 Gaps (10 total)

**Lab 1: Redis Environment & CLI Basics**
- SETEX (1 gap)

**Lab 2: RESP Protocol Deep Dive**
- HGET, HGETALL, HMGET, HMSET, ZADD, ZRANGE (6 gaps)

**Lab 4: Key Management & TTL**
- PSETEX, SETEX (2 gaps)

**Lab 5: Advanced CLI & Monitoring**
- LASTSAVE, SADD, ZADD (3 gaps - 2 are duplicates from above)

### Day 2 Gaps (19 total)

**Lab 9: Sets & Sorted Sets Analytics**
- SADD, SCARD, SDIFF, SINTER, SISMEMBER, SMEMBERS, SREM, SUNION (8 SET commands)
- ZADD, ZCARD, ZINCRBY, ZRANGE, ZRANGEBYSCORE, ZRANK, ZREM, ZREVRANGE, ZSCORE (9 SORTED SET commands)
- **Total: 17 gaps**

### Day 3 Gaps (3 total)

**Lab 11: Session Management**
- SMEMBERS (1 gap)

**Lab 12: Rate Limiting & API Protection**
- ZRANGE (1 gap)

**Lab 13: Production Configuration**
- LASTSAVE (1 gap)

---

**Report Generated:** November 10, 2025
**Analysis Tool:** `/tmp/analyze-prerequisites.js`
**Raw Data:** `PREREQUISITE-ANALYSIS.json`
**Status:** ⚠️ REMEDIATION REQUIRED
