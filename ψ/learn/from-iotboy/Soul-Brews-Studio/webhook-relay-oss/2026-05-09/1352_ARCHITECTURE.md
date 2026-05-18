# Webhook Relay OSS - Architecture Documentation

## Directory Structure

```
webhook-relay-oss/
├── src/                          # Backend (Cloudflare Workers + MCP)
│   ├── worker.ts                 # Main Hono router & webhook handlers
│   ├── mcp.ts                    # MCP stdio server entrypoint
│   ├── mcp-handler.ts            # JSON-RPC handler for MCP over HTTP
│   ├── db/
│   │   ├── index.ts              # Drizzle ORM initialization (D1)
│   │   └── schema.ts             # SQLite tables: webhook_hits, forward_rules, aliases
│   ├── stats.ts                  # Stats aggregation & D1 usage calculation
│   ├── forward.ts                # Webhook forwarding executor with retry/timeout logic
│   ├── github.ts                 # GitHub event parser (push, PR, issue, release, etc.)
│   └── auto-alias.ts             # LINE user/group resolver via LINE Messaging API
├── frontend/src/                 # React SPA (Tailwind CSS v4)
│   ├── main.tsx                  # React entry point (Vite)
│   ├── App.tsx                   # Auth routing & page shell
│   ├── pages/
│   │   ├── Landing.tsx           # Login form
│   │   ├── Dashboard.tsx         # Main hits viewer + forwarding config
│   │   ├── Today.tsx             # Today's hits with date filtering
│   │   ├── Aliases.tsx           # LINE user/group alias management
│   │   └── About.tsx             # Project info & settings
│   ├── components/
│   │   ├── HitsTable.tsx         # Webhook hit list renderer
│   │   ├── StatsGrid.tsx         # Dashboard metrics (total, avg, D1 usage)
│   │   ├── WebhookFeed.tsx       # Real-time hit feed (polling)
│   │   ├── ForwardConfig.tsx     # Forward rule CRUD UI
│   │   ├── GenerateUrl.tsx       # Signed URL generator
│   │   ├── Nav.tsx               # Navigation & logout
│   │   ├── PollBadge.tsx         # Polling indicator
│   │   └── ...
│   ├── demoData.ts               # Mock data for UI testing
│   └── index.css                 # Tailwind base styles
├── drizzle/                      # Database migrations (SQLite)
│   ├── 0000_*.sql                # Initial schema
│   ├── 0001_*.sql                # Forward rules & aliases
│   ├── ...
│   └── meta/                     # Migration metadata & snapshots
├── wrangler.toml                 # Cloudflare Workers config
├── package.json                  # Dependencies & scripts
├── tsconfig.json                 # TypeScript config (ESNext, ES2022)
├── vite.config.ts                # Frontend build (Vite + Tailwind + React)
├── index.html                    # HTML entry
├── README.md                     # Setup & usage guide
├── MCP.md                        # MCP tools reference
└── LICENSE                       # MIT
```

## Entry Points

### Backend
- **`src/worker.ts`** (Main Hono app, exported as default Worker handler)
  - Receives webhooks via `POST /w/:id/:token`, validates HMAC-SHA256 signature
  - Routes to specific handlers (GitHub, LINE, generic)
  - Stores hits in D1, forwards to configured URLs
  - Serves REST API (`/api/*`) for dashboard
  - Serves MCP endpoint at `POST /mcp` (JSON-RPC 2.0)
  - Falls back to React SPA via `ASSETS` binding for static routes

- **`src/mcp.ts`** (stdio transport, runs as child process)
  - Creates `McpServer` with StdioServerTransport
  - Calls REST API endpoints (authenticated via `API_TOKEN` env var)
  - Exposes 12 tools via MCP protocol

### Frontend
- **`frontend/src/main.tsx`** → Creates React root, renders `App.tsx`
- **`App.tsx`** → Auth router
  - Checks `/api/me` endpoint for login status
  - Routes to Landing, Dashboard, Today, Aliases, or About based on auth & URL path
  - Sets/clears `api_token` cookie on login/logout

## Core Abstractions

### Named Modules & Responsibilities

| Module | Purpose |
|--------|---------|
| `getDb(d1: D1Database)` | Drizzle ORM initialization for D1 |
| `recordHit()` | Insert webhook into database |
| `getStats()` | Aggregate totals: requests, avg response time, D1 usage, recent hits |
| `purgeOldHits()` | Delete hits older than 7 days (storage maintenance) |
| `getForwardRule()` | Look up forwarding config for endpoint |
| `executeForward()` | POST webhook to forward URL, track status/latency |
| `parseGitHubEvent()` | Parse GitHub webhook → human-readable summary |
| `autoAlias()` | Fetch LINE display names, auto-create aliases |
| `generateWebhookToken()` | HMAC-SHA256(id, API_TOKEN) → base64url |
| `verifyWebhookToken()` | Constant-time token comparison |
| `checkAuth()` | Bearer token or cookie validation |

### Key Classes & Types

**Drizzle ORM Schema** (`src/db/schema.ts`):

```typescript
webhookHits {
  id: integer (PK)
  endpoint: text
  suffix: text (optional, e.g., "/github")
  received_at: text (ISO8601)
  response_ms: integer
  body_length: integer
  body: text (first 4096 chars)
  forward_status: integer | null
  forward_ms: integer | null
  forward_error: text | null
}

forwardRules {
  endpoint: text (PK)
  forward_url: text
  enabled: boolean
  persist: boolean
  created_at: text
  updated_at: text
}

aliases {
  id: integer (PK)
  value: text (unique)
  label: text
  created_at: text
}
```

**Type Definitions**:
- `WebhookHit` — database record
- `ForwardRule` — routing config
- `Alias` — ID → display name mapping

## Dependencies

### Production Runtime
- **`hono`** ^4.11 — HTTP router/framework (Cloudflare Workers first-class)
- **`drizzle-orm`** ^0.45.1 — Type-safe ORM for D1 (SQLite)
- **`react`** ^19.2.4 — UI framework
- **`react-dom`** ^19.2.4 — React rendering
- **`tailwindcss`** ^4.2.1 — CSS utilities
- **`@tailwindcss/vite`** ^4.2.1 — Vite integration
- **`zod`** ^4.3.6 — Schema validation (MCP tool params)
- **`@modelcontextprotocol/sdk`** ^1.27.0 — MCP protocol (stdio + types)

### Dev Tooling
- **`vite`** ^7.3.1 — Frontend bundler (dev + prod build)
- **`@vitejs/plugin-react`** ^5.1.4 — JSX/React HMR
- **`@cloudflare/vite-plugin`** ^1.25.2 — Cloudflare Workers integration
- **`wrangler`** ^4 — Cloudflare Workers CLI (local dev, deploy)
- **`typescript`** ^5.7 — Type checking
- **`drizzle-kit`** ^0.31.9 — Schema generation & migrations
- **`better-sqlite3`** ^12.6.2 — Local D1 simulation
- **`@types/react`**, **`@types/react-dom`** — React types
- **`@cloudflare/workers-types`** ^4.20260302.0 — Workers API types
- **`dotenv`** ^17.3.1 — Env var loading

### Database Abstraction
- **D1 (Cloudflare SQLite)** — ACID database with 5GB limit, 100k writes/day
- Drizzle ORM abstracts SQL generation & type safety

## Cloudflare-Specific Configuration

**`wrangler.toml`**:
```toml
name = "webhook-relay"
main = "src/worker.ts"                      # Worker entry point
compatibility_date = "2025-06-01"           # Runtime version
compatibility_flags = ["nodejs_compat"]     # Node.js API support

[assets]
binding = "ASSETS"                          # Static file serving (SPA)
not_found_handling = "single-page-application"
run_worker_first = true                     # Router first, fallback to assets

[[d1_databases]]
binding = "DB"
database_name = "soul-brews-cat-lab"
migrations_dir = "drizzle"
```

**Environment Bindings**:
- `DB: D1Database` — SQLite database (migrations auto-applied on deploy)
- `ASSETS: Fetcher` — Static file server (built frontend)

**Secrets** (via `wrangler secret put`):
- `API_TOKEN` — `user:pass` format for auth & webhook signing
- `LINE_CHANNEL_ACCESS_TOKEN` — (optional) for auto-alias LINE users

## Frontend-to-Backend Integration

### REST API Routes
| Method | Route | Auth | Purpose |
|--------|-------|------|---------|
| GET | `/api/me` | — | Check if authenticated |
| POST | `/auth/login` | — | Form-based login (sets `api_token` cookie) |
| GET | `/auth/logout` | — | Clear cookie |
| GET | `/api/stats` | Bearer | Dashboard metrics (total, avg, recent, D1) |
| GET | `/api/hits?date=today&endpoint=X` | Bearer | Query hits by date & endpoint (GMT+7) |
| GET | `/api/generate-url?id=X` | Bearer | Generate signed webhook URL |
| GET | `/api/forward-rules` | Bearer | List all rules |
| PUT | `/api/forward-rules/:endpoint` | Bearer | Create/update rule |
| DELETE | `/api/forward-rules/:endpoint` | Bearer | Delete rule |
| GET | `/api/aliases` | Bearer | List aliases with activity |
| PUT | `/api/aliases` | Bearer | Create/update alias |
| DELETE | `/api/aliases/:id` | Bearer | Delete alias |
| GET | `/api/aliases/unknown` | Bearer | Unaliased IDs from recent hits |
| POST | `/api/aliases/resolve` | Bearer | Fetch LINE name via API, save as alias |
| POST | `/api/purge` | Bearer | Delete hits older than 7 days |

### Frontend State Management
- **Auth State**: localStorage/cookie (`api_token`)
- **Real-time Updates**: Polling (WebhookFeed component polls `/api/hits` every 2-5s)
- **Form Validation**: React hooks (no external state library)
- **API Calls**: `fetch()` with Bearer token in header

### Frontend Route Prefixes
- `/` — Dashboard (main view)
- `/today` — Today's hits
- `/aliases` — Alias management
- `/about` — Info page
- `/auth/login` — POST endpoint for form submission

## MCP Server Integration

### MCP Entrypoint: `src/mcp.ts`

Runs as a Node.js child process (via `npx tsx`). Provides two transport options:

1. **stdio (local)** — Recommended for development
   ```bash
   npx tsx src/mcp.ts
   ```

2. **HTTP (remote)** — Query `POST https://your-worker.workers.dev/mcp`
   - Requires Bearer auth header

### MCP Handler: `src/mcp-handler.ts`

Implements JSON-RPC 2.0 protocol with 12 tools:

| Tool | Description |
|------|-------------|
| `webhook_stats` | Dashboard overview (total, avg, recent, D1 usage) |
| `webhook_hits` | Query by date & endpoint (GMT+7) |
| `list_forward_rules` | Show all forwarding rules |
| `set_forward_rule` | Create/update rule (endpoint, url, enabled, persist) |
| `delete_forward_rule` | Remove rule |
| `list_aliases` | Show aliases + activity, filter by type, or unaliased only |
| `set_alias` | Create/update alias (value → label) |
| `delete_alias` | Remove alias by ID |
| `purge_old_hits` | Delete hits older than 7 days |
| `generate_webhook_url` | Get signed URL for endpoint |
| `line_groups` | List active LINE groups with message counts |
| `line_digest` | Parse LINE hits into table (time, group, from, type, text) |

### MCP Tool Capabilities

- **Date handling**: GMT+7 (Bangkok time), supports "today" or "YYYY-MM-DD"
- **Alias resolution**: Maps LINE user/group IDs to human names (auto-populated via `auto-alias.ts`)
- **Activity tracking**: Counts messages per ID, tracks last seen time
- **Filtering**: By endpoint, date, group, type (group vs. user)

## Build & Deployment Flow

### Development (`npm run dev`)
1. Vite starts frontend dev server (localhost:5173)
2. Wrangler starts local Cloudflare Workers runtime
3. D1 runs as local SQLite in memory (migrations auto-applied)
4. Frontend hot-reloads on changes
5. Backend requires full restart on changes

### Production (`npm run deploy`)
1. `vite build` → bundles frontend to `dist/`
2. `wrangler deploy` → deploys worker to Cloudflare
3. Migrations run automatically on D1

## Summary

**Webhook Relay** is a serverless webhook receiver & forwarder built on Cloudflare Workers. It receives signed webhook URLs (Discord-style `/w/{id}/{token}` pattern), validates via HMAC-SHA256, stores hits in D1 SQLite, optionally forwards to configured URLs, and provides a React dashboard for management. The 12-tool MCP server exposes the full API for Claude Code integration (both stdio and HTTP). LINE integration auto-resolves user/group IDs to display names and provides ready-to-read digest tables. GitHub events are parsed into human-readable summaries. Storage is capped at 5GB with 100k writes/day; hits older than 7 days can be purged manually.

---

**Architecture Key Insights:**
- **Stateless Workers**: Each request is independent; no in-memory state
- **HMAC signing**: URLs are self-authenticating (token = HMAC-SHA256(id, API_TOKEN))
- **Non-blocking forwarding**: Webhooks return immediately; forwards run in `waitUntil()`
- **D1 abstraction**: Drizzle ORM provides type-safe SQL without raw queries
- **MCP dual-mode**: stdio for local development, HTTP for remote access
- **Real-time UI**: Polling over WebSocket (simpler for SPA architecture)
