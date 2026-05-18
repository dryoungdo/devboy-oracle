# FloodBoy Astro - API Surface Map

**Project**: FloodBoy Web Application (Open Source)  
**Analysis Date**: 2026-05-11  
**Deployed**: https://blockchain.floodboy.online  
**Framework**: Astro 5.11.0 + React + TypeScript  
**Deployment**: Cloudflare Workers (Wrangler)

---

## Public API Endpoints

### Astro API Routes

#### `/api/rpc-check` (GET)
**Location**: `src/pages/api/rpc-check.ts`  
**Purpose**: Health check and RPC endpoint performance ranking  
**Returns**:
```json
{
  "results": [
    {
      "url": "https://rpc-l1.inan.in.th",
      "latency": 150,
      "blockNumber": 2847654,
      "online": true
    }
  ],
  "ranked": [...],
  "fastest": "https://rpc-l1.inan.in.th",
  "timestamp": 1715425200000
}
```
**Response Headers**: `Cache-Control: public, max-age=10`

---

## External Integration Points

### 1. Blockchain RPC Endpoints (Primary Integration)

#### JIBCHAIN L1 (Chain ID: 8899)
**Type**: JSON-RPC over HTTPS  
**Endpoints** (with fallback strategy):
- `https://rpc-l1.inan.in.th` (Primary - Thai server)
- `https://rpc-l1.jibchain.net` (Official fallback)
- `https://rpc2-l1.jbc.xpool.pw` (Offline)
- `https://rpc-l1.jbc.xpool.pw` (Offline)

**Health Check**:
- Timeout: 4000ms per endpoint
- Cache: 5 minutes per chain
- Method: `eth_blockNumber` to verify connectivity

**Implementation**: `src/utils/rpc.ts` (createResilientPublicClient)

#### SiChang (Chain ID: 700011)
**Endpoint**: `https://sichang-rpc.thaichain.org`  
**Explorer**: `https://sichang.thaichain.org`

#### Anvil Local (Chain ID: 31337)
**Endpoint**: `http://127.0.0.1:8545`  
**Purpose**: Development/testing

### 2. Block Explorer APIs

#### JBC Explorer
**URL**: `https://exp.jibchain.net`  
**Integration**: Links to view contract addresses and transactions  
**Used in**: Store card "Explorer" button links

#### SiChang Explorer
**URL**: `https://sichang.thaichain.org`

---

## Smart Contract Integration

### Contract ABIs & Deployments

#### Files
- **ABI Exports**: `src/abis/index.ts` (JSON imports from ABI files)
- **Deployments**: `src/abis/deployments.json`

#### CatLabFactory Contract
**Purpose**: Factory pattern for deploying and managing sensor stores  
**Chain**: JIBCHAIN L1 (8899)  
**Address**: `0x63bB41b79b5aAc6e98C7b35Dcb0fE941b85Ba5Bb`

**Key Methods** (Read-only):
```solidity
getUserStores(address user) → address[]
storeToNickname(address store) → string
getStoreMetadata(address store) → (uint128 deployedBlock, uint128 lastUpdatedBlock, string description, string pointer)
getStoreInfo(address store) → (string nickname, address owner, uint256 authorizedSensorCount, bool isEventOnly, uint128 deployedBlock, string description)
getAllStoresCount() → uint256
getStoresReverse(uint256 start, uint256 count) → address[]
```

**Events**:
- `SensorStoreDeployed(indexed address creator, address store, string nickname)`

#### CatLabSensorStore Contract
**Purpose**: Individual sensor data storage and retrieval  
**ABI**: `CatLabSensorStoreABI`

**Key Methods** (Read-only):
```solidity
getAllFields() → Field[] (name, unit, dtype)
getLatestRecord(address sensor) → (uint256 timestamp, int256[] values)
owner() → address
isSensorAuthorized(address sensor) → bool
authorizedSensorCount() → uint256
authorizedSignerCount() → uint256 [custom method]
lastDataTimestamp() → uint256 [custom method]
```

**Events**:
- `RecordStored(indexed address sensor, uint256 timestamp, int256[] values)`
- `SensorAuthorized(indexed address sensor)`
- `SensorRevoked(indexed address sensor)`

### Multicall3 (Universal Contract)
**Address**: `0xcA11bde05977b3631167028862bE2a173976CA11` (same on all chains)  
**Purpose**: Batch read operations for gas efficiency  
**Function**: `aggregate3(tuple[] calls) → tuple[] results`  
**Batch Size**: 60 calls per request (to respect RPC limits)

---

## Configuration & Constants

### Blockchain Configuration
**Location**: `src/config/blockchain.config.ts`

```typescript
BLOCKCHAIN_CONFIG = {
  31337: {
    NAME: "Anvil",
    DEPLOYER_ADDRESS: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
    EXPLORER_URL: "http://localhost:8545"
  },
  700011: {
    NAME: "SiChang",
    DEPLOYER_ADDRESS: "0x0000000000000000000000000000000000000000",
    EXPLORER_URL: "https://sichang.thaichain.org"
  },
  8899: {
    NAME: "JIBCHAIN L1",
    DEPLOYER_ADDRESS: "0x63bB41b79b5aAc6e98C7b35Dcb0fE941b85Ba5Bb",
    EXPLORER_URL: "https://exp.jibchain.net"
  }
}
```

### Key Contract Addresses
- **FACTORY_ADDRESS**: `0x63bB41b79b5aAc6e98C7b35Dcb0fE941b85Ba5Bb`
- **UNIVERSAL_SIGNER**: `0xcB0e58b011924e049ce4b4D62298Edf43dFF0BDd` (for demo/testing)
- **FLOODBOY020_ADDRESS**: `0x1701a62b62813160de104461573a9e6069405655` (specific store)
- **MULTICALL3_ADDRESS**: `0xcA11bde05977b3631167028862bE2a173976CA11`

### Scaling Factors
Data is scaled on-chain due to Solidity integer limitations:
- **Water Depth**: `x10000` (e.g., 1234 = 0.1234 meters)
- **Installation Height**: `x10000`
- **Battery Voltage**: `x100` (e.g., 320 = 3.20V)

---

## Extension Points & Hooks

### 1. Nanostores State Management
**Location**: `src/stores/blockchain.store.ts`

**Global Atoms**:
- `$currentBlock`: Current blockchain block number
- `$chainId`: Active chain ID
- `$publicClient`: Viem PublicClient instance
- `$activeRpcUrl`: Currently active RPC endpoint
- `$storeData`: Map of store data by address

**Actions**:
- `initializeClient(chainId)`: Connect to blockchain
- `startBlockWatcher(client)`: Watch for new blocks
- `loadStoreData(storeAddress)`: Load store data from chain
- `fetchNewEvents(storeAddress, fromBlock, toBlock)`: Fetch sensor events

### 2. React Components
- **Simulator**: `src/pages/simulator.astro` → React component
- **Stores Browser**: Inline React in `src/pages/blockchain.astro`
- **FloodBoy Visualization**: `src/components/blockchain/FloodboyVisualization.js` (p5.js)

### 3. Client-Side Caching
**Type**: IndexedDB (browser storage)  
**Location**: `src/lib/blockchain/cache.js`

**Database**: `floodboy-blockchain-cache`  
**Store**: `events`  
**Cache TTL**: Not explicitly set (persists across sessions)

**Operations**:
- `openCacheDB()`: Open IndexedDB
- `getCachedEvents(storeAddress, chainId)`: Retrieve cached logs
- `setCachedEvents(storeAddress, chainId, events, lastBlock)`: Store events

### 4. Event Log Pagination
**Location**: `src/lib/blockchain/client.js`

**Function**: `fetchLogsInChunks()`  
**Purpose**: Break large log queries into manageable chunks  
**Parameters**:
- `initialBatchSize`: 50,000 blocks (configurable)
- `maxRetries`: 3 attempts with binary backoff

---

## Data Models & Types

### Store Data
```typescript
interface StoreData {
  address: string;
  name: string;
  owner: string;
  fields: Array<{ name: string; unit: string; dtype: string }>;
  sensorRecords: Array<{
    sensor: string;
    timestamp: number;
    values: number[];
    blockNumber?: bigint;
    transactionHash?: string;
  }>;
  lastFetchedBlock: bigint;
  isLoading: boolean;
  totalRecords: number;
  lastTimestamp: number;
}
```

### Field Definition
```typescript
interface Field {
  name: string;        // e.g., "water_depth"
  unit: string;        // e.g., "m x10000"
  dtype: string;       // e.g., "int256"
}
```

---

## Frontend Libraries & Dependencies

### Blockchain/Web3
- **viem**: `^2.31.7` - Ethereum library (replaces ethers)
- **Import Method**: ESM from CDN in browser (`https://esm.sh/viem@2.21.19`)

### State Management
- **nanostores**: `^1.0.1` - Lightweight state management
- **@nanostores/react**: `^1.0.0` - React integration

### Visualization
- **p5**: `^2.0.3` - Creative coding library
- **chart.js**: `^4.5.0` - Chart library
- **chartjs-adapter-date-fns**: `^3.0.0` - Date formatting
- **react-chartjs-2**: `^5.3.0` - React wrapper

### UI/Styling
- **tailwindcss**: `^4.1.11` - Utility-first CSS
- **@tailwindcss/vite**: `^4.1.11` - Vite plugin
- **react**: `^18.3.1` - React framework
- **astro**: `5.11.0` - Meta-framework

### Utilities
- **date-fns**: `^4.1.0` - Date manipulation

---

## Deployment & Edge Configuration

### Cloudflare Workers
**Config**: `wrangler.json`

```json
{
  "name": "floodboy-astro",
  "account_id": "a5eabdc2b11aae9bd5af46bd6a88179e",
  "compatibility_date": "2025-04-01",
  "compatibility_flags": ["nodejs_compat"],
  "main": "./dist/_worker.js/index.js",
  "assets": { "directory": "./dist" },
  "observability": { "enabled": true },
  "upload_source_maps": true,
  "workers_dev": true
}
```

**Adapter**: `@astrojs/cloudflare` (directory mode, local runtime)

---

## External Network Calls Summary

| Service | Type | Purpose | Endpoint(s) |
|---------|------|---------|-------------|
| JIBCHAIN L1 RPC | JSON-RPC | Blockchain reads | `https://rpc-l1.inan.in.th` (primary) |
| JIBCHAIN L1 RPC | JSON-RPC | Blockchain reads | `https://rpc-l1.jibchain.net` (fallback) |
| SiChang RPC | JSON-RPC | Blockchain reads | `https://sichang-rpc.thaichain.org` |
| Anvil RPC | JSON-RPC | Dev/testing | `http://127.0.0.1:8545` |
| JBC Explorer | HTTPS | Link target | `https://exp.jibchain.net` |
| SiChang Explorer | HTTPS | Link target | `https://sichang.thaichain.org` |

---

## Security Considerations

### No IoT/MQTT Integration
- **Current**: No MQTT broker or WebSocket connections
- **Sensors**: Data flows through smart contracts only
- **Real-time**: Block watching (3-second polling) instead of event streams

### No Supabase/External Database
- **Storage**: 100% on-chain (smart contracts)
- **Caching**: Browser IndexedDB only (no cloud sync)

### RPC Endpoint Resilience
- Latency measurement with 4-second timeout
- Automatic fallback to next healthy endpoint
- 5-minute cache of RPC rankings per chain

### No API Keys in Code
- RPC endpoints are public
- No authentication required
- All data is read-only (view functions)

---

## Deployment Status

**Live Deployment**: JIBCHAIN L1  
**Stores Deployed**: 100 FloodBoy sensor stores  
**Factory**: `0x63bB41b79b5aAc6e98C7b35Dcb0fE941b85Ba5Bb`  
**Status**: FULLY OPERATIONAL (July 21, 2025)

---

## Development & Testing

### Viem Integration
```typescript
// Create client with fallback RPC endpoints
const client = createPublicClient({
  chain: jibchainL1,
  transport: fallback([
    http(rpcUrl1),
    http(rpcUrl2)
  ])
});

// Read contract data
const stores = await client.readContract({
  address: factoryAddress,
  abi: DEPLOYER_ABI,
  functionName: 'getUserStores',
  args: [userAddress]
});

// Watch new blocks
const unwatch = client.watchBlocks({
  onBlock: (block) => { /* handle new block */ },
  pollingInterval: 3000
});
```

### Block Range Queries
- **Typical Range**: Last 10,000 blocks (~30 minutes on JIBCHAIN at 3s blocks)
- **Chunk Size**: 50,000 blocks max per RPC call
- **Backoff**: Binary reduction on failure (50k → 25k → 12.5k)

---

## File Structure Reference

```
src/
├── pages/
│   ├── api/
│   │   └── rpc-check.ts          # RPC health endpoint
│   ├── blockchain.astro           # Stores browser (React inline)
│   ├── blockchain/[address].astro # Store detail page
│   ├── simulator.astro            # Sensor simulator
│   └── ...
├── lib/blockchain/
│   ├── client.js                  # Viem client setup
│   ├── chains.js                  # Chain config re-exports
│   ├── cache.js                   # IndexedDB caching
│   └── utils.js                   # Data aggregation
├── utils/
│   ├── blockchain-constants.ts    # RPC URLs, addresses, ABIs
│   ├── rpc.ts                     # Resilient client creation
│   └── blockchain-helpers.ts      # Utility functions
├── stores/
│   └── blockchain.store.ts        # Nanostores state
├── components/
│   ├── blockchain/
│   │   ├── FloodboyVisualization.js
│   │   └── ui/Header.astro
│   └── ...
├── abis/
│   ├── CatLabFactory.json
│   ├── CatLabSensorStore.json
│   ├── deployments.json
│   └── index.ts
└── config/
    └── blockchain.config.ts       # Chain configuration
```

---

## Notes

- **No Hooks/Observers**: Extension primarily through state management
- **No Webhooks**: All data pulled via RPC (polling or block watching)
- **Client-Side Only**: All logic runs in browser (Cloudflare Workers for hosting)
- **Open Data**: All contract addresses and RPC endpoints are public
- **No Backend Service**: Pure static site with client-side blockchain queries

