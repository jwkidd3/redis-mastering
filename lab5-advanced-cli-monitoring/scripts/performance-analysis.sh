#!/bin/bash

# Comprehensive Redis performance analysis script

echo "⚡ Redis Performance Analysis"
echo "============================="

# Function to run performance test
run_performance_test() {
    echo ""
    echo "🧪 Running performance benchmarks..."
    
    # Basic benchmark
    echo "📊 Basic Operations Benchmark:"
    redis-benchmark -h localhost -p 6379 -q -c 10 -n 1000 -t set,get
    
    echo ""
    echo "📊 Hash Operations Benchmark:"
    redis-benchmark -h localhost -p 6379 -q -c 10 -n 1000 -t hset,hget
    
    echo ""
    echo "📊 List Operations Benchmark:"
    redis-benchmark -h localhost -p 6379 -q -c 10 -n 1000 -t lpush,lpop
}

# Function to analyze memory usage
analyze_memory() {
    echo ""
    echo "💾 Memory Analysis:"
    echo "=================="
    
    # Memory info
    redis-cli INFO memory | grep -E "(used_memory_human|used_memory_peak_human|used_memory_rss_human|mem_fragmentation_ratio)"
    
    echo ""
    echo "🔍 Largest Keys:"
    redis-cli --bigkeys --i 0.01
    
    echo ""
    echo "📈 Memory Usage by Type:"
    redis-cli --memkeys --memkeys-samples 1000
}

# Function to check slow operations
check_slow_operations() {
    echo ""
    echo "🐌 Slow Operations Analysis:"
    echo "=========================="
    
    # Check slow log
    echo "Recent slow operations:"
    redis-cli SLOWLOG GET 10
    
    echo ""
    echo "Slow log length: $(redis-cli SLOWLOG LEN)"
}

# Function to analyze command statistics
analyze_commands() {
    echo ""
    echo "📋 Command Statistics:"
    echo "===================="
    
    # Command stats
    redis-cli INFO commandstats | head -20
}

# Function to check latency
check_latency() {
    echo ""
    echo "📡 Latency Analysis:"
    echo "=================="
    
    echo "Running latency test for 10 seconds..."
    timeout 10s redis-cli --latency -h localhost -p 6379 | tail -1
    
    echo ""
    echo "Intrinsic latency (measures Redis speed):"
    timeout 5s redis-cli --intrinsic-latency 5
}

# Function to analyze client connections
analyze_clients() {
    echo ""
    echo "👥 Client Analysis:"
    echo "=================="
    
    echo "Connected clients:"
    redis-cli INFO clients | grep connected_clients
    
    echo ""
    echo "Client list (first 5):"
    redis-cli CLIENT LIST | head -5
}

# Function to check persistence performance
check_persistence() {
    echo ""
    echo "💾 Persistence Analysis:"
    echo "======================"
    
    redis-cli INFO persistence | grep -E "(aof_enabled|rdb_last_save_time|aof_last_rewrite_time_sec)"
    
    echo ""
    echo "Last save information:"
    redis-cli LASTSAVE
}

# Main execution
echo "🚀 Starting comprehensive performance analysis..."
echo "$(date)"

run_performance_test
analyze_memory
check_slow_operations
analyze_commands
check_latency
analyze_clients
check_persistence

echo ""
echo "✅ Performance analysis completed!"
echo "💡 Review the results above for optimization opportunities"
echo "📊 Use Redis Insight for detailed visual analysis"
