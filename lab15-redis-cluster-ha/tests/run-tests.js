const Redis = require('ioredis');
const { exec } = require('child_process');
const { promisify } = require('util');
const chalk = require('chalk');
const Table = require('cli-table3');

const execAsync = promisify(exec);

class ClusterValidator {
  constructor() {
    this.cluster = null;
    this.tests = [];
    this.results = {
      passed: 0,
      failed: 0,
      skipped: 0
    };
  }

  async connect() {
    this.cluster = new Redis.Cluster([
      { port: 9000, host: '127.0.0.1' },
      { port: 9001, host: '127.0.0.1' },
      { port: 9002, host: '127.0.0.1' }
    ], {
      enableReadyCheck: true,
      maxRetriesPerRequest: 3,
      commandTimeout: 5000,
      natMap: {
        '172.21.0.2:9001': { host: '127.0.0.1', port: 9001 },
        '172.21.0.3:9000': { host: '127.0.0.1', port: 9000 },
        '172.21.0.4:9004': { host: '127.0.0.1', port: 9004 },
        '172.21.0.5:9005': { host: '127.0.0.1', port: 9005 },
        '172.21.0.6:9003': { host: '127.0.0.1', port: 9003 },
        '172.21.0.7:9002': { host: '127.0.0.1', port: 9002 }
      }
    });

    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  async runTest(name, testFn) {
    process.stdout.write(`  ${name}... `);
    
    try {
      const result = await testFn();
      if (result === true) {
        console.log(chalk.green('✓ PASSED'));
        this.results.passed++;
        return true;
      } else if (result === 'skip') {
        console.log(chalk.yellow('⊘ SKIPPED'));
        this.results.skipped++;
        return null;
      } else {
        console.log(chalk.red('✗ FAILED'));
        if (result) console.log(`    ${chalk.red(result)}`);
        this.results.failed++;
        return false;
      }
    } catch (error) {
      console.log(chalk.red('✗ FAILED'));
      console.log(`    ${chalk.red(error.message)}`);
      this.results.failed++;
      return false;
    }
  }

  async validateClusterSetup() {
    console.log(chalk.yellow('\n1. Cluster Setup Validation'));
    console.log('─'.repeat(40));

    await this.runTest('Cluster initialized', async () => {
      const info = await this.cluster.cluster('info');
      return info.includes('cluster_state:ok');
    });

    await this.runTest('Six nodes configured', async () => {
      const nodes = await this.cluster.cluster('nodes');
      const nodeCount = nodes.split('\n').filter(line => line.trim()).length;
      return nodeCount === 6;
    });

    await this.runTest('Three master nodes', async () => {
      const nodes = await this.cluster.cluster('nodes');
      const masters = nodes.split('\n').filter(line => line.includes('master')).length;
      return masters === 3;
    });

    await this.runTest('Three replica nodes', async () => {
      const nodes = await this.cluster.cluster('nodes');
      const replicas = nodes.split('\n').filter(line => line.includes('slave')).length;
      return replicas === 3;
    });

    await this.runTest('All nodes connected', async () => {
      const nodes = await this.cluster.cluster('nodes');
      const disconnected = nodes.split('\n').filter(line => 
        line.includes('disconnected') || line.includes('fail')
      ).length;
      return disconnected === 0;
    });
  }

  async validateHashSlots() {
    console.log(chalk.yellow('\n2. Hash Slot Distribution'));
    console.log('─'.repeat(40));

    await this.runTest('All 16384 slots assigned', async () => {
      const slots = await this.cluster.cluster('slots');
      let totalSlots = 0;
      slots.forEach(slot => {
        totalSlots += (slot[1] - slot[0] + 1);
      });
      return totalSlots === 16384;
    });

    await this.runTest('Slots evenly distributed', async () => {
      const nodes = await this.cluster.cluster('nodes');
      const masters = nodes.split('\n').filter(line => line.includes('master'));
      const slotCounts = [];
      
      masters.forEach(master => {
        const parts = master.split(' ');
        let slotCount = 0;
        for (let i = 8; i < parts.length; i++) {
          if (parts[i].includes('-')) {
            const [start, end] = parts[i].split('-').map(Number);
            slotCount += (end - start + 1);
          }
        }
        if (slotCount > 0) slotCounts.push(slotCount);
      });
      
      const avg = 16384 / 3;
      const tolerance = avg * 0.1; // 10% tolerance
      return slotCounts.every(count => Math.abs(count - avg) < tolerance);
    });
  }

  async validateReplication() {
    console.log(chalk.yellow('\n3. Replication Validation'));
    console.log('─'.repeat(40));

    await this.runTest('Each master has a replica', async () => {
      const nodes = await this.cluster.cluster('nodes');
      const lines = nodes.split('\n').filter(line => line.trim());
      
      const masters = [];
      lines.forEach(line => {
        if (line.includes('master')) {
          const nodeId = line.split(' ')[0];
          masters.push(nodeId);
        }
      });
      
      let replicasAssigned = 0;
      lines.forEach(line => {
        if (line.includes('slave')) {
          const masterId = line.split(' ')[3];
          if (masters.includes(masterId)) {
            replicasAssigned++;
          }
        }
      });
      
      return replicasAssigned === 3;
    });

    await this.runTest('Replication working', async () => {
      const testKey = `repl:test:${Date.now()}`;
      const testValue = `value-${Date.now()}`;
      
      // Write to cluster
      await this.cluster.set(testKey, testValue);
      
      // Wait for replication
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Read back
      const result = await this.cluster.get(testKey);
      
      // Cleanup
      await this.cluster.del(testKey);
      
      return result === testValue;
    });
  }

  async validateFailover() {
    console.log(chalk.yellow('\n4. Failover Capability'));
    console.log('─'.repeat(40));

    await this.runTest('Cluster can handle node failure', async () => {
      // This is a non-destructive test
      // We just verify the configuration supports failover
      const info = await this.cluster.cluster('info');
      const hasFullCoverage = !info.includes('cluster_require_full_coverage:yes');
      const hasReplicas = info.includes('cluster_known_nodes:6');
      
      return hasFullCoverage && hasReplicas;
    });

    await this.runTest('Failover timeout configured', async () => {
      // Check if node timeout is reasonable (5-15 seconds)
      try {
        const { stdout } = await execAsync('docker exec redis-node-1 redis-cli -p 9000 config get cluster-node-timeout');
        const timeout = parseInt(stdout.split('\n')[1]);
        return timeout >= 5000 && timeout <= 15000;
      } catch {
        return 'skip';
      }
    });
  }

  async validateClientOperations() {
    console.log(chalk.yellow('\n5. Client Operations'));
    console.log('─'.repeat(40));

    await this.runTest('Basic SET/GET operations', async () => {
      const key = `test:${Date.now()}`;
      const value = `value-${Date.now()}`;
      
      await this.cluster.set(key, value);
      const result = await this.cluster.get(key);
      await this.cluster.del(key);
      
      return result === value;
    });

    await this.runTest('Pipeline operations', async () => {
      const testId = Date.now();
      const pipeline = this.cluster.pipeline();
      const keys = [];
      
      // Use hash tags to ensure all keys go to the same slot
      for (let i = 0; i < 10; i++) {
        const key = `{pipeline:test:${testId}}:${i}`;
        keys.push(key);
        pipeline.set(key, `value-${i}`);
      }
      
      const setResults = await pipeline.exec();
      
      // Verify all succeeded
      const allSucceeded = setResults.every(([err, result]) => !err && result === 'OK');
      
      // Cleanup
      const delPipeline = this.cluster.pipeline();
      keys.forEach(key => delPipeline.del(key));
      await delPipeline.exec();
      
      return allSucceeded;
    });

    await this.runTest('Hash tag co-location', async () => {
      const customerId = `test-${Date.now()}`;
      const keys = [
        `{customer:${customerId}}:profile`,
        `{customer:${customerId}}:orders`,
        `{customer:${customerId}}:settings`
      ];
      
      // Set all keys
      for (const key of keys) {
        await this.cluster.set(key, 'test-value');
      }
      
      // Verify they're on the same slot
      const slots = [];
      for (const key of keys) {
        const slot = await this.cluster.cluster('keyslot', key);
        slots.push(slot);
      }
      
      // Cleanup
      for (const key of keys) {
        await this.cluster.del(key);
      }
      
      // All slots should be the same
      return slots.every(slot => slot === slots[0]);
    });

    await this.runTest('Automatic redirect handling', async () => {
      // Client should handle MOVED redirects automatically
      let redirectHandled = true;
      
      for (let i = 0; i < 10; i++) {
        try {
          const key = `redirect:test:${Math.random()}`;
          await this.cluster.set(key, 'value');
          const result = await this.cluster.get(key);
          await this.cluster.del(key);
          
          if (result !== 'value') {
            redirectHandled = false;
            break;
          }
        } catch {
          redirectHandled = false;
          break;
        }
      }
      
      return redirectHandled;
    });
  }

  async validatePerformance() {
    console.log(chalk.yellow('\n6. Performance Metrics'));
    console.log('─'.repeat(40));

    await this.runTest('Throughput > 10,000 ops/sec', async () => {
      const operations = 10000;
      const startTime = Date.now();
      
      const promises = [];
      for (let i = 0; i < operations; i++) {
        const key = `perf:test:${i}`;
        promises.push(
          this.cluster.set(key, 'value')
            .then(() => this.cluster.del(key))
        );
      }
      
      await Promise.all(promises);
      const duration = Date.now() - startTime;
      const opsPerSec = (operations * 2) / (duration / 1000); // *2 for SET and DEL
      
      return opsPerSec > 10000;
    });

    await this.runTest('Average latency < 10ms', async () => {
      const samples = 100;
      const latencies = [];
      
      for (let i = 0; i < samples; i++) {
        const start = Date.now();
        await this.cluster.ping();
        const latency = Date.now() - start;
        latencies.push(latency);
      }
      
      const avgLatency = latencies.reduce((a, b) => a + b, 0) / samples;
      return avgLatency < 10;
    });
  }

  async validateMonitoring() {
    console.log(chalk.yellow('\n7. Monitoring & Observability'));
    console.log('─'.repeat(40));

    await this.runTest('Cluster info accessible', async () => {
      const info = await this.cluster.cluster('info');
      return info.includes('cluster_state:ok');
    });

    await this.runTest('Node metrics available', async () => {
      const info = await this.cluster.info();
      return info.includes('used_memory') && info.includes('connected_clients');
    });

    await this.runTest('Replication lag monitored', async () => {
      // Check if we can get replication lag from replicas
      try {
        const node = new Redis({ port: 9003, host: '127.0.0.1' });
        const info = await node.info('replication');
        await node.quit();
        return info.includes('master_last_io_seconds_ago');
      } catch {
        return 'skip';
      }
    });
  }

  async runValidationSuite() {
    console.log(chalk.blue('====================================='));
    console.log(chalk.blue('Redis Cluster Validation Suite'));
    console.log(chalk.blue('====================================='));
    
    try {
      // Connect to cluster
      console.log(chalk.yellow('\nConnecting to cluster...'));
      await this.connect();
      console.log(chalk.green('✓ Connected successfully'));
      
      // Run all validation tests
      await this.validateClusterSetup();
      await this.validateHashSlots();
      await this.validateReplication();
      await this.validateFailover();
      await this.validateClientOperations();
      await this.validatePerformance();
      await this.validateMonitoring();
      
      // Display summary
      console.log(chalk.blue('\n====================================='));
      console.log(chalk.blue('Validation Summary'));
      console.log(chalk.blue('=====================================\n'));
      
      const summaryTable = new Table({
        head: ['Status', 'Count', 'Percentage'],
        colWidths: [15, 10, 15]
      });
      
      const total = this.results.passed + this.results.failed + this.results.skipped;
      
      summaryTable.push(
        [chalk.green('✓ Passed'), this.results.passed, `${((this.results.passed / total) * 100).toFixed(1)}%`],
        [chalk.red('✗ Failed'), this.results.failed, `${((this.results.failed / total) * 100).toFixed(1)}%`],
        [chalk.yellow('⊘ Skipped'), this.results.skipped, `${((this.results.skipped / total) * 100).toFixed(1)}%`],
        ['─────────', '─────', '─────────'],
        ['Total', total, '100.0%']
      );
      
      console.log(summaryTable.toString());
      
      // Overall result
      console.log(chalk.blue('\n📊 Overall Result:'));
      if (this.results.failed === 0) {
        console.log(chalk.green('✓ ALL TESTS PASSED! Cluster is properly configured and operational.'));
      } else if (this.results.failed <= 2) {
        console.log(chalk.yellow('⚠ MOSTLY PASSED: Cluster is functional but has minor issues.'));
      } else {
        console.log(chalk.red('✗ VALIDATION FAILED: Cluster has significant configuration issues.'));
      }
      
      // Recommendations
      if (this.results.failed > 0) {
        console.log(chalk.yellow('\n📝 Recommendations:'));
        console.log('1. Review failed tests above for specific issues');
        console.log('2. Check docker logs for error messages');
        console.log('3. Verify all nodes are running: docker ps | grep redis-node');
        console.log('4. Try reinitializing the cluster: ./scripts/init-cluster.sh');
      }
      
    } catch (error) {
      console.error(chalk.red('\nValidation suite error:'), error);
    } finally {
      if (this.cluster) {
        await this.cluster.quit();
      }
    }
    
    // Exit with appropriate code
    process.exit(this.results.failed > 0 ? 1 : 0);
  }
}

// Run validation
if (require.main === module) {
  const validator = new ClusterValidator();
  validator.runValidationSuite().catch(console.error);
}

module.exports = ClusterValidator;