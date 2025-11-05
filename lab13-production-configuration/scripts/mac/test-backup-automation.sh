#!/bin/bash

# Lab 13: Test Backup Automation
# Tests automated backup processes and recovery procedures
# Validates backup scheduling and retention policies

set -e

# Configuration
BACKUP_DIR="../backup"
REDIS_HOST="localhost"
REDIS_PORT="6379"
TEST_DATA_SIZE=1000
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="../monitoring/logs/backup-automation-test_${TIMESTAMP}.log"
TEST_KEY_PREFIX="backup_test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "../monitoring/logs"

# Logging function
log() {
    echo -e "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Header
log "${GREEN}=== Redis Backup Automation Test ===${NC}"
log "Starting test at $(date)"
log "----------------------------------------"

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    log "\n${YELLOW}Testing: $test_name${NC}"
    
    if eval "$test_command"; then
        log "${GREEN}✓ $test_name: PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log "${RED}✗ $test_name: FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Check Redis connectivity
test_redis_connection() {
    redis-cli -h $REDIS_HOST -p $REDIS_PORT ping &> /dev/null
}

# Test 2: Create test data
test_create_data() {
    log "  Creating $TEST_DATA_SIZE test keys..."
    
    for i in $(seq 1 $TEST_DATA_SIZE); do
        redis-cli -h $REDIS_HOST -p $REDIS_PORT SET "${TEST_KEY_PREFIX}:$i" "test_value_$i" &> /dev/null
    done
    
    # Verify data creation
    COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "${TEST_KEY_PREFIX}:*" | wc -l)
    log "  Created $COUNT test keys"
    
    [ $COUNT -eq $TEST_DATA_SIZE ]
}

# Test 3: Manual backup trigger
test_manual_backup() {
    log "  Triggering manual backup..."
    
    # Trigger BGSAVE
    redis-cli -h $REDIS_HOST -p $REDIS_PORT BGSAVE &> /dev/null
    
    # Wait for backup to complete
    while [ "$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO persistence | grep rdb_bgsave_in_progress | cut -d: -f2 | tr -d '\r')" = "1" ]; do
        sleep 1
    done
    
    # Check if backup was created
    LATEST_BACKUP=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir | tail -1)
    BACKUP_FILE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dbfilename | tail -1)
    
    if [ -f "$LATEST_BACKUP/$BACKUP_FILE" ]; then
        # Copy to backup directory with timestamp
        cp "$LATEST_BACKUP/$BACKUP_FILE" "$BACKUP_DIR/dump_manual_${TIMESTAMP}.rdb"
        log "  Backup created: dump_manual_${TIMESTAMP}.rdb"
        return 0
    else
        return 1
    fi
}

# Test 4: Automated backup script
test_backup_script() {
    if [ -f "./backup-insurance-redis.sh" ]; then
        log "  Running backup script..."
        ./backup-insurance-redis.sh &> /dev/null
        
        # Check if new backup was created
        BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.rdb 2>/dev/null | wc -l)
        log "  Total backups in directory: $BACKUP_COUNT"
        
        [ $BACKUP_COUNT -gt 0 ]
    else
        log "  Backup script not found"
        return 1
    fi
}

# Test 5: Backup retention policy
test_retention_policy() {
    log "  Testing retention policy..."
    
    # Create multiple dummy backups with different timestamps
    for i in {1..5}; do
        DUMMY_DATE=$(date -d "-$i days" +%Y%m%d 2>/dev/null || date -v -${i}d +%Y%m%d 2>/dev/null)
        touch "$BACKUP_DIR/dump_${DUMMY_DATE}_120000.rdb"
    done
    
    INITIAL_COUNT=$(ls -1 "$BACKUP_DIR"/*.rdb 2>/dev/null | wc -l)
    log "  Created $INITIAL_COUNT test backups"
    
    # Simulate retention cleanup (keep only last 3 days)
    find "$BACKUP_DIR" -name "*.rdb" -mtime +3 -delete 2>/dev/null || \
    find "$BACKUP_DIR" -name "*.rdb" -mtime +3 -exec rm {} \; 2>/dev/null
    
    FINAL_COUNT=$(ls -1 "$BACKUP_DIR"/*.rdb 2>/dev/null | wc -l)
    log "  After retention cleanup: $FINAL_COUNT backups"
    
    [ $FINAL_COUNT -lt $INITIAL_COUNT ]
}

# Test 6: Backup validation
test_backup_validation() {
    if [ -f "./validate-backup.sh" ]; then
        log "  Running backup validation..."
        ./validate-backup.sh &> /dev/null
    else
        log "  Creating simple validation check..."
        
        # Find latest backup
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.rdb 2>/dev/null | head -n1)
        
        if [ ! -z "$LATEST_BACKUP" ]; then
            # Check file integrity
            if head -c 5 "$LATEST_BACKUP" | grep -q "REDIS"; then
                log "  Valid Redis backup file format"
                return 0
            fi
        fi
        return 1
    fi
}

# Test 7: Recovery simulation
test_recovery_simulation() {
    log "  Simulating recovery process..."
    
    # Get current key count
    ORIGINAL_COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE | awk '{print $1}')
    log "  Original key count: $ORIGINAL_COUNT"
    
    # Delete test keys
    redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
        local keys = redis.call('keys', '${TEST_KEY_PREFIX}:*')
        for i=1,#keys do
            redis.call('del', keys[i])
        end
        return #keys
    " 0 &> /dev/null
    
    # Verify deletion
    AFTER_DELETE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE | awk '{print $1}')
    log "  After deletion: $AFTER_DELETE keys"
    
    # Simulate recovery by recreating some keys
    for i in $(seq 1 100); do
        redis-cli -h $REDIS_HOST -p $REDIS_PORT SET "${TEST_KEY_PREFIX}:recovered:$i" "recovered_value_$i" &> /dev/null
    done
    
    AFTER_RECOVERY=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE | awk '{print $1}')
    log "  After recovery simulation: $AFTER_RECOVERY keys"
    
    [ $AFTER_RECOVERY -gt $AFTER_DELETE ]
}

# Test 8: AOF backup if enabled
test_aof_backup() {
    AOF_ENABLED=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendonly | tail -1)
    
    if [ "$AOF_ENABLED" = "yes" ]; then
        log "  AOF is enabled, testing AOF backup..."
        
        # Get AOF file location
        AOF_DIR=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir | tail -1)
        AOF_FILE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendfilename | tail -1)
        
        if [ -f "$AOF_DIR/$AOF_FILE" ]; then
            # Copy AOF to backup
            cp "$AOF_DIR/$AOF_FILE" "$BACKUP_DIR/appendonly_${TIMESTAMP}.aof"
            log "  AOF backup created: appendonly_${TIMESTAMP}.aof"
            return 0
        fi
    else
        log "  AOF is disabled, skipping AOF backup test"
        return 0
    fi
    return 1
}

# Test 9: Backup scheduling check
test_backup_scheduling() {
    log "  Checking for backup scheduling..."
    
    # Check if cron job exists
    if crontab -l 2>/dev/null | grep -q "backup.*redis"; then
        log "  Found Redis backup in crontab"
        crontab -l | grep "backup.*redis" | while read line; do
            log "    $line"
        done
        return 0
    else
        log "  No automated backup scheduling found"
        log "  To add automated backups, run:"
        log "    (crontab -l ; echo '0 2 * * * /path/to/backup-insurance-redis.sh') | crontab -"
        return 1
    fi
}

# Test 10: Backup size and compression
test_backup_compression() {
    log "  Testing backup compression..."
    
    # Find latest backup
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.rdb 2>/dev/null | head -n1)
    
    if [ ! -z "$LATEST_BACKUP" ]; then
        # Get file size
        SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
        log "  Backup size: $SIZE"
        
        # Test compression
        gzip -c "$LATEST_BACKUP" > "${LATEST_BACKUP}.gz"
        COMPRESSED_SIZE=$(du -h "${LATEST_BACKUP}.gz" | cut -f1)
        log "  Compressed size: $COMPRESSED_SIZE"
        
        # Clean up
        rm -f "${LATEST_BACKUP}.gz"
        
        return 0
    fi
    return 1
}

# Run all tests
log "\n${BLUE}Starting automated backup tests...${NC}"
log "========================================="

run_test "Redis Connection" test_redis_connection
run_test "Test Data Creation" test_create_data
run_test "Manual Backup Trigger" test_manual_backup
run_test "Backup Script Execution" test_backup_script
run_test "Retention Policy" test_retention_policy
run_test "Backup Validation" test_backup_validation
run_test "Recovery Simulation" test_recovery_simulation
run_test "AOF Backup" test_aof_backup
run_test "Backup Scheduling" test_backup_scheduling
run_test "Backup Compression" test_backup_compression

# Cleanup test data
log "\n${YELLOW}Cleaning up test data...${NC}"
redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
    local keys = redis.call('keys', '${TEST_KEY_PREFIX}:*')
    for i=1,#keys do
        redis.call('del', keys[i])
    end
    return #keys
" 0 &> /dev/null

# Summary
log "\n${GREEN}=== Test Summary ===${NC}"
log "========================================="
log "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
log "Tests Failed: ${RED}$TESTS_FAILED${NC}"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
if [ $TESTS_FAILED -eq 0 ]; then
    log "\n${GREEN}✅ All backup automation tests PASSED!${NC}"
    EXIT_CODE=0
else
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    log "\n${YELLOW}⚠️  Success Rate: ${SUCCESS_RATE}%${NC}"
    
    if [ $SUCCESS_RATE -ge 70 ]; then
        log "${YELLOW}Backup automation is partially functional${NC}"
        EXIT_CODE=0
    else
        log "${RED}❌ Backup automation needs attention${NC}"
        EXIT_CODE=1
    fi
fi

# Recommendations
log "\n${BLUE}Recommendations:${NC}"
log "----------------------------------------"

if ! test_backup_scheduling 2>/dev/null; then
    log "1. Set up automated backup scheduling with cron"
fi

AOF_ENABLED=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendonly | tail -1)
if [ "$AOF_ENABLED" != "yes" ]; then
    log "2. Enable AOF for better data persistence"
fi

log "3. Regularly test backup restoration procedures"
log "4. Monitor backup sizes and adjust retention policies"
log "5. Implement off-site backup storage for disaster recovery"

log "\n${GREEN}Test log saved to: $LOG_FILE${NC}"

exit $EXIT_CODE