# Webhook Relay OSS — Quick Reference

## What It Does

Webhook Relay is a self-hosted webhook receiver built on Cloudflare Workers + D1 SQLite. It accepts incoming webhooks from external services (LINE, GitHub, etc.), stores them in a database, and optionally forwards them to your own backends. It includes a React dashboard for viewing webhook history, managing forwarding rules, and resolving user/group names via aliases (useful for LINE). The entire thing runs on Cloudflare's free tier or can be deployed locally for development — no webhooks are lost, and you control all your data.

---

## Install / Setup

### Local Development (Recommended First Step)

```bash
git clone https://github.com/Soul-Brews-Studio/webhook-relay-oss.git
cd webhook-relay-oss
npm install
cp .dev.vars.example .dev.vars   # edit credentials if needed
npm run dev                       # → http://localhost:5173
```

**What this does:**
- Starts a Vite + Wrangler dev server with a **local D1 database** (no Cloudflare account needed)
- Migrations run automatically on startup
- Default login: `admin` / `changeme` (from `.dev.vars`)
- Dashboard is live at `http://localhost:5173`

### Expose to Internet (For Receiving Webhooks)

Use Cloudflare Tunnel (free, no account needed):

```bash
cloudflared tunnel --url http://localhost:5173
```

This gives you a public `https://xxx.trycloudflare.com` URL. Then:
1. Open the dashboard at that URL and log in
2. Go to **Generate URL** → enter endpoint name (e.g., `line`)
3. Copy the signed URL → paste into your webhook provider (LINE Console, GitHub, etc.)

**Why this works:** The signed URL pattern `/w/{id}/{token}` uses HMAC-SHA256 authentication — the URL itself is the auth, no API key headers needed for senders.

### Production Deploy (Always-On Hosting)

```bash
npm run deploy   # builds frontend + deploys to Cloudflare Workers
```

After deploying:

```bash
wrangler secret put API_TOKEN   # enter user:pass when prompted
```

One-click deploy: [![Deploy to Cloudflare](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/Soul-Brews-Studio/webhook-relay-oss)

---

## Required Environment Variables / Wrangler Bindings

### `.dev.vars` (Local Development)

```
API_TOKEN=admin:changeme
# Optional: auto-fetch LINE display names
# LINE_CHANNEL_ACCESS_TOKEN=your-channel-access-token
```

### Production (Cloudflare Secrets)

| Variable | Required | Format | Purpose |
|----------|----------|--------|---------|
| `API_TOKEN` | Yes | `user:pass` | Dashboard login + API auth + webhook URL signing secret |
| `LINE_CHANNEL_ACCESS_TOKEN` | No | Bearer token | Auto-resolve LINE user/group display names |

**Wrangler Bindings (automatic from `wrangler.toml`):**

| Binding | Type | Name | Purpose |
|---------|------|------|---------|
| `DB` | D1 Database | `soul-brews-cat-lab` | SQLite database for hits, forward rules, aliases |
| `ASSETS` | Fetcher | — | Serves the React frontend SPA |

---

## Common Usage Examples

### Example 1: Receive LINE Webhooks

1. **Generate signed URL from dashboard:**
   - Navigate to `http://localhost:5173/` (or your production URL)
   - Go to **Generate URL** tab
   - Enter endpoint name: `line`
   - Copy the resulting URL: `https://xxx.trycloudflare.com/w/line/{token}`

2. **Register in LINE Developers Console:**
   - Go to [LINE Developers Console](https://developers.line.biz/console/)
   - Select your Messaging API channel
   - Webhook URL → paste the full `/w/line/{token}` URL
   - Enable "Use webhook"

3. **View incoming webhooks:**
   - Messages appear in the dashboard **Today** tab (GMT+7 timestamps)
   - Click on any hit to see the raw JSON
   - User/group names auto-resolve if `LINE_CHANNEL_ACCESS_TOKEN` is set

### Example 2: Forward Webhooks to Your Backend

1. **Set up forwarding rule:**
   ```bash
   curl -H "Authorization: Bearer admin:changeme" \
     -X PUT http://localhost:5173/api/forward-rules/line \
     -H "Content-Type: application/json" \
     -d '{
       "forward_url": "https://my-api.example.com/hooks/line",
       "enabled": true,
       "persist": true
     }'
   ```

2. **Webhooks now flow:**
   ```
   LINE → /w/line/{token} (recorded in DB) → https://my-api.example.com/hooks/line
   ```

3. **Monitor forwarding:**
   - Dashboard shows `forward_status`, `forward_ms`, and `forward_error` for each hit
   - Toggle forwarding on/off via **Forward Config** tab without deleting the rule

### Example 3: GitHub Webhooks (Auto-Parsed)

1. **Generate URL for GitHub endpoint:**
   - Dashboard: **Generate URL** → endpoint: `github`
   - Get: `https://xxx.trycloudflare.com/w/github/{token}`

2. **Register in GitHub repo settings:**
   - Repo → Settings → Webhooks → Add webhook
   - Payload URL: `https://xxx.trycloudflare.com/w/github/{token}/github`
   - Events: Select what you want (push, PR, etc.)

3. **Dashboard shows parsed summaries:**
   - Events are parsed via `parseGitHubEvent()` (commit authors, PR titles, etc.)
   - Body shows a human-readable summary, not raw JSON
   - Raw payload still forwarded if a forward rule is configured

### Example 4: Register Aliases for LINE Users

Aliases map raw IDs to human names:

```bash
# Create an alias
curl -H "Authorization: Bearer admin:changeme" \
  -X PUT http://localhost:5173/api/aliases \
  -H "Content-Type: application/json" \
  -d '{
    "value": "Uxxxxxxxxxxxxxxxxxxxxxx",
    "label": "Alice"
  }'
```

**Or via dashboard:**
- **Aliases** tab → click **Find unknown users** → Resolve button pulls from LINE API
- Aliases appear in the hit feed and `/api/aliases/unknown` endpoint

---

## Configuration Knobs

### Rate Limits & Retry Policy

**No built-in rate limits** — configure at your webhook provider or add a forwarding rule with a rate-limiting service.

**Retry policy:**
- Incoming webhook: Always accepted, stored immediately (forward is async)
- Forwarding: Single attempt, 10-second timeout per request
- On forward failure: Error logged in `forward_error` field, hit remains in database

### Webhook URL Signing

- **Algorithm:** HMAC-SHA256(endpoint_id, API_TOKEN)
- **Token format:** URL-safe base64 (no padding)
- **Verification:** Built into `/w/{id}/{token}` routes — invalid tokens return 401
- **Use:** No additional headers needed; the URL itself is the credential

### Database Retention

- **Default:** All hits kept until manually purged
- **Purge:** `POST /api/purge` → deletes hits older than 7 days
- **D1 limits:** Free tier is 5GB storage, 100K writes/day
- **Dashboard shows:** Current DB size, writes today, limits

### Hit Persistence Flag

```bash
# Disable persistence for an endpoint — webhooks received but NOT stored
PUT /api/forward-rules/line
{
  "forward_url": "https://...",
  "enabled": true,
  "persist": false   # ← prevents recording in DB
}
```

---

## All Available npm Scripts

| Script | Purpose |
|--------|---------|
| `npm run dev` | Local dev server (Vite + Wrangler, local D1) — http://localhost:5173 |
| `npm run build` | Build frontend only (Vite) — outputs to `dist/` |
| `npm run deploy` | Build frontend + deploy Worker to Cloudflare |
| `npm run typecheck` | TypeScript type-check without emitting |
| `npm run mcp` | Run the MCP server directly (stdio transport) |
| `npm run db:generate` | Generate Drizzle migration files from schema changes |
| `npm run db:migrate` | Apply pending migrations (local) |
| `npm run db:push` | Push schema directly to D1 (remote) |
| `npm run db:studio` | Open Drizzle Studio — inspect/edit local D1 DB in browser |

---

## All Endpoints

### Public (No Auth Required)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| **POST** | `/w/:id/:token` | Receive raw webhook, store in DB, forward if enabled |
| **POST** | `/w/:id/:token/github` | GitHub webhook — parse + store parsed summary, forward raw body |
| **POST** | `/w/:id/:token/:suffix` | Custom suffix endpoint — same as above but with `:suffix` recorded |

### Auth Required (Bearer token or session cookie)

#### Authentication
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **POST** | `/auth/login` | Login with `username` & `password` form fields → sets `api_token` cookie |
| **GET** | `/auth/logout` | Logout → clears cookie |
| **GET** | `/api/me` | Check login status → returns `{ loggedIn: boolean }` |

#### URL Generation
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **GET** | `/api/generate-url?id=:id` | Generate signed webhook URL `/w/{id}/{token}` for endpoint |

#### Statistics & Hits
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **GET** | `/api/stats` | Dashboard overview — total hits, avg response time, D1 usage, version, uptime |
| **GET** | `/api/hits?date=:date&endpoint=:endpoint` | Query webhook hits (GMT+7 date filtering, 500 limit) |

#### Forward Rules CRUD
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **GET** | `/api/forward-rules` | List all forwarding rules |
| **PUT** | `/api/forward-rules/:endpoint` | Create/update rule — body: `{ forward_url, enabled?, persist? }` |
| **DELETE** | `/api/forward-rules/:endpoint` | Delete a forwarding rule |

#### Aliases CRUD
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **GET** | `/api/aliases` | List all aliases |
| **GET** | `/api/aliases/unknown` | Scan recent LINE hits — return unaliased user/group IDs with activity counts |
| **PUT** | `/api/aliases` | Create/update alias — body: `{ value, label }` |
| **POST** | `/api/aliases/resolve` | Fetch LINE display name via LINE API — body: `{ id, groupId? }` |
| **DELETE** | `/api/aliases/:id` | Delete alias by ID |

#### Maintenance
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **POST** | `/api/purge` | Delete webhook hits older than 7 days |

#### MCP Server
| Method | Endpoint | Purpose |
|--------|----------|---------|
| **POST** | `/mcp` | JSON-RPC 2.0 MCP endpoint — tools/list, tools/call (requires Bearer auth) |

---

## Frontend Pages

Deployed at `/` and navigable via sidebar. All require login except Landing.

| Path | Name | Purpose |
|------|------|---------|
| `/` | **Dashboard** | Main status page — live stats, recent hits, hit detail modal, generate URL, forward config, webhook feed (auto-polls every 5s) |
| `/today` | **Today** | Hits for today (GMT+7) — filterable by endpoint, sortable table, raw JSON viewer |
| `/aliases` | **Aliases** | Manage aliases — list with activity data, find unknown users, auto-resolve via LINE API, delete |
| `/about` | **About** | Project info — version, GitHub link, contact, license |
| (no auth) | **Landing** | Login page if not authenticated |

**Features:**
- **Demo mode** (toggle via nav) — shows example data without live polling
- **Real-time updates** — Dashboard polls `/api/stats` every 5 seconds, other pages on demand
- **Responsive design** — Tailwind v4, works on mobile
- **User/group resolution** — Aliases auto-applied in all displays

---

## MCP (Model Context Protocol) Integration

### Setup

**Local stdio (recommended for development):**

```bash
claude mcp add webhook-relay \
  -e API_TOKEN=admin:changeme \
  -e WEBHOOK_RELAY_URL=http://localhost:5173 \
  -- npx tsx src/mcp.ts
```

**Remote HTTP (no local install needed):**

```bash
claude mcp add webhook-relay \
  -e API_TOKEN=user:pass \
  -e WEBHOOK_RELAY_URL=https://your-worker.workers.dev \
  -- npx tsx src/mcp.ts
```

### Available Tools (12 Total)

| Tool | Input | Purpose |
|------|-------|---------|
| `webhook_stats` | — | Get stats: total hits, avg response ms, D1 usage, uptime |
| `webhook_hits` | `date` (today/YYYY-MM-DD), `endpoint`, `group` | Query hits with GMT+7 filtering; optional group filter |
| `list_forward_rules` | — | List all forwarding rules (endpoint → URL mappings) |
| `set_forward_rule` | `endpoint`, `forward_url`, `enabled?`, `persist?` | Create/update forwarding rule |
| `delete_forward_rule` | `endpoint` | Remove a forwarding rule |
| `list_aliases` | `type?` (group/user/all), `unaliased?` (bool) | List aliases with activity; optionally show only unaliased IDs |
| `set_alias` | `value`, `label` | Create/update alias |
| `delete_alias` | `id` | Delete alias by ID |
| `purge_old_hits` | — | Delete hits older than 7 days |
| `generate_webhook_url` | `id` | Get signed URL `/w/{id}/{token}` for endpoint |
| `line_groups` | `date?` | List active LINE groups for a date with message counts |
| `line_digest` | `date?`, `endpoint?`, `group?` | Parse LINE hits into readable digest (who said what when, resolved via aliases) |

---

## Tech Stack

- **Backend:** Hono (router) on Cloudflare Workers
- **Database:** D1 (SQLite) + Drizzle ORM
- **Frontend:** React 19 + Tailwind CSS v4 + Vite
- **Auth:** HMAC-SHA256 signed URLs (Discord-style) + session cookies
- **Deployment:** Cloudflare Workers + D1

---

## Key Database Tables

| Table | Columns | Purpose |
|-------|---------|---------|
| `webhook_hits` | id, endpoint, suffix, received_at, response_ms, body_length, body, forward_status, forward_ms, forward_error | Stores incoming webhooks |
| `forward_rules` | endpoint, forward_url, enabled, persist, created_at, updated_at | Forwarding destinations per endpoint |
| `aliases` | id, value, label, created_at | Maps IDs (LINE user/group) to human names |

---

## Notes

- **Time zone:** All `/api/hits` date filtering uses GMT+7 (Thailand/Bangkok) — change in `worker.ts` if needed
- **Hit limit:** Queries return max 500 hits per request
- **Forward timeout:** 10 seconds per forwarding attempt
- **Body truncation:** Raw body stored up to 4096 chars (parsed summaries may be shorter)
- **No built-in auth for incoming webhooks** — rely on signed URL token in the path
- **Cloudflare free tier:** 100K requests/day, 100K D1 writes/day, 5GB storage
