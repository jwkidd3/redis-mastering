const Redis = require('ioredis');
const { exec } = require('child_process');
const { promisify } = require('util');
const chalk = require('chalk');
const Table = require('cli-table3');

const execAsync = promisify(exec);

class ChaosTest {
  constructor() {
    this.cluster = null;
    this.results = {
      totalOperations: 0,
      successfulOperations: 0,
      failedOperations: 0,
      nodesKilled: 0,
      nodesRecovered: 0,
      dataLost: false,
      startTime: null,
      endTime: null
    };
    this.testData = new Map();
  }

  async connect() {
    this.cluster = new Redis.Cluster([
      { port: 97000, host: '127.0.0.1' },
      { port: 97002, host: '127.0.0.1' },
      { port: 97004, host: '127.0.0.1' }
    ], {
      enableReadyCheck: true,
      maxRetriesPerRequest: 5,
      retryDelayOnFailover: 100,
      retryDelayOnClusterDown: 300,
      enableOfflineQueue: true
    });

    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  async killRandomNode() {
    const nodes = [1, 2, 3, 4, 5, 6];
    const nodeToKill = nodes[Math.floor(Math.random() * nodes.length)];
    
    console.log(chalk.red(`\n💀 Killing node ${nodeToKill} (port 700${nodeToKill - 1})...`));
    
    try {
      await execAsync(`docker stop redis-node-${nodeToKill}`);
      this.results.nodesKilled++;
      console.log(chalk.red(`✓ Node ${nodeToKill} killed`));
      return nodeToKill;
    } catch (error) {
      console.error(chalk.red(`Failed to kill node ${nodeToKill}:`, error.message));
      return null;
    }
  }

  async recoverNode(nodeNumber) {
    console.log(chalk.green(`\n🔄 Recovering node ${nodeNumber}...`));
    
    try {
      await execAsync(`docker start redis-node-${nodeNumber}`);
      this.results.nodesRecovered++;
      console.log(chalk.green(`✓ Node ${nodeNumber} recovered`));
      
      // Wait for node to rejoin cluster
      await new Promise(resolve => setTimeout(resolve, 3000));
    } catch (error) {
      console.error(chalk.red(`Failed to recover node ${nodeNumber}:`, error.message));
    }
  }

  async performOperations(duration = 1000) {
    const operations = [];
    const startTime = Date.now();
    
    while (Date.now() - startTime < duration) {
      // Generate random operation
      const operation = Math.random();
      const key = `chaos:test:${Math.floor(Math.random() * 1000)}`;
      const value = `value-${Date.now()}-${Math.random()}`;
      
      try {
        if (operation < 0.4) {
          // 40% writes
          await this.cluster.set(key, value);
          this.testData.set(key, value);
          this.results.successfulOperations++;
        } else if (operation < 0.8) {
          // 40% reads
          const result = await this.cluster.get(key);
          if (this.testData.has(key) && result !== this.testData.get(key)) {
            console.log(chalk.yellow(`⚠ Data mismatch for key ${key}`));
            this.results.dataLost = true;
          }
          this.results.successfulOperations++;
        } else {
          // 20% deletes
          await this.cluster.del(key);
          this.testData.delete(key);
          this.results.successfulOperations++;
        }
        
        this.results.totalOperations++;
      } catch (error) {
        this.results.failedOperations++;
        this.results.totalOperations++;
        
        if (!error.message.includes('CLUSTERDOWN')) {
          console.log(chalk.yellow(`Operation failed: ${error.message}`));
        }
      }
      
      // Small delay between operations
      await new Promise(resolve => setTimeout(resolve, 10));
    }
  }

  async verifyDataIntegrity() {
    console.log(chalk.yellow('\n🔍 Verifying data integrity...'));
    
    let verified = 0;
    let missing = 0;
    let mismatched = 0;
    
    for (const [key, expectedValue] of this.testData.entries()) {
      try {
        const actualValue = await this.cluster.get(key);
        
        if (actualValue === null) {
          missing++;
        } else if (actualValue !== expectedValue) {
          mismatched++;
        } else {
          verified++;
        }
      } catch (error) {
        // Key might be on a node that's still down
        missing++;
      }
    }
    
    return { verified, missing, mismatched };
  }

  async runChaosTest() {
    console.log(chalk.blue('====================================='));
    console.log(chalk.blue('Redis Cluster Chaos Test'));
    console.log(chalk.blue('=====================================\n'));
    
    this.results.startTime = Date.now();
    
    try {
      // Connect to cluster
      console.log(chalk.yellow('Connecting to cluster...'));
      await this.connect();
      console.log(chalk.green('✓ Connected to cluster\n'));
      
      // Test scenarios
      const scenarios = [
        {
          name: 'Single Node Failure',
          description: 'Kill one node and continue operations',
          action: async () => {
            const killedNode = await this.killRandomNode();
            await this.performOperations(5000);
            if (killedNode) await this.recoverNode(killedNode);
          }
        },
        {
          name: 'Multiple Node Failures',
          description: 'Kill two nodes sequentially',
          action: async () => {
            const killed1 = await this.killRandomNode();
            await this.performOperations(2000);
            const killed2 = await this.killRandomNode();
            await this.performOperations(2000);
            if (killed1) await this.recoverNode(killed1);
            if (killed2) await this.recoverNode(killed2);
          }
        },
        {
          name: 'Rapid Failover',
          description: 'Kill and recover nodes rapidly',
          action: async () => {
            for (let i = 0; i < 3; i++) {
              const killed = await this.killRandomNode();
              await this.performOperations(1000);
              if (killed) await this.recoverNode(killed);
              await this.performOperations(1000);
            }
          }
        }
      ];
      
      // Run each scenario
      for (const scenario of scenarios) {
        console.log(chalk.cyan(`\n📋 Scenario: ${scenario.name}`));
        console.log(chalk.gray(`   ${scenario.description}`));
        console.log(chalk.gray('   ' + '─'.repeat(40)));
        
        await scenario.action();
        
        // Verify after each scenario
        const integrity = await this.verifyDataIntegrity();
        console.log(chalk.yellow('\n   Post-scenario verification:'));
        console.log(`   ✓ Verified: ${integrity.verified}`);
        console.log(`   ✗ Missing: ${integrity.missing}`);
        console.log(`   ⚠ Mismatched: ${integrity.mismatched}`);
      }
      
      // Final verification
      console.log(chalk.yellow('\n🔍 Final data integrity check...'));
      await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for cluster to stabilize
      
      const finalIntegrity = await this.verifyDataIntegrity();
      
      this.results.endTime = Date.now();
      
      // Display results
      console.log(chalk.blue('\n====================================='));
      console.log(chalk.blue('Chaos Test Results'));
      console.log(chalk.blue('=====================================\n'));
      
      const resultsTable = new Table({
        head: ['Metric', 'Value', 'Status'],
        colWidths: [30, 20, 15]
      });
      
      const duration = ((this.results.endTime - this.results.startTime) / 1000).toFixed(2);
      const successRate = ((this.results.successfulOperations / this.results.totalOperations) * 100).toFixed(2);
      const availability = successRate >= 99.9 ? chalk.green('✓ High') : 
                          successRate >= 99 ? chalk.yellow('⚠ Good') : 
                          chalk.red('✗ Low');
      
      resultsTable.push(
        ['Test Duration', `${duration}s`, ''],
        ['Total Operations', this.results.totalOperations, ''],
        ['Successful Operations', this.results.successfulOperations, chalk.green('✓')],
        ['Failed Operations', this.results.failedOperations, this.results.failedOperations > 0 ? chalk.yellow('⚠') : chalk.green('✓')],
        ['Success Rate', `${successRate}%`, availability],
        ['Nodes Killed', this.results.nodesKilled, ''],
        ['Nodes Recovered', this.results.nodesRecovered, ''],
        ['Data Verified', finalIntegrity.verified, chalk.green('✓')],
        ['Data Missing', finalIntegrity.missing, finalIntegrity.missing === 0 ? chalk.green('✓') : chalk.red('✗')],
        ['Data Mismatched', finalIntegrity.mismatched, finalIntegrity.mismatched === 0 ? chalk.green('✓') : chalk.red('✗')]
      );
      
      console.log(resultsTable.toString());
      
      // Overall assessment
      console.log(chalk.blue('\n📊 Overall Assessment:'));
      
      if (successRate >= 99.9 && finalIntegrity.missing === 0 && finalIntegrity.mismatched === 0) {
        console.log(chalk.green('✓ EXCELLENT: Cluster demonstrated high availability and data integrity'));
      } else if (successRate >= 99 && finalIntegrity.missing + finalIntegrity.mismatched < 10) {
        console.log(chalk.yellow('⚠ GOOD: Cluster handled failures well with minimal data issues'));
      } else {
        console.log(chalk.red('✗ NEEDS IMPROVEMENT: Cluster showed availability or data integrity issues'));
      }
      
      // Cleanup test data
      console.log(chalk.yellow('\n🧹 Cleaning up test data...'));
      const pipeline = this.cluster.pipeline();
      for (const key of this.testData.keys()) {
        pipeline.del(key);
      }
      await pipeline.exec();
      console.log(chalk.green('✓ Cleanup complete'));
      
    } catch (error) {
      console.error(chalk.red('Chaos test failed:'), error);
    } finally {
      if (this.cluster) {
        await this.cluster.quit();
      }
    }
    
    console.log(chalk.blue('\n====================================='));
    console.log(chalk.blue('Chaos Test Complete'));
    console.log(chalk.blue('====================================='));
  }
}

// Run the chaos test
if (require.main === module) {
  const chaos = new ChaosTest();
  chaos.runChaosTest().catch(console.error);
}

module.exports = ChaosTest;