# FloodBoy Astro - Architecture Overview

**Repository**: [LarisLabs/floodboy-astro](https://github.com/LarisLabs/floodboy-astro)  
**Pushed**: 2026-01-29  
**Production**: https://blockchain.floodboy.online  
**Platform**: Cloudflare Workers (SSR + Static)  
**Framework**: Astro 5.11.0 + React 18

---

## 1. Project Layout

```
src/
├── pages/                 # Route definitions (file-based)
│   ├── index.astro       # Landing page (redirects to /blockchain)
│   ├── blockchain.astro  # Main blockchain dashboard
│   ├── opencode.astro    # Open code examples
│   ├── opendata.astro    # Public data explorer
│   ├── sensors.astro     # Sensor directory
│   ├── stores.astro      # Store directory
│   ├── prompts.astro     # Prompt library
│   ├── analytics.astro   # Analytics dashboard
│   ├── about.astro       # About page
│   ├── rpc.astro         # RPC endpoint tester
│   ├── simulator.astro   # Blockchain simulator
│   ├── blog/
│   │   ├── [...slug].astro      # Blog post dynamic route
│   │   └── index.astro          # Blog list
│   ├── blockchain/
│   │   └── [address].astro      # Store by address route
│   ├── s/
│   │   └── [identifier].astro   # Short URL resolver
│   ├── store/
│   │   └── [address].astro      # Store detail page
│   ├── api/
│   │   └── rpc-check.ts         # RPC health endpoint (serverless)
│   └── rss.xml.js              # RSS feed generation
│
├── layouts/               # Page templates
│   ├── BaseLayout.astro  # Main layout (header, footer, styles)
│   └── BlogPost.astro    # Blog-specific layout
│
├── components/            # UI components (Astro + React)
│   ├── Header.astro      # Navigation header
│   ├── Footer.astro      # Footer component
│   ├── BaseHead.astro    # Meta tags & head
│   ├── SystemInfo.astro  # Status bar (git, RPC, block, load time)
│   ├── Dashboard.tsx     # Main React dashboard wrapper
│   ├── BlockchainDashboard.tsx  # Blockchain-specific dashboard
│   ├── FloodboyVisualization.tsx # p5.js visualization wrapper
│   ├── P5Loader.tsx      # p5.js library loader
│   │
│   └── blockchain/       # Blockchain feature components
│       ├── index.ts      # Component exports
│       ├── ui/           # UI primitives
│       │   ├── Header.astro
│       │   ├── ThemeProvider.tsx    # Context for light/dark mode
│       │   ├── ViewModeTabs.tsx     # Public/Wallet/Direct modes
│       │   ├── BlockIndicator.tsx   # Live block display
│       │   ├── LoadingSkeleton.tsx
│       │   └── ErrorDisplay.tsx
│       ├── connection/   # Wallet & chain logic
│       │   ├── WalletConnection.tsx # Wallet integration
│       │   ├── ChainSelector.tsx    # Multi-chain support
│       │   ├── PublicStoreView.tsx  # Read-only mode
│       │   └── DirectStoreView.tsx  # Direct address input
│       ├── data/         # Data display components
│       │   ├── StoreInfo.tsx
│       │   ├── StoreMetadata.tsx
│       │   ├── SensorDataViews.tsx  # Chart.js integration
│       │   └── PublicUrlShare.tsx
│       ├── visualization/
│       │   └── FloodboyVisualization.tsx  # p5.js canvas
│       └── FloodboyVisualization.js       # Pure JS p5 sketch
│
├── stores/                # State management (Nanostores)
│   └── blockchain.store.ts  # Global blockchain state
│
├── styles/                # Global CSS
│   └── global.css        # Tailwind + custom styles
│
├── content/               # Markdown-based content
│   └── blog/             # Blog posts (MDX/MD)
│       ├── 2025-07-13-when-sensors-lie-blockchain-truth.md
│       ├── 2025-07-16-implementation-speed-run.md
│       ├── 2025-07-23-ui-evolution-hardcoded-to-dynamic.md
│       ├── 2025-07-25-progressive-ui-design-three-column-dashboard-integration.md
│       ├── 2025-07-22-worst-why-table-disaster.md
│       ├── 2025-07-23-visual-debugging-mcp-puppeteer.md
│       ├── 2025-07-23-comprehensive-open-data-developer-hub.md
│       ├── 2025-07-25-open-code-page-layout-optimization.md
│       ├── 2025-07-22-three-tier-sensor-classification.md
│       ├── 2025-07-25-lab-testing-group-implementation-journey.md
│       └── 2025-07-24-chart-accuracy-detective-work.md
│
├── lib/                   # Utility libraries
│   └── blockchain/       # Blockchain helpers
│       ├── index.js      # Re-exports
│       ├── chains.js     # Chain definitions
│       ├── client.js     # RPC client factory
│       ├── cache.js      # In-memory caching
│       └── utils.js      # Format/parse helpers
│
├── utils/                 # Helper functions
│   ├── blockchain-constants.ts     # ABIs, chain configs, addresses
│   ├── blockchain-helpers.ts       # URL parsing, formatting
│   ├── rpc.ts                      # Resilient RPC client creation
│   ├── simple-multicall.ts         # Multicall3 abstraction
│   └── theme-utils.ts              # Dark/light mode utilities
│
├── config/                # App configuration
│   ├── aliases.config.ts  # Path aliases & build config
│   └── blockchain.config.ts # Contract addresses & settings
│
├── abis/                  # Smart contract ABIs
│   └── [ABIs directory]  # CatLabSensorStore, Factory ABIs
│
├── scripts/               # Build/runtime scripts
│   └── blockchain-page.ts # Page initialization logic
│
├── types/                 # TypeScript definitions
│   └── blockchain.ts      # Blockchain interfaces
│
├── consts.ts              # Global constants (SITE_TITLE, etc)
├── content.config.ts      # Astro Content Collections config
├── env.d.ts               # Environment type definitions
└── styles/global.css      # Tailwind CSS imports
```

---

## 2. Entry Points & Routes

### Static Pages (File-based Routing)
- **`/`** → `pages/index.astro` (redirects to `/blockchain`)
- **`/blockchain`** → `pages/blockchain.astro` — Main dashboard
- **`/blockchain/[address]`** → `pages/blockchain/[address].astro` — Store detail by address
- **`/blog`** → `pages/blog/index.astro` — Blog list
- **`/blog/[...slug]`** → `pages/blog/[...slug].astro` — Individual post (content collection)
- **`/opencode`** → Open code examples page
- **`/opendata`** → Public data explorer
- **`/sensors`** → Sensor directory
- **`/stores`** → Store directory
- **`/s/[identifier]`** → Short URL resolver
- **`/store/[address]`** → Alternative store view
- **`/prompts`** → Prompt library
- **`/analytics`** → Analytics dashboard
- **`/about`** → About page
- **`/rpc`** → RPC endpoint tester
- **`/simulator`** → Blockchain simulator
- **`/rss.xml`** → Feed generation

### API Routes
- **`/api/rpc-check`** → `pages/api/rpc-check.ts` — RPC health check (serverless function)

### Astro Islands (Client-Side Hydration)
```astro
<Dashboard client:only="react" />  <!-- Only load on client -->
```

---

## 3. Core Abstractions & Astro Features Used

### 3.1 **Content Collections** (Astro 4.0+)
**File**: `src/content.config.ts`
```typescript
const blog = defineCollection({
  loader: glob({ base: "./src/content/blog", pattern: "**/*.{md,mdx}" }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    heroImage: z.string().optional(),
  }),
});
export const collections = { blog };
```

**Benefits**:
- Type-safe frontmatter validation
- Automatic schema validation
- Integration with dynamic routes (`[...slug].astro`)

### 3.2 **Islands Architecture** (Astro's Signature Feature)
- Astro renders **static HTML by default**
- React components are islands that hydrate **only when needed**
- Used for interactive blockchain components:
  ```astro
  <BlockchainDashboard client:only="react" />  <!-- No SSR hydration -->
  <Dashboard client:only="react" />
  ```
- Reduces JavaScript overhead for static pages

### 3.3 **Integrations**

| Integration | Version | Purpose |
|-----------|---------|---------|
| `@astrojs/react` | 4.3.0 | React 18 support + island hydration |
| `@astrojs/mdx` | 4.3.0 | MDX blog posts (Markdown + JSX) |
| `@astrojs/cloudflare` | 12.6.0 | Cloudflare Workers adapter + functions |
| `@astrojs/sitemap` | 3.4.1 | SEO sitemap generation |
| `@astrojs/rss` | 4.0.12 | RSS feed generation (`rss.xml.js`) |
| `@tailwindcss/vite` | 4.1.11 | Tailwind CSS 4 (Vite plugin) |

### 3.4 **Layouts System**
- **`BaseLayout.astro`** — Wraps all pages with header, footer, global styles
  ```astro
  <BaseLayout title="Page Title">
    <main><slot /></main>  <!-- Page content -->
  </BaseLayout>
  ```
- **`BlogPost.astro`** — Blog-specific layout
- Layouts receive frontmatter as `Astro.props`

### 3.5 **Astro Components** (`.astro` files)
- **No JavaScript runtime** (files compile to static HTML)
- Used for: Header, Footer, layouts, static sections
- Props typed with TypeScript interfaces
- Example:
  ```astro
  ---
  export interface Props { title: string; }
  const { title } = Astro.props;
  ---
  <h1>{title}</h1>
  ```

### 3.6 **Partial Hydration**
- Pages are **100% static HTML** by default
- React islands load **only the necessary JavaScript**
- Example from `blockchain.astro`:
  ```astro
  <Dashboard client:only="react" />
  <!-- Dashboard code only loads in browser -->
  ```

### 3.7 **File-Based Routing**
- No config needed — file structure = routes
- Dynamic routes: `[param].astro` or `[...slug].astro`
- Astro auto-generates slugs from content filenames

---

## 4. State Management

### **Nanostores** (Lightweight Alternative to Redux)
**File**: `src/stores/blockchain.store.ts`

```typescript
// Atomic state
export const $currentBlock = atom<bigint | null>(null);
export const $chainId = atom<number>(8899);
export const $publicClient = atom<PublicClient | null>(null);
export const $activeRpcUrl = atom<string | null>(null);

// Computed values (derived state)
export const $timeSinceUpdate = computed($lastBlockUpdate, (lastUpdate) => {
  return Math.floor((Date.now() - lastUpdate.getTime()) / 1000);
});

// Map-based state (key-value store)
export const $storeData = map<{ [address: string]: StoreData }>({});
```

**Why Nanostores?**
- No overhead (< 1KB)
- Works with React via `@nanostores/react`
- Atoms are subscribed to automatically
- Great for fine-grained reactivity

### **Store Data Structure**
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

---

## 5. Blockchain Integration

### 5.1 **Core Blockchain Libraries**
- **viem** (^2.31.7) — Ethereum client library (alternative to ethers.js)
- **Nanostores** — Global state for wallet, chain, RPC client
- **Chart.js + react-chartjs-2** — Time-series visualization
- **p5** (^2.0.3) — Creative coding visualization

### 5.2 **Blockchain Constants** (`src/utils/blockchain-constants.ts`)

**Supported Chains**:
```typescript
export const SUPPORTED_CHAINS = [
  jibchainL1 (id: 8899) — JIBCHAIN L1 (Thai blockchain)
  sichang (id: 700011) — SiChang L2
  anvil (id: 31337) — Foundry local testnet
];
```

**RPC Endpoints** (with fallback):
```typescript
export const JIBCHAIN_RPC_ENDPOINTS = [
  'https://rpc-l1.inan.in.th',      // Primary (Thai)
  'https://rpc-l1.jibchain.net',    // Official fallback
  'https://rpc2-l1.jbc.xpool.pw',   // Tertiary
  'https://rpc-l1.jbc.xpool.pw',    // Quaternary
];
```

**Key Contracts**:
```typescript
export const FACTORY_ADDRESS = "0x63bB41b79b5aAc6e98C7b35Dcb0fE941b85Ba5Bb";
export const FLOODBOY020_ADDRESS = "0x1701a62b62813160de104461573a9e6069405655";
export const MULTICALL3_ADDRESS = "0xcA11bde05977b3631167028862bE2a173976CA11";
```

### 5.3 **Smart Contract ABIs**
Two main contracts tracked:

**Factory Contract** (`DEPLOYER_ABI`):
- `getUserStores(user)` → Store addresses
- `getStoreMetadata(store)` → Deployed block, description
- `getStoresReverse(start, count)` → Paginated stores
- Listens to `SensorStoreDeployed` events

**Store Contract** (`STORE_ABI`):
- `getAllFields()` → Sensor field definitions
- `getLatestRecord(sensor)` → Most recent sensor reading
- `owner()` → Store owner address
- `isSensorAuthorized(sensor)` → Authorization check
- Listens to `RecordStored` events

### 5.4 **RPC Client Factory** (`src/utils/rpc.ts`)
```typescript
export async function createResilientPublicClient(chainId: number) {
  // Try each RPC endpoint in order
  // Return first that works
  return { client, primaryRpcUrl };
}
```

Features:
- Automatic fallback to secondary RPCs
- Handles network failures gracefully
- Caches working endpoints

### 5.5 **Block Watching & Event Polling**
From `blockchain.store.ts`:
```typescript
export function startBlockWatcher(client: PublicClient) {
  const unwatchBlocks = client.watchBlocks({
    onBlock: (block) => {
      $currentBlock.set(block.number);
      checkStoreUpdates(block.number);
    },
    pollingInterval: 3_000,  // 3 second polling
  });
}
```

---

## 6. Dependencies & Ecosystem

### **Core Framework**
```json
{
  "astro": "5.11.0",
  "react": "^18.3.1",
  "react-dom": "^18.3.1",
  "typescript": "5.8.3"
}
```

### **Blockchain**
```json
{
  "viem": "^2.31.7",           // Ethereum RPC client
  "nanostores": "^1.0.1",      // State management
  "@nanostores/react": "^1.0.0" // React bindings
}
```

### **UI/Visualization**
```json
{
  "@tailwindcss/vite": "^4.1.11",
  "tailwindcss": "^4.1.11",
  "chart.js": "^4.5.0",
  "react-chartjs-2": "^5.3.0",
  "date-fns": "^4.1.0",
  "chartjs-adapter-date-fns": "^3.0.0",
  "p5": "^2.0.3",
  "@types/p5": "^1.7.6"
}
```

### **Astro Integrations**
```json
{
  "@astrojs/cloudflare": "12.6.0",
  "@astrojs/react": "^4.3.0",
  "@astrojs/mdx": "4.3.0",
  "@astrojs/sitemap": "3.4.1",
  "@astrojs/rss": "4.0.12"
}
```

### **Build & Deploy**
```json
{
  "@playwright/test": "^1.58.0",  // E2E testing
  "wrangler": "4.21.x"            // Cloudflare CLI
}
```

---

## 7. Build & Deployment

### **Build Configuration** (`astro.config.mjs`)

```javascript
export default defineConfig({
  site: "https://blockchain.floodboy.online",
  integrations: [mdx(), sitemap(), react()],
  adapter: cloudflare({
    mode: 'directory',           // Output structure
    imageService: 'compile',     // Image optimization
    runtime: {
      mode: 'local',             // Don't use Workers Platform runtime
      type: 'pages',             // Target Cloudflare Pages
    },
  }),
  redirects: {
    '/': '/blockchain'           // Landing page redirect
  },
  vite: {
    plugins: [tailwindcss()],
    ssr: { 
      external: ['node:buffer'], // Exclude Node APIs
    },
  },
});
```

### **Output Structure**
- **Static HTML/CSS/JS**: Served from `dist/` (Cloudflare Pages)
- **Dynamic Routes**: Compiled to `dist/_worker.js`
- **Assets**: Bundled in `dist/`

### **Deployment Assumptions**

| Aspect | Assumption |
|--------|-----------|
| **Adapter** | `@astrojs/cloudflare` (Cloudflare Workers/Pages) |
| **Output** | `static` (default) + `server` capabilities (SSR on demand) |
| **Runtime** | Cloudflare Workers (serverless) |
| **Hosting** | Cloudflare Workers Builds auto-deploy on `main` push |
| **Domain** | `blockchain.floodboy.online` (custom CNAME) |
| **Environment** | Zero env vars needed (client-side RPC, localStorage config) |

### **Deploy Methods**

**Auto-Deploy** (Recommended):
```bash
git push origin main
# Cloudflare Workers Builds detects push
# Runs: pnpm build
# Auto-deploys to production
```

**Manual Deploy**:
```bash
pnpm build
wrangler deploy  # Deploys ./dist to production
```

### **Build Scripts**
```json
{
  "build": "astro build",
  "dev": "astro dev",
  "preview": "astro build && wrangler dev",
  "check": "astro build && tsc && wrangler deploy --dry-run",
  "deploy": "wrangler deploy",
  "cf-typegen": "wrangler types",
  "test": "playwright test",
  "test:prod": "playwright test --config=playwright.prod.config.ts"
}
```

### **Wrangler Configuration** (`wrangler.json`)
```json
{
  "name": "floodboy-astro",
  "account_id": "a5eabdc2b11aae9bd5af46bd6a88179e",
  "compatibility_date": "2025-04-01",
  "compatibility_flags": ["nodejs_compat"],
  "main": "./dist/_worker.js/index.js",
  "assets": {
    "directory": "./dist",
    "binding": "ASSETS"
  },
  "observability": { "enabled": true },
  "upload_source_maps": true,
  "workers_dev": true
}
```

---

## 8. Key Features & Evolution

### **From `floodboy-ui-simple`**
This version evolved from the earlier `floodboy-ui-simple` by:

1. **Framework Upgrade**: Moved to Astro 5.11+ with modern integrations
2. **Full Blockchain Integration**: viem client, real RPC connections, event watching
3. **State Management**: Nanostores for global blockchain state
4. **Blog System**: MDX content collections with type-safe frontmatter
5. **Multi-Chain Support**: JIBCHAIN, SiChang, Anvil with fallback RPC logic
6. **Rich Visualizations**: Chart.js time-series + p5.js creative sketches
7. **Responsive UI**: Tailwind CSS 4 with dark mode support
8. **Serverless API Routes**: Astro's built-in SSR + `pages/api/` for endpoints
9. **Production Deployment**: Cloudflare Workers with automatic build pipeline

### **Current Capabilities**
- ✅ Real-time blockchain data fetching (3-second polling)
- ✅ Store discovery (factory contract integration)
- ✅ Sensor record history (100 most recent per store)
- ✅ Multi-chain switching (with RPC fallback)
- ✅ Public/Wallet/Direct view modes
- ✅ Live block indicator + RPC status
- ✅ Data export (CSV/JSON)
- ✅ Time-series charting (hourly/daily/weekly)
- ✅ p5.js visualization (water flow simulation)
- ✅ Short URL resolution (`/s/identifier`)
- ✅ Blog with rich markdown
- ✅ RSS feeds
- ✅ Automated sitemap generation

---

## 9. Testing & Quality Assurance

**E2E Testing** (Playwright):
```bash
pnpm test                    # Run locally
pnpm test:ui                 # Interactive UI mode
pnpm test:headed            # Headed browser
pnpm test:prod              # Test production deployment
```

**Type Checking**:
```bash
tsc                         # TypeScript compiler check
astro build                 # Full build validation
wrangler deploy --dry-run   # Test Workers deployment
```

---

## 10. Scaling Assumptions

| Scale Factor | Assumption |
|---|---|
| **Number of Stores** | Unlimited (paginated factory queries) |
| **Records per Store** | Last 100 cached in state (configurable) |
| **Block History** | Last ~10,000 blocks (~8.3 hours on JIBCHAIN) |
| **Concurrent Users** | Unlimited (static + serverless) |
| **RPC Throughput** | 4 endpoints with automatic failover |
| **Data Freshness** | 3-second polling interval |
| **Build Time** | ~30-60s (Cloudflare Workers Builds) |
| **Page Load** | < 2s (static HTML + React islands) |

---

## 11. Summary

**FloodBoy Astro** is a **modern, full-stack blockchain dashboard** built with Astro's island architecture. It combines:

- **Static-first rendering** (fast, SEO-friendly)
- **React islands** for interactive blockchain features
- **Nanostores** for lightweight global state
- **viem** for Ethereum RPC interactions
- **Cloudflare Workers** for edge deployment
- **Multi-chain support** with intelligent RPC fallback
- **Content collections** for blog/documentation

The project evolved from `floodboy-ui-simple` to include production-grade blockchain integration, sophisticated state management, and enterprise-level deployment infrastructure on Cloudflare.

**Key Differentiator**: Uses Astro's partial hydration to minimize JavaScript payload while maintaining rich interactivity for blockchain operations.
