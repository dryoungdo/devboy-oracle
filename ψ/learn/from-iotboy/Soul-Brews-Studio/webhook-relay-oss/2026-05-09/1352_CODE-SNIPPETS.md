# Webhook Relay OSS - Code Snippets
**Project:** Soul-Brews-Studio/webhook-relay-oss  
**Extracted:** 2026-05-09  
**Thoroughness:** Medium  

---

## 1. Main Hono Entrypoint & Route Registrations
**File:** `/src/worker.ts` (lines 64-111)

```typescript
const app = new Hono<HonoEnv>();
app.use("*", cors());

// Auth check — for React SPA to determine logged-in state
app.get("/api/me", (c) => {
  return c.json({ loggedIn: checkAuth(c.req.raw, c.env) });
});

// Raw webhook: POST /w/{id}/{token}
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

  const rule = await getForwardRule(c.env.DB, endpoint);
  const hitId = rule?.persist === false
    ? null
    : await recordHit(c.env.DB, { endpoint, received_at, response_ms, body_length: body.length, body: body.slice(0, 4096) });

  if (rule?.enabled && rule.forward_url) {
    c.executionCtx.waitUntil(executeForward(c.env.DB, hitId, rule.forward_url, body, c.req.raw.headers));
  }

  return c.json({ ok: true, endpoint, received_at, response_ms });
});
```

---

## 2. Inbound Webhook Handler (Receive & Store)
**File:** `/src/worker.ts` (lines 84-111)

The webhook POST handler receives raw HTTP webhooks, validates token via HMAC, records the hit to D1, and asynchronously forwards via `executeForward`.

Key pattern: Uses `c.executionCtx.waitUntil()` to fire async tasks without blocking the response.

---

## 3. Drizzle Schema Definition
**File:** `/src/db/schema.ts` (lines 1-35)

```typescript
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

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
});

export const forwardRules = sqliteTable('forward_rules', {
  endpoint:    text('endpoint').primaryKey(),
  forward_url: text('forward_url').notNull(),
  enabled:     integer('enabled', { mode: 'boolean' }).notNull().default(true),
  persist:     integer('persist', { mode: 'boolean' }).notNull().default(true),
  created_at:  text('created_at').notNull(),
  updated_at:  text('updated_at').notNull(),
});

export const aliases = sqliteTable('aliases', {
  id:         integer('id').primaryKey({ autoIncrement: true }),
  value:      text('value').notNull().unique(),
  label:      text('label').notNull(),
  created_at: text('created_at').notNull(),
});
```

Three tables: webhookHits (stores incoming payloads + forward status), forwardRules (endpoint→URL mappings), aliases (value→label for LINE IDs).

---

## 4. Queue Producer: Forward Rule Lookup
**File:** `/src/forward.ts` (lines 16-56)

```typescript
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

Pattern: Forwards to external URL via fetch with 10s timeout. Updates the webhook_hits record with forward_status, forward_ms, and error (if any). No Cloudflare Queues used; relying on `waitUntil()` for async fire-and-forget.

---

## 5. HMAC Signing & Token Verification (Auth Middleware)
**File:** `/src/worker.ts` (lines 23-42)

```typescript
// HMAC-based webhook token: token = HMAC-SHA256(id, API_TOKEN)
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

async function verifyWebhookToken(id: string, token: string, secret: string): Promise<boolean> {
  const expected = await generateWebhookToken(id, secret);
  return token === expected;
}
```

Clever pattern: Generates URL-safe Base64 HMAC-SHA256 tokens (using `-` and `_` instead of `+` and `/`). Every webhook endpoint gets a signed URL like `/w/{id}/{token}` verified client-side before storage.

---

## 6. MCP Server Tool Registrations
**File:** `/src/mcp.ts` (lines 170-186)

```typescript
const server = new McpServer({
  name: "webhook-relay",
  version: "1.0.0",
});

// ── Tools ──

server.tool(
  "webhook_stats",
  "Get webhook relay dashboard stats: total requests, avg response time, recent hits, D1 usage",
  {},
  async () => {
    const stats = await api("/api/stats") as StatsResponse;
    const slim = { ...stats, recent: stats.recent.map(stripBody) };
    return text(JSON.stringify(slim, null, 2));
  }
);
```

The MCP server wraps REST API endpoints. Tools include: `webhook_stats`, `webhook_hits`, `list_forward_rules`, `set_forward_rule`, `list_aliases`, `set_alias`, `purge_old_hits`, `generate_webhook_url`, `line_groups`, `line_digest`.

---

## 7. JSON-RPC MCP Handler (Error Handling Pattern)
**File:** `/src/mcp-handler.ts` (lines 567-632)

```typescript
export async function handleMcp(
  request: Request,
  db: D1Database,
  generateToken: (id: string) => Promise<string>,
): Promise<Response> {
  if (request.method === "GET") {
    return Response.json({
      jsonrpc: "2.0",
      result: {
        ...SERVER_INFO,
        protocolVersion: PROTOCOL_VERSION,
        capabilities: { tools: {} },
      },
    });
  }

  let body: any;
  try {
    body = await request.json();
  } catch {
    return jsonrpcError(null, -32700, "Parse error");
  }

  const { id, method, params } = body;

  switch (method) {
    case "tools/call": {
      const toolName = params?.name;
      const toolArgs = params?.arguments ?? {};
      const origin = new URL(request.url).origin;
      try {
        const result = await callTool(toolName, toolArgs, db, generateToken, origin);
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
}
```

Error handling idiom: All MCP errors wrapped in JSON-RPC response with `isError: true`. Try-catch at tool level returns error content without throwing.

---

## 8. Database Stats Query (Aggregation & Pagination)
**File:** `/src/stats.ts` (lines 22-67)

```typescript
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

Collates stats: count + avg response_ms, today's write count, DB size, recent 50 hits, oldest hit timestamp, all rules and aliases.

---

## 9. GitHub Event Parser (Clever Pattern)
**File:** `/src/github.ts` (lines 4-92)

```typescript
export function parseGitHubEvent(event: string, payload: any): string {
  const repo = payload.repository?.full_name ?? payload.organization?.login ?? "unknown";

  switch (event) {
    case "push": {
      const branch = (payload.ref ?? "").replace("refs/heads/", "");
      const commits = payload.commits ?? [];
      const who = payload.pusher?.name ?? "someone";
      const lines = [`[${repo}] ${who} pushed ${commits.length} commit(s) to ${branch}`];
      for (const c of commits.slice(0, 5)) {
        lines.push(`  - ${c.message?.split("\n")[0] ?? "(no message)"}`);
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
    // ... more cases (issues, issue_comment, star, release, etc.)
    
    default: {
      const json = JSON.stringify(payload, null, 2);
      const truncated = json.length > 2048 ? json.slice(0, 2048) + "\n... (truncated)" : json;
      return `[${event}] ${truncated}`;
    }
  }
}
```

Clever pattern: Converts GitHub webhook payloads into human-readable summaries. Handles 9+ event types (push, PR, issues, comments, stars, releases, workflow_run, create/delete branches). Fallback: truncated JSON pretty-print.

---

## 10. LINE Message Digest Parser (Real-Time Message Aggregation)
**File:** `/src/mcp-handler.ts` (lines 56-114)

```typescript
function parseLineDigest(
  hits: WebhookHit[],
  aliasMap: Map<string, string>,
): LineDigestRow[] {
  const rows: LineDigestRow[] = [];
  for (const hit of hits) {
    if (!hit.body) continue;
    let parsed: LineWebhookBody;
    try {
      parsed = JSON.parse(hit.body);
    } catch {
      continue;
    }
    const events = parsed.events ?? [];
    for (const ev of events) {
      const src = ev.source ?? {};
      const msg = ev.message ?? {};
      const groupId = src.groupId ?? src.roomId ?? "";
      const userId = src.userId ?? "";

      let text: string;
      if (msg.type === "text") {
        text = msg.text ?? "";
      } else if (msg.type === "file") {
        text = `[FILE] ${msg.fileName ?? "unknown"} (${formatSize(msg.fileSize)})`;
      } else if (msg.type === "image") {
        const setInfo = msg.imageSet ? ` ${msg.imageSet.index}/${msg.imageSet.total}` : "";
        text = `[IMAGE${setInfo}]`;
      } else if (msg.type === "sticker") {
        const kw = msg.keywords?.slice(0, 2).join(", ") ?? "";
        text = `[STICKER${kw ? `: ${kw}` : ""}]`;
      } else if (msg.type === "video") {
        text = `[VIDEO]`;
      } else if (msg.type === "audio") {
        text = `[AUDIO]`;
      } else if (msg.type === "location") {
        text = `[LOCATION] ${msg.title ?? ""}`;
      } else if (msg.type) {
        text = `[${msg.type}]`;
      } else {
        text = `[${ev.type ?? "unknown"}]`;
      }

      // Convert to Bangkok time (GMT+7)
      const utc = new Date(hit.received_at);
      const bkk = new Date(utc.getTime() + 7 * 60 * 60 * 1000);
      const timeStr = `${String(bkk.getUTCHours()).padStart(2, "0")}:${String(bkk.getUTCMinutes()).padStart(2, "0")}`;

      rows.push({
        time: timeStr,
        group: aliasMap.get(groupId) ?? (groupId.slice(-6) || "-"),
        from: aliasMap.get(userId) ?? (userId.slice(-6) || "-"),
        type: msg.type ?? ev.type ?? "?",
        text,
      });
    }
  }
  return rows;
}
```

Clever pattern: Parses LINE webhook hits into a table digest (time, group, from, type, text). Resolves IDs via aliasMap (user/group names). Handles 7+ message types (text, file, image, sticker, video, audio, location). Converts timestamps to GMT+7 (Bangkok time).

---

## 11. Upsert Pattern (onConflictDoUpdate)
**File:** `/src/worker.ts` (lines 219-245)

```typescript
app.put("/api/forward-rules/:endpoint", async (c) => {
  if (!checkAuth(c.req.raw, c.env)) return c.json({ error: "Unauthorized" }, 401);
  const body = await c.req.json() as { forward_url: string; enabled?: boolean; persist?: boolean };
  if (!body.forward_url) return c.json({ error: "Missing forward_url" }, 400);
  try { new URL(body.forward_url); } catch {
    return c.json({ error: "Invalid forward_url" }, 400);
  }
  const now = new Date().toISOString();
  const d = getDb(c.env.DB);
  await d.insert(forwardRules).values({
    endpoint: c.req.param("endpoint"),
    forward_url: body.forward_url,
    enabled: body.enabled ?? true,
    persist: body.persist ?? true,
    created_at: now,
    updated_at: now,
  }).onConflictDoUpdate({
    target: forwardRules.endpoint,
    set: {
      forward_url: body.forward_url,
      enabled: body.enabled ?? true,
      persist: body.persist ?? true,
      updated_at: now,
    },
  });
  return c.json({ ok: true, endpoint: c.req.param("endpoint") });
});
```

Drizzle upsert idiom: `insert().onConflictDoUpdate()` with primary key as conflict target. Updates only forward_url, enabled, persist, and updated_at on conflict (excludes created_at).

---

## 12. Retry/Timeout Handling (AbortSignal)
**File:** `/src/forward.ts` (lines 36-41)

```typescript
const res = await fetch(forwardUrl, {
  method: 'POST',
  headers,
  body,
  signal: AbortSignal.timeout(10_000),  // 10 second timeout
});
status = res.status;
```

Pattern: Enforces 10-second timeout on forward requests via `AbortSignal.timeout()`. Errors caught in outer try-catch, logged as status=0 with error message.

---

## Summary

**Webhook Relay OSS** is a Cloudflare Workers + D1 + Hono application that:
- Receives webhooks at signed URLs (`/w/{id}/{token}`)
- Records full payloads to D1 with response timing
- Forwards webhooks asynchronously to configured URLs
- Parses GitHub and LINE events into human-readable summaries
- Serves REST + MCP APIs for dashboard access
- Uses HMAC-SHA256 token signing for webhook URL generation
- Implements Drizzle ORM with upsert patterns for rule/alias management
- Supports LINE group/user aliasing and activity tracking (GMT+7)
