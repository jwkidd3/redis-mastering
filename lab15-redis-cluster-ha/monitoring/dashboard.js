const Redis = require('ioredis');
const express = require('express');
const chalk = require('chalk');

const app = express();
const PORT = 3000;

// Cluster connection
const cluster = new Redis.Cluster([
  { port: 9000, host: '127.0.0.1' },
  { port: 9001, host: '127.0.0.1' },
  { port: 9002, host: '127.0.0.1' }
], {
  enableReadyCheck: true,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
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

// Serve static HTML
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Redis Cluster Dashboard</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
          color: #fff;
          margin: 0;
          padding: 20px;
        }
        .container {
          max-width: 1400px;
          margin: 0 auto;
        }
        h1 {
          text-align: center;
          margin-bottom: 30px;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
          gap: 20px;
          margin-bottom: 30px;
        }
        .card {
          background: rgba(255,255,255,0.1);
          backdrop-filter: blur(10px);
          border-radius: 10px;
          padding: 20px;
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
          border: 1px solid rgba(255,255,255,0.18);
        }
        .card h2 {
          margin-top: 0;
          border-bottom: 2px solid rgba(255,255,255,0.3);
          padding-bottom: 10px;
        }
        .node {
          margin: 10px 0;
          padding: 10px;
          background: rgba(255,255,255,0.05);
          border-radius: 5px;
        }
        .master {
          border-left: 4px solid #4CAF50;
        }
        .replica {
          border-left: 4px solid #2196F3;
        }
        .down {
          border-left: 4px solid #f44336;
          opacity: 0.6;
        }
        .metric {
          display: flex;
          justify-content: space-between;
          margin: 5px 0;
        }
        .metric-value {
          font-weight: bold;
        }
        .status-ok {
          color: #4CAF50;
        }
        .status-fail {
          color: #f44336;
        }
        .refresh {
          text-align: center;
          margin-top: 20px;
          color: rgba(255,255,255,0.7);
        }
        table {
          width: 100%;
          border-collapse: collapse;
        }
        th, td {
          padding: 8px;
          text-align: left;
          border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        th {
          background: rgba(255,255,255,0.1);
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Redis Cluster Dashboard</h1>
        <div id="dashboard"></div>
        <div class="refresh">Auto-refreshing every 2 seconds...</div>
      </div>
      <script>
        async function fetchData() {
          try {
            const response = await fetch('/api/cluster-status');
            const data = await response.json();
            updateDashboard(data);
          } catch (error) {
            console.error('Failed to fetch cluster status:', error);
          }
        }

        function updateDashboard(data) {
          const dashboard = document.getElementById('dashboard');
          
          let html = '<div class="grid">';
          
          // Cluster Overview Card
          html += '<div class="card">';
          html += '<h2>Cluster Overview</h2>';
          html += '<div class="metric"><span>Status:</span><span class="metric-value ' + 
                  (data.clusterInfo.state === 'ok' ? 'status-ok' : 'status-fail') + '">' + 
                  data.clusterInfo.state.toUpperCase() + '</span></div>';
          html += '<div class="metric"><span>Total Nodes:</span><span class="metric-value">' + 
                  data.clusterInfo.knownNodes + '</span></div>';
          html += '<div class="metric"><span>Total Slots:</span><span class="metric-value">16384</span></div>';
          html += '<div class="metric"><span>Slots Covered:</span><span class="metric-value">' + 
                  data.clusterInfo.slotsCovered + '</span></div>';
          html += '<div class="metric"><span>Current Epoch:</span><span class="metric-value">' + 
                  data.clusterInfo.currentEpoch + '</span></div>';
          html += '</div>';
          
          // Nodes Status Card
          html += '<div class="card">';
          html += '<h2>Nodes Status</h2>';
          data.nodes.forEach(node => {
            const statusClass = node.connected ? (node.role === 'master' ? 'master' : 'replica') : 'down';
            html += '<div class="node ' + statusClass + '">';
            html += '<strong>Port ' + node.port + ' - ' + node.role.toUpperCase() + '</strong>';
            if (node.connected) {
              html += '<div class="metric"><span>Memory:</span><span class="metric-value">' + 
                      node.memory + '</span></div>';
              if (node.role === 'master') {
                html += '<div class="metric"><span>Slots:</span><span class="metric-value">' + 
                        node.slots + '</span></div>';
                html += '<div class="metric"><span>Keys:</span><span class="metric-value">' + 
                        node.keys + '</span></div>';
              } else {
                html += '<div class="metric"><span>Master:</span><span class="metric-value">Port ' + 
                        node.masterPort + '</span></div>';
                html += '<div class="metric"><span>Lag:</span><span class="metric-value">' + 
                        node.lag + 's</span></div>';
              }
            } else {
              html += '<div style="color: #f44336;">Node is down</div>';
            }
            html += '</div>';
          });
          html += '</div>';
          
          html += '</div>';
          
          // Performance Metrics Card
          html += '<div class="card">';
          html += '<h2>Performance Metrics</h2>';
          html += '<table>';
          html += '<tr><th>Node</th><th>Ops/sec</th><th>Connections</th><th>CPU</th></tr>';
          data.nodes.forEach(node => {
            if (node.connected) {
              html += '<tr>';
              html += '<td>Port ' + node.port + '</td>';
              html += '<td>' + (node.opsPerSec || 'N/A') + '</td>';
              html += '<td>' + (node.connectedClients || 'N/A') + '</td>';
              html += '<td>' + (node.cpuUsage || 'N/A') + '</td>';
              html += '</tr>';
            }
          });
          html += '</table>';
          html += '</div>';
          
          dashboard.innerHTML = html;
        }

        // Initial fetch and auto-refresh
        fetchData();
        setInterval(fetchData, 2000);
      </script>
    </body>
    </html>
  `);
});

// API endpoint for cluster status
app.get('/api/cluster-status', async (req, res) => {
  try {
    const status = {
      clusterInfo: {},
      nodes: [],
      timestamp: new Date().toISOString()
    };

    // Get cluster info
    const clusterInfo = await cluster.cluster('info');
    const lines = clusterInfo.split('\r\n');
    lines.forEach(line => {
      if (line.includes('cluster_state:')) {
        status.clusterInfo.state = line.split(':')[1];
      } else if (line.includes('cluster_known_nodes:')) {
        status.clusterInfo.knownNodes = parseInt(line.split(':')[1]);
      } else if (line.includes('cluster_current_epoch:')) {
        status.clusterInfo.currentEpoch = parseInt(line.split(':')[1]);
      }
    });

    // Calculate slots covered
    let slotsCovered = 0;
    const slots = await cluster.cluster('slots');
    slots.forEach(slot => {
      slotsCovered += (slot[1] - slot[0] + 1);
    });
    status.clusterInfo.slotsCovered = slotsCovered;

    // Get info for each node
    const ports = [9000, 9001, 9002, 9003, 9004, 9005];
    
    for (const port of ports) {
      const nodeInfo = {
        port: port,
        connected: false,
        role: 'unknown',
        memory: 'N/A',
        slots: 0,
        keys: 0
      };

      try {
        const node = new Redis({ port, host: '127.0.0.1' });
        
        // Get replication info
        const replInfo = await node.info('replication');
        const replLines = replInfo.split('\r\n');
        replLines.forEach(line => {
          if (line.includes('role:')) {
            nodeInfo.role = line.split(':')[1];
            nodeInfo.connected = true;
          }
          if (line.includes('master_port:')) {
            nodeInfo.masterPort = parseInt(line.split(':')[1]);
          }
          if (line.includes('master_last_io_seconds_ago:')) {
            nodeInfo.lag = parseInt(line.split(':')[1]);
          }
        });

        // Get memory info
        const memInfo = await node.info('memory');
        const memLines = memInfo.split('\r\n');
        memLines.forEach(line => {
          if (line.includes('used_memory_human:')) {
            nodeInfo.memory = line.split(':')[1];
          }
        });

        // Get stats
        const statsInfo = await node.info('stats');
        const statsLines = statsInfo.split('\r\n');
        statsLines.forEach(line => {
          if (line.includes('instantaneous_ops_per_sec:')) {
            nodeInfo.opsPerSec = parseInt(line.split(':')[1]);
          }
        });

        // Get clients
        const clientsInfo = await node.info('clients');
        const clientsLines = clientsInfo.split('\r\n');
        clientsLines.forEach(line => {
          if (line.includes('connected_clients:')) {
            nodeInfo.connectedClients = parseInt(line.split(':')[1]);
          }
        });

        // Get keyspace info for masters
        if (nodeInfo.role === 'master') {
          const keyspaceInfo = await node.info('keyspace');
          const keyspaceLines = keyspaceInfo.split('\r\n');
          let totalKeys = 0;
          keyspaceLines.forEach(line => {
            if (line.startsWith('db')) {
              const keys = parseInt(line.split('keys=')[1]?.split(',')[0] || 0);
              totalKeys += keys;
            }
          });
          nodeInfo.keys = totalKeys;

          // Get slot count for this master
          const nodesInfo = await node.cluster('nodes');
          const nodeLines = nodesInfo.split('\n');
          nodeLines.forEach(line => {
            if (line.includes('myself') && line.includes('master')) {
              const parts = line.split(' ');
              let slotCount = 0;
              for (let i = 8; i < parts.length; i++) {
                if (parts[i].includes('-')) {
                  const range = parts[i].split('-');
                  slotCount += (parseInt(range[1]) - parseInt(range[0]) + 1);
                }
              }
              nodeInfo.slots = slotCount;
            }
          });
        }

        await node.quit();
      } catch (error) {
        // Node is down or not accessible
        nodeInfo.connected = false;
      }

      status.nodes.push(nodeInfo);
    }

    res.json(status);
  } catch (error) {
    console.error('Error getting cluster status:', error);
    res.status(500).json({ error: 'Failed to get cluster status' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(chalk.green(`\n✓ Dashboard running at http://localhost:${PORT}`));
  console.log(chalk.blue('Open your browser to view the Redis Cluster Dashboard\n'));
});