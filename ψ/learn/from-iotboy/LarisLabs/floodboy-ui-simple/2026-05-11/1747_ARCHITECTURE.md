# Floodboy UI Simple - Architecture Analysis

**Repository**: LarisLabs/floodboy-ui-simple  
**Last Commit**: f9b748e (Initial commit: Flood sensor visualization demos with p5.js and blockchain integration)  
**Language Tag**: HTML  
**Actual Focus**: Blockchain/Web3 IoT Dashboard + Real-time Sensor Visualization  
**Date**: 2026-05-11

---

## Project Overview

Floodboy UI Simple is a **pure-HTML + CDN-based web application** that demonstrates:

1. **Real-time flood sensor monitoring** with interactive p5.js visualizations
2. **Smart contract integration** for on-chain IoT data storage and retrieval
3. **Multi-chain blockchain support** (Anvil, JIBCHAIN L1, SiChang)
4. **Live sensor data dashboards** with charts, tables, and historical data export

The entire application runs **without build tools, package.json, or any server-side code**. Everything is browser-based with ES modules loaded from CDNs.

---

## Directory Structure

```
floodboy-ui-simple/
├── p5.html                      # IoT Sensor Visualization Demo (40KB)
├── blockchain.html              # Smart Contract Dashboard (162KB, 2755 lines)
├── img/
│   └── Cat-Lab.png             # Project logo/mascot
├── run.sh                       # Local dev server launcher script
├── README.md                    # User documentation
└── .git/                        # Git history (single initial commit)
```

**Key Design Philosophy**: Zero-build, all-CDN approach. No dependencies to install. Open HTML file directly in browser or serve via local HTTP.

---

## Entry Points

### 1. **p5.html** - Sensor Visualization Demo
- **Type**: Standalone HTML5 application
- **Purpose**: Interactive flood sensor monitoring with water/air measurement modes
- **Load Method**: Direct browser open or HTTP server
- **Dependencies**: CDN-loaded React 18, p5.js, Tailwind CSS, Viem (Web3)

**Features**:
- Real-time p5.js animation of sensor apparatus
- Water level & air distance visualization
- Sensor status indicators (Online/Offline/Dead)
- Installation height calibration
- Mock data presets (Normal, Flooding, Dry, Offline, Dead)
- Preset scenarios with realistic physics relationships
- No blockchain interaction (pure visualization)

**Entry Point Logic**:
```html
<div id="root"></div>
<script type="module">
  // Import viem for potential Web3 capabilities
  import { createPublicClient, http, parseAbi, formatEther } from 'https://esm.sh/viem@2.21.19'
  // ...
</script>
<script type="text/babel">
  // React App component with SensorVisualizationP5 sub-component
  ReactDOM.render(<App />, document.getElementById('root'))
</script>
```

### 2. **blockchain.html** - IoT Factory Smart Contract Dashboard
- **Type**: Standalone HTML5 application with Web3 wallet integration
- **Purpose**: Query and visualize on-chain IoT sensor data from smart contracts
- **Load Method**: Direct browser open or HTTP server
- **URL Query Parameters**:
  - `?store=0x...` - Direct store address to load
  - `?chain=8899|700011|31337` - Blockchain chain ID (JIBCHAIN L1, SiChang, Anvil)
  - `?mode=public|wallet|direct` - View mode
  - `?address=0x...` - Public address for user stores view
- **Legacy URL Format**: `#store/0x...` (hash-based routing)

**Three Operation Modes**:
1. **Direct Store View** (default): Query specific smart contract store by address
2. **Wallet Connected View**: Browse user's own stores after MetaMask connection
3. **Public View**: Browse stores of any public address without wallet connection

---

## Core Abstractions & Relationships

### 1. **Blockchain Client Layer** (Viem ESM Module)

```javascript
// Imported from https://esm.sh/viem@2.21.19
import { 
  createPublicClient, 
  createWalletClient, 
  http, 
  custom,
  parseAbi, 
  formatEther, 
  decodeEventLog 
} from 'https://esm.sh/viem@2.21.19'

import { 
  mainnet, 
  sepolia, 
  anvil 
} from 'https://esm.sh/viem@2.21.19/chains'
```

**Custom Chain Configurations**:
- **JIBCHAIN L1** (ID: 8899)
  - RPC: `https://rpc-l1.jbc.xpool.pw`
  - Explorer: `https://exp.jibchain.net`
  - Native Currency: JBC (18 decimals)

- **SiChang** (ID: 700011)
  - RPC: `https://sichang-rpc.thaichain.org`
  - Explorer: `https://sichang.thaichain.org`
  - Native Currency: TCH (18 decimals)

- **Anvil** (ID: 31337)
  - Local development chain
  - RPC: `http://localhost:8545`

### 2. **Smart Contract Interface Layer**

Two core ABIs (Application Binary Interfaces):

#### **DEPLOYER_ABI** (Factory Pattern)
Manages store creation and user lookups:
```javascript
- getUserStores(address user) → address[]
- storeToNickname(address store) → string
- getStoreMetadata(address store) → (deployedBlock, lastUpdatedBlock, description, pointer)
- event SensorStoreDeployed(indexed address creator, address store, string nickname)
```

**Deployed Addresses**:
- Anvil (31337): `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`
- JIBCHAIN L1 (8899): `0x5cEe5489DdB5006e5c1c1f2029bc7451E4A25837`
- SiChang (700011): Not deployed (placeholder)

#### **STORE_ABI** (Data Store Contract)
Stores and retrieves sensor data with field definitions:
```javascript
- getAllFields() → Field[] (struct with name, unit, dtype)
- getLatestRecord(address sensor) → (uint256 timestamp, int256[] values)
- isSensorAuthorized(address sensor) → bool
- owner() → address
- event RecordStored(indexed address sensor, uint256 timestamp, int256[] values)
- event SensorAuthorized(indexed address sensor)
- event SensorRevoked(indexed address sensor)
```

### 3. **React Component Hierarchy**

```
<App>                           # Main state management & blockchain interaction
├── <SensorDataViews>           # Tabbed interface for sensor data
│   ├── Table View
│   │   └── Pagination controls
│   └── Chart View
│       └── <SensorDataChart>   # Chart.js visualization component
├── <FloodboyVisualization>     # p5.js canvas-based sensor apparatus drawing
└── Theme Switcher             # Fixed dark/light mode toggle
```

**Core Component Props Flow**:
1. `App` fetches contract data → sets `storeData` state
2. `storeData` passes to `FloodboyVisualization` (props: waterLevel, airLevel, sensorMode, etc.)
3. p5.js sketch reads `propsRef.current` on each animation frame (no re-renders)
4. `SensorDataViews` manages table/chart toggle and pagination
5. `SensorDataChart` uses Chart.js with time range filtering

### 4. **Data Flow Architecture**

```
User Browser
    ↓
URL Parameters (mode, store, chain)
    ↓
[Chain Selection] → publicClient setup (HTTP RPC)
    ↓
    ├→ [Direct Store View]
    │   └→ readContract(DEPLOYER_ABI) → fields metadata
    │   └→ readContract(STORE_ABI) → latest sensor readings
    │
    ├→ [Wallet Connected View]
    │   └→ window.ethereum → MetaMask
    │   └→ eth_requestAccounts → account address
    │   └→ readContract(DEPLOYER_ABI.getUserStores)
    │   └→ Load all user stores & their data
    │
    └→ [Public View]
        └→ publicAddress parameter
        └→ readContract(DEPLOYER_ABI.getUserStores)
        └→ Load public user's visible stores

    ↓
Event Log Filtering (async)
    └→ createEventFilter(RecordStored events)
    └→ Parse historical data from blockchain
    └→ CSV export capability

    ↓
Display Layer
    ├→ FloodboyVisualization (p5.js)
    ├→ Table (paginated, 10 records default)
    ├→ Chart.js (time-range filtered: 1h/6h/24h/7d)
    └→ Block number indicator (JBC chain polling)
```

### 5. **Helper Functions & Utilities**

```javascript
// Value formatting with unit scaling
formatValue(value, unit)
  - Handles: °C, pH, %, m, V with custom divisors
  - Example: "m x 1000" → divides by 1000 (mm to m conversion)

// Address shortening
formatAddress(address) → "0x1234...cdef"

// Human-readable timestamps
getTimeAgo(timestamp) → "5 minutes ago" | "2 hours ago" | "3 days ago"

// CSV Export
exportToCSV()
  - Generates columns: Timestamp, Sensor, Field values (with units), Block
  - Blob download with ISO timestamp filename
```

### 6. **State Management (React Hooks)**

**App-level state** (blockchain.html):
- `walletClient` - Viem wallet client (post-connection)
- `publicClient` - Viem public client (HTTP RPC)
- `account` - Connected wallet address
- `chainId` - Current blockchain network ID
- `stores` - List of user/public stores
- `selectedStore` - Currently viewing store details
- `storeData` - Contract data (fields, sensor records, metadata)
- `viewMode` - 'public' | 'wallet' | 'direct'
- `theme` - 'light' | 'dark' (applied to body classList)
- `currentBlock` - Latest blockchain block number
- `blockNumber` - For JBC chain polling indicator

**SensorDataViews state**:
- `viewMode` - 'table' | 'chart'
- `page` - Pagination offset
- `historicalData` - Cached event log records
- `recordsPerPage` - Default 10

**SensorDataChart state**:
- `selectedField` - Which sensor field to chart
- `timeRange` - '1h' | '6h' | '24h' | '7d'
- `chartInstanceRef` - Chart.js instance management

**p5.html App state**:
- `waterLevel` - Meters (0 to installationHeight)
- `airLevel` - Meters (ultrasonic distance reading)
- `sensorMode` - 'water' | 'air'
- `installationHeight` - Sensor height above ground (meters)
- `showMeasurement` - Toggle measurement labels
- `isOnline` - Sensor data freshness (< 1 hour = online)
- `isDead` - No data for 24+ hours

---

## Dependencies (All CDN-Based)

### React Ecosystem
```html
<!-- React 18 (production build, no JSX compilation) -->
<script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>

<!-- Babel standalone for JSX transformation in browser -->
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
```

### Graphics & Visualization
```html
<!-- p5.js 1.7.0 (creative coding library) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.7.0/p5.min.js"></script>

<!-- Chart.js 4.4.0 (data charting) -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

<!-- date-fns 2.29.3 (date utilities for Chart.js adapter) -->
<script src="https://cdn.jsdelivr.net/npm/date-fns@2.29.3/index.min.js"></script>

<!-- Chart.js date-fns adapter -->
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"></script>
```

### Styling & UI
```html
<!-- Tailwind CSS (JIT compiled, no build step) -->
<script src="https://cdn.tailwindcss.com"></script>
```

### Web3/Blockchain
```javascript
// Viem - lightweight Ethereum/EVM library (ESM module)
import { createPublicClient, createWalletClient, custom, http, ... } 
  from 'https://esm.sh/viem@2.21.19'

import { mainnet, sepolia, anvil, ... } 
  from 'https://esm.sh/viem@2.21.19/chains'
```

**No build tools required**: 
- No webpack, Vite, or rollup
- No package.json or npm dependencies
- All imports loaded via `<script type="module">` or ESM CDN (`esm.sh`)
- Babel standalone handles JSX transformation in real-time

---

## Build & Deploy Assumptions

### Development Environment
**No build step required**. Application runs as-is:

```bash
# Option 1: Direct file open
open p5.html
open blockchain.html

# Option 2: Local HTTP server (recommended)
./run.sh                    # Auto-detects Bun, npm, or Python
npx serve                   # npm method
bunx serve                  # Bun method (fastest)
python3 -m http.server 8000 # Python fallback

# Navigate to http://localhost:3000 (npx serve) or http://localhost:8000 (Python)
```

### Deployment Assumptions

1. **Static Hosting**: Deploy as-is to any static file host (GitHub Pages, Vercel, Netlify, S3)
   - No server-side rendering needed
   - No build artifacts required

2. **HTTPS Required**: 
   - MetaMask wallet connection requires HTTPS in production
   - Localhost development works over HTTP

3. **CORS-Friendly RPC Endpoints**: 
   - Public RPC URLs must support CORS headers
   - JIBCHAIN L1 (`rpc-l1.jbc.xpool.pw`) - public
   - SiChang (`sichang-rpc.thaichain.org`) - public

4. **No Environment Variables**: 
   - Contract addresses hardcoded in `CONTRACTS` object
   - Chain RPC URLs hardcoded in chain configs
   - No .env file support needed

5. **File Size Considerations**:
   - blockchain.html: 162KB (large due to ~2755 lines of JSX + ABI definitions)
   - p5.html: 40KB
   - Total minified size can't go lower without refactoring (no bundler)

### Performance Characteristics

| Aspect | Details |
|--------|---------|
| **Initial Load** | 4-5 CDN requests (React, p5.js, Chart.js, Tailwind, Viem) |
| **Time to Interactive** | 2-4 seconds (depends on CDN latency) |
| **Blockchain RPC Calls** | Real-time HTTP requests to RPC endpoints (no batching) |
| **Event Log Filtering** | Lazy-loaded on user action (history button) |
| **Chart.js Rendering** | Up to 100 historical records (limited to prevent lag) |
| **p5.js Animation** | 30 FPS target (tied to sensor data updates) |

---

## Integration Points

### 1. **Wallet Injection (MetaMask)**
```javascript
if (!window.ethereum) {
  throw new Error("Please install MetaMask or another Web3 wallet")
}

// Request accounts
const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })

// Listen for chain changes
window.ethereum.on('chainChanged', (chainIdHex) => {
  // Reload data for new chain
})
```

### 2. **Smart Contract Read Calls**
```javascript
const result = await publicClient.readContract({
  address: storeAddress,
  abi: STORE_ABI,
  functionName: 'getLatestRecord',
  args: [sensorAddress]
})
// Returns: { latestRecord: { timestamp, values[] }, totalRecords }
```

### 3. **Event Log Querying**
```javascript
const filter = await publicClient.createEventFilter({
  address: storeAddress,
  event: parseAbi(['event RecordStored(address indexed sensor, ...)']),
  fromBlock: BigInt(latestBlock + 1),
  toBlock: 'latest'
})

const events = await publicClient.getFilterLogs({ filter })
```

### 4. **p5.js Canvas Integration**
```javascript
const sketch = (p) => {
  p.setup = () => {
    const canvas = p.createCanvas(350, 420)
    canvas.parent(sketchRef.current)
    p.frameRate(30)
  }
  
  p.draw = () => {
    // Read from propsRef.current (React state via ref)
    const { waterLevel, sensorMode } = propsRef.current
    // Draw sensor apparatus
  }
}

// Lifecycle: create on mount, remove on unmount
const instance = new p5(sketch, containerRef)
return () => instance.remove()
```

---

## Known Limitations

1. **Monolithic HTML Files**: No code splitting. All logic in single HTML file makes it hard to maintain.
2. **No TypeScript**: No type safety; relies on JSDoc comments (minimal).
3. **Limited Error Handling**: Basic try-catch, limited user feedback.
4. **Performance**: 
   - No lazy loading of Chart.js data
   - Event logs capped at 100 records
   - Full re-renders when store changes
5. **Contract Address Hardcoding**: No dynamic deployment detection.
6. **Timezone Handling**: Uses browser local time; no UTC normalization.

---

## Future Refactoring Opportunities

1. **Extract to modules** (ESM imports from CDN):
   - `constants.js` - Contract ABIs, addresses, chains
   - `blockchain.js` - Viem client utilities
   - `components/` - Separate React components
   - Build with esbuild or similar for single-file bundles

2. **Add TypeScript Support**:
   - Use TypeScript via esm.sh (ts files compiled on-the-fly)
   - Or post-process with tsc before deployment

3. **Improve State Management**:
   - Migrate to Zustand or Jotai for complex state
   - Reduce prop drilling

4. **Add Testing**:
   - Vitest or Jest for unit tests
   - Playwright for E2E (blockchain interaction testing)

5. **Separate Styling**:
   - Extract Tailwind classes to CSS modules
   - Or use UnoCSS for smaller payload

---

## Summary

**Floodboy UI Simple** is a sophisticated **IoT blockchain dashboard** disguised as an "HTML project". Despite the HTML tag, it's:
- A **full React application** (no build tools)
- A **Web3 dApp** with multi-chain support
- A **real-time data visualization system** using p5.js and Chart.js

The zero-build architecture makes it uniquely portable and deployable, but at the cost of monolithic files and limited tooling support. It's designed for rapid prototyping and demonstration of blockchain-integrated IoT concepts, particularly focused on flood sensor monitoring with visual representation of sensor apparatus and water level dynamics.

The code suggests it's part of a larger **LarisLabs** ecosystem working on **EVM-compatible IoT data chains** (JIBCHAIN, SiChang) with field-deployable sensor networks storing readings on-chain via smart contracts.
