#!/bin/bash

# Lab 13: Generate Redis Configuration Report
# Generates comprehensive configuration report for production Redis
# Analyzes and documents all configuration settings

set -e

# Configuration
REDIS_HOST="localhost"
REDIS_PORT="6379"
CONFIG_FILE="../config/redis-production.conf"
REPORT_DIR="../monitoring/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/config-report_${TIMESTAMP}.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Header
echo -e "${GREEN}=== Redis Configuration Report Generator ===${NC}"
echo "Generating report at $(date)"
echo "----------------------------------------"

# Start report
cat > "$REPORT_FILE" <<EOF
# Redis Production Configuration Report
Generated: $(date)
Host: $REDIS_HOST:$REDIS_PORT

---

## Executive Summary

This report provides a comprehensive analysis of the Redis production configuration, including:
- Current runtime settings
- Memory configuration
- Persistence settings
- Security configuration
- Performance optimizations
- Compliance with best practices

---

## 1. Server Information

EOF

# Get Redis info
echo -e "\n${YELLOW}Collecting server information...${NC}"
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO server | grep -E "redis_version|redis_mode|os|arch_bits|process_id|uptime_in_days" >> "$REPORT_FILE"

# Memory Configuration
cat >> "$REPORT_FILE" <<EOF

---

## 2. Memory Configuration

### Current Memory Usage
EOF

redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep -E "used_memory_human|used_memory_rss_human|used_memory_peak_human|mem_fragmentation_ratio" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

### Memory Policies
EOF

echo -e "${YELLOW}Analyzing memory configuration...${NC}"

# Get memory-related configs
for config in maxmemory maxmemory-policy maxmemory-samples; do
    VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET $config | tail -1)
    echo "- **$config**: $VALUE" >> "$REPORT_FILE"
done

# Persistence Configuration
cat >> "$REPORT_FILE" <<EOF

---

## 3. Persistence Configuration

### RDB (Snapshotting)
EOF

echo -e "${YELLOW}Analyzing persistence settings...${NC}"

# RDB settings
for config in save dbfilename dir stop-writes-on-bgsave-error rdbcompression rdbchecksum; do
    VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET $config | tail -1)
    echo "- **$config**: $VALUE" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" <<EOF

### AOF (Append Only File)
EOF

# AOF settings
for config in appendonly appendfilename appendfsync no-appendfsync-on-rewrite auto-aof-rewrite-percentage auto-aof-rewrite-min-size; do
    VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET $config | tail -1)
    echo "- **$config**: $VALUE" >> "$REPORT_FILE"
done

# Security Configuration
cat >> "$REPORT_FILE" <<EOF

---

## 4. Security Configuration

### Access Control
EOF

echo -e "${YELLOW}Analyzing security settings...${NC}"

# Check if password is set
if redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET requirepass | tail -1 | grep -q "^$"; then
    echo "- **Password Protection**: ❌ NOT SET (CRITICAL)" >> "$REPORT_FILE"
else
    echo "- **Password Protection**: ✅ Enabled" >> "$REPORT_FILE"
fi

# Check bind settings
BIND_VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET bind | tail -1)
echo "- **Bind Address**: $BIND_VALUE" >> "$REPORT_FILE"

# Check protected mode
PROTECTED=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET protected-mode | tail -1)
echo "- **Protected Mode**: $PROTECTED" >> "$REPORT_FILE"

# Network and Client Configuration
cat >> "$REPORT_FILE" <<EOF

---

## 5. Network and Client Configuration

### Connection Limits
EOF

echo -e "${YELLOW}Analyzing network configuration...${NC}"

for config in maxclients timeout tcp-keepalive tcp-backlog; do
    VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET $config | tail -1)
    echo "- **$config**: $VALUE" >> "$REPORT_FILE"
done

# Performance Tuning
cat >> "$REPORT_FILE" <<EOF

---

## 6. Performance Tuning

### Database Settings
EOF

echo -e "${YELLOW}Analyzing performance settings...${NC}"

for config in databases hz dynamic-hz; do
    VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET $config | tail -1)
    echo "- **$config**: $VALUE" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" <<EOF

### Slow Log Configuration
EOF

for config in slowlog-log-slower-than slowlog-max-len; do
    VALUE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET $config | tail -1)
    echo "- **$config**: $VALUE" >> "$REPORT_FILE"
done

# Replication Configuration
cat >> "$REPORT_FILE" <<EOF

---

## 7. Replication Configuration

EOF

echo -e "${YELLOW}Checking replication status...${NC}"

ROLE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO replication | grep "role:" | cut -d: -f2 | tr -d '\r')
echo "### Current Role: $ROLE" >> "$REPORT_FILE"

if [ "$ROLE" = "master" ]; then
    SLAVES=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO replication | grep "connected_slaves:" | cut -d: -f2 | tr -d '\r')
    echo "- Connected Slaves: $SLAVES" >> "$REPORT_FILE"
fi

# Best Practices Compliance
cat >> "$REPORT_FILE" <<EOF

---

## 8. Best Practices Compliance Check

EOF

echo -e "${YELLOW}Checking compliance with best practices...${NC}"

COMPLIANCE_SCORE=0
TOTAL_CHECKS=0

# Check password
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET requirepass | tail -1 | grep -q "^$"; then
    echo "❌ **Password Protection**: Not configured (CRITICAL)" >> "$REPORT_FILE"
else
    echo "✅ **Password Protection**: Configured" >> "$REPORT_FILE"
    COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
fi

# Check persistence
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
AOF_ENABLED=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendonly | tail -1)
if [ "$AOF_ENABLED" = "yes" ]; then
    echo "✅ **AOF Persistence**: Enabled" >> "$REPORT_FILE"
    COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
else
    echo "⚠️  **AOF Persistence**: Disabled (recommended for production)" >> "$REPORT_FILE"
fi

# Check maxmemory policy
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
MAXMEM_POLICY=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory-policy | tail -1)
if [ "$MAXMEM_POLICY" != "noeviction" ]; then
    echo "✅ **Memory Policy**: $MAXMEM_POLICY configured" >> "$REPORT_FILE"
    COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
else
    echo "⚠️  **Memory Policy**: Using noeviction (may cause OOM)" >> "$REPORT_FILE"
fi

# Check protected mode
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ "$PROTECTED" = "yes" ]; then
    echo "✅ **Protected Mode**: Enabled" >> "$REPORT_FILE"
    COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
else
    echo "⚠️  **Protected Mode**: Disabled" >> "$REPORT_FILE"
fi

# Check slowlog
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
SLOWLOG_LEN=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET slowlog-max-len | tail -1)
if [ "$SLOWLOG_LEN" -gt 0 ]; then
    echo "✅ **Slow Log**: Configured (max-len: $SLOWLOG_LEN)" >> "$REPORT_FILE"
    COMPLIANCE_SCORE=$((COMPLIANCE_SCORE + 1))
else
    echo "⚠️  **Slow Log**: Not configured" >> "$REPORT_FILE"
fi

# Calculate compliance percentage
COMPLIANCE_PERCENT=$((COMPLIANCE_SCORE * 100 / TOTAL_CHECKS))

cat >> "$REPORT_FILE" <<EOF

### Compliance Score: ${COMPLIANCE_SCORE}/${TOTAL_CHECKS} (${COMPLIANCE_PERCENT}%)

---

## 9. Current Statistics

EOF

echo -e "${YELLOW}Collecting current statistics...${NC}"

# Get stats
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep -E "total_connections_received|total_commands_processed|instantaneous_ops_per_sec|rejected_connections|expired_keys|evicted_keys" >> "$REPORT_FILE"

# Recommendations
cat >> "$REPORT_FILE" <<EOF

---

## 10. Recommendations

Based on the configuration analysis, here are the recommendations:

EOF

echo -e "${YELLOW}Generating recommendations...${NC}"

# Generate recommendations based on findings
if redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET requirepass | tail -1 | grep -q "^$"; then
    echo "1. **CRITICAL**: Set a strong password using 'requirepass' directive" >> "$REPORT_FILE"
fi

if [ "$AOF_ENABLED" != "yes" ]; then
    echo "2. **HIGH**: Enable AOF persistence for better data durability" >> "$REPORT_FILE"
fi

if [ "$MAXMEM_POLICY" = "noeviction" ]; then
    echo "3. **MEDIUM**: Configure appropriate maxmemory-policy (e.g., allkeys-lru)" >> "$REPORT_FILE"
fi

MAXMEM=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory | tail -1)
if [ "$MAXMEM" = "0" ]; then
    echo "4. **MEDIUM**: Set maxmemory limit to prevent OOM issues" >> "$REPORT_FILE"
fi

# Configuration file backup
cat >> "$REPORT_FILE" <<EOF

---

## 11. Configuration File Location

Current configuration file: \`$CONFIG_FILE\`

Last modified: $(stat -c %y "$CONFIG_FILE" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CONFIG_FILE" 2>/dev/null || echo "Unknown")

---

## Report Metadata

- **Generated By**: $(whoami)
- **Generation Time**: $(date)
- **Report Location**: $REPORT_FILE
- **Redis Version**: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')

---

*End of Report*
EOF

# Summary output
echo -e "\n${GREEN}=== Report Generation Complete ===${NC}"
echo "----------------------------------------"
echo -e "${GREEN}✓${NC} Server information collected"
echo -e "${GREEN}✓${NC} Memory configuration analyzed"
echo -e "${GREEN}✓${NC} Persistence settings documented"
echo -e "${GREEN}✓${NC} Security configuration reviewed"
echo -e "${GREEN}✓${NC} Performance settings analyzed"
echo -e "${GREEN}✓${NC} Best practices compliance: ${COMPLIANCE_PERCENT}%"
echo -e "\n${BLUE}Report saved to: $REPORT_FILE${NC}"

# Display key findings
echo -e "\n${YELLOW}Key Findings:${NC}"
if [ "$COMPLIANCE_PERCENT" -ge 80 ]; then
    echo -e "${GREEN}✅ Configuration meets most best practices${NC}"
elif [ "$COMPLIANCE_PERCENT" -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Configuration needs some improvements${NC}"
else
    echo -e "${RED}❌ Configuration requires significant improvements${NC}"
fi

echo -e "\n${GREEN}Run 'cat $REPORT_FILE' to view the full report${NC}"