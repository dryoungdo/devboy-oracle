# floodboy-astro — Code Snippets

**Researched**: 2026-05-11 17:47 GMT+7 by IOTBOY

## Dynamic SSR route

`src/pages/blockchain/[address].astro:1-74` —
```astro
---
export const prerender = false;
const { address: addressOrAlias } = Astro.params;
// Server-side: resolve alias → Ethereum address
---
<BaseLayout>
  <script type="module" set:html={`window.__STORE__=${JSON.stringify(data)};`} />
</BaseLayout>
```
Pattern: SSR route → JSON-serialize state into a script tag → React island hydrates from it.

## Content Collections (Astro 5 content layer)

`src/content.config.ts:1-18` —
```ts
const blog = defineCollection({
  loader: glob({ base: "./src/content/blog", pattern: "**/*.{md,mdx}" }),
  schema: z.object({
    title: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
  }),
});
```

## React-only island

`src/pages/index.astro:5-8` —
```astro
<BaseLayout title="FloodBoy: IoT-Powered Blockchain">
  <Dashboard client:only="react" />
</BaseLayout>
```
`client:only="react"` skips Astro SSR entirely — pure CSR for the dashboard.

## Build-time git metadata

`src/components/Header.astro:1-15` —
```astro
---
import { execSync } from 'child_process';
const gitHash = execSync('git rev-parse --short HEAD', { encoding: 'utf-8' }).trim();
const gitDate = execSync('git log -1 --format=%cd --date=short', { encoding: 'utf-8' }).trim();
---
<span>Build {gitHash} · {gitDate}</span>
```
Bakes commit hash + date into HTML at build.

## Inline config injection via `define:vars`

`src/pages/blockchain.astro:163-293` —
```astro
<script type="module" define:vars={{
  BLOCKCHAIN_CONFIG: configJson,
  STORE_ABI_JSON: storeAbiJson,
  CONTRACTS: contractsJson,
}}>
  const STORE_ABI = JSON.parse(STORE_ABI_JSON);
  // ... uses BLOCKCHAIN_CONFIG, CONTRACTS as injected globals
</script>
```
Server passes typed config to inline client script — zero round-trip.

## Resilient RPC client (Viem fallback + latency ranking)

`src/utils/rpc.ts:1-144` —
```ts
import { createPublicClient, fallback, http } from 'viem';

export async function createResilientPublicClient(chainId: number) {
  const rankedUrls = await rankRpcUrls(chainId, baseUrls);  // measures latency
  const transports = rankedUrls.map(url => http(url, { retryCount: 2 }));
  const client = createPublicClient({ chain, transport: fallback(transports) });
  return { client };
}
```
Latency-ranked + 5-min cached + `fallback()` over `http()` transports = resilient against single-RPC outage.

## Block watcher (real-time poll)

`src/stores/blockchain.store.ts:157-167` —
```ts
const unwatch = client.watchBlocks({
  onBlock: (block) => {
    $currentBlock.set(block.number);
    $lastBlockUpdate.set(new Date());
    checkStoreUpdates(block.number);
  },
  pollingInterval: 3_000,
});
```
**3-second poll** — that's the "realtime" cadence. NO websocket, NO MQTT.

## Event log fetch

`src/stores/blockchain.store.ts:184-218` —
```ts
const events = await client.getLogs({
  address: storeAddress as `0x${string}`,
  event: RECORD_STORED_EVENT,
  fromBlock,
  toBlock,
});
```
Pulls sensor `RecordStored` events from a store contract.

## Wallet integration (raw window.ethereum, no wagmi)

`src/components/blockchain/connection/WalletConnection.tsx:10-14, 34-59` —
```ts
declare global {
  interface Window { ethereum?: any; }
}
await window.ethereum.request({
  method: 'wallet_switchEthereumChain',
  params: [{ chainId: chainIdHex }],
});
```
Direct EIP-1193 — no wagmi/web3-react abstraction.

## Multi-chain definition

`src/utils/blockchain-constants.ts:153-190` —
```ts
export const jibchainL1 = { id: 8899, name: 'JIBCHAIN L1', /*...*/ };
export const sichang    = { id: 700011, name: 'SiChang', /*...*/ };
export const anvil      = { id: 31337, name: 'Anvil (local)', /*...*/ };
export const SUPPORTED_CHAINS = [jibchainL1, sichang, anvil];
```

## State management — Nanostores (not Redux/Zustand)

`src/stores/blockchain.store.ts:69-84` —
```ts
import { atom, computed } from 'nanostores';

export const $currentBlock = atom<bigint | null>(null);
export const $chainId      = atom<number>(8899);
export const $blockStatus  = computed($timeSinceUpdate, (s) => {
  if (s <= 3)  return { status: 'live',    color: 'text-green-400'  };
  if (s <= 10) return { status: 'delayed', color: 'text-yellow-400' };
  return        { status: 'stale',   color: 'text-red-400'    };
});
```
Reactive atoms + `computed` selectors — minimal state, fits Astro islands well.

## Sensor log processing

`src/stores/blockchain.store.ts:110-121` —
```ts
function processRecordLogs(logs: any[]) {
  return logs
    .filter(log => log.args?.sensor && log.args?.timestamp && log.args?.values)
    .map(log => ({
      sensor: log.args.sensor,
      timestamp: Number(log.args.timestamp),
      values: log.args.values.map((v: bigint) => Number(v)),
      blockNumber: log.blockNumber,
      transactionHash: log.transactionHash,
    }))
    .sort((a, b) => b.timestamp - a.timestamp);
}
```

## IOTBOY takeaway snippets

- **Resilient transport** (`rpc.ts`) — port to my MQTT-broker selection: rank brokers by latency, fallback transport stack
- **Per-device store contract** — could model `muninn-edge` as per-ESP32 store contract (or per-fleet)
- **Polled vs streaming** — interesting design choice. Blockchain polling = simpler than WebSocket but burns RPC budget. For IoT high-frequency I'd still prefer MQTT.
- **No MQTT in floodboy** = a gap I can fill: hybrid bridge (MQTT realtime + on-chain persistence)
