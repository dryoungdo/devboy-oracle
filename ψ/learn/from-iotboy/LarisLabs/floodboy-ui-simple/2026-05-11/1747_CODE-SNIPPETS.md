# Floodboy UI Simple - Code Architecture & Patterns

**Source:** `/home/drdo/Code/github.com/dryoungdo/iotboy/ψ/learn/LarisLabs/floodboy-ui-simple/origin/`
**Date:** 2026-05-11

## Project Overview

Floodboy UI Simple is a **sensor visualization & blockchain dashboard** combining React 18, p5.js for graphics, and Viem for Web3/smart contract integration. Two main entry points:
- **p5.html** - Standalone IoT sensor visualization demo
- **blockchain.html** - Full smart contract dashboard for JIBCHAIN L1 and other EVM chains

---

## 1. Main Entry Points

### blockchain.html - Smart Contract Dashboard

**File:** `/origin/blockchain.html` (162.9KB)

The main entry point for the blockchain integration. Uses inline `<script type="module">` pattern with Viem for Web3 access.

#### Module Import (Viem via ESM)

```javascript
// blockchain.html:66-102
import { createPublicClient, http, parseAbi, formatEther, createWalletClient, custom, decodeEventLog } from 'https://esm.sh/viem@2.21.19';
import { mainnet, sepolia, anvil } from 'https://esm.sh/viem@2.21.19/chains';

// Custom chain configurations
const jibchainL1 = {
    id: 8899,
    name: 'JIBCHAIN L1',
    network: 'jibchain',
    nativeCurrency: { name: 'JBC', symbol: 'JBC', decimals: 18 },
    rpcUrls: {
        default: { http: ['https://rpc-l1.jbc.xpool.pw'] },
        public: { http: ['https://rpc-l1.jbc.xpool.pw'] }
    },
    blockExplorers: {
        default: { name: 'JBC Explorer', url: 'https://exp.jibchain.net' }
    }
};

const sichang = {
    id: 700011,
    name: 'SiChang',
    network: 'sichang',
    nativeCurrency: { name: 'TCH', symbol: 'TCH', decimals: 18 },
    rpcUrls: {
        default: { http: ['https://sichang-rpc.thaichain.org'] },
        public: { http: ['https://sichang-rpc.thaichain.org'] }
    },
    blockExplorers: {
        default: { name: 'SiChang Explorer', url: 'https://sichang.thaichain.org' }
    }
};

// Make viem and chains available globally
window.viem = { createPublicClient, createWalletClient, custom, http, parseAbi, formatEther, decodeEventLog };
window.chains = { mainnet, sepolia, anvil, jibchainL1, sichang };
```

**Key Patterns:**
- Uses **Viem v2.21.19** via ESM CDN (`esm.sh`)
- Exports Viem functions to `window` for React/Babel access
- Supports custom chain configs (JIBCHAIN L1, SiChang)
- Enables both **public client** (read-only) and **wallet client** (transactions)

---

## 2. Core React Components

### 2.1 FloodboyVisualization - p5.js Sensor Graphics

**File:** `blockchain.html:280-628`

Advanced p5.js visualization rendering sensor state with animated water, ripples, and LED indicators.

```javascript
const FloodboyVisualization = ({ storeData, currentBlock }) => {
    const sketchRef = useRef();
    const p5InstanceRef = useRef();
    const propsRef = useRef({ storeData, currentBlock });
    
    useEffect(() => {
        propsRef.current = { storeData, currentBlock };
    }, [storeData, currentBlock]);

    useEffect(() => {
        const sketch = (p) => {
            p.setup = () => {
                const canvas = p.createCanvas(350, 420);
                canvas.parent(sketchRef.current);
                p.frameRate(30);
            };

            p.draw = () => {
                p.clear();
                p.background(255, 255, 255, 0);
                
                const { storeData } = propsRef.current;
                
                // Extract sensor values from blockchain
                let waterLevel = 0;
                let airLevel = 0;
                let installationHeight = 3.0;
                let isOnline = false;
                let isDead = false;
                
                if (storeData && storeData.sensorRecords.length > 0) {
                    const latestRecord = storeData.sensorRecords[0].latestRecord;
                    if (latestRecord && latestRecord.timestamp !== '0') {
                        // Find field indices
                        const waterIdx = storeData.fields.findIndex(f => f.name === 'water_depth');
                        const airIdx = storeData.fields.findIndex(f => f.name === 'air_height');
                        const installIdx = storeData.fields.findIndex(f => f.name === 'installation_height');
                        
                        // Scale values: blockchain stores in mm, convert to meters
                        if (waterIdx >= 0 && latestRecord.values[waterIdx]) {
                            waterLevel = parseInt(latestRecord.values[waterIdx]) / 1000;
                        }
                        if (airIdx >= 0 && latestRecord.values[airIdx]) {
                            airLevel = parseInt(latestRecord.values[airIdx]) / 1000;
                        }
                        if (installIdx >= 0 && latestRecord.values[installIdx]) {
                            installationHeight = parseInt(latestRecord.values[installIdx]) / 1000;
                        }
                        
                        // Status logic: online if data < 1 hour old, dead if > 24 hours
                        const timestamp = parseInt(latestRecord.timestamp);
                        const now = Math.floor(Date.now() / 1000);
                        isOnline = (now - timestamp) < 3600;
                        isDead = (now - timestamp) > 86400;
                    }
                }
                
                // Water surface visualization with wave animation
                if (isDead) {
                    p.fill(239, 68, 68, 102); // Red water when dead
                } else if (isOnline) {
                    p.fill(59, 130, 246, 102); // Blue water when online
                } else {
                    p.fill(245, 158, 11, 102); // Orange water when offline
                }
                p.rect(waterArea, waterY, 150, groundY - waterY);
                
                // Animated ripples at measurement point
                for (let i = 0; i < 3; i++) {
                    const rippleTime = (time * 1.5 + i * 0.8) % 3;
                    const rippleRadius = 5 + rippleTime * 20;
                    const rippleAlpha = Math.max(0, 1 - rippleTime / 3) * 77;
                    
                    if (rippleAlpha > 0) {
                        p.noFill();
                        p.stroke(59, 130, 246, rippleAlpha);
                        p.strokeWeight(1.5 - rippleTime * 0.5);
                        p.ellipse(sensorX, waterY, rippleRadius * 2, rippleRadius * 0.5);
                    }
                }
            };
        };

        // Create p5 instance
        if (sketchRef.current && !p5InstanceRef.current) {
            p5InstanceRef.current = new p5(sketch, sketchRef.current);
        }

        // Cleanup
        return () => {
            if (p5InstanceRef.current) {
                p5InstanceRef.current.remove();
                p5InstanceRef.current = null;
            }
        };
    }, []);

    return <div ref={sketchRef} id="p5-container" className="w-full flex justify-center"></div>;
};
```

**Interesting Patterns:**
- **useRef for p5 lifecycle:** Keeps p5 instance persistent across React renders
- **propsRef.current pattern:** Avoids stale closure in p5 draw loop; reads live props without re-creating sketch
- **Blockchain value scaling:** Stores mm on-chain, converts to meters for display (÷1000)
- **Time-based status:** Determines online/offline/dead from timestamp delta
- **Animated ripples:** `rippleTime % 3` creates continuous expanding circles; alpha calculated as `1 - rippleTime/3` for fade-out

---

### 2.2 SensorDataViews - Table & Chart Toggle

**File:** `blockchain.html:631-977`

Flexible data display with pagination, CSV export, and real-time event fetching from blockchain.

```javascript
const SensorDataViews = ({ storeAddress, fields, publicClient, theme, currentBlock }) => {
    const [viewMode, setViewMode] = useState('chart'); // 'table' or 'chart'
    const [historicalData, setHistoricalData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [page, setPage] = useState(0);
    const recordsPerPage = 20;
    
    // Fetch all historical data
    const fetchHistoricalData = async () => {
        if (!publicClient || !storeAddress) return;
        
        setLoading(true);
        try {
            const currentBlockBigInt = await publicClient.getBlockNumber();
            const fromBlock = currentBlockBigInt > 10000n ? currentBlockBigInt - 10000n : 0n;
            
            // Define the event ABI
            const eventAbi = parseAbi(['event RecordStored(address indexed sensor, uint256 timestamp, int256[] values)'])[0];
            
            const events = await publicClient.getLogs({
                address: storeAddress,
                event: eventAbi,
                fromBlock: fromBlock,
                toBlock: currentBlockBigInt
            });
            
            // Process events with proper decoding
            const processedData = events.map(event => {
                try {
                    const decoded = decodeEventLog({
                        abi: [eventAbi],
                        data: event.data,
                        topics: event.topics
                    });
                    
                    return {
                        timestamp: parseInt(decoded.args.timestamp) * 1000,
                        sensor: decoded.args.sensor,
                        values: decoded.args.values.map(v => Number(v)),
                        block: event.blockNumber.toString(),
                        txHash: event.transactionHash
                    };
                } catch (err) {
                    console.error('Error decoding event:', err);
                    return null;
                }
            }).filter(Boolean).sort((a, b) => b.timestamp - a.timestamp); // Newest first
            
            setHistoricalData(processedData);
        } catch (err) {
            console.error('Error fetching historical data:', err);
        } finally {
            setLoading(false);
        }
    };
```

**Key Patterns:**
- **Event fetching from logs:** Uses Viem's `getLogs` to query past blockchain events
- **Event decoding:** `decodeEventLog` manually parses event topics and data
- **Efficient block scanning:** Only scans last 10,000 blocks to avoid overload
- **Nullable filter:** `.filter(Boolean)` removes failed decodings gracefully

---

### 2.3 SensorDataChart - Chart.js Integration

**File:** `blockchain.html:979-1160`

Real-time charting with dynamic time range selection and statistics memoization.

```javascript
const SensorDataChart = React.memo(({ storeAddress, fields, publicClient, theme, historicalData: propHistoricalData }) => {
    const [historicalData, setHistoricalData] = useState(propHistoricalData || []);
    const [selectedField, setSelectedField] = useState(0);
    const [timeRange, setTimeRange] = useState('24h');
    const chartRef = useRef(null);
    const chartInstanceRef = useRef(null);
    
    const timeRanges = {
        '1h': { label: '1 Hour', seconds: 3600 },
        '6h': { label: '6 Hours', seconds: 21600 },
        '24h': { label: '24 Hours', seconds: 86400 },
        '7d': { label: '7 Days', seconds: 604800 }
    };
    
    // Chart configuration
    const config = {
        type: 'line',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { intersect: false, mode: 'index' },
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: theme === 'dark' ? 'rgba(31, 41, 55, 0.9)' : 'rgba(255, 255, 255, 0.9)',
                    titleColor: theme === 'dark' ? '#F3F4F6' : '#1F2937',
                    bodyColor: theme === 'dark' ? '#D1D5DB' : '#4B5563',
                    borderColor: theme === 'dark' ? '#4B5563' : '#E5E7EB',
                    borderWidth: 1,
                    callbacks: {
                        title: (tooltipItems) => {
                            const date = new Date(tooltipItems[0].parsed.x);
                            return date.toLocaleString();
                        },
                        label: (context) => {
                            return `${field.name}: ${context.parsed.y} ${field.unit}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    type: 'time',
                    time: {
                        tooltipFormat: 'MMM dd, HH:mm',
                        displayFormats: { hour: 'HH:mm', day: 'MMM dd' }
                    },
                    grid: { display: false }
                },
                y: {
                    grid: { color: theme === 'dark' ? 'rgba(75, 85, 99, 0.3)' : 'rgba(229, 231, 235, 0.5)' },
                    ticks: {
                        callback: function(value) {
                            return value + ' ' + field.unit;
                        }
                    }
                }
            }
        }
    };
    
    // Calculate statistics with useMemo
    const stats = useMemo(() => {
        if (historicalData.length === 0) return null;
        
        const values = historicalData.map(d => {
            const value = d.values[selectedField] || 0;
            return parseFloat(formatValue(value, fields[selectedField].unit));
        });
        
        const min = Math.min(...values);
        const max = Math.max(...values);
        const avg = values.reduce((a, b) => a + b, 0) / values.length;
        const latest = values[values.length - 1];
        const previous = values[values.length - 2] || latest;
        const trend = ((latest - previous) / previous * 100).toFixed(1);
        
        return { min, max, avg, trend, latest };
    }, [historicalData, selectedField, fields]);
```

**Interesting Patterns:**
- **Chart.js with date-fns:** Uses `chartjs-adapter-date-fns` for time-series X-axis
- **Data sampling:** Limits to 200 points: `if (processedData.length > maxPoints) { const step = Math.floor(processedData.length / maxPoints); ... }`
- **useMemo for stats:** Only recalculates min/max/avg when data or selectedField changes
- **Theme-aware styling:** Tooltip colors respond to dark/light mode in Chart.js config

---

### 2.4 Main App Component - State & Wallet Integration

**File:** `blockchain.html:1300-1660`

The root component managing wallet connection, chain selection, and store data loading.

```javascript
// Top-level state
const [account, setAccount] = useState(null);
const [walletClient, setWalletClient] = useState(null);
const [publicClient, setPublicClient] = useState(null);
const [chainId, setChainId] = useState(8899); // Default to JIBCHAIN L1
const [selectedChain, setSelectedChain] = useState(8899);
const [blockNumber, setBlockNumber] = useState(null);
const [currentBlock, setCurrentBlock] = useState('0');
const [theme, setTheme] = useState('dark');
const [stores, setStores] = useState([]);
const [selectedStore, setSelectedStore] = useState(null);
const [storeData, setStoreData] = useState(null);
const [viewMode, setViewMode] = useState('public'); // 'wallet', 'public', 'direct'

// Connect wallet - requests MetaMask/wallet access
const connectWallet = async () => {
    try {
        if (!window.ethereum) {
            throw new Error("Please install MetaMask or another Web3 wallet");
        }
        
        // Request accounts
        const accounts = await window.ethereum.request({ 
            method: 'eth_requestAccounts' 
        });
        
        // Get chain ID
        const chainIdHex = await window.ethereum.request({ 
            method: 'eth_chainId' 
        });
        const currentChainId = parseInt(chainIdHex, 16);
        
        // Setup clients based on chain
        const chain = currentChainId === 31337 ? anvil : 
                     currentChainId === 8899 ? jibchainL1 : 
                     currentChainId === 700011 ? sichang : null;
        
        if (!chain || !CONTRACTS[currentChainId]) {
            throw new Error(`Unsupported chain ID: ${currentChainId}`);
        }
        
        const wClient = createWalletClient({
            chain,
            transport: custom(window.ethereum)
        });
        
        const pClient = createPublicClient({
            chain,
            transport: http()
        });
        
        setWalletClient(wClient);
        setPublicClient(pClient);
        setAccount(accounts[0]);
        setChainId(currentChainId);
        setSelectedChain(currentChainId);
        setViewMode('wallet');
        setError(null);
        
        // Load stores for this address
        await loadUserStores(accounts[0], pClient, currentChainId);
    } catch (err) {
        console.error('Connection error:', err);
        setError(err.message);
    }
};

// Fetch block number and update periodically
useEffect(() => {
    if (!publicClient) return;
    
    let fastIntervalId;
    let slowIntervalId;
    
    const fetchBlockNumber = async () => {
        try {
            const block = await publicClient.getBlockNumber();
            
            // Update block number for display (JBC chain only)
            if (chainId === 8899 && block !== blockNumber) {
                setBlockNumber(block);
            }
            
            // Always update current block for data refresh
            setCurrentBlock(block.toString());
        } catch (err) {
            console.error('Error fetching block number:', err);
        }
    };
    
    // Fetch immediately
    fetchBlockNumber();
    
    // For JBC chain, poll every 1 second; others every 5 seconds
    if (chainId === 8899) {
        fastIntervalId = setInterval(fetchBlockNumber, 1000);
    } else {
        slowIntervalId = setInterval(fetchBlockNumber, 5000);
    }
    
    return () => {
        if (fastIntervalId) clearInterval(fastIntervalId);
        if (slowIntervalId) clearInterval(slowIntervalId);
    };
}, [publicClient, chainId, blockNumber]);
```

**Key Patterns:**
- **Wallet detection:** Checks `window.ethereum` before requesting access
- **Chain-aware client setup:** Viem clients configured per chain (anvil, jibchainL1, sichang)
- **Block polling with conditional intervals:** JBC fast (1s), others slow (5s) to balance UX vs RPC load
- **Multi-view architecture:** Switches between 'wallet', 'public', 'direct' modes

---

## 3. Smart Contract Integration

### 3.1 Contract ABIs and Configuration

**File:** `blockchain.html:111-221`

Defines contract addresses and ABIs for two main contracts:

```javascript
const CONTRACTS = {
    31337: { // Anvil
        DEPLOYER_ADDRESS: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
        EXPLORER_URL: "http://localhost:8545",
    },
    700011: { // SiChang
        DEPLOYER_ADDRESS: "0x0000000000000000000000000000000000000000", // To be deployed
        EXPLORER_URL: "https://sichang.thaichain.org",
    },
    8899: { // JIBCHAIN L1
        DEPLOYER_ADDRESS: "0x5cEe5489DdB5006e5c1c1f2029bc7451E4A25837",
        EXPLORER_URL: "https://exp.jibchain.net",
    },
};

// Deployer Contract ABI (Factory Pattern)
const DEPLOYER_ABI = [
    {
        "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
        "name": "getUserStores",
        "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "address", "name": "", "type": "address"}],
        "name": "storeToNickname",
        "outputs": [{"internalType": "string", "name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "creator", "type": "address"},
            {"indexed": false, "internalType": "address", "name": "store", "type": "address"},
            {"indexed": false, "internalType": "string", "name": "nickname", "type": "string"}
        ],
        "name": "SensorStoreDeployed",
        "type": "event"
    }
];

// Sensor Store Contract ABI
const STORE_ABI = [
    {
        "inputs": [],
        "name": "getAllFields",
        "outputs": [{"components": [...], "internalType": "struct SecureSensorStore.Field[]", "name": "", "type": "tuple[]"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "address", "name": "sensor", "type": "address"}],
        "name": "getLatestRecord",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}, {"internalType": "int256[]", "name": "", "type": "int256[]"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "sensor", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"indexed": false, "internalType": "int256[]", "name": "values", "type": "int256[]"}
        ],
        "name": "RecordStored",
        "type": "event"
    }
];
```

**Architecture:**
- **Deployer (Factory):** Tracks store deployments and nicknames
- **Store (Data Contract):** Holds sensor data, fields, and authorization
- **Events:** Emit on deployment, sensor authorization, and data recording

---

### 3.2 Event-Driven Data Loading

**File:** `blockchain.html:1723-1785`

Queries blockchain events to reconstruct store state:

```javascript
// Get authorized sensors from events
const authFilter = await publicClient.createEventFilter({
    address: storeAddress,
    event: parseAbi(['event SensorAuthorized(address indexed sensor)'])[0],
    fromBlock: 'earliest'
});

const revokeFilter = await publicClient.createEventFilter({
    address: storeAddress,
    event: parseAbi(['event SensorRevoked(address indexed sensor)'])[0],
    fromBlock: 'earliest'
});

const [authEvents, revokeEvents] = await Promise.all([
    publicClient.getFilterLogs({ filter: authFilter }),
    publicClient.getFilterLogs({ filter: revokeFilter })
]);

// Calculate currently authorized sensors by replaying events
const authorizedSet = new Set();
authEvents.forEach(event => authorizedSet.add(event.args.sensor));
revokeEvents.forEach(event => authorizedSet.delete(event.args.sensor));
const authorizedSensors = Array.from(authorizedSet);

// Get records from RecordStored events
const recordFilter = await publicClient.createEventFilter({
    address: storeAddress,
    event: parseAbi(['event RecordStored(address indexed sensor, uint256 timestamp, int256[] values)'])[0],
    fromBlock: 'earliest'
});

const recordEvents = await publicClient.getFilterLogs({ filter: recordFilter });

// Process sensor records - group by sensor address
const sensorDataMap = new Map();
recordEvents.forEach(event => {
    const sensor = event.args.sensor;
    if (!sensorDataMap.has(sensor)) {
        sensorDataMap.set(sensor, {
            sensor,
            records: [],
            totalRecords: 0
        });
    }
    const data = sensorDataMap.get(sensor);
    data.records.push({
        timestamp: event.args.timestamp.toString(),
        values: event.args.values.map(v => v.toString())
    });
    data.totalRecords++;
});

// Get latest record for each sensor
const sensorRecords = Array.from(sensorDataMap.values()).map(data => {
    const latestRecord = data.records.length > 0 
        ? data.records[data.records.length - 1]
        : { timestamp: '0', values: [] };
    
    return {
        sensor: data.sensor,
        totalRecords: data.totalRecords.toString(),
        latestRecord
    };
});
```

**Interesting Pattern:**
- **Event replay for state:** Rather than storing explicit state, replays auth/revoke events to compute current authorized set
- **Map-based aggregation:** Groups records by sensor address for efficient lookup
- **Latest record extraction:** Maintains full history but surfaces latest per sensor

---

## 4. p5.html - Standalone Visualization

**File:** `/origin/p5.html` (40.1KB)

Simplified version focused on sensor visualization without blockchain integration.

### React Component - SensorVisualizationP5

**File:** `p5.html:48-428`

```javascript
const SensorVisualizationP5 = ({ waterLevel, airLevel, sensorMode, installationHeight = 2.5, showMeasurement = true, isOnline = true, isDead = false }) => {
    const sketchRef = useRef();
    const p5InstanceRef = useRef();
    const propsRef = useRef({ waterLevel, airLevel, sensorMode, installationHeight, showMeasurement, isOnline, isDead });

    // Update props ref
    useEffect(() => {
        propsRef.current = { waterLevel, airLevel, sensorMode, installationHeight, showMeasurement, isOnline, isDead };
    }, [waterLevel, airLevel, sensorMode, installationHeight, showMeasurement, isOnline, isDead]);

    useEffect(() => {
        const sketch = (p) => {
            p.setup = () => {
                const canvas = p.createCanvas(350, 420);
                canvas.parent(sketchRef.current);
                p.frameRate(30);
            };

            p.draw = () => {
                p.clear();
                p.background(255, 255, 255, 0);
                
                // Get current props from ref
                const { waterLevel: currentWaterLevel, airLevel: currentAirLevel, sensorMode: currentSensorMode, installationHeight: currentInstallationHeight, showMeasurement: currentShowMeasurement, isOnline, isDead } = propsRef.current;
                
                // Draw base/foundation
                p.fill(75, 85, 99);
                p.rect(centerX - 30, baseY - 20, 60, 20, 2);
                p.fill(55, 65, 81);
                p.rect(centerX - 40, baseY - 5, 80, 8);
                
                // Draw vertical pole
                p.fill(107, 114, 128);
                p.rect(centerX - 5, yOffset + 70, 10, 30);
                p.fill(156, 163, 175, 127);
                p.rect(centerX - 3, yOffset + 70, 6, 300);
                
                // ... (solar panel, arm, sensor rendering)
            };
        };

        // Create p5 instance
        if (sketchRef.current && !p5InstanceRef.current) {
            p5InstanceRef.current = new p5(sketch, sketchRef.current);
        }

        // Cleanup
        return () => {
            if (p5InstanceRef.current) {
                p5InstanceRef.current.remove();
                p5InstanceRef.current = null;
            }
        };
    }, []);

    return <div ref={sketchRef} id="p5-container" className="w-full flex justify-center"></div>;
};

// Main App Component
const App = () => {
    const [waterLevel, setWaterLevel] = useState(1.5);
    const [airLevel, setAirLevel] = useState(2.3);
    const [sensorMode, setSensorMode] = useState('water');
    const [installationHeight, setInstallationHeight] = useState(2.5);
    const [showMeasurement, setShowMeasurement] = useState(true);
    const [isOnline, setIsOnline] = useState(true);
    const [isDead, setIsDead] = useState(false);
    
    // Mock data presets
    const mockDataPresets = {
        normal: { 
            waterLevel: Math.min(0.5, installationHeight), 
            airLevel: installationHeight - 0.5,
            isOnline: true, 
            isDead: false 
        },
        flooding: { 
            waterLevel: Math.min(installationHeight * 0.8, installationHeight),
            airLevel: installationHeight * 0.2,
            isOnline: true, 
            isDead: false 
        },
        dry: { 
            waterLevel: 0, 
            airLevel: installationHeight,
            isOnline: true, 
            isDead: false 
        },
        offline: { 
            waterLevel: Math.min(0.3, installationHeight), 
            airLevel: installationHeight - 0.3, 
            isOnline: false, 
            isDead: false 
        },
        dead: { 
            waterLevel: Math.min(installationHeight * 0.6, installationHeight), 
            airLevel: installationHeight * 0.4, 
            isOnline: false, 
            isDead: true 
        }
    };
    
    const applyPreset = (preset) => {
        setWaterLevel(Math.min(preset.waterLevel, installationHeight));
        setAirLevel(preset.airLevel);
        setIsOnline(preset.isOnline);
        setIsDead(preset.isDead);
    };
    
    useEffect(() => {
        // Enforce max water level = installation height
        if (waterLevel > installationHeight) {
            setWaterLevel(installationHeight);
        }
    }, [installationHeight]);
```

**Patterns:**
- **Preset system:** Quick scenario buttons (Normal, Flooding, Dry, Offline, Dead)
- **Constraint enforcement:** Prevents water level > installation height
- **Dual mode support:** Water depth or air distance measurement modes

---

## 5. Interesting Patterns & Idioms

### 5.1 useRef for p5.js Lifecycle Management

**Why useful:**
- p5 sketch expects a permanent reference to persist animations and state
- Prevents re-instantiation on React re-renders (which would break animations)
- `propsRef.current` allows p5's draw loop to read latest React state without closure staling

```javascript
const sketchRef = useRef();
const p5InstanceRef = useRef();
const propsRef = useRef({ waterLevel, airLevel, ... });

useEffect(() => {
    propsRef.current = { waterLevel, airLevel, ... }; // Keep in sync
}, [waterLevel, airLevel, ...]);

useEffect(() => {
    const sketch = (p) => {
        p.draw = () => {
            const { waterLevel } = propsRef.current; // Read live value
            // ... render with current waterLevel
        };
    };
    p5InstanceRef.current = new p5(sketch);
    return () => p5InstanceRef.current?.remove();
}, []);
```

### 5.2 Viem Event Decoding Pattern

**File:** `blockchain.html:649-679`

```javascript
const eventAbi = parseAbi(['event RecordStored(address indexed sensor, uint256 timestamp, int256[] values)'])[0];

const events = await publicClient.getLogs({
    address: storeAddress,
    event: eventAbi,
    fromBlock: fromBlock,
    toBlock: currentBlockBigInt
});

const processedData = events.map(event => {
    try {
        const decoded = decodeEventLog({
            abi: [eventAbi],
            data: event.data,
            topics: event.topics
        });
        
        return {
            timestamp: parseInt(decoded.args.timestamp) * 1000,
            sensor: decoded.args.sensor,
            values: decoded.args.values.map(v => Number(v)),
            block: event.blockNumber.toString(),
            txHash: event.transactionHash
        };
    } catch (err) {
        console.error('Error decoding event:', err);
        return null; // Will be filtered out
    }
}).filter(Boolean).sort((a, b) => b.timestamp - a.timestamp);
```

**Key insight:** Viem's `parseAbi` converts ABI string to object, `decodeEventLog` manually parses topics + data. Graceful error handling with filter.

### 5.3 Theme-Aware Tailwind Conditionals

**File:** `blockchain.html:776-789`

```javascript
<div className={`rounded-lg p-6 border ${
    theme === 'dark' 
        ? 'bg-gray-800 border-gray-700' 
        : 'bg-white border-gray-200 shadow-sm'
}`}>
    <h3 className={`text-lg font-semibold ${
        theme === 'dark' ? 'text-white' : 'text-gray-900'
    }`}>Sensor Data</h3>
</div>
```

**Pattern:** Every visual component reads `theme` state and applies dark/light variants via template literals. Maintains consistency across 162KB of HTML.

### 5.4 useMemo for Expensive Computations

**File:** `blockchain.html:1173-1189`

```javascript
const stats = useMemo(() => {
    if (historicalData.length === 0) return null;
    
    const values = historicalData.map(d => {
        const value = d.values[selectedField] || 0;
        return parseFloat(formatValue(value, fields[selectedField].unit));
    });
    
    const min = Math.min(...values);
    const max = Math.max(...values);
    const avg = values.reduce((a, b) => a + b, 0) / values.length;
    const latest = values[values.length - 1];
    const previous = values[values.length - 2] || latest;
    const trend = ((latest - previous) / previous * 100).toFixed(1);
    
    return { min, max, avg, trend, latest };
}, [historicalData, selectedField, fields]);
```

Only recalculates when data or field selection changes, not on every render.

### 5.5 Chart.js with React Refs & Cleanup

**File:** `blockchain.html:1061-1160`

```javascript
useEffect(() => {
    if (!chartRef.current || historicalData.length === 0) return;
    
    const ctx = chartRef.current.getContext('2d');
    
    // Destroy existing chart
    if (chartInstanceRef.current) {
        chartInstanceRef.current.destroy();
    }
    
    // Create new chart
    chartInstanceRef.current = new Chart(ctx, config);
    
    // Cleanup on unmount
    return () => {
        if (chartInstanceRef.current) {
            chartInstanceRef.current.destroy();
        }
    };
}, [historicalData, selectedField, theme, fields]);
```

**Pattern:** Viem + Chart.js require manual DOM refs and cleanup. Destroys old chart before creating new to avoid memory leaks.

---

## 6. Technology Stack Summary

| Technology | Version/Source | Usage |
|-----------|----------------|-------|
| **React** | 18 (CDN) | Component framework |
| **Babel Standalone** | Latest (CDN) | JSX transpilation |
| **p5.js** | 1.7.0 | Sensor visualization graphics |
| **Viem** | 2.21.19 (esm.sh) | Web3 client, contract reads, event decoding |
| **Chart.js** | 4.4.0 | Historical data visualization |
| **date-fns** | 2.29.3 + chartjs adapter | Time series formatting |
| **Tailwind CSS** | Latest (CDN) | Responsive styling |

---

## 7. Files Breakdown

| File | Size | Purpose |
|------|------|---------|
| `blockchain.html` | 162.9 KB | Full smart contract dashboard, theme support, wallet integration |
| `p5.html` | 40.1 KB | Standalone sensor viz, mock data presets, control panel |
| `README.md` | 2.0 KB | Quick start guide |
| `run.sh` | 1.0 KB | Local dev server launcher |
| `img/Cat-Lab.png` | Logo | Floodboy mascot |

---

## Key Takeaways

1. **Viem over ethers.js:** Uses Viem v2 for lighter weight, better TypeScript, modern ESM support
2. **Event-driven architecture:** Reconstructs contract state from blockchain events rather than direct state queries
3. **Animation-aware refs:** p5.js lifecycle managed carefully with useRef + propsRef pattern to avoid stale closures
4. **Multi-chain support:** Dynamically configures RPC + ABI based on selected chain (JIBCHAIN L1, SiChang, Anvil)
5. **Theme as first-class:** All components respond to `theme` state for dark/light mode
6. **No build step:** Inline Babel + CDN libs enable deployment as single HTML files

