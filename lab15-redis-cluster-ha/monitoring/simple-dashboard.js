const express = require('express');
const { exec } = require('child_process');
const chalk = require('chalk');

const app = express();
const PORT = 3001;

// Helper function to execute Docker commands
function execCommand(command) {
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
          padding: 15px;
          background: rgba(255,255,255,0.05);
          border-radius: 8px;
          border-left: 4px solid #4CAF50;
        }
        .master {
          border-left-color: #4CAF50;
        }
        .replica {
          border-left-color: #2196F3;
        }
        .fail {
          border-left-color: #f44336;
          opacity: 0.7;
        }
        .metric {
          display: flex;
          justify-content: space-between;
          margin: 8px 0;
          font-size: 14px;
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
        .node-id {
          font-family: monospace;
          font-size: 12px;
          opacity: 0.8;
        }
        .slots {
          font-family: monospace;
          font-size: 12px;
        }
        pre {
          background: rgba(0,0,0,0.3);
          padding: 15px;
          border-radius: 5px;
          overflow-x: auto;
          font-size: 12px;
          line-height: 1.4;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Redis Cluster Dashboard</h1>
        <div id="dashboard"></div>
        <div class="refresh">Auto-refreshing every 3 seconds...</div>
      </div>
      <script>
        async function fetchData() {
          try {
            const response = await fetch('/api/cluster-status');
            const data = await response.json();
            updateDashboard(data);
          } catch (error) {
            console.error('Failed to fetch cluster status:', error);
            document.getElementById('dashboard').innerHTML = 
              '<div class="card"><h2>Error</h2><p>Failed to connect to cluster</p></div>';
          }
        }

        function updateDashboard(data) {
          const dashboard = document.getElementById('dashboard');
          
          let html = '<div class="grid">';
          
          // Cluster Overview Card
          html += '<div class="card">';
          html += '<h2>📊 Cluster Overview</h2>';
          html += '<div class="metric"><span>Status:</span><span class="metric-value ' + 
                  (data.clusterInfo.state === 'ok' ? 'status-ok' : 'status-fail') + '">' + 
                  data.clusterInfo.state.toUpperCase() + '</span></div>';
          html += '<div class="metric"><span>Known Nodes:</span><span class="metric-value">' + 
                  data.clusterInfo.knownNodes + '</span></div>';
          html += '<div class="metric"><span>Slots Assigned:</span><span class="metric-value">' + 
                  data.clusterInfo.slotsAssigned + '</span></div>';
          html += '<div class="metric"><span>Slots OK:</span><span class="metric-value">' + 
                  data.clusterInfo.slotsOk + '</span></div>';
          html += '<div class="metric"><span>Current Epoch:</span><span class="metric-value">' + 
                  data.clusterInfo.currentEpoch + '</span></div>';
          html += '</div>';
          
          // Nodes Details Card
          html += '<div class="card">';
          html += '<h2>🖥️ Node Details</h2>';
          data.nodes.forEach(node => {
            const statusClass = node.flags.includes('fail') ? 'fail' : 
                               (node.role === 'master' ? 'master' : 'replica');
            html += '<div class="node ' + statusClass + '">';
            html += '<div style="display: flex; justify-content: space-between; align-items: center;">';
            html += '<strong>Port ' + node.port + ' - ' + node.role.toUpperCase() + '</strong>';
            html += '<span class="node-id">' + node.id.substring(0, 8) + '...</span>';
            html += '</div>';
            
            if (node.role === 'master') {
              html += '<div class="metric"><span>Hash Slots:</span><span class="metric-value slots">' + 
                      (node.slots || 'None') + '</span></div>';
              if (node.replicas && node.replicas.length > 0) {
                html += '<div class="metric"><span>Replicas:</span><span class="metric-value">' + 
                        node.replicas.length + '</span></div>';
              }
            } else if (node.role === 'slave') {
              html += '<div class="metric"><span>Master:</span><span class="metric-value">Port ' + 
                      node.masterPort + '</span></div>';
            }
            
            html += '<div class="metric"><span>Status:</span><span class="metric-value">' + 
                    node.flags + '</span></div>';
            html += '</div>';
          });
          html += '</div>';
          
          html += '</div>';
          
          // Raw Cluster Info
          html += '<div class="card">';
          html += '<h2>🔍 Raw Cluster Info</h2>';
          html += '<pre>' + data.rawInfo + '</pre>';
          html += '</div>';
          
          dashboard.innerHTML = html;
        }

        // Initial fetch and auto-refresh
        fetchData();
        setInterval(fetchData, 3000);
      </script>
    </body>
    </html>
  `);
});

// API endpoint for cluster status
app.get('/api/cluster-status', async (req, res) => {
  try {
    // Get cluster info using docker exec
    const clusterInfoRaw = await execCommand('docker exec redis-node-1 redis-cli -p 9000 cluster info');
    const clusterNodesRaw = await execCommand('docker exec redis-node-1 redis-cli -p 9000 cluster nodes');
    
    // Parse cluster info
    const clusterInfo = {};
    clusterInfoRaw.split('\r\n').forEach(line => {
      const [key, value] = line.split(':');
      if (key && value) {
        clusterInfo[key.replace('cluster_', '')] = value;
      }
    });

    // Parse cluster nodes
    const nodes = [];
    clusterNodesRaw.split('\n').forEach(line => {
      if (line.trim()) {
        const parts = line.split(' ');
        if (parts.length >= 8) {
          const node = {
            id: parts[0],
            address: parts[1],
            port: parseInt(parts[1].split(':')[1]) || 'unknown',
            flags: parts[2],
            master: parts[3],
            pingSent: parts[4],
            pongRecv: parts[5],
            configEpoch: parts[6],
            linkState: parts[7],
            slots: parts.slice(8).join(' ') || 'None'
          };
          
          // Determine role
          if (node.flags.includes('master')) {
            node.role = 'master';
            node.masterPort = null;
          } else if (node.flags.includes('slave')) {
            node.role = 'slave';
            // Find master port
            const masterNode = clusterNodesRaw.split('\n').find(l => l.startsWith(node.master));
            if (masterNode) {
              node.masterPort = parseInt(masterNode.split(' ')[1].split(':')[1]);
            }
          }
          
          nodes.push(node);
        }
      }
    });

    // Find replicas for each master
    nodes.forEach(node => {
      if (node.role === 'master') {
        node.replicas = nodes.filter(n => n.master === node.id);
      }
    });

    const response = {
      clusterInfo: {
        state: clusterInfo.state || 'unknown',
        slotsAssigned: clusterInfo.slots_assigned || '0',
        slotsOk: clusterInfo.slots_ok || '0',
        knownNodes: clusterInfo.known_nodes || '0',
        currentEpoch: clusterInfo.current_epoch || '0'
      },
      nodes: nodes,
      rawInfo: clusterInfoRaw,
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Error getting cluster status:', error);
    res.status(500).json({ 
      error: 'Failed to get cluster status',
      message: error.message 
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(chalk.green(`\n✓ Simple Dashboard running at http://localhost:${PORT}`));
  console.log(chalk.blue('This dashboard uses Docker exec commands for cluster info\n'));
});