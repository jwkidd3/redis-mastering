#!/bin/bash

# Trend analysis script for Redis metrics

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
METRICS_LOG="monitoring/metrics.log"
TREND_REPORT="analysis/trend-analysis.txt"

echo "📈 Redis Trend Analysis" > $TREND_REPORT
echo "======================" >> $TREND_REPORT
echo "Generated: $(date)" >> $TREND_REPORT
echo "" >> $TREND_REPORT

# Check if metrics log exists
if [ ! -f "$METRICS_LOG" ]; then
    echo "❌ Metrics log not found: $METRICS_LOG" >> $TREND_REPORT
    echo "   Run production monitoring first to collect metrics" >> $TREND_REPORT
    echo ""
    echo "⚠️  No metrics data available for trend analysis"
    echo "   Start monitoring first: ./scripts/production-monitor.sh"
    exit 1
fi

# Analyze metrics trends
echo "📊 METRICS TRENDS:" >> $TREND_REPORT

# Count total metrics entries
TOTAL_ENTRIES=$(wc -l < $METRICS_LOG)
echo "   Total Metrics Entries: $TOTAL_ENTRIES" >> $TREND_REPORT

if [ $TOTAL_ENTRIES -gt 0 ]; then
    # Get latest metrics
    LATEST_ENTRY=$(tail -1 $METRICS_LOG)
    echo "   Latest Entry: $LATEST_ENTRY" >> $TREND_REPORT
    
    # Get oldest metrics
    OLDEST_ENTRY=$(head -1 $METRICS_LOG)
    echo "   Oldest Entry: $OLDEST_ENTRY" >> $TREND_REPORT
    
    echo "" >> $TREND_REPORT
    echo "   📈 Growth Trends (based on available data):" >> $TREND_REPORT
    echo "      Monitoring Period: $(head -1 $METRICS_LOG | cut -d, -f1) to $(tail -1 $METRICS_LOG | cut -d, -f1)" >> $TREND_REPORT
    echo "      Data Points Collected: $TOTAL_ENTRIES" >> $TREND_REPORT
else
    echo "   No trend data available yet" >> $TREND_REPORT
fi

echo "" >> $TREND_REPORT

# Current snapshot for comparison
echo "📸 CURRENT SNAPSHOT:" >> $TREND_REPORT
CURRENT_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
CURRENT_MEMORY=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory_human:" | cut -d: -f2)
CURRENT_CLIENTS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO clients | grep "connected_clients:" | cut -d: -f2)

echo "   Current Keys: ${CURRENT_KEYS}" >> $TREND_REPORT
echo "   Current Memory: ${CURRENT_MEMORY}" >> $TREND_REPORT
echo "   Current Clients: ${CURRENT_CLIENTS}" >> $TREND_REPORT

echo "" >> $TREND_REPORT
echo "💡 TREND RECOMMENDATIONS:" >> $TREND_REPORT
echo "1. Continue monitoring for at least 24 hours for meaningful trends" >> $TREND_REPORT
echo "2. Set up automated trend analysis with longer data collection" >> $TREND_REPORT
echo "3. Establish baseline metrics for comparison" >> $TREND_REPORT
echo "4. Monitor during peak and off-peak hours" >> $TREND_REPORT

echo "✅ Trend analysis completed: $TREND_REPORT"
echo ""
echo "📋 Analysis Summary:"
cat $TREND_REPORT
