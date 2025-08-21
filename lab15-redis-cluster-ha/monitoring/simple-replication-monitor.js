const { exec } = require('child_process');
const chalk = require('chalk');
const Table = require('cli-table3');

class SimpleReplicationMonitor {
  constructor() {
    this.isRunning = false;
    this.stats = {
      totalChecks: 0,
      warnings: 0,
      criticals: 0,
      startTime: Date.now()
    };
  }

  async getClusterNodes() {
    return new Promise((resolve, reject) => {
      exec('docker exec redis-node-1 redis-cli -p 9000 cluster nodes', (error, stdout, stderr) => {
        if (error) {
          reject(error);
        } else {
          resolve(stdout.trim());
        }
      });
    });
  }

  async getReplicationInfo(containerName, port) {
    return new Promise((resolve, reject) => {
      exec(`docker exec ${containerName} redis-cli -p ${port} info replication`, (error, stdout, stderr) => {
        if (error) {
          reject(error);
        } else {
          const info = {};
          stdout.split('\r\n').forEach(line => {
            if (line.includes(':')) {
              const [key, value] = line.split(':');
              info[key] = value;
            }
          });
          resolve(info);
        }
      });
    });
  }

  parseNodes(nodesOutput) {
    const masters = [];
    const replicas = [];
    
    const lines = nodesOutput.split('\n').filter(line => line.trim());
    
    for (const line of lines) {
      const parts = line.split(' ');
      if (parts.length < 8) continue;

      const node = {
        id: parts[0],
        address: parts[1],
        flags: parts[2],
        masterId: parts[3] !== '-' ? parts[3] : null,
        linkState: parts[7]
      };

      // Extract port and container info
      const [host, portInfo] = node.address.split(':');
      const port = parseInt(portInfo.split('@')[0]);
      node.port = port;
      node.containerName = `redis-node-${port - 8999}`; // 9000->1, 9001->2, etc.

      if (node.flags.includes('master')) {
        masters.push(node);
      } else if (node.flags.includes('slave')) {
        replicas.push(node);
      }
    }

    return { masters, replicas };
  }

  async monitorReplication() {
    try {
      console.log(chalk.gray('Fetching cluster topology...'));
      const nodesOutput = await this.getClusterNodes();
      const { masters, replicas } = this.parseNodes(nodesOutput);

      console.log(chalk.gray(`Found ${masters.length} masters and ${replicas.length} replicas`));

      if (replicas.length === 0) {
        console.log(chalk.yellow('No replica nodes found in cluster!'));
        return [];
      }

      const results = [];

      for (const replica of replicas) {
        const master = masters.find(m => m.id === replica.masterId);
        
        try {
          const replicationInfo = await this.getReplicationInfo(replica.containerName, replica.port);
          
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
          } else if (lastIOSecondsAgo > 5) {
            status = chalk.red('CRITICAL_LAG');
            lagLevel = 'critical';
            this.stats.criticals++;
          } else if (lastIOSecondsAgo > 1) {
            status = chalk.yellow('HIGH_LAG');
            lagLevel = 'warning';
            this.stats.warnings++;
          } else {
            status = chalk.green('HEALTHY');
          }

          results.push({
            replicaId: replica.id.substring(0, 8),
            replicaAddress: replica.address,
            replicaContainer: replica.containerName,
            masterAddress: master ? master.address : `${masterHost}:${masterPort}`,
            status,
            lag: `${lastIOSecondsAgo}s`,
            lastIO: lastIOSecondsAgo === 0 ? 'Just now' : `${lastIOSecondsAgo}s ago`,
            linkStatus: masterLinkStatus,
            lagLevel
          });

        } catch (error) {
          results.push({
            replicaId: replica.id.substring(0, 8),
            replicaAddress: replica.address,
            replicaContainer: replica.containerName,
            masterAddress: master ? master.address : 'Unknown',
            status: chalk.red('ERROR'),
            lag: 'N/A',
            lastIO: 'N/A',
            linkStatus: 'error',
            lagLevel: 'critical',
            error: error.message
          });
          this.stats.criticals++;
        }
      }

      this.stats.totalChecks++;
      return results;

    } catch (error) {
      console.error(chalk.red('Failed to monitor replication:'), error.message);
      return [];
    }
  }

  displayResults(results) {
    console.clear();
    
    console.log(chalk.blue('====================================='));
    console.log(chalk.blue('Redis Cluster Replication Monitor'));
    console.log(chalk.blue('====================================='));
    
    const now = new Date();
    console.log(`Last Updated: ${now.toLocaleTimeString()}`);
    console.log(`Uptime: ${Math.floor((Date.now() - this.stats.startTime) / 1000)}s | Checks: ${this.stats.totalChecks} | Warnings: ${this.stats.warnings} | Criticals: ${this.stats.criticals}\n`);

    if (results.length === 0) {
      console.log(chalk.yellow('No replication data available.\n'));
      return;
    }

    const monitorTable = new Table({
      head: ['Replica ID', 'Container', 'Replica Address', 'Master Address', 'Status', 'Lag', 'Last I/O'],
      colWidths: [12, 14, 18, 18, 15, 8, 12]
    });

    for (const result of results) {
      monitorTable.push([
        result.replicaId,
        result.replicaContainer,
        result.replicaAddress,
        result.masterAddress,
        result.status,
        result.lag,
        result.lastIO
      ]);
    }

    console.log(monitorTable.toString());

    // Summary
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
        console.log(chalk.red(`  - ${result.replicaContainer}: ${result.error || 'Replication issues'}`));
      });
    }

    console.log(chalk.gray('\nPress Ctrl+C to stop monitoring...\n'));
  }

  async start() {
    this.isRunning = true;
    console.log(chalk.green('Starting simple replication monitor...\n'));

    const monitorLoop = async () => {
      if (!this.isRunning) return;

      const results = await this.monitorReplication();
      this.displayResults(results);

      setTimeout(monitorLoop, 3000); // Update every 3 seconds
    };

    // Start monitoring
    monitorLoop();

    // Handle Ctrl+C
    process.on('SIGINT', () => {
      this.stop();
    });
  }

  stop() {
    this.isRunning = false;
    const uptimeSeconds = Math.floor((Date.now() - this.stats.startTime) / 1000);
    
    console.log(chalk.yellow('\nStopping monitor...'));
    console.log(chalk.blue('\nSession Summary:'));
    console.log(`Runtime: ${uptimeSeconds}s | Checks: ${this.stats.totalChecks} | Warnings: ${this.stats.warnings} | Criticals: ${this.stats.criticals}`);
    console.log(chalk.green('Monitor stopped.'));
    process.exit(0);
  }
}

// Start the monitor
const monitor = new SimpleReplicationMonitor();
monitor.start().catch(console.error);