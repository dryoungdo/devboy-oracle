# webhook-relay-oss API Surface Map

**Date**: 2026-05-09  
**Source**: /home/drdo/Code/github.com/github.com/Soul-Brews-Studio/webhook-relay-oss  
**Archive**: git @ `Soul-Brews-Studio/webhook-relay-oss` (OSS, MIT)

---

## Overview

**webhook-relay** is a webhook receiver + forwarder built on Cloudflare Workers + D1 (SQLite). It provides:

1. **Signed webhook endpoints** — receive webhooks without authentication headers
2. **Dashboard** — React SPA for monitoring, configuration, alias management
3. **Forwarding rules** — route webhooks to external URLs
4. **LINE integration** — auto-resolve user/group names via LINE Messaging API
5. **GitHub integration** — parse and summarize GitHub events
6. **MCP server** — 12 tools for Claude Code integration (stdio or HTTP transport)

---

## HTTP API Surface (Hono Router)

**File**: `/src/worker.ts` (lines 1-443)  
**Framework**: Hono (framework: `hono`, `hono/cors`)  
**Env**: `D1Database`, `API_TOKEN?`, `LINE_CHANNEL_ACCESS_TOKEN?`

### Authentication Model

All authenticated endpoints check `API_TOKEN`:

- **Bearer token**: `Authorization: Bearer ${API_TOKEN}` header
- **Cookie fallback**: `api_token=${API_TOKEN}` (set by login endpoint)
- **Token format**: `user:pass` (e.g., `admin:changeme`)
- **Check function**: `checkAuth(request, env)` — line 53

Webhook endpoints (`/w/:id/:token*`) use **HMAC-SHA256 signed URLs** instead of bearer auth:

- **Token generation**: `generateWebhookToken(id, secret)` — line 24
- **Verification**: `verifyWebhookToken(id, token, secret)` — line 39
- **Signature scheme**: `token = HMAC-SHA256(id, API_TOKEN)` → base64 URL-safe

---

### Webhook Receive Endpoints

#### 1. Generic Webhook: `POST /w/:id/:token`

**File**: worker.ts, line 84  
**Auth**: HMAC-SHA256 signed URL (or no check if `API_TOKEN` not configured)  
**Body**: Raw (text or JSON), max 4096 bytes stored

**Request**:
```
POST /w/line/AbCdEfGh... HTTP/1.1
Content-Type: application/json

{ "events": [ ... ] }
```

**Response**: HTTP 200 JSON
```json
{
  "ok": true,
  "endpoint": "line",
  "received_at": "2026-05-09T12:34:56.789Z",
  "response_ms": 42
}
```

**Side effects**:
- Records hit to `webhookHits` table (unless rule has `persist: false`)
- If forward rule exists for endpoint with `enabled: true`, fires async forward
- If endpoint is `"line"` and `LINE_CHANNEL_ACCESS_TOKEN` configured, auto-aliases unknown user/group IDs (async)

**Fields stored** (via `recordHit()` — line 99):
- `endpoint`, `suffix`, `received_at`, `response_ms`, `body_length`, `body` (first 4096 chars)
- `forward_status`, `forward_ms`, `forward_error` (set if forwarded)

---

#### 2. GitHub Webhook: `POST /w/:id/:token/github`

**File**: worker.ts, line 114  
**Auth**: HMAC-SHA256 signed URL  
**Body**: GitHub webhook JSON (parsed + summarized)

**Request**:
```
POST /w/github/AbCdEfGh.../github HTTP/1.1
Content-Type: application/json
X-GitHub-Event: push

{ "ref": "refs/heads/main", "commits": [...], "pusher": {...} }
```

**Response**: HTTP 200 JSON
```json
{
  "ok": true,
  "endpoint": "github",
  "event": "push",
  "received_at": "2026-05-09T12:34:56.789Z",
  "response_ms": 42
}
```

**Side effects**:
- Parses GitHub event via `parseGitHubEvent(event, payload)` (line 126)
- Stores **parsed summary** as body (not raw JSON) — see GitHub integration section
- Records hit with `suffix: "/github"`
- Forwards original raw body (not parsed) if rule exists

**Events parsed** (file `github.ts`, line 4):
- `push` — commits, branch, author
- `pull_request` — PR number, title, action (opened/closed/synchronize)
- `issues` — issue number, title, action
- `issue_comment` — issue number, comment excerpt
- `star` — create/delete action
- `release` — tag, author, action
- `ping` — webhook config test
- `create` / `delete` — branch/tag creation
- `workflow_run` — CI result + conclusion
- **Default**: pretty-print truncated JSON

---

#### 3. Dynamic Suffix: `POST /w/:id/:token/:suffix`

**File**: worker.ts, line 148  
**Auth**: HMAC-SHA256 signed URL  
**Body**: Raw text/JSON

**Request**:
```
POST /w/custom-hook/AbCdEfGh.../webhook-v2 HTTP/1.1
Content-Type: application/json

{ "data": "..." }
```

**Response**: HTTP 200 JSON
```json
{
  "ok": true,
  "endpoint": "custom-hook",
  "suffix": "/webhook-v2",
  "received_at": "2026-05-09T12:34:56.789Z",
  "response_ms": 42
}
```

**Side effects**:
- Records hit with dynamic `suffix` (e.g., `/webhook-v2`)
- Allows routing multiple webhook variants to same endpoint with different suffix tracking

---

### Authentication Endpoints

#### 4. Check Auth Status: `GET /api/me`

**File**: worker.ts, line 68  
**Auth**: Optional (returns public info)  
**Response**: HTTP 200 JSON

```json
{
  "loggedIn": true | false
}
```

---

#### 5. Login (Set Cookie): `POST /auth/login`

**File**: worker.ts, line 174  
**Auth**: None  
**Body**: Form data

**Request**:
```
POST /auth/login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=admin&password=changeme
```

**Response**: HTTP 200 JSON + Set-Cookie header
```json
{
  "ok": true
}
```

**Headers**:
```
Set-Cookie: api_token=admin:changeme; Path=/; HttpOnly; SameSite=Strict; Secure; Max-Age=86400
```

---

#### 6. Logout (Clear Cookie): `GET /auth/logout`

**File**: worker.ts, line 194  
**Auth**: None  
**Response**: HTTP 200 JSON + Set-Cookie header

```json
{
  "ok": true
}
```

**Headers**:
```
Set-Cookie: api_token=; Path=/; HttpOnly; SameSite=Strict; Secure; Max-Age=0
```

---

### Webhook URL Generation

#### 7. Generate Signed URL: `GET /api/generate-url`

**File**: worker.ts, line 73  
**Auth**: Bearer or Cookie  
**Query params**: `id` (endpoint name)  
**Response**: HTTP 200 or 400/401/500 JSON

**Request**:
```
GET /api/generate-url?id=line HTTP/1.1
Authorization: Bearer admin:changeme
```

**Response** (HTTP 200):
```json
{
  "url": "https://example.workers.dev/w/line/AbCdEfGhIjKlMnOpQrStUvWx"
}
```

**Error cases**:
- 401: Not authenticated
- 400: Missing `id` query param
- 500: No `API_TOKEN` configured

---

### Forwarding Rules (CRUD)

#### 8. List Forward Rules: `GET /api/forward-rules`

**File**: worker.ts, line 212  
**Auth**: Required  
**Response**: HTTP 200 JSON array

```json
[
  {
    "endpoint": "line",
    "forward_url": "https://webhook.site/xxx",
    "enabled": true,
    "persist": true,
    "created_at": "2026-05-09T10:00:00.000Z",
    "updated_at": "2026-05-09T10:00:00.000Z"
  }
]
```

---

#### 9. Create/Update Forward Rule: `PUT /api/forward-rules/:endpoint`

**File**: worker.ts, line 219  
**Auth**: Required  
**Path param**: `endpoint` (string)  
**Body**: JSON

**Request**:
```
PUT /api/forward-rules/line HTTP/1.1
Authorization: Bearer admin:changeme
Content-Type: application/json

{
  "forward_url": "https://webhook.site/yyy",
  "enabled": true,
  "persist": true
}
```

**Response** (HTTP 200):
```json
{
  "ok": true,
  "endpoint": "line"
}
```

**Error cases**:
- 400: Missing `forward_url` or invalid URL
- 401: Not authenticated

**Side effects**:
- Inserts new rule or updates existing (upsert on `endpoint`)
- Sets `created_at` and `updated_at` timestamps
- Defaults: `enabled: true`, `persist: true`

---

#### 10. Delete Forward Rule: `DELETE /api/forward-rules/:endpoint`

**File**: worker.ts, line 247  
**Auth**: Required  
**Path param**: `endpoint` (string)  
**Response**: HTTP 200 JSON

```json
{
  "ok": true
}
```

---

### Aliases (CRUD)

Aliases map raw field values (LINE user/group IDs, customer codes, etc.) to human-readable labels.

#### 11. List Aliases: `GET /api/aliases`

**File**: worker.ts, line 255  
**Auth**: Required  
**Response**: HTTP 200 JSON array

```json
[
  {
    "id": 1,
    "value": "Uc1234567890abcdef1234567",
    "label": "Alice",
    "created_at": "2026-05-09T10:00:00.000Z"
  }
]
```

---

#### 12. Create/Update Alias: `PUT /api/aliases`

**File**: worker.ts, line 262  
**Auth**: Required  
**Body**: JSON

**Request**:
```
PUT /api/aliases HTTP/1.1
Authorization: Bearer admin:changeme
Content-Type: application/json

{
  "value": "Uc1234567890abcdef1234567",
  "label": "Alice"
}
```

**Response** (HTTP 200):
```json
{
  "ok": true,
  "value": "Uc1234567890abcdef1234567",
  "label": "Alice"
}
```

---

#### 13. Delete Alias: `DELETE /api/aliases/:id`

**File**: worker.ts, line 278  
**Auth**: Required  
**Path param**: `id` (numeric ID)  
**Response**: HTTP 200 JSON

```json
{
  "ok": true
}
```

---

#### 14. Find Unaliased LINE IDs: `GET /api/aliases/unknown`

**File**: worker.ts, line 286  
**Auth**: Required  
**Response**: HTTP 200 JSON array

Scans recent hits (last 7 days) for LINE webhook events and returns IDs without aliases.

```json
[
  {
    "id": "Uc9876543210fedcba9876543",
    "type": "user",
    "count": 12,
    "last_seen": "2026-05-09T12:30:00.000Z",
    "seen_in_groups": ["Team A"]
  }
]
```

**Side effects**:
- Scans last 2000 hits from `line` endpoint
- Extracts `source.groupId` and `source.userId` from LINE webhook events
- Groups by ID and tracks activity

---

#### 15. Resolve LINE ID via API: `POST /api/aliases/resolve`

**File**: worker.ts, line 333  
**Auth**: Required  
**Body**: JSON

Fetches display name from LINE Messaging API and creates/updates alias.

**Request**:
```
POST /api/aliases/resolve HTTP/1.1
Authorization: Bearer admin:changeme
Content-Type: application/json

{
  "id": "Uc1234567890abcdef1234567",
  "groupId": "Ca0000000000000000000000"
}
```

**Response** (HTTP 200):
```json
{
  "ok": true,
  "value": "Uc1234567890abcdef1234567",
  "label": "Alice"
}
```

**Error cases**:
- 500: No `LINE_CHANNEL_ACCESS_TOKEN` configured
- 404: Could not resolve name from LINE API
- 400: Missing `id`

**LINE API endpoints called**:
- Group summary: `GET /v2/bot/group/{id}/summary` (for `C`-prefix IDs)
- User profile: `GET /v2/bot/profile/{id}` (for `U`-prefix IDs without group)
- Group member profile: `GET /v2/bot/group/{groupId}/member/{id}` (for `U`-prefix with group)

---

### Hits Query API

#### 16. Query Webhook Hits: `GET /api/hits`

**File**: worker.ts, line 381  
**Auth**: Required  
**Query params**: `date`, `endpoint`  
**Response**: HTTP 200 JSON

**Request**:
```
GET /api/hits?date=2026-05-09&endpoint=line HTTP/1.1
Authorization: Bearer admin:changeme
```

**Response**:
```json
{
  "date": "2026-05-09",
  "from": "2026-05-09T00:00:00+07:00",
  "to": "2026-05-09T23:59:59.999+07:00",
  "count": 42,
  "hits": [
    {
      "id": 1,
      "endpoint": "line",
      "suffix": null,
      "received_at": "2026-05-09T12:34:56.789Z",
      "response_ms": 42,
      "body_length": 512,
      "body": "{ \"events\": [...] }",
      "forward_status": 200,
      "forward_ms": 123,
      "forward_error": null
    }
  ]
}
```

**Date handling**:
- Default: `"today"` (GMT+7 Thailand timezone offset)
- Format: `YYYY-MM-DD` or `"today"`
- Query window: 00:00:00 to 23:59:59 GMT+7
- Limits: max 500 hits returned

---

### Statistics API

#### 17. Dashboard Stats: `GET /api/stats`

**File**: worker.ts, line 417  
**Auth**: Required  
**Response**: HTTP 200 JSON

```json
{
  "total_requests": 1234,
  "avg_response_ms": 42,
  "oldest_hit_at": "2026-05-02T10:00:00.000Z",
  "recent": [ ... ],
  "forward_rules": [ ... ],
  "aliases": [ ... ],
  "d1": {
    "db_size_bytes": 2500000,
    "writes_today": 234,
    "limit_storage_bytes": 5000000000,
    "limit_writes_day": 100000
  },
  "started_at": "2026-05-07T08:00:00.000Z",
  "uptime_ms": 345600000,
  "version": "1.0.0",
  "deployedAt": "2026-05-07T08:00:00.000Z"
}
```

---

### Data Cleanup

#### 18. Purge Old Hits: `POST /api/purge`

**File**: worker.ts, line 205  
**Auth**: Required  
**Body**: None  
**Response**: HTTP 200 JSON

```json
{
  "deleted": 456
}
```

**Side effects**:
- Deletes all hits older than 7 days
- Frees D1 storage space

---

### MCP Server (JSON-RPC 2.0)

#### 19. MCP Endpoint: `POST /mcp`

**File**: worker.ts, line 430  
**Auth**: Bearer token required  
**Transport**: JSON-RPC 2.0 over HTTP

**Handler**: `/src/mcp-handler.ts` (lines 1-633)

The endpoint implements the Model Context Protocol v2025-03-26 with 12 tools for Claude Code integration.

**Request structure**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "webhook_stats",
    "arguments": {}
  }
}
```

**Response structure** (success):
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "..."
      }
    ]
  }
}
```

**Response structure** (error):
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32601,
    "message": "Method not found"
  }
}
```

**Standard RPC methods**:
- `GET /mcp` — Server info + capabilities
- `DELETE /mcp` — No-op (health check)
- `POST /mcp` with `method: "initialize"` — Initialize protocol
- `POST /mcp` with `method: "notifications/initialized"` — Client ready
- `POST /mcp` with `method: "ping"` — Ping
- `POST /mcp` with `method: "tools/list"` — List all 12 tools
- `POST /mcp` with `method: "tools/call"` — Call a tool by name with args

---

## MCP Tools (12 tools)

**File**: `/src/mcp-handler.ts`, lines 118-238 (definitions)  
**File**: `/src/mcp-handler.ts`, lines 242-553 (implementations)

All tools return JSON-RPC result: `{ content: [{ type: "text", text: "..." }], isError?: boolean }`

### 1. `webhook_stats`

**Description**: Get webhook relay dashboard stats: total requests, avg response time, recent hits, D1 usage

**Input**: (none)

**Output**: JSON with fields:
- `total_requests`: total hits ever
- `avg_response_ms`: mean response time
- `oldest_hit_at`: timestamp of earliest hit
- `recent`: array of recent 50 hits (with body)
- `forward_rules`: array of all rules
- `aliases`: array of all aliases
- `d1`: storage stats (size, writes today, limits)

**File reference**: Line 252-254

---

### 2. `webhook_hits`

**Description**: Query webhook hits by date and/or endpoint. Date is in GMT+7. Use group param to filter by LINE groupId.

**Input schema**:
```typescript
{
  date?: string;      // "today" or "YYYY-MM-DD" (default: today)
  endpoint?: string;  // Filter by endpoint name
  group?: string;     // Filter by LINE groupId (exact match in body)
}
```

**Output**: JSON with fields:
- `date`: the date queried
- `count`: number of hits returned
- `hits`: array of webhook hit records

**Side effect**: If `group` param provided, filters hits client-side by parsing each body's `events[0].source.groupId` (D1 doesn't support JSON queries)

**File reference**: Line 257-293

---

### 3. `list_forward_rules`

**Description**: List all forwarding rules (endpoint to URL mappings with enabled/persist flags)

**Input**: (none)

**Output**: Array of forward rules

**File reference**: Line 296-298

---

### 4. `set_forward_rule`

**Description**: Create or update a forwarding rule for an endpoint

**Input schema**:
```typescript
{
  endpoint: string;         // required
  forward_url: string;      // required, must be valid URL
  enabled?: boolean;        // default: true
  persist?: boolean;        // default: true
}
```

**Output**: `{ ok: true, endpoint: "..." }`

**Validation**: Validates `forward_url` is a valid URL before inserting

**File reference**: Line 301-324

---

### 5. `delete_forward_rule`

**Description**: Delete a forwarding rule for an endpoint

**Input schema**:
```typescript
{
  endpoint: string;  // required
}
```

**Output**: `{ ok: true }`

**File reference**: Line 327-329

---

### 6. `list_aliases`

**Description**: List all value aliases with activity data. Filter by type (group/user) or find unaliased IDs from recent webhook hits.

**Input schema**:
```typescript
{
  type?: "group" | "user" | "all";  // default: all
  unaliased?: boolean;              // if true, return only unaliased IDs
}
```

**Output**: 
- If `unaliased: true`: Array of unaliased IDs found in recent hits
- Otherwise: Array of aliases with enriched activity data (last_seen, message_count, seen_in_groups)

**Side effects**: Scans last 2000 hits from LINE endpoint (7 days) to build activity map

**File reference**: Line 332-410

---

### 7. `set_alias`

**Description**: Create or update an alias label for a webhook field value

**Input schema**:
```typescript
{
  value: string;   // raw value to alias (e.g. LINE user ID)
  label: string;   // human-readable label
}
```

**Output**: `{ ok: true, value: "...", label: "..." }`

**File reference**: Line 413-422

---

### 8. `delete_alias`

**Description**: Delete an alias by its ID

**Input schema**:
```typescript
{
  id: number;  // alias ID to delete
}
```

**Output**: `{ ok: true }`

**File reference**: Line 425-427

---

### 9. `purge_old_hits`

**Description**: Delete webhook hits older than 7 days to free D1 storage

**Input**: (none)

**Output**: `{ deleted: number }`

**File reference**: Line 430-432

---

### 10. `generate_webhook_url`

**Description**: Generate a signed webhook URL for an endpoint

**Input schema**:
```typescript
{
  id: string;  // endpoint ID to generate URL for
}
```

**Output**: `{ url: "https://example.workers.dev/w/{id}/{token}" }`

**Token generation**: Uses `generateToken(id)` callback from handler (HMAC-SHA256)

**File reference**: Line 435-438

---

### 11. `line_groups`

**Description**: List active LINE groups for a date with message counts and member names. Use this first to see which groups are active, then query line_digest per group for full detail.

**Input schema**:
```typescript
{
  date?: string;  // "today" or "YYYY-MM-DD" (default: today)
}
```

**Output**: JSON with fields:
- `date`: date queried
- `groups`: array of group summaries, each with:
  - `groupId`: raw group ID
  - `groupName`: alias label or ID suffix
  - `aliased`: boolean (whether this group has an alias)
  - `messages`: total messages in group for date
  - `activeUsers`: array of user summaries (name, aliased)
  - `lastMessage`: snippet of last text message sent (first 60 chars)

**File reference**: Line 441-503

---

### 12. `line_digest`

**Description**: Parse LINE webhook hits into a readable digest with full message text. Resolves IDs via aliases. Always filter by group for best results.

**Input schema**:
```typescript
{
  date?: string;          // "today" or "YYYY-MM-DD" (default: today)
  endpoint?: string;      // LINE endpoint name (default: "line")
  group?: string;         // Filter by group alias name or groupId (recommended)
}
```

**Output**: JSON with fields:
- `date`: date queried
- `endpoint`: endpoint name
- `count`: number of messages in digest
- `messages`: array of message rows, each with:
  - `time`: HH:MM in Bangkok time (GMT+7)
  - `group`: group alias or ID suffix
  - `from`: sender alias or ID suffix
  - `type`: message type (text, image, file, sticker, video, audio, location, etc.)
  - `text`: message content or formatted label

**Message type parsing** (file `mcp-handler.ts`, line 56-114):
- `text` → full text (max 80 chars in MCP version)
- `image` → `[IMAGE n/m]`
- `file` → `[FILE] filename (size KB)`
- `sticker` → `[STICKER keyword1, keyword2]`
- `video` → `[VIDEO]`
- `audio` → `[AUDIO]`
- `location` → `[LOCATION] title`

**File reference**: Line 506-547

---

## Drizzle Schema (Data API)

**File**: `/src/db/schema.ts` (lines 1-36)

### Table: `webhook_hits`

**Columns**:
- `id: integer` (PK, auto-increment)
- `endpoint: text` (NOT NULL) — endpoint name (e.g., "line", "github")
- `suffix: text` (nullable) — dynamic route suffix (e.g., "/webhook-v2")
- `received_at: text` (NOT NULL) — ISO 8601 timestamp
- `response_ms: integer` (NOT NULL) — handler duration
- `body_length: integer` (NOT NULL) — bytes received
- `body: text` (nullable) — first 4096 chars of payload
- `forward_status: integer` (nullable) — HTTP status from forward URL
- `forward_ms: integer` (nullable) — forward request duration
- `forward_error: text` (nullable) — error message if forward failed

**TypeScript types**:
- `WebhookHit = typeof webhookHits.$inferSelect` (read)
- `NewWebhookHit = typeof webhookHits.$inferInsert` (write)

---

### Table: `forward_rules`

**Columns**:
- `endpoint: text` (PK) — unique endpoint name
- `forward_url: text` (NOT NULL) — target URL for forwarding
- `enabled: integer[boolean]` (NOT NULL, default: true) — forwarding active?
- `persist: integer[boolean]` (NOT NULL, default: true) — save hits to DB?
- `created_at: text` (NOT NULL) — ISO 8601 timestamp
- `updated_at: text` (NOT NULL) — ISO 8601 timestamp

**TypeScript type**:
- `ForwardRule = typeof forwardRules.$inferSelect`

---

### Table: `aliases`

**Columns**:
- `id: integer` (PK, auto-increment)
- `value: text` (NOT NULL, UNIQUE) — raw ID value (LINE user/group ID, customer code, etc.)
- `label: text` (NOT NULL) — human-readable label
- `created_at: text` (NOT NULL) — ISO 8601 timestamp

**TypeScript type**:
- `Alias = typeof aliases.$inferSelect`

---

## GitHub Webhook Integration

**File**: `/src/github.ts` (lines 1-93)

Function `parseGitHubEvent(event: string, payload: any): string` transforms GitHub webhook payloads into human-readable summaries.

### Event types parsed:

| Event | Summary format |
|-------|---|
| `push` | `[repo] who pushed N commits to branch` + first 5 commit messages |
| `pull_request` | `[repo] who action PR #N: title` |
| `issues` | `[repo] who action issue #N: title` |
| `issue_comment` | `[repo] who commented on #N: excerpt (120 chars)` |
| `star` | `[repo] who starred/unstarred the repo` |
| `release` | `[repo] who action release tag` |
| `ping` | `Webhook configured for repo (events: [list])` |
| `create` | `[repo] who created branch/tag: ref` |
| `delete` | `[repo] who deleted branch/tag: ref` |
| `workflow_run` | `[repo] workflow action (conclusion)` |
| **default** | Pretty-printed JSON (truncated to 2048 chars) |

**File reference**: Line 4-92

---

## LINE Webhook Integration

### Auto-Alias Feature

**File**: `/src/auto-alias.ts` (lines 1-127)

When a webhook arrives on endpoint `"line"` and `LINE_CHANNEL_ACCESS_TOKEN` is configured:

1. Extracts all `groupId` and `userId` from webhook events
2. Checks which IDs don't already have aliases
3. Fetches display names from LINE Messaging API in parallel:
   - Groups: `GET /v2/bot/group/{id}/summary` → `groupName`
   - Users (no group): `GET /v2/bot/profile/{id}` → `displayName`
   - Users (in group): `GET /v2/bot/group/{groupId}/member/{id}` → `displayName`
4. Inserts new aliases or updates existing ones (upsert)

**Safety**: Runs in `c.executionCtx.waitUntil()` — non-blocking, errors caught silently

**Function**: `autoAlias(db, body, lineToken): Promise<void>` — line 86

**ID extraction** (line 23):
- `groupIds: Set<string>` — group IDs (C-prefix)
- `userIds: Map<string, string>` — user ID → group ID mapping

---

### Forwarding with Header Preservation

**File**: `/src/forward.ts` (lines 1-57)

Function `executeForward(db, hitId, forwardUrl, body, originalHeaders): Promise<void>`

**Request to forward URL**:
- Method: `POST`
- Headers:
  - `content-type`: from original request or `application/json`
  - `user-agent`: `webhook-relay/0.5.0`
  - `x-github-event`: forwarded if present in original
- Timeout: 10 seconds
- Body: raw (unchanged from received)

**Side effects**:
- Measures forward request duration
- Records `forward_status`, `forward_ms`, `forward_error` to hit
- Catches all errors (network, timeout, etc.)

**File reference**: Line 16-56

---

## Public TypeScript Types/Interfaces

**File**: `/src/db/schema.ts`

**Exported types** (used by consumers/MCP client):

```typescript
// Webhook hit record (read from DB)
type WebhookHit = {
  id: number;
  endpoint: string;
  suffix: string | null;
  received_at: string;
  response_ms: number;
  body_length: number;
  body: string | null;
  forward_status: number | null;
  forward_ms: number | null;
  forward_error: string | null;
};

// Webhook hit record (write to DB)
type NewWebhookHit = Omit<WebhookHit, 'id'>;

// Forwarding rule record
type ForwardRule = {
  endpoint: string;
  forward_url: string;
  enabled: boolean;
  persist: boolean;
  created_at: string;
  updated_at: string;
};

// Alias record
type Alias = {
  id: number;
  value: string;
  label: string;
  created_at: string;
};
```

---

## Extension Points (Pluggability)

### 1. New Webhook Parser

Add a new event type by extending `parseGitHubEvent()` or creating a new function like `parseSlackEvent()`.

**Pattern**:
- Create `/src/slack.ts` with `export function parseSlackEvent(payload: any): string`
- Import in `worker.ts`
- Add route: `app.post("/w/:id/:token/slack", ...)` → parse → store with suffix `/slack`

---

### 2. New Forwarder Integration

Extend the forward logic to support webhooks to different services (Slack, Telegram, Discord DMs).

**Pattern**:
- Create `/src/forwarders/slack.ts` with `export async function forwardToSlack(body, token): Promise<ForwardResult>`
- Call in `executeForward()` based on forward rule metadata
- Store integration-specific metadata in extended `forwardRules` table (requires schema change)

---

### 3. Custom Alias Resolution

Add resolvers for other services (Discord, Telegram, Matrix).

**Pattern**:
- Create `/src/resolvers/discord.ts` with `async function resolveDiscordUser(id, token): Promise<string | null>`
- Hook into auto-alias flow in `autoAlias()` based on endpoint
- Extend alias `label` to include service prefix (e.g., `"@alice"`, `"#general"`)

---

### 4. MCP Tool Plugins

Add new MCP tools by extending the `TOOLS` array and `callTool()` switch statement.

**Pattern**:
```typescript
// In mcp-handler.ts TOOLS array (line 118)
{
  name: "custom_tool",
  description: "Custom action",
  inputSchema: { type: "object", properties: { ... } },
}

// In callTool() (line 251)
case "custom_tool": {
  // implementation
  return { content: [{ type: "text", text: "..." }] };
}
```

---

### 5. Dashboard (React Frontend)

Located in `/frontend/src`. Uses Vite + React + Tailwind v4.

**Key components**:
- `Dashboard.tsx` — main view (hits table, stats grid)
- `GenerateUrl.tsx` — URL generation form
- `ForwardConfig.tsx` — forwarding rule editor
- `HitsTable.tsx` — paginated webhook history
- `WebhookFeed.tsx` — real-time feed (demo)
- `Aliases.tsx` — alias CRUD + auto-resolve LINE users

**API calls** made by dashboard:
- `GET /api/me` — auth check
- `GET /api/stats` — load stats
- `GET /api/hits?date=X&endpoint=Y` — load hits
- `GET /api/generate-url?id=X` — get signed URL
- `PUT /api/forward-rules/X` — save rule
- `DELETE /api/forward-rules/X` — delete rule
- `GET /api/aliases` — list aliases
- `PUT /api/aliases` — create/update alias
- `DELETE /api/aliases/X` — delete alias
- `GET /api/aliases/unknown` — find unaliased IDs
- `POST /api/aliases/resolve` — resolve + save alias
- `POST /api/purge` — cleanup old data
- `POST /auth/login` / `/auth/logout` — session

---

## Stats & Limits

**File**: `/src/stats.ts` (lines 1-68)

### D1 Storage Limits

```typescript
D1_LIMIT_STORAGE_BYTES = 5_000_000_000  // 5 GB
D1_LIMIT_WRITES_DAY = 100_000           // 100k writes/day
```

### Retention Policy

- Hits older than **7 days** are deleted via `purge_old_hits()`
- Manual purge available via `POST /api/purge`
- MCP tool `purge_old_hits` triggers cleanup

### Query Limits

- `/api/hits` → max 500 records per query
- `/api/aliases/unknown` → scans last 2000 recent hits
- `line_digest` → max 500 hits per query

---

## Environment Variables

| Variable | Required | Type | Usage |
|----------|----------|------|-------|
| `API_TOKEN` | Yes | `string` (format: `user:pass`) | Auth for REST API, dashboard login, webhook URL signing |
| `LINE_CHANNEL_ACCESS_TOKEN` | No | `string` | Bearer token for LINE Messaging API (auto-alias resolution) |
| `WEBHOOK_RELAY_URL` | No | `string` | MCP client config (e.g., `http://localhost:5173` or `https://worker.dev`) |
| `WEBHOOK_RELAY_TOKEN` | No | `string` | MCP client config (alternative to `API_TOKEN`) |

---

## Summary

**webhook-relay** presents 19 HTTP routes + 12 MCP tools covering:

1. **Webhook reception**: signed URLs + dynamic suffixes + format-specific parsers (GitHub, LINE)
2. **Forwarding**: rules-based routing with enable/disable + response tracking
3. **Storage**: D1 SQLite with 3-table schema (hits, rules, aliases)
4. **LINE integration**: auto-resolution of user/group names + message digest parsing
5. **Authentication**: bearer tokens + cookies + HMAC-SHA256 signed URLs
6. **MCP server**: Claude Code integration with 12 administrative tools
7. **Extension points**: custom parsers, forwarders, resolvers, and MCP tools

**Core use case**: Receive webhooks from LINE, GitHub, or any service → inspect in dashboard → auto-forward to external URL, with human-friendly alias resolution for LINE users/groups.

---

**Document version**: 1.0  
**Document date**: 2026-05-09  
**Source architecture**: Cloudflare Workers (Hono) + D1 (Drizzle ORM) + React frontend
