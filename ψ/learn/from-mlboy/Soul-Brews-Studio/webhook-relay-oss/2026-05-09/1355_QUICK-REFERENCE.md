# Webhook Relay OSS — Quick Reference Guide

**What it does**: Receive webhooks (LINE, GitHub, any HTTP service), store them in SQLite, forward to other URLs, and inspect via a React dashboard. Built on Cloudflare Workers + D1. Minimal auth: signed HMAC URLs mean senders don't need API keys.

**Who it's for**: Teams needing webhook ingestion + inspection without vendor lock-in. LINE group integrations. Local webhook testing. Quick event logging and forwarding logic.

---

## Installation & Setup

### Local Development (No Cloudflare Account Needed)

```bash
git clone https://github.com/Soul-Brews-Studio/webhook-relay-oss.git
cd webhook-relay-oss
npm install
cp .dev.vars.example .dev.vars
npm run dev
# → Dashboard at http://localhost:5173
```

Login with default: `admin` / `changeme` (from `.dev.vars`).

The `npm run dev` command:
- Applies D1 migrations to a local SQLite DB
- Starts Vite dev server (frontend)
- Starts Wrangler dev server (backend)
- No Cloudflare account required.

### Expose to Internet (Local Testing)

Use free **Cloudflare Tunnel**:

```bash
cloudflared tunnel --url http://localhost:5173
# → https://xxx.trycloudflare.com
```

Then open that URL + login to generate signed webhook URLs.

### Production Deploy

```bash
npm run deploy
# → deploys to Cloudflare Workers

wrangler secret put API_TOKEN
# → set user:pass auth token
```

**One-click deploy**:
[![Deploy to Cloudflare](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/Soul-Brews-Studio/webhook-relay-oss)

---

## Environment Variables & Bindings

### `.dev.vars` (Local)

```env
API_TOKEN=admin:changeme
# Optional: auto-fetch LINE display names
# LINE_CHANNEL_ACCESS_TOKEN=xxxxxxxxxxx
```

### `wrangler.toml` (Production)

```toml
name = "webhook-relay"
main = "src/worker.ts"
compatibility_date = "2025-06-01"

[assets]
binding = "ASSETS"
not_found_handling = "single-page-application"
run_worker_first = true

[[d1_databases]]
binding = "DB"
database_name = "soul-brews-cat-lab"
migrations_dir = "drizzle"
```

### Secrets & Config

| Variable | Purpose | Required | How to Set |
|----------|---------|----------|-----------|
| `API_TOKEN` | Auth token (`user:pass`). Used for dashboard login, API calls, webhook URL signing. | Yes | `.dev.vars` (local) or `wrangler secret put API_TOKEN` (prod) |
| `LINE_CHANNEL_ACCESS_TOKEN` | Auto-fetch LINE user/group display names for aliases. | No | `.dev.vars` or `wrangler secret put` |

### Database Bindings

D1 database auto-configured in `wrangler.toml`. Tables created by Drizzle migrations:
- `webhook_hits` — webhook payloads + metadata
- `forward_rules` — endpoint → URL mappings
- `aliases` — LINE user/group ID → human name mappings

---

## Key Features & Examples

### 1. Signed Webhook URLs (Discord-Style)

Generate a signed URL in the dashboard or via API:

```bash
curl -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/generate-url?id=line"

# Response:
# {"url": "http://localhost:5173/w/line/AeC8HpQ..."}
```

The token is `HMAC-SHA256(id, API_TOKEN)` encoded as base64-URL. **No bearer header needed from webhook senders** — the URL itself is the auth.

### 2. Receive Webhooks

**Raw endpoint** (any service):
```
POST /w/{id}/{token}
Content-Type: application/json

{"key": "value"}
```

**GitHub parsing endpoint**:
```
POST /w/{id}/{token}/github
X-GitHub-Event: push
```
→ Auto-parses `push`, `pull_request`, `issues`, `release`, etc. into readable summaries.

**Dynamic suffix endpoint**:
```
POST /w/{id}/{token}/custom-action
```
→ Stores with `suffix: "/custom-action"` in the database.

### 3. Forward Rules

Create forwarding rules via dashboard or API:

```bash
curl -X PUT \
  -H "Authorization: Bearer admin:changeme" \
  -H "Content-Type: application/json" \
  -d '{
    "forward_url": "https://webhook.site/xxx",
    "enabled": true,
    "persist": true
  }' \
  "http://localhost:5173/api/forward-rules/line"
```

Options:
- `forward_url`: destination URL (required)
- `enabled`: toggle forwarding on/off
- `persist`: if `false`, don't store hits in database (log-only)

### 4. Aliases (LINE Integration)

Auto-alias LINE user/group IDs to human names:

```bash
# List aliases
curl -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/aliases"

# Create alias
curl -X PUT \
  -H "Authorization: Bearer admin:changeme" \
  -H "Content-Type: application/json" \
  -d '{"value": "C1234567...", "label": "Family Group"}' \
  "http://localhost:5173/api/aliases"

# Delete alias (by ID)
curl -X DELETE \
  -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/aliases/1"
```

**Auto-alias** (if `LINE_CHANNEL_ACCESS_TOKEN` set):
- Background job after each LINE webhook
- Resolves unknown user/group IDs via LINE Messaging API
- Stores as aliases automatically

### 5. Query Recent Webhooks

```bash
# Today (GMT+7 offset)
curl -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/hits?date=today"

# Specific date
curl -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/hits?date=2026-05-09"

# By endpoint
curl -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/hits?date=today&endpoint=line"
```

Response includes up to 500 recent hits with timestamps, response times, body, and forward status.

### 6. Dashboard

- **Real-time hit viewer** — see webhooks as they arrive (GMT+7)
- **Forwarding rules** — enable/disable per endpoint
- **Alias management** — map unknown IDs to names
- **Stats** — total requests, avg response time, D1 usage

---

## Hello World — First Webhook

1. **Start local dev**:
   ```bash
   npm run dev
   ```

2. **Generate webhook URL** (dashboard or API):
   ```bash
   curl -H "Authorization: Bearer admin:changeme" \
     "http://localhost:5173/api/generate-url?id=test"
   ```

3. **Send a webhook** (from another terminal):
   ```bash
   curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello!"}' \
     "http://localhost:5173/w/test/YOUR_TOKEN_HERE"
   ```

4. **View in dashboard**:
   - Open http://localhost:5173
   - Login: `admin` / `changeme`
   - See your webhook under "Today"

---

## Common Operations

### Add a New Webhook Endpoint

1. Dashboard → "Generate URL" → enter endpoint name (e.g. `stripe`)
2. Copy the signed URL: `/w/stripe/...`
3. Paste into webhook provider (Stripe Console, GitHub, etc.)
4. Webhooks start appearing in dashboard

### Configure Forwarding

1. Dashboard → "Forwarding Rules"
2. Enter endpoint (e.g. `line`) and destination URL (e.g. `https://my-service.com/webhooks`)
3. Toggle "Enabled"
4. Webhooks now forward + stored in DB

### Manually Alias a LINE User

1. Dashboard → "Aliases" → "Scan Unknown"
2. See list of unaliased LINE users/groups
3. Click "Resolve" → fetches name from LINE API
4. Auto-saved as alias

### Purge Old Webhooks

```bash
curl -X POST \
  -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/purge"
```

Deletes all hits older than 7 days.

### Check Stats

```bash
curl -H "Authorization: Bearer admin:changeme" \
  "http://localhost:5173/api/stats"
```

Returns: total requests, avg response time, recent hits, forward rules, version.

---

## MCP Integration (Claude Code)

### Local Setup (Recommended for Development)

```bash
claude mcp add webhook-relay \
  -e API_TOKEN=admin:changeme \
  -e WEBHOOK_RELAY_URL=http://localhost:5173 \
  -- npx tsx src/mcp.ts
```

### Remote Setup (Production, HTTP Transport)

```bash
claude mcp add webhook-relay \
  -e API_TOKEN=user:pass \
  -e WEBHOOK_RELAY_URL=https://your-worker.workers.dev \
  -- npx tsx src/mcp.ts
```

### Available MCP Tools

| Tool | Input | Output |
|------|-------|--------|
| `webhook_stats` | — | Dashboard stats (total, avg response, D1 usage, uptime) |
| `webhook_hits` | `date` (YYYY-MM-DD or "today"), `endpoint` (optional) | Array of hits for the date range |
| `list_forward_rules` | — | All forwarding rules with URLs, enabled status, timestamps |
| `set_forward_rule` | `endpoint`, `forward_url`, `enabled` (bool), `persist` (bool) | Confirms rule created/updated |
| `delete_forward_rule` | `endpoint` | Confirms deletion |
| `list_aliases` | — | All aliases (ID, value, label, created_at) |
| `set_alias` | `value` (ID), `label` (human name) | Confirms alias created/updated |
| `delete_alias` | `id` (numeric) | Confirms deletion |
| `purge_old_hits` | — | Confirmation + count deleted |
| `generate_webhook_url` | `id` (endpoint name) | Signed URL `/w/{id}/{token}` |
| `line_groups` | `date` (YYYY-MM-DD or "today") | List active LINE groups on that date |
| `line_digest` | `date` (YYYY-MM-DD or "today") | Parsed LINE message digest with alias resolution |

### Example MCP Usage

```typescript
// Get dashboard stats
await webhook_stats()
// → {total_requests: 142, avg_response_ms: 23, ...}

// Query LINE webhooks for today
await webhook_hits({date: "today", endpoint: "line"})
// → [{id: 1, endpoint: "line", body: "...", received_at: "..."}]

// Generate a signed URL for "slack" endpoint
await generate_webhook_url({id: "slack"})
// → {url: "http://localhost:5173/w/slack/..."}

// Set a forwarding rule
await set_forward_rule({
  endpoint: "stripe",
  forward_url: "https://api.example.com/stripe",
  enabled: true,
  persist: true
})

// Digest LINE messages for the day
await line_digest({date: "today"})
// → "John: hello\nFamily Group: Got it\n..."
```

---

## Configuration & Customization

### Add a New Webhook Endpoint

No code needed. Just:
1. Generate a signed URL in dashboard for a new endpoint name
2. Forward rules auto-create entries when you set them

### Customize GitHub Event Parsing

Edit `src/github.ts`:
- `parseGitHubEvent(event, payload)` handles `push`, `pull_request`, `issues`, `release`, etc.
- Add new cases for additional event types

### Extend Alias Resolution

Edit `src/auto-alias.ts`:
- Modify `extractIds()` to parse additional webhook formats
- Customize `fetchGroupName()` / `fetchUserName()` for non-LINE providers

### Add a New API Route

Edit `src/worker.ts` — add routes like:
```typescript
app.get("/api/my-endpoint", async (c) => {
  if (!checkAuth(c.req.raw, c.env)) return c.json({ error: "Unauthorized" }, 401);
  // your logic
  return c.json({...});
});
```

### Deploy to Custom Domain

```bash
npm run deploy
# Update DNS CNAME to Cloudflare Workers
# wrangler assigns a workers.dev subdomain automatically
```

---

## Gotchas & Footguns

### 1. Token Rotation

- Tokens are derived from `API_TOKEN` at runtime (HMAC)
- If you change `API_TOKEN`, old signed URLs break
- Regenerate all signed URLs after changing token

### 2. Timezone (GMT+7 Hardcoded)

- `/api/hits?date=today` uses GMT+7 offset
- If you run in a different timezone, adjust in `src/worker.ts` line 386:
  ```typescript
  const GMT7_OFFSET_MS = 7 * 60 * 60 * 1000;
  ```

### 3. D1 Size Limits

- Free tier: 5 GB
- Each webhook body truncated to 4096 chars (see `src/worker.ts` line 99)
- Purge old hits regularly: `npm run db:studio` → check table size

### 4. LINE API Rate Limits

- Auto-alias resolves in parallel but respects LINE's 300 req/min
- If you receive >5 new LINE users per second, some aliases may be delayed

### 5. Forwarding Timeout

- 10-second timeout per forward (see `src/forward.ts` line 40)
- If destination is slow, webhook is marked "forward failed"
- Hits are always stored even if forward fails

### 6. CORS & SPA

- `run_worker_first = true` in `wrangler.toml` ensures Workers run before SPA fallback
- Dashboard login handled via `api_token` cookie (HttpOnly, SameSite=Strict)

### 7. MCP Over HTTP

- Remote HTTP transport requires `API_TOKEN` in Authorization header
- No streaming — full request/response (OK for <10KB payloads)
- Local stdio transport preferred for real-time updates

---

## Security Notes

- **Signed URLs**: HMAC-SHA256, URL-safe base64 encoding. Sender cannot forge without `API_TOKEN`.
- **Dashboard auth**: Cookie-based, HttpOnly + Secure + SameSite=Strict.
- **API auth**: Bearer token OR Cookie (backward-compat).
- **Secrets**: Never commit `.dev.vars` with real tokens. Use `wrangler secret` for production.
- **Data retention**: Hits stored in D1. Manual purge via `/api/purge` or cron job.
- **No encryption at rest**: D1 is managed by Cloudflare; encrypt sensitive payloads client-side if needed.

---

## Useful Commands

```bash
npm run dev              # Start local dev server (Vite + Wrangler)
npm run build            # Build frontend (Vite)
npm run deploy           # Build + deploy to Cloudflare Workers
npm run typecheck        # Run TypeScript type check
npm run db:generate      # Generate Drizzle migrations (after schema change)
npm run db:migrate       # Apply pending migrations
npm run db:push          # Push schema to D1 (for production)
npm run db:studio        # Open Drizzle Studio to inspect local DB
npm run mcp              # Test MCP server locally
```

---

## Architecture

```
┌─ LINE / GitHub / Any Service
│
└─→ Cloudflare Worker (Hono)
    ├─ POST /w/:id/:token              → store + forward (signed URL)
    ├─ POST /w/:id/:token/github       → parse GitHub events
    ├─ POST /w/:id/:token/:suffix      → custom suffixes
    ├─ GET  /api/hits?date=...         → query stored webhooks
    ├─ GET  /api/generate-url?id=...   → generate signed URL
    ├─ PUT  /api/forward-rules/:id     → set forwarding rule
    ├─ GET  /api/aliases               → list aliases
    ├─ POST /auth/login                → dashboard login
    ├─ POST /mcp                       → MCP server (JSON-RPC)
    └─ /* (SPA fallback)               → React dashboard
         │
         └─→ D1 (SQLite via Drizzle ORM)
             ├─ webhook_hits    (id, endpoint, suffix, body, received_at, forward_status, ...)
             ├─ forward_rules   (endpoint, forward_url, enabled, persist, created_at)
             └─ aliases         (id, value, label, created_at)
```

---

## Next Steps

- **LINE integration**: Set `LINE_CHANNEL_ACCESS_TOKEN` in `.dev.vars` → auto-resolve group/user names
- **GitHub integration**: Add webhook endpoint, paste signed URL into GitHub repo settings
- **Forwarding logic**: Set rules to forward filtered webhooks to your backend
- **MCP tools**: Query dashboards via Claude Code (stats, recent hits, alias management)
- **Custom parsing**: Extend `src/github.ts` or `src/auto-alias.ts` for your providers
- **Production secrets**: Use `wrangler secret put` for real tokens; never commit `.env`

Built by [Soul Brews Studio](https://github.com/soul-brews-studio). MIT License.
