#!/bin/bash

echo "========================================"
echo "Redis Cluster Monitoring & Alerts Setup"
echo "========================================"
echo ""

# Check if required commands are available
echo "Step 1: Checking prerequisites..."

REQUIREMENTS_MET=true

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "✗ Docker is required but not installed"
    REQUIREMENTS_MET=false
else
    echo "✓ Docker found"
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "✗ Node.js is required but not installed"
    REQUIREMENTS_MET=false
else
    echo "✓ Node.js found ($(node --version))"
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "✗ npm is required but not installed"
    REQUIREMENTS_MET=false
else
    echo "✓ npm found ($(npm --version))"
fi

if [ "$REQUIREMENTS_MET" = false ]; then
    echo ""
    echo "Please install missing requirements and run this script again."
    exit 1
fi

echo ""
echo "Step 2: Verifying Redis cluster is running..."

# Check if cluster containers are running
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep redis-node | wc -l | tr -d ' ')

if [ "$RUNNING_CONTAINERS" -lt 6 ]; then
    echo "⚠ Warning: Expected 6 Redis containers, found $RUNNING_CONTAINERS"
    echo ""
    echo "Available Redis containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep redis-node || echo "No Redis containers found"
    echo ""
    echo "To start the cluster, run:"
    echo "  docker-compose up -d"
    echo ""
    read -p "Continue with setup anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
else
    echo "✓ Found $RUNNING_CONTAINERS Redis containers running"
fi

# Test cluster connectivity
echo ""
echo "Step 3: Testing cluster connectivity..."

if docker exec redis-node-1 redis-cli -p 9000 ping &> /dev/null; then
    echo "✓ Redis cluster is responding"
    
    # Check cluster status
    CLUSTER_STATE=$(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r')
    if [ "$CLUSTER_STATE" = "ok" ]; then
        echo "✓ Cluster state is OK"
    else
        echo "⚠ Warning: Cluster state is '$CLUSTER_STATE'"
    fi
else
    echo "✗ Cannot connect to Redis cluster"
    echo "Please ensure the cluster is running and healthy"
    exit 1
fi

echo ""
echo "Step 4: Installing monitoring dependencies..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
else
    echo "✓ Dependencies already installed"
fi

echo ""
echo "Step 5: Creating monitoring configuration..."

# Create monitoring config directory
mkdir -p monitoring/config

# Create alerting configuration
cat > monitoring/config/alerts.json << 'EOF'
{
  "alerting": {
    "enabled": true,
    "checkInterval": 30000,
    "email": {
      "enabled": false,
      "smtp": {
        "host": "smtp.gmail.com",
        "port": 587,
        "secure": false,
        "auth": {
          "user": "your-email@gmail.com",
          "pass": "your-app-password"
        }
      },
      "recipients": ["admin@example.com"]
    },
    "webhook": {
      "enabled": false,
      "url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
      "method": "POST"
    },
    "console": {
      "enabled": true
    }
  },
  "thresholds": {
    "cluster": {
      "minHealthyNodes": 4,
      "maxFailedNodes": 2,
      "slotsNotCovered": true
    },
    "node": {
      "maxMemoryUsage": 90,
      "maxCpuUsage": 85,
      "maxConnectionLag": 30,
      "maxReplicationLag": 10
    },
    "performance": {
      "minOpsPerSec": 0,
      "maxResponseTime": 1000
    }
  }
}
EOF

echo "✓ Created alerts configuration: monitoring/config/alerts.json"

# Create systemd service file (optional)
cat > monitoring/config/redis-cluster-monitor.service << 'EOF'
[Unit]
Description=Redis Cluster Monitor
After=network.target

[Service]
Type=simple
User=redis
WorkingDirectory=/path/to/your/lab15-redis-cluster-ha
ExecStart=/usr/bin/node monitoring/simple-replication-monitor.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "✓ Created systemd service template: monitoring/config/redis-cluster-monitor.service"

# Create monitoring script with alerts
cat > monitoring/cluster-monitor-with-alerts.js << 'EOF'
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const chalk = require('chalk');

// Load configuration
const configPath = path.join(__dirname, 'config', 'alerts.json');
let config;

try {
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (error) {
  console.error('Failed to load alerts configuration:', error.message);
  process.exit(1);
}

class ClusterMonitor {
  constructor() {
    this.previousState = null;
    this.alertHistory = new Map();
  }

  async execCommand(command) {
    return new Promise((resolve, reject) => {
      exec(command, (error, stdout, stderr) => {
        if (error) {
          reject(error);
        } else {
          resolve(stdout.trim());
        }
      });
    });
  }

  async getClusterInfo() {
    try {
      const clusterInfo = await this.execCommand('docker exec redis-node-1 redis-cli -p 9000 cluster info');
      const clusterNodes = await this.execCommand('docker exec redis-node-1 redis-cli -p 9000 cluster nodes');
      
      const info = {};
      clusterInfo.split('\r\n').forEach(line => {
        const [key, value] = line.split(':');
        if (key && value) {
          info[key.replace('cluster_', '')] = value;
        }
      });

      const nodes = [];
      clusterNodes.split('\n').forEach(line => {
        if (line.trim()) {
          const parts = line.split(' ');
          if (parts.length >= 8) {
            nodes.push({
              id: parts[0],
              address: parts[1],
              port: parseInt(parts[1].split(':')[1]) || 0,
              flags: parts[2],
              role: parts[2].includes('master') ? 'master' : 'slave',
              master: parts[3],
              slots: parts.slice(8).join(' ')
            });
          }
        }
      });

      return { info, nodes };
    } catch (error) {
      throw new Error(`Failed to get cluster info: ${error.message}`);
    }
  }

  async checkHealth() {
    const timestamp = new Date().toISOString();
    const alerts = [];

    try {
      const { info, nodes } = await this.getClusterInfo();

      // Check cluster state
      if (info.state !== 'ok') {
        alerts.push({
          level: 'critical',
          message: `Cluster state is ${info.state}`,
          timestamp
        });
      }

      // Check slot coverage
      const slotsAssigned = parseInt(info.slots_assigned) || 0;
      const slotsOk = parseInt(info.slots_ok) || 0;
      
      if (slotsAssigned !== 16384) {
        alerts.push({
          level: 'critical',
          message: `Only ${slotsAssigned}/16384 slots assigned`,
          timestamp
        });
      }

      if (slotsOk !== slotsAssigned) {
        alerts.push({
          level: 'critical',
          message: `${slotsAssigned - slotsOk} slots not OK`,
          timestamp
        });
      }

      // Check node health
      const healthyNodes = nodes.filter(n => !n.flags.includes('fail')).length;
      const failedNodes = nodes.filter(n => n.flags.includes('fail')).length;

      if (healthyNodes < config.thresholds.cluster.minHealthyNodes) {
        alerts.push({
          level: 'critical',
          message: `Only ${healthyNodes} healthy nodes (minimum: ${config.thresholds.cluster.minHealthyNodes})`,
          timestamp
        });
      }

      if (failedNodes > config.thresholds.cluster.maxFailedNodes) {
        alerts.push({
          level: 'warning',
          message: `${failedNodes} failed nodes detected`,
          timestamp
        });
      }

      // Check for split-brain scenarios
      const masters = nodes.filter(n => n.role === 'master' && !n.flags.includes('fail'));
      if (masters.length > 3) {
        alerts.push({
          level: 'warning',
          message: `Unusual number of masters: ${masters.length}`,
          timestamp
        });
      }

      return {
        timestamp,
        healthy: alerts.length === 0,
        info,
        nodes,
        alerts,
        summary: {
          totalNodes: nodes.length,
          healthyNodes,
          failedNodes,
          masters: masters.length,
          slaves: nodes.filter(n => n.role === 'slave' && !n.flags.includes('fail')).length
        }
      };

    } catch (error) {
      return {
        timestamp,
        healthy: false,
        error: error.message,
        alerts: [{
          level: 'critical',
          message: `Monitor failed: ${error.message}`,
          timestamp
        }]
      };
    }
  }

  async sendAlert(alert) {
    const key = `${alert.level}-${alert.message}`;
    const lastSent = this.alertHistory.get(key);
    const now = Date.now();

    // Prevent spam - only send same alert once per 5 minutes
    if (lastSent && (now - lastSent) < 300000) {
      return;
    }

    this.alertHistory.set(key, now);

    if (config.alerting.console.enabled) {
      const color = alert.level === 'critical' ? chalk.red : chalk.yellow;
      console.log(color(`\n🚨 ALERT [${alert.level.toUpperCase()}]: ${alert.message}`));
      console.log(chalk.gray(`   Time: ${alert.timestamp}\n`));
    }

    // Add email/webhook sending logic here if configured
    if (config.alerting.email.enabled) {
      console.log(chalk.blue(`📧 Email alert would be sent to: ${config.alerting.email.recipients.join(', ')}`));
    }

    if (config.alerting.webhook.enabled) {
      console.log(chalk.blue(`🔗 Webhook alert would be sent to: ${config.alerting.webhook.url}`));
    }
  }

  async run() {
    console.log(chalk.blue('🔍 Redis Cluster Monitor with Alerting Started'));
    console.log(chalk.gray(`Check interval: ${config.alerting.checkInterval}ms\n`));

    const monitor = async () => {
      try {
        const status = await this.checkHealth();
        
        if (status.healthy) {
          console.log(chalk.green(`✓ ${status.timestamp} - Cluster healthy (${status.summary.healthyNodes}/${status.summary.totalNodes} nodes)`));
        } else {
          console.log(chalk.red(`✗ ${status.timestamp} - Cluster issues detected`));
          
          for (const alert of status.alerts) {
            await this.sendAlert(alert);
          }
        }

        this.previousState = status;

      } catch (error) {
        console.error(chalk.red(`Monitor error: ${error.message}`));
      }
    };

    // Initial check
    await monitor();

    // Set up periodic monitoring
    setInterval(monitor, config.alerting.checkInterval);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log(chalk.yellow('\n🛑 Monitor shutting down...'));
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log(chalk.yellow('\n🛑 Monitor terminating...'));
  process.exit(0);
});

// Start monitoring
const monitor = new ClusterMonitor();
monitor.run().catch(error => {
  console.error(chalk.red('Failed to start monitor:', error));
  process.exit(1);
});
EOF

echo "✓ Created monitoring script with alerts: monitoring/cluster-monitor-with-alerts.js"

echo ""
echo "Step 6: Creating monitoring scripts..."

# Create log rotation script
cat > monitoring/rotate-logs.sh << 'EOF'
#!/bin/bash

LOG_DIR="monitoring/logs"
MAX_LOG_SIZE="100M"
MAX_LOG_FILES=10

mkdir -p "$LOG_DIR"

# Function to rotate logs for a specific service
rotate_service_logs() {
    local service=$1
    local log_file="$LOG_DIR/${service}.log"
    
    if [ -f "$log_file" ]; then
        local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
        local max_size=$((100 * 1024 * 1024))  # 100MB in bytes
        
        if [ "$size" -gt "$max_size" ]; then
            echo "Rotating log file: $log_file"
            
            # Rotate existing files
            for i in $(seq $((MAX_LOG_FILES-1)) -1 1); do
                if [ -f "${log_file}.$i" ]; then
                    mv "${log_file}.$i" "${log_file}.$((i+1))"
                fi
            done
            
            # Move current log to .1
            mv "$log_file" "${log_file}.1"
            
            # Create new empty log file
            touch "$log_file"
            
            echo "Log rotation completed for $service"
        fi
    fi
}

# Rotate logs for different services
rotate_service_logs "cluster-monitor"
rotate_service_logs "replication-monitor"
rotate_service_logs "dashboard"

# Clean up old rotated files
find "$LOG_DIR" -name "*.log.*" -type f -mtime +30 -delete

echo "Log rotation check completed at $(date)"
EOF

chmod +x monitoring/rotate-logs.sh
echo "✓ Created log rotation script: monitoring/rotate-logs.sh"

# Create backup script
cat > monitoring/backup-cluster-config.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="monitoring/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Creating cluster configuration backup..."

# Create backup directory for this timestamp
BACKUP_PATH="$BACKUP_DIR/cluster_backup_$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

# Backup cluster nodes information
docker exec redis-node-1 redis-cli -p 9000 cluster nodes > "$BACKUP_PATH/cluster-nodes.txt"
docker exec redis-node-1 redis-cli -p 9000 cluster info > "$BACKUP_PATH/cluster-info.txt"

# Backup configuration files
cp -r config/ "$BACKUP_PATH/" 2>/dev/null || true

# Backup docker-compose configuration
cp docker-compose.yml "$BACKUP_PATH/" 2>/dev/null || true

# Create metadata file
cat > "$BACKUP_PATH/backup-metadata.txt" << METADATA
Backup created: $(date)
Cluster nodes: $(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_known_nodes | cut -d: -f2 | tr -d '\r')
Cluster state: $(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r')
Total keys: $(docker exec redis-node-1 redis-cli -p 9000 dbsize)
METADATA

echo "✓ Backup created: $BACKUP_PATH"

# Clean up old backups (keep last 10)
cd "$BACKUP_DIR"
ls -t | tail -n +11 | xargs rm -rf 2>/dev/null || true

echo "Backup completed successfully"
EOF

chmod +x monitoring/backup-cluster-config.sh
echo "✓ Created backup script: monitoring/backup-cluster-config.sh"

echo ""
echo "Step 7: Setting up log directory..."
mkdir -p monitoring/logs
echo "✓ Created monitoring/logs directory"

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Available monitoring tools:"
echo ""
echo "1. Basic replication monitor:"
echo "   npm run monitor-replication"
echo ""
echo "2. Web dashboard:"
echo "   npm run monitor"
echo "   Then open: http://localhost:3001"
echo ""
echo "3. Monitor with alerting:"
echo "   node monitoring/cluster-monitor-with-alerts.js"
echo ""
echo "4. Log rotation (run periodically):"
echo "   ./monitoring/rotate-logs.sh"
echo ""
echo "5. Backup cluster config:"
echo "   ./monitoring/backup-cluster-config.sh"
echo ""
echo "Configuration files:"
echo "- Alerts config: monitoring/config/alerts.json"
echo "- Systemd service: monitoring/config/redis-cluster-monitor.service"
echo ""
echo "To customize alerting:"
echo "1. Edit monitoring/config/alerts.json"
echo "2. Configure email/webhook settings"
echo "3. Adjust thresholds as needed"
echo ""
echo "For production deployment:"
echo "1. Copy systemd service to /etc/systemd/system/"
echo "2. Update paths in service file"
echo "3. Enable with: systemctl enable redis-cluster-monitor"
echo ""
echo "🎉 Redis Cluster monitoring is ready!"