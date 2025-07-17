const WebSocket = require('ws');

const endpoint = process.env.ENDPOINT;
const waitTime = parseInt(process.env.WAIT, 10) || 60;

if (!endpoint) {
  console.error('Error: ENDPOINT environment variable is not set');
  process.exit(1);
}

// Parse number of concurrent connections
const connections = parseInt(process.env.CONNECTIONS, 10) || 1;
console.log(`Opening ${connections} connections to ${endpoint}`);

// Open multiple WebSocket connections
for (let i = 0; i < connections; i++) {
  const ws = new WebSocket(endpoint, { rejectUnauthorized: false });

  ws.on('open', () => {
    console.log(`Connection ${i} opened, holding open for ${waitTime} seconds`);
    setTimeout(() => {
      console.log(`Connection ${i} closing`);
      ws.close();
    }, waitTime * 1000);
  });

  ws.on('error', err => {
    console.error(`WebSocket ${i} error:`, err.message);
  });
}
