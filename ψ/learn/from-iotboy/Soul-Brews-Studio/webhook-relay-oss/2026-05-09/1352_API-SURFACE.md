# Webhook Relay - Public Integration Surface Map

**Project:** webhook-relay-oss by Soul-Brews-Studio  
**Version:** 0.5.0  
**Generated:** 2026-05-09  
**Thoroughness Level:** Very Thorough

---

## 1. HTTP Routes Summary

| Method | Path | Purpose | Auth | Request Body | Response Shape | Status Codes |
|--------|------|---------|------|--------------|----------------|-------------|
| POST | `/w/:id/:token` | Receive & store webhook | URL-signed token | Any (text/json) | `{"ok":true,"endpoint":"...","received_at":"...","response_ms":N}` | 200, 401 |
| POST | `/w/:id/:token/github` | GitHub webhook with parsing | URL-signed token | JSON | `{"ok":true,"endpoint":"...","event":"...","received_at":"...","response_ms":N}` | 200, 401 |
| POST | `/w/:id/:token/:suffix` | Generic webhook with path suffix | URL-signed token | Any (text/json) | `{"ok":true,"endpoint":"...","suffix":"/...","received_at":"...","response_ms":N}` | 200, 401 |
| POST | `/auth/login` | Dashboard login (set cookie) | None (form auth) | `{username,password}` form-data | `{"ok":true}` + Set-Cookie header | 200, 401 |
| GET | `/auth/logout` | Clear auth cookie | None | - | `{"ok":true}` + Set-Cookie header | 200 |
| GET | `/api/me` | Check auth status | Optional | - | `{"loggedIn":boolean}` | 200 |
| GET | `/api/generate-url` | Get signed webhook URL | Bearer or Cookie | Query: `?id=endpoint` | `{"url":"https://.../w/{id}/{token}"}` | 200, 400, 401, 500 |
| GET | `/api/stats` | Dashboard stats (full) | Bearer or Cookie | - | `{total_requests,avg_response_ms,oldest_hit_at,recent[],forward_rules[],aliases[],d1:{...},uptime_ms,version,started_at}` | 200, 401 |
| GET | `/api/hits` | Query stored webhook hits | Bearer or Cookie | Query: `?date=today\|YYYY-MM-DD&endpoint=name` | `{date,from,to,count,hits:[{id,endpoint,suffix,received_at,response_ms,body_length,body,forward_status,forward_ms,forward_error}]}` | 200, 401 |
| GET | `/api/forward-rules` | List all forwarding rules | Bearer or Cookie | - | `[{endpoint,forward_url,enabled,persist,created_at,updated_at}]` | 200, 401 |
| PUT | `/api/forward-rules/:endpoint` | Create/update rule | Bearer or Cookie | `{forward_url:string,enabled?:bool,persist?:bool}` | `{"ok":true,"endpoint":"..."}` | 200, 400, 401 |
| DELETE | `/api/forward-rules/:endpoint` | Delete forwarding rule | Bearer or Cookie | - | `{"ok":true}` | 200, 401 |
| GET | `/api/aliases` | List all aliases | Bearer or Cookie | - | `[{id,value,label,created_at}]` | 200, 401 |
| PUT | `/api/aliases` | Create/update alias | Bearer or Cookie | `{value:string,label:string}` | `{"ok":true,"value":"...","label":"..."}` | 200, 400, 401 |
| DELETE | `/api/aliases/:id` | Delete alias by ID | Bearer or Cookie | - | `{"ok":true}` | 200, 401 |
| GET | `/api/aliases/unknown` | Find unaliased IDs in recent hits | Bearer or Cookie | - | `[{id,type:("group"\|"user"\|"other"),count,last_seen,seen_in_groups:[]}]` | 200, 401 |
| POST | `/api/aliases/resolve` | Resolve LINE ID via LINE API | Bearer or Cookie | `{id:string,groupId?:string}` | `{"ok":true,"value":"...","label":"..."}` or `{"ok":false,"error":"..."}` | 200, 401, 404, 500 |
| POST | `/api/purge` | Delete hits older than 7 days | Bearer or Cookie | - | `{"deleted":N}` | 200, 401 |
| POST | `/mcp` | MCP JSON-RPC endpoint | Bearer or Cookie | JSON-RPC 2.0 request | JSON-RPC 2.0 response | 200, 204, 401 |
| GET | `/mcp` | MCP server info (JSON-RPC GET) | Bearer or Cookie | - | `{"jsonrpc":"2.0","result":{name,version,protocolVersion,capabilities}}` | 200, 401 |
| DELETE | `/mcp` | MCP DELETE (no-op) | Bearer or Cookie | - | empty response | 200, 401 |
| GET, * | `/*` | Serve React dashboard SPA | None | - | HTML/JS/CSS assets | 200, 404 → SPA |

---

## 2. WebSocket / SSE Endpoints

**None implemented.** Real-time updates via dashboard polling only (React on Vite).

---

## 3. MCP Tools (via `/mcp` POST endpoint)

### Tool: `webhook_stats`
- **Description:** Get dashboard overview — total requests, avg response time, recent hits, D1 usage
- **Input Schema:** `{}` (no parameters)
- **Output:** JSON object with fields:
  - `total_requests: number`
  - `avg_response_ms: number`
  - `oldest_hit_at: string | null`
  - `recent: WebhookHit[]` (up to 50)
  - `forward_rules: ForwardRule[]`
  - `aliases: Alias[]`
  - `d1: {db_size_bytes, writes_today, limit_storage_bytes: 5GB, limit_writes_day: 100k}`
  - `started_at: string` (ISO 8601)
  - `uptime_ms: number`
  - `version: string`

### Tool: `webhook_hits`
- **Description:** Query hits by date and/or endpoint (GMT+7 timezone)
- **Input Schema:**
  - `date: string?` — "today" or "YYYY-MM-DD" (default: "today")
  - `endpoint: string?` — Filter by endpoint name
  - `group: string?` — Filter by LINE groupId (exact match in body)
- **Output:** `{date, count, hits: WebhookHit[]}`
- **Limit:** 500 hits per query

### Tool: `list_forward_rules`
- **Description:** List all forwarding rules (endpoint → URL mappings)
- **Input Schema:** `{}` (no parameters)
- **Output:** `ForwardRule[]`

### Tool: `set_forward_rule`
- **Description:** Create or update forwarding rule
- **Input Schema:**
  - `endpoint: string` (required)
  - `forward_url: string` (required, must be valid URL)
  - `enabled: boolean?` (default: true)
  - `persist: boolean?` (default: true) — if false, don't save hits to DB
- **Output:** `{ok: true, endpoint: string}`
- **Errors:** Invalid URL → error response

### Tool: `delete_forward_rule`
- **Description:** Delete a forwarding rule
- **Input Schema:**
  - `endpoint: string` (required)
- **Output:** `{ok: true}`

### Tool: `list_aliases`
- **Description:** List value aliases with activity data; filter by type or find unaliased IDs
- **Input Schema:**
  - `type: "group" | "user" | "all"?` (default: "all")
  - `unaliased: boolean?` — if true, return only IDs in recent hits with NO alias
- **Output:** Array of aliases with enrichment:
  - `id: number`
  - `value: string`
  - `label: string`
  - `created_at: string`
  - `last_seen: string | null` (activity tracking)
  - `message_count: number` (from LINE hits)
  - `seen_in_groups: string[]`

### Tool: `set_alias`
- **Description:** Create or update alias label for a value
- **Input Schema:**
  - `value: string` (required)
  - `label: string` (required) — human-readable name
- **Output:** `{ok: true, value: string, label: string}`

### Tool: `delete_alias`
- **Description:** Delete alias by ID
- **Input Schema:**
  - `id: number` (required)
- **Output:** `{ok: true}`

### Tool: `purge_old_hits`
- **Description:** Delete webhook hits older than 7 days (free D1 storage)
- **Input Schema:** `{}` (no parameters)
- **Output:** `{deleted: number}` — count of deleted records

### Tool: `generate_webhook_url`
- **Description:** Generate signed webhook URL for an endpoint
- **Input Schema:**
  - `id: string` (required) — endpoint name
- **Output:** `{url: string}` — full signed URL like `https://xxx/w/{id}/{token}`

### Tool: `line_groups`
- **Description:** List active LINE groups for a date with message counts and member names
- **Input Schema:**
  - `date: string?` — "today" or "YYYY-MM-DD" (default: "today")
- **Output:** `{date, groups: [{groupId, groupName, aliased: bool, messages: number, activeUsers: [{name, aliased}], lastMessage: string}]}`
- **Limit:** 500 hits scanned per query

### Tool: `line_digest`
- **Description:** Parse LINE webhook hits into readable table (time, group, from, type, text); resolves IDs via aliases
- **Input Schema:**
  - `date: string?` — "today" or "YYYY-MM-DD" (default: "today")
  - `endpoint: string?` — LINE endpoint name (default: "line")
  - `group: string?` — Filter by group alias or groupId substring
- **Output:** `{date, endpoint, count, messages: [{time, group, from, type, text}]}`
- **Time Zone:** GMT+7 (Bangkok)

---

## 4. Authentication Model

### Bearer Token (API/MCP)
- **Header:** `Authorization: Bearer {API_TOKEN}`
- **Format:** `API_TOKEN = "user:pass"` (colon-separated)
- **Scope:** All `/api/*` routes, `/mcp` endpoint

### Cookie-based (Dashboard)
- **Name:** `api_token`
- **Value:** `user:pass`
- **Flags:** HttpOnly, SameSite=Strict, Secure
- **Max-Age:** 86400 seconds (1 day)
- **Set via:** `POST /auth/login` with form data

### Webhook URL Signing (No auth header needed)
- **Pattern:** `/w/{id}/{token}`
- **Token Type:** HMAC-SHA256 signature
- **Signature Base:** endpoint ID (`{id}`)
- **Secret:** `API_TOKEN` (the "user:pass" value)
- **Verification:** In worker, token is regenerated and compared for exact match
- **Senders:** Don't need to know the secret — URL is signed at generation time

---

## 5. Webhook Signing Format

### HMAC Algorithm & Headers

**Algorithm:** HMAC-SHA256  
**No custom headers added to incoming webhooks** — the signature is in the URL itself, not headers.

### Generation Process (inside Worker)

```typescript
// generateWebhookToken(id: string, secret: string): Promise<string>
1. Import CryptoKey from secret using SubtleCrypto
2. Sign the endpoint ID (the {id} part)
3. Encode as base64
4. Apply URL-safe encoding (replace + → -, / → _, trim =)
5. Result: token for /w/{id}/{token}
```

### Verification Process

```typescript
// verifyWebhookToken(id: string, token: string, secret: string): Promise<boolean>
1. Regenerate expected token using same algorithm
2. Compare with provided token
3. Return boolean (exact match required)
```

### Sending webhooks to `/w/:id/:token`

**No signature validation on POST body** — the URL token authenticates the webhook.

Example from LINE:
```
POST https://your-domain/w/line/{generated-token}
Content-Type: application/json

{"events": [...]}
```

LINE, GitHub, or any external service simply POSTs the raw webhook to the signed URL.

---

## 6. Outbound Destination Contract

### Forward Request Format

When a forwarding rule is enabled and active, the relay forwards:

```http
POST {forward_url}
Content-Type: {original or application/json}
User-Agent: webhook-relay/0.5.0
X-GitHub-Event: {header if present in original}
{other incoming headers preserved: content-type only}

{raw body from original webhook}
```

### Forwarding Response Capture

- **Status Code:** Captured in `forward_status` field
- **Latency:** Captured in `forward_ms` field (milliseconds)
- **Errors:** Captured in `forward_error` field (fetch error messages)
- **Timeout:** 10 seconds (AbortSignal.timeout(10_000))
- **Retries:** None — fire-and-forget (no retry logic)
- **Persistence:** Hit record includes forward attempt metadata even if forward fails

### Special Handling

**GitHub events:** If `X-GitHub-Event` header is present, it's forwarded to destination.

---

## 7. Error Response Shape

### Standard API Errors (HTTP)

```json
{
  "error": "Error message",
  "status": 400 | 401 | 404 | 500
}
```

### HTTP Status Codes Used

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 204 | No content (MCP DELETE) |
| 400 | Bad request (invalid params, missing fields, invalid URL) |
| 401 | Unauthorized (invalid token, cookie, or webhook signature) |
| 404 | Not found (LINE API resolution failed) |
| 500 | Server error (no API token configured, LINE API unavailable) |

### MCP JSON-RPC Errors

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32700 | -32600 | -32601 | ...,
    "message": "Parse error | Invalid Request | Method not found | ..."
  }
}
```

### Error Codes (JSON-RPC)

- `-32700` Parse error
- `-32601` Method not found
- Tool-specific errors returned in `isError: true` + content field

---

## 8. Rate Limits and Quotas

### D1 Database Limits (Cloudflare)

| Limit | Value | Notes |
|-------|-------|-------|
| Storage | 5 GB | `D1_LIMIT_STORAGE_BYTES = 5_000_000_000` |
| Writes per day | 100,000 | `D1_LIMIT_WRITES_DAY = 100_000` |
| Queries per request | Cloudflare Workers limits | Not explicit in code |

### Hit Retention

| Policy | Value | Notes |
|--------|-------|-------|
| Auto-purge age | 7 days | `purge_old_hits()` deletes hits older than 7 days |
| Body truncation | 4,096 bytes | Stored body limited to first 4KB (suffix routes) |

### MCP Query Limits

| Tool | Limit | Notes |
|------|-------|-------|
| `webhook_hits` | 500 | Max hits per query |
| `line_groups` | 500 | Max hits scanned for aggregation |
| `line_digest` | 500 | Max hits scanned for digest |
| `webhook_stats` | 50 | Recent hits in stats response |
| `list_aliases` | 2000 | Recent hits scanned (7-day window) |

### API Rate Limits

**None explicitly implemented** — rely on Cloudflare Workers CPU time & request limits (default: 50ms CPU, 600s request timeout).

---

## 9. Extension Points & Plugin Architecture

### Middleware Seams

**CORS:** Enabled on all routes via Hono middleware
```typescript
app.use("*", cors());
```

### Hook Points for Extension

#### 1. **Webhook Suffix Routes**
```
POST /w/:id/:token/:suffix
```
Allows arbitrary suffixes; parsed and stored with `suffix` field for custom handling.

#### 2. **GitHub Event Parser**
- Location: `src/github.ts`
- Function: `parseGitHubEvent(event: string, payload: any): string`
- Extensible via: Adding new `case` statements for event types
- Used in route: `POST /w/:id/:token/github`

#### 3. **LINE Auto-aliasing**
- Location: `src/auto-alias.ts`
- Function: `autoAlias(db, body, lineToken)`
- Called in `waitUntil()` after webhook receipt (non-blocking)
- Extensible via: Custom LINE API calls, identity resolution plugins

#### 4. **Forward Rules**
- Conditional execution: `if (rule?.enabled && rule.forward_url)`
- Extensible via: Adding transformation middleware before forward
- No middleware hooks present — direct POST forward only

#### 5. **Alias Resolution**
- Endpoint: `POST /api/aliases/resolve` — resolves LINE IDs via LINE API
- Can be extended to support other identity providers (Discord, Slack, etc.)

#### 6. **Custom Forwarding**
- Database schema includes `persist` flag (default: true)
- Set `persist: false` to skip DB recording (webhook-only mode)
- Extensible via: Adding `forward_middleware` before line 102 in worker.ts

### Plugin Integration Points

#### MCP Server
- Location: `src/mcp.ts` (stdio transport) + `src/mcp-handler.ts` (HTTP transport)
- 12 tools exported via MCP protocol
- Tools call REST API internally (via Bearer token)
- Can add new tools by:
  1. Adding tool to `TOOLS` array in `mcp-handler.ts`
  2. Implementing handler in `callTool()` switch statement
  3. Testing via Claude Code MCP integration

#### Custom Tool Example
```typescript
// In src/mcp-handler.ts TOOLS array:
{
  name: "my_custom_tool",
  description: "...",
  inputSchema: { type: "object", properties: {...} }
}

// In callTool() switch:
case "my_custom_tool": {
  // implementation
}
```

---

## 10. Database Schema

### Tables

#### `webhook_hits`
```typescript
id: integer (PK, auto-increment)
endpoint: text (not null) — webhook endpoint name
suffix: text — optional path suffix
received_at: text (not null) — ISO 8601 timestamp
response_ms: integer (not null) — processing time in ms
body_length: integer (not null) — byte count of raw body
body: text — raw webhook body (up to 4KB)
forward_status: integer — HTTP status from forward destination
forward_ms: integer — forward request latency in ms
forward_error: text — error message if forward failed
```

#### `forward_rules`
```typescript
endpoint: text (PK) — unique endpoint identifier
forward_url: text (not null) — destination URL
enabled: boolean (default: true) — forwarding active?
persist: boolean (default: true) — save hits to DB?
created_at: text (not null) — ISO 8601
updated_at: text (not null) — ISO 8601
```

#### `aliases`
```typescript
id: integer (PK, auto-increment)
value: text (not null, unique) — LINE ID or other identifier
label: text (not null) — human-readable name
created_at: text (not null) — ISO 8601
```

---

## 11. Configuration & Secrets

### Environment Variables

| Variable | Required | Default | Usage |
|----------|----------|---------|-------|
| `API_TOKEN` | Yes | — | Format: `user:pass`. Used for auth, webhook signing, MCP access |
| `LINE_CHANNEL_ACCESS_TOKEN` | No | — | LINE Messaging API token. Enables auto-alias & name resolution |
| `WEBHOOK_RELAY_URL` | No (MCP) | `http://localhost:5173` | Base URL for MCP client (stdio mode ignores) |

### Local Development

- `.dev.vars` file (not committed)
- Example: `.dev.vars.example` → copy and edit with credentials
- Default: `API_TOKEN=admin:changeme`

### Production

- `wrangler secret put API_TOKEN` — stored in Cloudflare Workers secrets
- `wrangler secret put LINE_CHANNEL_ACCESS_TOKEN` — optional

---

## 12. Transport Modes

### MCP Over Stdio (Local)
```bash
claude mcp add webhook-relay \
  -e API_TOKEN=user:pass \
  -e WEBHOOK_RELAY_URL=http://localhost:5173 \
  -- npx tsx src/mcp.ts
```
- No HTTP transport overhead
- Best for local development
- Node.js SDK required on client

### MCP Over HTTP (Remote)
```
POST https://your-worker.workers.dev/mcp
Authorization: Bearer user:pass
Content-Type: application/json

{"jsonrpc":"2.0","id":1,"method":"tools/list"}
```
- Works from any HTTP client (Claude Code, API, curl)
- No local installation needed
- JSON-RPC 2.0 protocol

---

## 13. Summary of Key Characteristics

| Aspect | Value |
|--------|-------|
| **Framework** | Hono (Router on Cloudflare Workers) |
| **Database** | D1 (SQLite) via Drizzle ORM |
| **Frontend** | React + Tailwind v4 (Vite) |
| **Auth** | Bearer token (user:pass format) + URL-signed webhooks |
| **Webhook Signing** | HMAC-SHA256 (Discord-style URL tokens) |
| **MCP Protocol** | JSON-RPC 2.0 (12 tools) |
| **Forwarding** | Fire-and-forget, no retries |
| **Storage** | 5GB D1 limit, 100k writes/day |
| **Retention** | 7-day auto-purge |
| **Concurrency** | Cloudflare Workers limits (non-blocking via waitUntil) |
| **CORS** | Enabled on all routes |
| **Version** | 0.5.0 |

---

## 14. Typical Integration Flow

### Scenario 1: Receive LINE Webhook

```
1. LINE service POSTs to https://your-domain/w/line/{token}
2. Worker verifies token (HMAC-SHA256)
3. Records webhook in DB (webhook_hits table)
4. If enabled, forwards to configured URL
5. Spawns autoAlias() task to resolve user/group names via LINE API (non-blocking)
6. Returns {"ok": true, ...} immediately
```

### Scenario 2: Query Webhooks via MCP

```
1. Claude Code calls webhook_hits tool with date="today"
2. MCP server makes REST API call: GET /api/hits?date=today
3. Worker checks Bearer token
4. Returns 500 hits (max) from today (GMT+7)
5. MCP formats result for display
```

### Scenario 3: Set Up Forwarding

```
1. User logs in to dashboard (POST /auth/login + cookie)
2. Navigates to "Forward Rules"
3. Clicks "Add Rule" → enters URL, toggles enabled
4. Frontend calls PUT /api/forward-rules/endpoint with {forward_url, enabled}
5. Worker inserts/upserts into forward_rules table
6. Future webhooks to /w/endpoint/{token} will POST to that URL
```

---

**End of API Surface Map**
