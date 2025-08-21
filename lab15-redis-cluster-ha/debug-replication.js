const Redis = require('ioredis');
const chalk = require('chalk');

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

async function debugReplication() {
  console.log('Debugging Redis Cluster Replication...\n');

  try {
    // Test cluster connectivity
    console.log('1. Testing cluster connectivity...');
    const ping = await cluster.ping();
    console.log(`   Ping result: ${ping}`);

    // Get cluster nodes
    console.log('\n2. Getting cluster nodes...');
    const nodes = await cluster.cluster('nodes');
    console.log('   Raw cluster nodes output:');
    console.log('   ' + nodes.replace(/\n/g, '\n   '));

    // Parse nodes
    console.log('\n3. Parsing nodes...');
    const nodeLines = nodes.split('\n').filter(line => line.trim());
    console.log(`   Found ${nodeLines.length} node lines`);

    let masters = [];
    let replicas = [];

    for (const line of nodeLines) {
      const parts = line.split(' ');
      if (parts.length < 8) {
        console.log(`   Skipping invalid line: ${line}`);
        continue;
      }

      const nodeInfo = {
        id: parts[0],
        address: parts[1],
        flags: parts[2],
        masterId: parts[3] !== '-' ? parts[3] : null,
        linkState: parts[7]
      };

      console.log(`   Node: ${nodeInfo.address} | Flags: ${nodeInfo.flags} | Master: ${nodeInfo.masterId || 'none'} | State: ${nodeInfo.linkState}`);

      if (nodeInfo.flags.includes('master')) {
        masters.push(nodeInfo);
      } else if (nodeInfo.flags.includes('slave')) {
        replicas.push(nodeInfo);
      }
    }

    console.log(`\n4. Summary:`);
    console.log(`   Masters found: ${masters.length}`);
    console.log(`   Replicas found: ${replicas.length}`);

    // Test replication info from a replica
    if (replicas.length > 0) {
      console.log('\n5. Testing replication info from first replica...');
      const replica = replicas[0];
      const [host, portInfo] = replica.address.split(':');
      const port = parseInt(portInfo.split('@')[0]);
      
      console.log(`   Connecting to replica: ${host}:${port}`);
      
      const replicaClient = new Redis({
        host,
        port,
        connectTimeout: 2000,
        commandTimeout: 2000
      });

      try {
        const info = await replicaClient.info('replication');
        console.log('   Replication info:');
        const lines = info.split('\r\n').filter(line => line.includes(':'));
        lines.forEach(line => {
          if (line.includes('role:') || line.includes('master_') || line.includes('slave_')) {
            console.log(`     ${line}`);
          }
        });
        await replicaClient.quit();
      } catch (error) {
        console.log(`   Error getting replication info: ${error.message}`);
      }
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await cluster.quit();
    console.log('\nDebug complete.');
  }
}

debugReplication().catch(console.error);