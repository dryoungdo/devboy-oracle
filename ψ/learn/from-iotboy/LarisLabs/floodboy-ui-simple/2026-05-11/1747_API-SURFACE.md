# Floodboy UI Simple - API Surface & External Integration Points

**Date**: 2026-05-11  
**Scope**: LarisLabs flood IoT + blockchain monitoring UI  
**Files Analyzed**: `blockchain.html` (2755 lines, 163KB), `p5.html` (interactive visualization)

---

## Overview

Floodboy UI Simple is a dual-mode web application for flood sensor monitoring:
1. **p5.html**: Interactive p5.js + React sensor visualization (air distance + water level)
2. **blockchain.html**: Full smart contract dashboard with wallet integration, on-chain data querying, event tracking

Both files are single-file HTML applications using CDN-loaded dependencies (no build process).

---

## 1. Public HTTP API / Web Endpoints

### Application URLs

**Deployed as**:
- `p5.html` — sensor visualization demo
- `blockchain.html` — blockchain dashboard (support for URL parameters)

**URL Parameters** (blockchain.html):
```
?store=<address>           # Pre-load a specific sensor store contract address
#store/<address>           # Hash-based routing to store address
```

**Generated Shareable URLs**:
```javascript
`${window.location.origin}/blockchain.html?store=${selectedStore.address}`
```

---

## 2. Smart Contract ABIs (On-Chain Interfaces)

### Supported Chains
- **Ethereum Mainnet** (id: 1)
- **Ethereum Sepolia Testnet** (id: 11155111)
- **Anvil Local** (id: 31337)
- **JIBCHAIN L1** (id: 8899) — RPC: `https://rpc-l1.jbc.xpool.pw`
- **SiChang** (id: 700011) — RPC: `https://sichang-rpc.thaichain.org`

### DEPLOYER_ABI (Factory Contract)

**Contract Addresses**:
- Anvil: `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`
- JIBCHAIN: `0x5cEe5489DdB5006e5c1c1f2029bc7451E4A25837`
- SiChang: `0x0000000000000000000000000000000000000000` (TBD)

**Read Functions**:

| Function | Inputs | Outputs | Purpose |
|----------|--------|---------|---------|
| `getUserStores(address user)` | user: address | address[] | Get all sensor stores deployed by a user |
| `storeToNickname(address store)` | store: address | string | Retrieve friendly name for a store contract |
| `getStoreMetadata(address store)` | store: address | (uint128 deployedBlock, uint128 lastUpdatedBlock, string description, string pointer) | Fetch store deployment info, last update block, description, and external data pointer |

**Events**:

```solidity
event SensorStoreDeployed(
    address indexed creator,
    address store,
    string nickname
)
```
Emitted when a new sensor store is deployed.

---

### STORE_ABI (Sensor Store Contract)

**Read Functions**:

| Function | Inputs | Outputs | Purpose |
|----------|--------|---------|---------|
| `getAllFields()` | — | Field[] | List all sensor field definitions (name, unit, dtype) |
| `getLatestRecord(address sensor)` | sensor: address | (uint256 timestamp, int256[] values) | Get most recent data point from a sensor |
| `owner()` | — | address | Contract owner address |
| `isSensorAuthorized(address sensor)` | sensor: address | bool | Check if sensor is authorized to write data |

**Events**:

```solidity
event RecordStored(
    address indexed sensor,
    uint256 timestamp,
    int256[] values
)
```
Emitted when sensor data is stored on-chain.

```solidity
event SensorAuthorized(address indexed sensor)
event SensorRevoked(address indexed sensor)
```
Emitted when a sensor authorization changes.

---

## 3. Web3 Provider Integration (window.ethereum)

### MetaMask / EIP-1193 Provider

**Global Access**:
```javascript
window.ethereum  // Requires MetaMask or compatible EIP-1193 provider
```

**Supported RPC Methods**:

| Method | Purpose | Returns |
|--------|---------|---------|
| `eth_requestAccounts` | Connect wallet | string[] (account addresses) |
| `eth_chainId` | Get connected chain | string (hex chain ID) |
| `wallet_switchEthereumChain` | Switch networks | void |

**Event Listeners**:

```javascript
window.ethereum.on('accountsChanged', callback)   // When user switches account
window.ethereum.on('chainChanged', callback)      // When user switches chain
```

**Viem Wallet Integration**:
```javascript
createWalletClient({
    chain: selectedChain,
    transport: custom(window.ethereum)
})
```

---

## 4. Viem Web3 Library Exports (window.viem & window.chains)

**Global Exports** (injected into `window` object):

### window.viem
```javascript
{
    createPublicClient,        // Read-only RPC client
    createWalletClient,        // Wallet-connected client (blockchain.html only)
    custom,                    // Custom transport for EIP-1193 providers
    http,                      // HTTP transport
    parseAbi,                  // Parse ABI strings
    formatEther,               // Convert wei to ether
    decodeEventLog             // Decode contract events
}
```

### window.chains
```javascript
{
    mainnet,                   // Ethereum mainnet
    sepolia,                   // Sepolia testnet
    anvil,                     // Local Anvil (blockchain.html only)
    jibchainL1,                // JIBCHAIN custom chain
    sichang                    // SiChang custom chain
}
```

---

## 5. JavaScript Module/React Exports

### p5.html Exports (Browser Global)

```javascript
window.viem                    // Viem functions (limited set)
window.chains                  // Chain configurations
```

### blockchain.html Additional Exports

None explicitly exported; all state is internal to React component tree.

---

## 6. Custom Events & Event Listeners

### Window/DOM Events

**Data Export Trigger**:
```javascript
// CSV export via File API (no custom event)
window.URL.createObjectURL(blob)
window.URL.revokeObjectURL(url)
```

**Navigation/Routing**:
```javascript
window.location.search        // Read URL query params (?store=...)
window.location.hash          // Read hash-based routing (#store/...)
window.location.reload()      // Force page reload on chain/account change
```

**No Custom Events**: The application does not define or dispatch custom events. All communication is through React state and Web3 provider callbacks.

---

## 7. React Component Exports & Props

### p5.html Components

#### SensorVisualizationP5
```typescript
<SensorVisualizationP5 
    waterLevel: number              // 0-5m
    airLevel: number                // Distance in meters
    sensorMode: 'water' | 'air'     // Measurement mode
    installationHeight?: number     // Calibration height (default: 2.5m)
    showMeasurement?: boolean       // Show distance label
    isOnline?: boolean              // Status indicator
    isDead?: boolean                // Dead sensor indicator
/>
```

### blockchain.html Components

#### FloodboyVisualization
```typescript
<FloodboyVisualization 
    storeData: {
        fields: Array<{name: string, unit: string, dtype: string}>,
        sensorRecords: Array<{latestRecord: {timestamp: string, values: int256[]}}>
    }
    currentBlock: string | number
/>
```

#### SensorDataViews
```typescript
<SensorDataViews 
    storeAddress: string            // Store contract address
    fields: Array<{name: string, unit: string}>
    publicClient: VieemPublicClient  // RPC client
    theme: 'dark' | 'light'
    currentBlock: string | number
/>
```
Exports CSV via `exportToCSV()` which triggers browser download.

---

## 8. External API Dependencies (CDN)

### Runtime Dependencies

| Library | Version | CDN | Purpose |
|---------|---------|-----|---------|
| React | 18 | `unpkg.com/react@18/umd/react.production.min.js` | UI framework |
| ReactDOM | 18 | `unpkg.com/react-dom@18/umd/react-dom.production.min.js` | DOM rendering |
| Babel | Latest | `unpkg.com/@babel/standalone/babel.min.js` | JSX transformation |
| p5.js | 1.7.0 | `cdnjs.cloudflare.com/ajax/libs/p5.js/1.7.0/p5.min.js` | Graphics/visualization |
| Tailwind CSS | Latest | `cdn.tailwindcss.com` | Styling |
| Chart.js | 4.4.0 | `cdn.jsdelivr.net/npm/chart.js@4.4.0` | Data visualization (blockchain.html) |
| date-fns | 2.29.3 | `cdn.jsdelivr.net/npm/date-fns@2.29.3` | Date formatting (blockchain.html) |
| chartjs-adapter-date-fns | 3.0.0 | `cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0` | Chart date axis (blockchain.html) |
| viem | 2.21.19 | `esm.sh/viem@2.21.19` | Web3 client library |

---

## 9. Network Requests & RPC Calls

### Blockchain RPC Endpoints (via Viem createPublicClient)

**Dynamic Selection**:
- User selects chain from dropdown → Creates new `createPublicClient` instance
- RPC endpoint chosen from chain config

**RPC Methods Called**:

| Method | Usage | Returns |
|--------|-------|---------|
| `eth_blockNumber` | Get current block | BigInt |
| `eth_call` (via readContract) | Read contract state | Parsed return values |
| `eth_getLogs` (via getLogs) | Fetch event logs | Event[] |
| `eth_chainId` | Verify chain | Hex string |

**Contract Read Calls** (via viem readContract):

```javascript
// Get user's sensor stores
publicClient.readContract({
    address: DEPLOYER_ADDRESS,
    abi: DEPLOYER_ABI,
    functionName: 'getUserStores',
    account: userAddress
})

// Get latest sensor data
publicClient.readContract({
    address: storeAddress,
    abi: STORE_ABI,
    functionName: 'getLatestRecord',
    args: [sensorAddress]
})

// Get all field definitions
publicClient.readContract({
    address: storeAddress,
    abi: STORE_ABI,
    functionName: 'getAllFields'
})

// Get store metadata
publicClient.readContract({
    address: DEPLOYER_ADDRESS,
    abi: DEPLOYER_ABI,
    functionName: 'getStoreMetadata',
    args: [storeAddress]
})
```

**Event Log Queries**:

```javascript
publicClient.getLogs({
    address: storeAddress,
    event: eventAbi,  // e.g., RecordStored event
    fromBlock: BigInt(blockStart),
    toBlock: blockEnd
})
```

---

## 10. Data Flow & Integration Points

### Read Pathways (blockchain.html)

```
User connects wallet (window.ethereum)
    ↓
Detect account & chain
    ↓
Create viem PublicClient → selected RPC endpoint
    ↓
Call DEPLOYER_ABI.getUserStores(account)
    ↓
For each store address:
  ├─ DEPLOYER_ABI.getStoreMetadata(store) → name, description, pointer
  ├─ STORE_ABI.getAllFields() → field definitions
  └─ STORE_ABI.getLatestRecord(sensor) → timestamp + latest values
    ↓
Fetch event logs: RecordStored events from store
    ↓
Visualize with p5.js + Chart.js
```

### Visualization Data Scaling

Sensor values stored on-chain as `int256` with implicit scaling:

```javascript
formatValue(value, unit) → applies unit-based divisor:
  'x 1000' → divide by 1000     // e.g., mm → m
  'x 100'  → divide by 100      // partial scaling
  'x 10'   → divide by 10
  '°C'     → divide by 100      // temperature
  '%'      → divide by 10       // percentage
  'pH'     → divide by 100      // pH value
```

---

## 11. Extension Points & Hooks

### User Interaction Hooks

**1. Chain Selection**
```javascript
// Trigger wallet switch via window.ethereum
await window.ethereum.request({
    method: 'wallet_switchEthereumChain',
    params: [{ chainId: '0x...' }]
})
```

**2. Store Address Input**
```javascript
// Manual entry or URL parameter (#store/<address>)
// Triggers immediate re-query of all contract data
```

**3. Data Export**
```javascript
exportToCSV() → downloads sensor-data-YYYY-MM-DDTHH-MM-SS.csv
```

**4. Theme Toggle**
```javascript
// Dark/Light mode state managed in AppContainer component
// Toggles body.classList (dark/light)
```

**5. View Mode Toggle**
```javascript
// 'table' or 'chart' view of historical sensor data
// Chart mode uses Chart.js for time-series rendering
```

### Observable State Changes

**Viem createEventFilter + getFilterLogs** (blockchain.html):
- Polls for new `RecordStored` events when currentBlock updates
- Incremental data fetch to avoid re-querying all historical data

---

## 12. Global window.* Objects & Properties

| Object | Type | Purpose |
|--------|------|---------|
| `window.viem` | Object | Viem Web3 library exports |
| `window.chains` | Object | Chain configurations (mainnet, sepolia, anvil, jibchainL1, sichang) |
| `window.ethereum` | EIP-1193 Provider | MetaMask or compatible wallet (if installed) |
| `window.React` | Object | React library (implicit via Babel) |
| `window.ReactDOM` | Object | ReactDOM library (implicit via Babel) |
| `window.p5` | Constructor | p5.js global (loaded via script tag) |
| `window.Chart` | Constructor | Chart.js (blockchain.html only) |
| `window.URL` | API | File blob handling for CSV export |
| `window.location` | Object | URL navigation & routing |

---

## 13. File Format & Dependencies

### Asset Files

```
img/Cat-Lab.png        # Logo/mascot (inline reference in README)
```

### Runtime Files

- **blockchain.html** (2,755 lines, 163KB)
  - Single-file app with embedded React JSX
  - No external component imports
  - Viem ES modules imported via esm.sh CDN

- **p5.html** (~800 lines, 40KB)
  - Simpler visualization-only app
  - Reusable SensorVisualizationP5 component
  - Same Viem integration

- **run.sh** — Local development server launcher (npx serve)

---

## 14. Security & Wallet Integration Notes

### Wallet Permissions Required

- `eth_requestAccounts` — User approves account connection
- `wallet_switchEthereumChain` — User approves chain switch
- Event listeners (`accountsChanged`, `chainChanged`) — No permission required

### No Direct Contract Writes

- **blockchain.html is read-only** for contract state
- All calls use `readContract()` and `getLogs()` (no `writeContract()`)
- MetaMask connected for data source verification, not transaction signing

### No PostMessage or iframe Communication

- No `postMessage()` API usage
- No iframe embeds expected
- Pure single-page app with CDN-hosted dependencies

---

## 15. Summary Table: Integration Points

| Layer | Type | Endpoint/Interface | Status |
|-------|------|-------------------|--------|
| **RPC** | HTTP | Chain-specific RPC URLs | Required |
| **Provider** | EIP-1193 | `window.ethereum` | Optional (read-only fallback) |
| **Web3 Library** | ES Module | `viem@2.21.19` via esm.sh | Required |
| **Contract Read** | Solidity ABI | DEPLOYER_ABI, STORE_ABI | Required |
| **Events** | Solidity Events | RecordStored, SensorAuthorized, SensorRevoked | Required |
| **Styling** | CDN | Tailwind CSS | Required |
| **Graphics** | CDN | p5.js 1.7.0 | Required |
| **Charts** | CDN | Chart.js 4.4.0 | blockchain.html only |
| **UI Framework** | CDN | React 18 | Required |

---

## 16. Known Limitations & Future Extensions

### Current Limitations

1. **No Write Operations** — Dashboard is read-only; sensor data pushed by off-chain oracles
2. **No Event Subscriptions** — Uses log polling instead of WebSocket subscriptions
3. **No IPFS Integration** — External data `pointer` field expected to be HTTP URL
4. **No Custom Themes** — Dark/light toggle only
5. **No Multi-Store Comparison** — Single store address at a time

### Potential Extension Points

```javascript
// Monitor wallet balance (ETH/JBC)
publicClient.getBalance({ address: userAddress })

// Watch contract for state changes (if WebSocket RPC available)
publicClient.watchContractEvent({ ... })

// Write operations (if sensor authority added)
createWalletClient({ ... }).writeContract({ ... })

// Subscribe to real-time data via WebSocket
publicClient.watchBlockNumber({ onBlockNumber: ... })
```

---

**End of API Surface Documentation**
