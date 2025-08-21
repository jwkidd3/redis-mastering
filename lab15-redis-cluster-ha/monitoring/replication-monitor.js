const Redis = require('ioredis');
const chalk = require('chalk');
const Table = require('cli-table3');

// Create cluster connection
const cluster = new Redis.Cluster([
  { port: 9000, host: '127.0.0.1' },
  { port: 9001, host: '127.0.0.1' },
  { port: 9002, host: '127.0.0.1' }
], {
  enableReadyCheck: true,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100
});

// Configuration
const MONITOR_INTERVAL = 2000; // 2 seconds
const MAX_LAG_WARNING = 1; // seconds
const MAX_LAG_CRITICAL = 5; // seconds

class ReplicationMonitor {
  constructor() {
    this.isRunning = false;
    this.masterNodes = new Map();
    this.replicaNodes = new Map();
    this.stats = {
      totalChecks: 0,
      warnings: 0,
      criticals: 0,
      startTime: Date.now()
    };
  }

  async initialize() {
    console.log(chalk.blue('====================================='));
    console.log(chalk.blue('Redis Cluster Replication Monitor'));
    console.log(chalk.blue('=====================================\n'));

    try {
      await this.discoverNodes();
      console.log(chalk.green('✓ Node discovery complete'));
      console.log(chalk.yellow(`Discovered ${this.masterNodes.size} masters and ${this.replicaNodes.size} replicas\n`));
      
      if (this.replicaNodes.size === 0) {
        console.log(chalk.yellow('⚠ No replica nodes found. This might indicate:'));
        console.log('  - All nodes are masters (no replication configured)');
        console.log('  - Cluster is still initializing');
        console.log('  - Connection or parsing issues\n');
      }
      
      this.displayNodeTopology();
      
    } catch (error) {
      console.error(chalk.red('Failed to initialize monitor:'), error.message);
      throw error;
    }
  }

  async discoverNodes() {
    const nodes = await cluster.cluster('nodes');
    const nodeLines = nodes.split('\n').filter(line => line.trim());

    for (const line of nodeLines) {
      const parts = line.split(' ');
      if (parts.length < 8) continue;

      const nodeInfo = {
        id: parts[0],
        address: parts[1],
        flags: parts[2],
        masterId: parts[3] !== '-' ? parts[3] : null,
        ping: parseInt(parts[4]) || 0,
        pong: parseInt(parts[5]) || 0,
        epoch: parseInt(parts[6]) || 0,
        linkState: parts[7],
        slots: parts.slice(8).join(' ')
      };

      // Extract host and port
      const [host, portInfo] = nodeInfo.address.split(':');
      const port = parseInt(portInfo.split('@')[0]);
      
      nodeInfo.host = host;
      nodeInfo.port = port;

      if (nodeInfo.flags.includes('master')) {
        this.masterNodes.set(nodeInfo.id, nodeInfo);
        console.log(chalk.gray(`  Found master: ${nodeInfo.address} (${nodeInfo.flags})`));
      } else if (nodeInfo.flags.includes('slave') || nodeInfo.flags.includes('replica')) {
        this.replicaNodes.set(nodeInfo.id, nodeInfo);
        console.log(chalk.gray(`  Found replica: ${nodeInfo.address} (${nodeInfo.flags}) -> master: ${nodeInfo.masterId?.substring(0,8)}`));
      } else {
        console.log(chalk.gray(`  Skipped node: ${nodeInfo.address} (${nodeInfo.flags})`));
      }
    }
  }

  displayNodeTopology() {
    console.log(chalk.yellow('Cluster Topology:'));
    console.log('=================');

    const topologyTable = new Table({
      head: ['Type', 'Node ID', 'Address', 'Status', 'Master/Replica Relationship'],
      colWidths: [8, 12, 15, 12, 30]
    });

    // Add masters
    for (const [id, node] of this.masterNodes) {
      const replicas = Array.from(this.replicaNodes.values())
        .filter(replica => replica.masterId === id)
        .map(replica => `${replica.host}:${replica.port}`)
        .join(', ');

      topologyTable.push([
        'Master',
        id.substring(0, 8),
        `${node.host}:${node.port}`,
        node.linkState === 'connected' ? chalk.green('Connected') : chalk.red('Disconnected'),
        replicas || 'No replicas'
      ]);
    }

    // Add replicas
    for (const [id, node] of this.replicaNodes) {
      const master = this.masterNodes.get(node.masterId);
      const masterAddress = master ? `${master.host}:${master.port}` : 'Unknown master';

      topologyTable.push([
        'Replica',
        id.substring(0, 8),
        `${node.host}:${node.port}`,
        node.linkState === 'connected' ? chalk.green('Connected') : chalk.red('Disconnected'),
        `Replica of ${masterAddress}`
      ]);
    }

    console.log(topologyTable.toString());
    console.log('');
  }

  async getReplicationInfo(host, port) {
    try {
      const nodeClient = new Redis({
        host,
        port,
        connectTimeout: 1000,
        commandTimeout: 1000,
        retryDelayOnFailover: 100,
        maxRetriesPerRequest: 1
      });

      const info = await nodeClient.info('replication');
      await nodeClient.quit();

      const replicationInfo = {};
      const lines = info.split('\r\n');
      
      for (const line of lines) {
        if (line.includes(':')) {
          const [key, value] = line.split(':');
          replicationInfo[key] = value;
        }
      }

      return replicationInfo;
    } catch (error) {
      return { error: error.message };
    }
  }

  async monitorReplication() {
    this.stats.totalChecks++;
    const monitoringResults = [];

    // Monitor all replica nodes
    for (const [id, replica] of this.replicaNodes) {
      const master = this.masterNodes.get(replica.masterId);
      if (!master) continue;

      const replicationInfo = await this.getReplicationInfo(replica.host, replica.port);
      
      if (replicationInfo.error) {
        monitoringResults.push({
          replicaId: id.substring(0, 8),
          replicaAddress: `${replica.host}:${replica.port}`,
          masterAddress: `${master.host}:${master.port}`,
          status: chalk.red('ERROR'),
          lag: 'N/A',
          lastIO: 'N/A',
          error: replicationInfo.error
        });
        this.stats.criticals++;
        continue;
      }

      const role = replicationInfo.role;
      const masterLinkStatus = replicationInfo.master_link_status;
      const lastIOSecondsAgo = parseInt(replicationInfo.master_last_io_seconds_ago) || 0;
      const masterHost = replicationInfo.master_host;
      const masterPort = replicationInfo.master_port;

      let status;
      let lagLevel = 'normal';

      if (role !== 'slave') {
        status = chalk.red('NOT_REPLICA');
        lagLevel = 'critical';
        this.stats.criticals++;
      } else if (masterLinkStatus !== 'up') {
        status = chalk.red('LINK_DOWN');
        lagLevel = 'critical';
        this.stats.criticals++;
      } else if (lastIOSecondsAgo > MAX_LAG_CRITICAL) {
        status = chalk.red('CRITICAL_LAG');
        lagLevel = 'critical';
        this.stats.criticals++;
      } else if (lastIOSecondsAgo > MAX_LAG_WARNING) {
        status = chalk.yellow('HIGH_LAG');
        lagLevel = 'warning';
        this.stats.warnings++;
      } else {
        status = chalk.green('HEALTHY');
      }

      monitoringResults.push({
        replicaId: id.substring(0, 8),
        replicaAddress: `${replica.host}:${replica.port}`,
        masterAddress: `${masterHost}:${masterPort}`,
        status,
        lag: `${lastIOSecondsAgo}s`,
        lastIO: lastIOSecondsAgo === 0 ? 'Just now' : `${lastIOSecondsAgo}s ago`,
        linkStatus: masterLinkStatus,
        lagLevel
      });
    }

    return monitoringResults;
  }

  displayMonitoringResults(results) {
    // Clear screen for real-time display
    console.clear();
    
    console.log(chalk.blue('====================================='));
    console.log(chalk.blue('Redis Cluster Replication Monitor'));
    console.log(chalk.blue('====================================='));
    
    const now = new Date();
    console.log(`Last Updated: ${now.toLocaleTimeString()}`);
    console.log(`Uptime: ${Math.floor((Date.now() - this.stats.startTime) / 1000)}s | Checks: ${this.stats.totalChecks} | Warnings: ${this.stats.warnings} | Criticals: ${this.stats.criticals}\n`);

    const monitorTable = new Table({
      head: ['Replica ID', 'Replica Address', 'Master Address', 'Status', 'Lag', 'Last I/O'],
      colWidths: [12, 18, 18, 15, 8, 12]
    });

    for (const result of results) {
      monitorTable.push([
        result.replicaId,
        result.replicaAddress,
        result.masterAddress,
        result.status,
        result.lag,
        result.lastIO
      ]);
    }

    console.log(monitorTable.toString());

    // Display summary statistics
    const healthyCount = results.filter(r => r.lagLevel === 'normal').length;
    const warningCount = results.filter(r => r.lagLevel === 'warning').length;
    const criticalCount = results.filter(r => r.lagLevel === 'critical').length;

    console.log('\nReplication Health Summary:');
    console.log('==========================');
    console.log(`${chalk.green('●')} Healthy: ${healthyCount}`);
    console.log(`${chalk.yellow('●')} Warning: ${warningCount}`);
    console.log(`${chalk.red('●')} Critical: ${criticalCount}`);

    if (criticalCount > 0) {
      console.log(chalk.red('\n⚠ CRITICAL ISSUES DETECTED!'));
      results.filter(r => r.lagLevel === 'critical').forEach(result => {
        console.log(chalk.red(`  - ${result.replicaAddress}: ${result.error || 'Replication issues'}`));
      });
    }

    console.log(chalk.gray('\nPress Ctrl+C to stop monitoring...\n'));
  }

  async start() {
    if (this.isRunning) return;

    this.isRunning = true;
    console.log(chalk.green('Starting replication monitoring...'));
    console.log(chalk.gray(`Monitoring interval: ${MONITOR_INTERVAL}ms`));
    console.log(chalk.gray(`Warning threshold: ${MAX_LAG_WARNING}s`));
    console.log(chalk.gray(`Critical threshold: ${MAX_LAG_CRITICAL}s\n`));

    const monitorLoop = async () => {
      if (!this.isRunning) return;

      try {
        const results = await this.monitorReplication();
        this.displayMonitoringResults(results);
      } catch (error) {
        console.error(chalk.red('Monitoring error:'), error.message);
      }

      setTimeout(monitorLoop, MONITOR_INTERVAL);
    };

    // Start monitoring loop
    monitorLoop();

    // Handle graceful shutdown
    process.on('SIGINT', () => {
      this.stop();
    });
  }

  stop() {
    if (!this.isRunning) return;

    console.log(chalk.yellow('\nStopping replication monitor...'));
    this.isRunning = false;
    
    // Display final statistics
    const uptimeSeconds = Math.floor((Date.now() - this.stats.startTime) / 1000);
    console.log(chalk.blue('\nMonitoring Session Summary:'));
    console.log('===========================');
    console.log(`Total Runtime: ${uptimeSeconds}s`);
    console.log(`Total Checks: ${this.stats.totalChecks}`);
    console.log(`Warnings Detected: ${this.stats.warnings}`);
    console.log(`Critical Issues: ${this.stats.criticals}`);
    console.log(`Average Check Interval: ${uptimeSeconds > 0 ? (this.stats.totalChecks / uptimeSeconds).toFixed(2) : 0}/s`);

    cluster.quit().then(() => {
      console.log(chalk.green('✓ Monitoring stopped'));
      process.exit(0);
    });
  }
}

// Create and start monitor
async function startReplicationMonitor() {
  try {
    const monitor = new ReplicationMonitor();
    await monitor.initialize();
    await monitor.start();
  } catch (error) {
    console.error(chalk.red('Failed to start replication monitor:'), error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  startReplicationMonitor().catch(console.error);
}

module.exports = ReplicationMonitor;