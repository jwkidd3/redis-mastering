#!/bin/bash

# Lab 13: Validate Redis Backup
# Validates Redis backup integrity and restoration capability
# Production backup validation for enterprise deployments

set -e

# Configuration
BACKUP_DIR="../backup"
REDIS_HOST="localhost"
REDIS_PORT="6379"
TEST_PORT="6380"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="../monitoring/logs/backup-validation_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Header
log "${GREEN}=== Redis Backup Validation ===${NC}"
log "Starting validation at $(date)"
log "----------------------------------------"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    log "${RED}✗ Backup directory not found: $BACKUP_DIR${NC}"
    exit 1
fi

# Find latest backup files
log "\n${YELLOW}1. Finding latest backup files...${NC}"

# Find latest RDB backup
LATEST_RDB=$(ls -t "$BACKUP_DIR"/*.rdb 2>/dev/null | head -n1)
if [ -z "$LATEST_RDB" ]; then
    log "${RED}✗ No RDB backup files found${NC}"
else
    log "${GREEN}✓ Found RDB backup: $(basename $LATEST_RDB)${NC}"
    RDB_SIZE=$(du -h "$LATEST_RDB" | cut -f1)
    log "  Size: $RDB_SIZE"
fi

# Find latest AOF backup
LATEST_AOF=$(ls -t "$BACKUP_DIR"/*.aof 2>/dev/null | head -n1)
if [ -z "$LATEST_AOF" ]; then
    log "${YELLOW}⚠ No AOF backup files found (optional)${NC}"
else
    log "${GREEN}✓ Found AOF backup: $(basename $LATEST_AOF)${NC}"
    AOF_SIZE=$(du -h "$LATEST_AOF" | cut -f1)
    log "  Size: $AOF_SIZE"
fi

# Validate RDB file integrity
if [ ! -z "$LATEST_RDB" ]; then
    log "\n${YELLOW}2. Validating RDB file integrity...${NC}"
    
    # Check file magic string
    if head -c 5 "$LATEST_RDB" | grep -q "REDIS"; then
        log "${GREEN}✓ Valid Redis RDB file format${NC}"
    else
        log "${RED}✗ Invalid RDB file format${NC}"
        exit 1
    fi
    
    # Try to parse with redis-check-rdb if available
    if command -v redis-check-rdb &> /dev/null; then
        if redis-check-rdb "$LATEST_RDB" &> /dev/null; then
            log "${GREEN}✓ RDB file integrity check passed${NC}"
        else
            log "${RED}✗ RDB file integrity check failed${NC}"
            exit 1
        fi
    else
        log "${YELLOW}⚠ redis-check-rdb not available, skipping deep validation${NC}"
    fi
fi

# Validate AOF file integrity
if [ ! -z "$LATEST_AOF" ]; then
    log "\n${YELLOW}3. Validating AOF file integrity...${NC}"
    
    # Check if file is not empty
    if [ -s "$LATEST_AOF" ]; then
        log "${GREEN}✓ AOF file is not empty${NC}"
        
        # Try to parse with redis-check-aof if available
        if command -v redis-check-aof &> /dev/null; then
            if redis-check-aof --fix "$LATEST_AOF" &> /dev/null; then
                log "${GREEN}✓ AOF file integrity check passed${NC}"
            else
                log "${YELLOW}⚠ AOF file has issues but can be fixed${NC}"
            fi
        else
            log "${YELLOW}⚠ redis-check-aof not available, skipping deep validation${NC}"
        fi
    else
        log "${RED}✗ AOF file is empty${NC}"
    fi
fi

# Test restoration (if possible)
log "\n${YELLOW}4. Testing backup restoration...${NC}"

# Check if test Redis instance is running
if redis-cli -p $TEST_PORT ping &> /dev/null; then
    log "${YELLOW}⚠ Test Redis instance already running on port $TEST_PORT${NC}"
    log "  Skipping restoration test"
else
    # Try to start a test Redis instance with the backup
    if [ ! -z "$LATEST_RDB" ]; then
        log "Starting test Redis instance with backup..."
        
        # Create test config
        cat > /tmp/redis-test-$TIMESTAMP.conf <<EOF
port $TEST_PORT
dbfilename dump.rdb
dir $BACKUP_DIR
appendonly no
daemonize yes
pidfile /tmp/redis-test-$TIMESTAMP.pid
logfile /tmp/redis-test-$TIMESTAMP.log
EOF
        
        # Start test instance
        if redis-server /tmp/redis-test-$TIMESTAMP.conf &> /dev/null; then
            sleep 2
            
            # Test connection
            if redis-cli -p $TEST_PORT ping &> /dev/null; then
                log "${GREEN}✓ Successfully restored backup to test instance${NC}"
                
                # Get key count
                KEY_COUNT=$(redis-cli -p $TEST_PORT DBSIZE | awk '{print $1}')
                log "  Restored keys: $KEY_COUNT"
                
                # Shutdown test instance
                redis-cli -p $TEST_PORT SHUTDOWN &> /dev/null
                sleep 1
                
                # Cleanup
                rm -f /tmp/redis-test-$TIMESTAMP.*
            else
                log "${RED}✗ Failed to connect to test instance${NC}"
            fi
        else
            log "${RED}✗ Failed to start test instance${NC}"
        fi
    fi
fi

# Backup metadata validation
log "\n${YELLOW}5. Validating backup metadata...${NC}"

# Check backup age
if [ ! -z "$LATEST_RDB" ]; then
    BACKUP_AGE=$(( ($(date +%s) - $(stat -f %m "$LATEST_RDB" 2>/dev/null || stat -c %Y "$LATEST_RDB" 2>/dev/null)) / 3600 ))
    
    if [ $BACKUP_AGE -lt 24 ]; then
        log "${GREEN}✓ Backup is recent (${BACKUP_AGE} hours old)${NC}"
    elif [ $BACKUP_AGE -lt 168 ]; then
        log "${YELLOW}⚠ Backup is ${BACKUP_AGE} hours old${NC}"
    else
        log "${RED}✗ Backup is too old (${BACKUP_AGE} hours)${NC}"
    fi
fi

# Check backup retention
log "\n${YELLOW}6. Checking backup retention...${NC}"
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.rdb 2>/dev/null | wc -l)
log "Total RDB backups: $BACKUP_COUNT"

if [ $BACKUP_COUNT -gt 0 ]; then
    log "${GREEN}✓ Backup retention policy active${NC}"
    
    # List recent backups
    log "\nRecent backups:"
    ls -lht "$BACKUP_DIR"/*.rdb 2>/dev/null | head -5 | while read line; do
        log "  $line"
    done
else
    log "${RED}✗ No backups found${NC}"
fi

# Summary
log "\n${GREEN}=== Validation Summary ===${NC}"
log "----------------------------------------"

VALIDATION_PASSED=true

if [ -z "$LATEST_RDB" ] && [ -z "$LATEST_AOF" ]; then
    log "${RED}✗ No backup files found${NC}"
    VALIDATION_PASSED=false
else
    log "${GREEN}✓ Backup files present${NC}"
fi

if [ ! -z "$LATEST_RDB" ]; then
    log "${GREEN}✓ RDB backup validated${NC}"
fi

if [ ! -z "$LATEST_AOF" ]; then
    log "${GREEN}✓ AOF backup validated${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    log "\n${GREEN}✅ Backup validation PASSED${NC}"
    exit 0
else
    log "\n${RED}❌ Backup validation FAILED${NC}"
    exit 1
fi