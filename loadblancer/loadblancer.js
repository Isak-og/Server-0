const http = require('http');

const containers = [
  { host: 'localhost', port: 8001 },
  { host: 'localhost', port: 8002 },
  { host: 'localhost', port: 8003 },
  { host: 'localhost', port: 8004 },
  { host: 'localhost', port: 8005 },
];

// Health check timeout in ms
const HEALTH_CHECK_TIMEOUT = 2000;

// Time window before it's allowed to switch (e.g., 10000 ms = 10 seconds)
const TIME_WINDOW_MS = 10000;

// Memory variables to track the current state
let currentActiveContainer = null;
let lastSwitchTime = 0;

// Helper function to randomly shuffle an array
function shuffleArray(array) {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

// Check if a container is available by making a simple HTTP GET request
function checkContainer(container) {
  return new Promise((resolve) => {
    const req = http.request(
      { 
        hostname: container.host, 
        port: container.port, 
        method: 'GET', 
        timeout: HEALTH_CHECK_TIMEOUT, 
        path: '/' 
      },
      (res) => {
        resolve(res.statusCode === 200);
      }
    );

    req.on('error', () => resolve(false));
    req.on('timeout', () => {
      req.destroy();
      resolve(false);
    });

    req.end();
  });
}

// Find a random available container, sticking to it for a fixed time window
async function getAvailableContainer() {
  const now = Date.now();

  // Condition 1: If we have an active container AND the time window has NOT expired
  if (currentActiveContainer && (now - lastSwitchTime < TIME_WINDOW_MS)) {
    // We still must check if it's healthy (in case it crashed during the time window)
    const isHealthy = await checkContainer(currentActiveContainer);
    if (isHealthy) {
      console.log(`[Time Window Active] Routing to Port ${currentActiveContainer.port}`);
      return currentActiveContainer;
    }
  }

  // Condition 2: Time window expired OR the active container died
  // Shuffle the containers so we pick a random one
  const randomizedContainers = shuffleArray(containers);
  
  for (const container of randomizedContainers) {
    const isAvailable = await checkContainer(container);
    if (isAvailable) {
      // Update our memory variables with the new container and current time
      currentActiveContainer = container;
      lastSwitchTime = now;
      console.log(`[Time Expired/Switching] Now routing to Port ${currentActiveContainer.port}`);
      return container;
    }
  }

  // Condition 3: Total failure (no containers available)
  currentActiveContainer = null;
  return null;
}

// Create the proxy server
const server = http.createServer(async (req, res) => {
  const target = await getAvailableContainer();

  if (!target) {
    res.statusCode = 503;
    res.end('503 Service Unavailable: No containers available');
    return;
  }

  const proxyReq = http.request(
    { 
      hostname: target.host, 
      port: target.port, 
      method: req.method, 
      path: req.url, 
      headers: req.headers 
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res, { end: true });
    }
  );

  proxyReq.on('error', () => {
    res.statusCode = 502;
    res.end('502 Bad Gateway');
  });

  req.pipe(proxyReq, { end: true });
});

const LISTEN_PORT = 3000;
server.listen(LISTEN_PORT, () => {
  console.log(`Failover proxy server running on http://localhost:${LISTEN_PORT}`);
});
