# Webhook Relay OSS — Code Snippets

> A Cloudflare Workers-based webhook relay with signing, forwarding, LINE integration, and 12-tool MCP interface. Real-time React dashboard + SQLite storage (D1). Pattern study for message routing + triage + alias resolution.

## Worker Entry Point & Hono Routing

**Context**: Main worker handler — Hono HTTP framework routes requests to webhook receiver, auth, CRUD endpoints, and MCP handler. All requests verified with HMAC-SHA256 signed token or Bearer auth.

```typescript
// src/worker.ts:27-46 — HMAC-based webhook token generation (Discord-style)
async function generateWebhookToken(id: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(id));
  return btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}
```
**Reference**: `/src/worker.ts:27-46`

**Context**: Signature verification for incoming webhook requests — compares computed token against provided value.

```typescript
// src/worker.ts:43-46 — Token verification
async function verifyWebhookToken(id: string, token: string, secret: string): Promise<boolean> {
  const expected = await generateWebhookToken(id, secret);
  return token === expected;
}
```
**Reference**: `/src/worker.ts:43-46`

**Context**: Hono app initialization with CORS middleware and auth check endpoints.

```typescript
// src/worker.ts:66-74 — Hono app setup & auth me endpoint
type HonoEnv = { Bindings: Env };
const app = new Hono<HonoEnv>();
app.use("*", cors());

// Auth check — for React SPA to determine logged-in state
app.get("/api/me", (c) => {
  return c.json({ loggedIn: checkAuth(c.req.raw, c.env) });
});
```
**Reference**: `/src/worker.ts:66-74`

---

## Webhook Receiver Path: POST /w/{id}/{token}

**Context**: Main webhook endpoint — receives raw body, records hit, optionally forwards to configured URL, and auto-aliases unknown LINE IDs.

```typescript
// src/worker.ts:87-138 — Raw webhook receiver with LINE triage & forwarding
app.post("/w/:id/:token", async (c) => {
  if (c.env.API_TOKEN) {
    const valid = await verifyWebhookToken(c.req.param("id"), c.req.param("token"), c.env.API_TOKEN);
    if (!valid) return c.json({ error: "Invalid webhook token" }, 401);
  }

  const start = performance.now();
  const body = await c.req.text();
  const received_at = new Date().toISOString();
  const response_ms = Math.round(performance.now() - start);
  const endpoint = c.req.param("id");

  // Verify LINE webhook signature when Channel Secret is configured
  const isLine = endpoint === "line";
  if (isLine && c.env.LINE_CHANNEL_SECRET) {
    const sig = c.req.header("x-line-signature");
    if (sig) {
      const valid = await verifyLineSignature(body, sig, c.env.LINE_CHANNEL_SECRET);
      if (!valid) return c.json({ error: "Invalid LINE signature" }, 401);
    }
  }

  // Triage LINE messages
  const triage = isLine ? triageWebhook(body) : null;

  const rule = await getForwardRule(c.env.DB, endpoint);
  const hitId = rule?.persist === false
    ? null
    : await recordHit(c.env.DB, {
        endpoint, received_at, response_ms,
        body_length: body.length, body: body.slice(0, 4096),
        triage_category: triage?.category ?? null,
        triage_reason: triage?.reason ?? null,
      });

  if (rule?.enabled && rule.forward_url) {
    // Apply triage filter: if set, only forward matching categories
    const shouldForward = !rule.triage_filter ||
      rule.triage_filter.split(",").includes(triage?.category ?? "routine");
    if (shouldForward) {
      c.executionCtx.waitUntil(executeForward(c.env.DB, hitId, rule.forward_url, body, c.req.raw.headers));
    }
  }

  // Auto-alias unknown LINE users/groups
  if (isLine && c.env.LINE_CHANNEL_ACCESS_TOKEN) {
    c.executionCtx.waitUntil(autoAlias(c.env.DB, body, c.env.LINE_CHANNEL_ACCESS_TOKEN));
  }

  return c.json({ ok: true, endpoint, received_at, response_ms, triage: triage?.category ?? null });
});
```
**Reference**: `/src/worker.ts:87-138`

---

## Storage Layer: Drizzle Schema & D1 SQLite

**Context**: Three core tables (webhook_hits, forward_rules, aliases) with TypeScript-inferred types for full type safety.

```typescript
// src/db/schema.ts:3-39 — Complete schema with triage metadata
export const webhookHits = sqliteTable('webhook_hits', {
  id:              integer('id').primaryKey({ autoIncrement: true }),
  endpoint:        text('endpoint').notNull(),
  suffix:          text('suffix'),
  received_at:     text('received_at').notNull(),
  response_ms:     integer('response_ms').notNull(),
  body_length:     integer('body_length').notNull(),
  body:            text('body'),
  forward_status:  integer('forward_status'),
  forward_ms:      integer('forward_ms'),
  forward_error:   text('forward_error'),
  triage_category: text('triage_category'),   // 'urgent' | 'routine' | 'spam'
  triage_reason:   text('triage_reason'),
});

export const forwardRules = sqliteTable('forward_rules', {
  endpoint:       text('endpoint').primaryKey(),
  forward_url:    text('forward_url').notNull(),
  enabled:        integer('enabled', { mode: 'boolean' }).notNull().default(true),
  persist:        integer('persist', { mode: 'boolean' }).notNull().default(true),
  triage_filter:  text('triage_filter'),  // NULL = forward all, or comma-separated: "urgent", "urgent,routine"
  created_at:     text('created_at').notNull(),
  updated_at:     text('updated_at').notNull(),
});

export const aliases = sqliteTable('aliases', {
  id:         integer('id').primaryKey({ autoIncrement: true }),
  value:      text('value').notNull().unique(),
  label:      text('label').notNull(),
  created_at: text('created_at').notNull(),
});
```
**Reference**: `/src/db/schema.ts:3-39`

**Context**: Drizzle ORM initialization — minimal wrapper for D1 with schema binding.

```typescript
// src/db/index.ts:1-6 — Drizzle factory for D1 binding
import { drizzle } from 'drizzle-orm/d1';
import * as schema from './schema';

export function getDb(d1: D1Database) {
  return drizzle(d1, { schema });
}
```
**Reference**: `/src/db/index.ts:1-6`

---

## Forwarding Logic: executeForward()

**Context**: Non-blocking webhook re-emission with configurable timeout, header passthrough, and error recording.

```typescript
// src/forward.ts:16-56 — Forward webhook to configured endpoint
export async function executeForward(
  db: D1Database,
  hitId: number | null,
  forwardUrl: string,
  body: string,
  originalHeaders: Headers,
): Promise<void> {
  const d = getDb(db);
  const start = performance.now();
  let status: number | null = null;
  let error: string | null = null;

  try {
    const headers: Record<string, string> = {
      'content-type': originalHeaders.get('content-type') || 'application/json',
      'user-agent': 'webhook-relay/0.5.0',
    };
    const ghEvent = originalHeaders.get('x-github-event');
    if (ghEvent) headers['x-github-event'] = ghEvent;

    const res = await fetch(forwardUrl, {
      method: 'POST',
      headers,
      body,
      signal: AbortSignal.timeout(10_000),
    });
    status = res.status;
  } catch (err: any) {
    status = 0;
    error = err?.message ?? 'Unknown fetch error';
  }

  const forward_ms = Math.round(performance.now() - start);

  if (hitId !== null) {
    await d
      .update(webhookHits)
      .set({ forward_status: status, forward_ms, forward_error: error })
      .where(eq(webhookHits.id, hitId));
  }
}
```
**Reference**: `/src/forward.ts:16-56`

---

## LINE Message Triage: AI-Free Rule-Based Classification

**Context**: Categorizes LINE messages into urgent/routine/spam using Thai + English keyword matching and pattern analysis. Runs inline in request handler (no external API).

```typescript
// src/triage.ts:89-160 — Core triage classifier
function classifyEvent(event: LineEventForTriage): TriageResult {
  // Non-message events (follow, unfollow, join, leave) → spam
  if (event.type !== "message") {
    return { category: "spam", reason: `non-message event: ${event.type}` };
  }

  const msg = event.message;
  if (!msg) return { category: "spam", reason: "empty message" };

  // Stickers → spam (unless they have urgent-sounding keywords, which is rare)
  if (msg.type === "sticker") {
    return { category: "spam", reason: "sticker" };
  }

  // Audio/video without context → routine (could be important, don't dismiss)
  if (msg.type === "audio" || msg.type === "video") {
    return { category: "routine", reason: `${msg.type} content` };
  }

  // Images → routine (could be receipts, patient photos, etc.)
  if (msg.type === "image") {
    return { category: "routine", reason: "image" };
  }

  // Text messages → keyword analysis
  if (msg.type === "text" && msg.text) {
    const text = msg.text;
    const lower = text.toLowerCase();

    // Check spam patterns first
    for (const pattern of SPAM_PATTERNS) {
      if (pattern.test(text.trim())) {
        return { category: "spam", reason: "low-signal pattern" };
      }
    }

    // Very short messages (1-2 chars) → spam
    if (text.trim().length <= 2) {
      return { category: "spam", reason: "very short message" };
    }

    // Check urgent keywords (Thai)
    for (const kw of URGENT_KEYWORDS_TH) {
      if (text.includes(kw)) {
        return { category: "urgent", reason: `keyword: ${kw}` };
      }
    }

    // Check urgent keywords (English)
    for (const kw of URGENT_KEYWORDS_EN) {
      if (lower.includes(kw)) {
        return { category: "urgent", reason: `keyword: ${kw}` };
      }
    }

    // Longer text messages → routine
    return { category: "routine", reason: "text message" };
  }

  // Unknown type → routine (don't dismiss unknowns)
  return { category: "routine", reason: `unknown type: ${msg.type}` };
}
```
**Reference**: `/src/triage.ts:89-160`

---

## GitHub Event Parser

**Context**: Converts GitHub webhook payloads into human-readable summaries for LINE/forward relay (no full event body shipped).

```typescript
// src/github.ts:4-92 — GitHub event parser with fallback truncation
export function parseGitHubEvent(event: string, payload: any): string {
  const repo = payload.repository?.full_name ?? payload.organization?.login ?? "unknown";

  switch (event) {
    case "push": {
      const branch = (payload.ref ?? "").replace("refs/heads/", "");
      const commits = payload.commits ?? [];
      const who = payload.pusher?.name ?? "someone";
      const lines = [`[${repo}] ${who} pushed ${commits.length} commit(s) to ${branch}`];
      for (const c of commits.slice(0, 5)) {
        lines.push(`  - ${c.message?.split("\n")[0] ?? "(no message)"`);
      }
      if (commits.length > 5) lines.push(`  ... and ${commits.length - 5} more`);
      return lines.join("\n");
    }

    case "pull_request": {
      const pr = payload.pull_request ?? {};
      const action = payload.action ?? "updated";
      const who = pr.user?.login ?? payload.sender?.login ?? "someone";
      return `[${repo}] ${who} ${action} PR #${pr.number}: ${pr.title}`;
    }

    case "issues": {
      const issue = payload.issue ?? {};
      const action = payload.action ?? "updated";
      const who = issue.user?.login ?? payload.sender?.login ?? "someone";
      return `[${repo}] ${who} ${action} issue #${issue.number}: ${issue.title}`;
    }

    default: {
      // Fallback: pretty-print truncated JSON
      const json = JSON.stringify(payload, null, 2);
      const truncated = json.length > 2048 ? json.slice(0, 2048) + "\n... (truncated)" : json;
      return `[${event}] ${truncated}`;
    }
  }
}
```
**Reference**: `/src/github.ts:4-92`

---

## MCP Server: 12-Tool JSON-RPC Interface

**Context**: Cloudflare Workers-native MCP implementation (no SDK) — stateless JSON-RPC 2.0 for tools/list and tools/call. Accessible via HTTP POST to /mcp endpoint.

```typescript
// src/mcp-handler.ts:13-264 — Tool definitions array (12 tools)
const TOOLS = [
  {
    name: "webhook_stats",
    description: "Get webhook relay dashboard stats: total requests, avg response time, recent hits, D1 usage",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "webhook_hits",
    description: "Query webhook hits by date and/or endpoint. Date is in GMT+7. Use group param to filter by LINE groupId.",
    inputSchema: {
      type: "object",
      properties: {
        date: { type: "string", description: 'Date filter: "today" or "YYYY-MM-DD" (default: today)' },
        endpoint: { type: "string", description: "Filter by endpoint name" },
        group: { type: "string", description: "Filter by LINE groupId (exact match in body)" },
      },
    },
  },
  {
    name: "webhook_stats",
    description: "Get webhook relay dashboard stats: total requests, avg response time, recent hits, D1 usage",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "line_groups",
    description: "List active LINE groups for a date with message counts and member names.",
    inputSchema: {
      type: "object",
      properties: {
        date: { type: "string", description: 'Date filter: "today" or "YYYY-MM-DD" (default: today)' },
      },
    },
  },
  {
    name: "line_digest",
    description: "Parse LINE webhook hits into a readable digest with full message text. Resolves IDs via aliases.",
    inputSchema: {
      type: "object",
      properties: {
        date: { type: "string", description: 'Date filter: "today" or "YYYY-MM-DD" (default: today)' },
        endpoint: { type: "string", description: "LINE endpoint name (default: line)" },
        group: { type: "string", description: "Filter by group alias name or groupId" },
      },
    },
  },
  {
    name: "line_triage",
    description: "Get LINE messages filtered by triage category (urgent/routine/spam). Use to build Captain's morning brief.",
    inputSchema: {
      type: "object",
      properties: {
        date: { type: "string", description: 'Date filter: "today" or "YYYY-MM-DD" (default: today)' },
        category: { type: "string", enum: ["urgent", "routine", "spam", "all"], description: 'Filter by category (default: "urgent")' },
        group: { type: "string", description: "Filter by group alias name or groupId" },
      },
    },
  },
  {
    name: "line_send",
    description: "Send a LINE message to a user or group via the chatboy oracle OA. Requires LINE_CHANNEL_ACCESS_TOKEN.",
    inputSchema: {
      type: "object",
      properties: {
        to: { type: "string", description: "LINE user ID (U...) or group ID (C...) to send to" },
        text: { type: "string", description: "Message text to send" },
      },
      required: ["to", "text"],
    },
  },
];
```
**Reference**: `/src/mcp-handler.ts:13-264`

**Context**: JSON-RPC request dispatcher — stateless handler for tools/list and tools/call methods.

```typescript
// src/mcp-handler.ts:754-800 — JSON-RPC request routing
  const { id, method, params } = body;

  switch (method) {
    case "initialize":
      return jsonrpc(id, {
        protocolVersion: PROTOCOL_VERSION,
        capabilities: { tools: {} },
        serverInfo: SERVER_INFO,
      });

    case "notifications/initialized":
      return new Response(null, { status: 204 });

    case "ping":
      return jsonrpc(id, {});

    case "tools/list":
      return jsonrpc(id, { tools: TOOLS });

    case "tools/call": {
      const toolName = params?.name;
      const toolArgs = params?.arguments ?? {};
      const origin = new URL(request.url).origin;
      try {
        const result = await callTool(toolName, toolArgs, db, generateToken, origin, lineAccessToken);
        return jsonrpc(id, result);
      } catch (err: any) {
        return jsonrpc(id, {
          content: [{ type: "text", text: `Error: ${err?.message ?? "Unknown"}` }],
          isError: true,
        });
      }
    }

    default:
      return jsonrpcError(id, -32601, `Method not found: ${method}`);
  }
```
**Reference**: `/src/mcp-handler.ts:754-800`

---

## LINE Signature Verification & API Helpers

**Context**: Manual HMAC-SHA256 signature verification (no SDK required) — matches LINE's webhook signing standard. Reply and push message helpers.

```typescript
// src/line.ts:12-31 — LINE webhook signature verification
export async function verifyLineSignature(
  body: string,
  signature: string,
  channelSecret: string,
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(channelSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(body),
  );
  const expected = btoa(String.fromCharCode(...new Uint8Array(sig)));
  return expected === signature;
}
```
**Reference**: `/src/line.ts:12-31`

**Context**: Push message to LINE user/group without replyToken (for async replies and outbound sends).

```typescript
// src/line.ts:60-77 — LINE push message (no replyToken required)
export async function linePush(
  to: string,
  messages: Array<{ type: string; text?: string; [key: string]: unknown }>,
  accessToken: string,
): Promise<{ ok: boolean; status: number; error?: string }> {
  const res = await fetch("https://api.line.me/v2/bot/message/push", {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ to, messages }),
  });

  if (res.ok) return { ok: true, status: res.status };
  const text = await res.text();
  return { ok: false, status: res.status, error: text };
}
```
**Reference**: `/src/line.ts:60-77`

---

## Auto-Alias: Async LINE ID Resolution

**Context**: Non-blocking background task (runs in waitUntil) — scans webhook body for unknown LINE groupIds/userIds, fetches names from LINE API, caches as aliases.

```typescript
// src/auto-alias.ts:86-127 — Auto-resolve and cache LINE IDs
export async function autoAlias(db: D1Database, body: string, lineToken: string): Promise<void> {
  const { groupIds, userIds } = extractIds(body);
  if (groupIds.size === 0 && userIds.size === 0) return;

  const d = getDb(db);

  // Load existing aliases to check which IDs are already known
  const existing = await d.select({ value: aliases.value }).from(aliases);
  const known = new Set(existing.map(a => a.value));

  const unknownGroups = [...groupIds].filter(id => !known.has(id));
  const unknownUsers = [...userIds.entries()].filter(([id]) => !known.has(id));

  if (unknownGroups.length === 0 && unknownUsers.length === 0) return;

  // Resolve in parallel (but limit concurrency to avoid rate limits)
  const results: { value: string; label: string }[] = [];

  await Promise.all([
    ...unknownGroups.map(async (gid) => {
      const name = await fetchGroupName(gid, lineToken);
      if (name) results.push({ value: gid, label: name });
    }),
    ...unknownUsers.map(async ([uid, gid]) => {
      const name = await fetchUserName(uid, gid, lineToken);
      if (name) results.push({ value: uid, label: name });
    }),
  ]);

  // Insert aliases
  for (const { value, label } of results) {
    await d.insert(aliases).values({
      value,
      label,
      created_at: new Date().toISOString(),
    }).onConflictDoUpdate({
      target: aliases.value,
      set: { label },
    });
  }
}
```
**Reference**: `/src/auto-alias.ts:86-127`

---

## React Dashboard: Real-Time Stats & Polling

**Context**: React SPA polls /api/stats every 5 seconds, displays live webhook count and recent hits with filterable alias resolution.

```typescript
// frontend/src/pages/Dashboard.tsx:69-86 — Poll loop with count tracking
  const poll = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/stats");
      if (res.status === 401) { onLogout(); return; }
      const data: StatsData = await res.json();
      setStats(data);

      if (data.total_requests > lastCount.current) {
        const n = data.total_requests - lastCount.current;
        document.title = `(${n} new) Status - Webhook Relay`;
        setTimeout(() => { document.title = "Status - Webhook Relay"; }, 3000);
      }
      lastCount.current = data.total_requests;
    } catch {}
    setLoading(false);
    setRemaining(POLL_INTERVAL);
  }, [onLogout]);
```
**Reference**: `/frontend/src/pages/Dashboard.tsx:69-86`

**Context**: Webhook feed component with multi-filter support (endpoint, event type, group ID) and memoized filtering logic.

```typescript
// frontend/src/components/WebhookFeed.tsx:83-89 — Memoized multi-filter with dependency tracking
  const filteredHits = useMemo(() => {
    let h = hits;
    if (endpoint) h = h.filter(hit => hit.endpoint === endpoint);
    if (eventType) h = h.filter(hit => hitMatchesEventType(hit, eventType));
    if (groupId) h = h.filter(hit => extractGroupId(hit) === groupId);
    return h;
  }, [hits, endpoint, eventType, groupId]);
```
**Reference**: `/frontend/src/components/WebhookFeed.tsx:83-89`

---

## Stats & Metrics: D1 Aggregation

**Context**: Collects dashboard stats — total requests, D1 storage usage, D1 daily write quota, recent/oldest hits.

```typescript
// src/stats.ts:22-67 — Comprehensive stats query
export async function getStats(db: D1Database) {
  const d = getDb(db);
  const todayISO = new Date(new Date().setUTCHours(0, 0, 0, 0)).toISOString();

  const [totals] = await d
    .select({ total_requests: count(), avg_response_ms: avg(webhookHits.response_ms) })
    .from(webhookHits);

  const [{ writes_today }] = await d
    .select({ writes_today: count() })
    .from(webhookHits)
    .where(gte(webhookHits.received_at, todayISO));

  const sizeResult = await d.run(sql`SELECT 1`);
  const db_size_bytes = sizeResult.meta.size_after ?? 0;

  const recent = await d
    .select()
    .from(webhookHits)
    .orderBy(desc(webhookHits.received_at))
    .limit(50);

  const oldest = await d
    .select({ received_at: webhookHits.received_at })
    .from(webhookHits)
    .orderBy(asc(webhookHits.received_at))
    .limit(1);

  const rules = await d.select().from(forwardRules);
  const allAliases = await d.select().from(aliases);

  return {
    total_requests: totals.total_requests ?? 0,
    avg_response_ms: Math.round(Number(totals.avg_response_ms ?? 0)),
    oldest_hit_at: oldest[0]?.received_at ?? null,
    recent,
    forward_rules: rules,
    aliases: allAliases,
    d1: {
      db_size_bytes,
      writes_today,
      limit_storage_bytes: D1_LIMIT_STORAGE_BYTES,
      limit_writes_day: D1_LIMIT_WRITES_DAY,
    },
  };
}
```
**Reference**: `/src/stats.ts:22-67`

---

## Artifact & Patterns

### Idioms & Notable Patterns

1. **Non-blocking background tasks**: Uses `c.executionCtx.waitUntil()` for auto-alias and forwarding — request returns immediately while work continues.

2. **Cookie + Bearer token auth**: Dual-mode auth for SPA (cookie) and API clients (Bearer).

3. **GMT+7 timestamp handling**: All date queries convert UTC to Bangkok time (GMT+7 offset = 7 * 60 * 60 * 1000 ms).

4. **Drizzle onConflictDoUpdate**: Idempotent upserts on both aliases and forward_rules via `.onConflictDoUpdate()`.

5. **D1 JSON limitations**: Client-side filtering for JSON fields (e.g., groupId search) since D1 SQLite lacks JSON functions.

6. **MCP streaming JSON-RPC**: No SDK needed — raw POST with `{"jsonrpc":"2.0","id":N,"method":"...","params":{...}}`.

### Error Handling

- Signature verification failures → 401 responses (both webhook token + LINE signature)
- Forward endpoint timeouts → AbortSignal.timeout(10_000) with try-catch recording to DB
- JSON parse errors → silent fallback (e.g., triageWebhook catches and returns "unparseable body")
- LINE API call failures in auto-alias → caught and ignored (non-blocking)

### TypeScript Inference

- `typeof webhookHits.$inferSelect` for read types
- `typeof webhookHits.$inferInsert` for write types
- Full type safety without manual interfaces (borrowed from Drizzle pattern)

---

## File Reference Guide

| Path | Purpose | LOC |
|------|---------|-----|
| `src/worker.ts` | Hono app, routes, auth, CRUD | 471 |
| `src/db/schema.ts` | Drizzle table definitions | 39 |
| `src/db/index.ts` | D1 factory wrapper | 6 |
| `src/forward.ts` | Webhook re-emitter with timeout | 56 |
| `src/triage.ts` | LINE message classifier (Thai/EN) | 191 |
| `src/github.ts` | GitHub event parser | 92 |
| `src/line.ts` | LINE API utilities (HMAC, push/reply) | 77 |
| `src/auto-alias.ts` | Async ID-to-name resolver | 127 |
| `src/mcp-handler.ts` | JSON-RPC 2.0 server (12 tools) | 800 |
| `src/stats.ts` | Dashboard metrics aggregator | 67 |
| `frontend/src/pages/Dashboard.tsx` | Main SPA + poll loop | 145 |
| `frontend/src/components/WebhookFeed.tsx` | Real-time feed + multi-filter | ~150 |

---

## Summary

**webhook-relay-oss** is a Cloudflare Workers-native webhook router with:
- HMAC-SHA256 signed URLs (Discord-style)
- LINE integration (signature verification, auto-aliasing, triage)
- GitHub event parsing
- Drizzle ORM + D1 SQLite (5GB storage, 100k writes/day quota)
- 12-tool MCP interface (JSON-RPC 2.0, no SDK needed)
- React SPA dashboard with real-time polling + filtering
- Non-blocking background tasks via `waitUntil()`

**Key takeaways for ML systems**: Message triage (Thai/EN keywords, type-based heuristics), ID aliasing (async caching), multi-format event parsing, and stats aggregation patterns are directly applicable to data preprocessing and feature engineering pipelines.

---

_Document created 2026-05-09 13:55 UTC by MLBOY. Studied codebase: github.com/dryoungdo/webhook-relay-oss._
