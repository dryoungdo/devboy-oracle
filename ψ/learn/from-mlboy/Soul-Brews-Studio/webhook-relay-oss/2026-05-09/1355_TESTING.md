# Testing Approach in webhook-relay-oss

**Status**: No automated tests present. Manual testing + type safety via TypeScript.

---

## Test Frameworks & Infrastructure

### Missing

- **No test runner** — vitest, jest, mocha, or playwright absent from `package.json`
- **No test files** — no `*.test.ts`, `*.spec.ts`, or `/test/`, `/tests/`, `/__tests__/` directories
- **No test scripts** — `package.json` has no `test`, `test:*`, or coverage commands
- **No test configuration** — no vitest.config.ts, jest.config.js, or similar
- **No CI/CD** — no `.github/workflows/` directory; no GitHub Actions or other pipeline

### What Exists

- **TypeScript strict mode** (`tsconfig.json`: `"strict": true`) — primary guard
- **Type checking script** — `npm run typecheck` (runs `tsc --noEmit`)
- **Development server** — `npm run dev` (local Vite + Wrangler with D1 SQLite)

---

## Code Structure & What's Tested

### Source Layout

```
src/
├── worker.ts           (main Hono app, 443 lines — webhook routing, auth, CRUD)
├── github.ts           (GitHub event parser, 93 lines — pure functions)
├── forward.ts          (webhook forwarding logic, 57 lines — HTTP egress, DB update)
├── stats.ts            (database queries, 68 lines — aggregations, purge)
├── auto-alias.ts       (LINE auto-aliasing, impl not shown)
├── mcp-handler.ts      (MCP JSON-RPC adapter, impl not shown)
├── mcp.ts              (MCP stdio server, impl not shown)
└── db/
    ├── schema.ts       (Drizzle ORM schema, 36 lines — 3 tables)
    └── index.ts        (DB helper, wrapper for D1)

frontend/src/
├── components/         (7 React components — no tests, no testing-library)
└── pages/              (5 page components)
```

---

## Testing Approach Constraints

### D1 SQLite (No Mock)

- **Local dev**: `npm run dev` applies migrations to **local D1 database** (Wrangler handles it)
- **Migration files**: `drizzle/000X_*.sql` — auto-created by Drizzle Kit
- **No in-memory SQLite** or mocking layer
- **Manual schema verification**: Developers inspect with `npm run db:studio` (Drizzle Studio GUI)
- **No test isolation**: Real table writes during development; manual purging needed

### Workers Runtime (No Miniflare)

- **Deployed runtime**: Cloudflare Workers (proprietary V8 isolate)
- **Local dev**: Wrangler (`wrangler dev`) simulates env + D1
- **No miniflare or custom test harness** — dev server is the only runtime simulator
- **No unit test of Worker context**: No tests for `ExecutionContext`, `waitUntil()`, async execution
- **Manual integration testing**: Tunnel webhooks to localhost via Cloudflare Tunnel

### React Components (No Testing Library)

- **No vitest DOM environment** or testing-library/react
- **No component tests** — components are purely presentational (fetch data via API, render)
- **Manual E2E only**: Developers start `npm run dev` and click the dashboard
- **No visual regression tests** or Playwright

---

## Webhook Signature Validation — Tested Only Manually

### Implementation

```typescript
// src/worker.ts, lines 24–42
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

### Tested Paths

1. **Valid token**: `/w/{id}/{token}` → calls `verifyWebhookToken()` → line 86–87 (worker.ts)
2. **Invalid token**: Returns 401 Unauthorized (no test assertion, human-verified)
3. **No API_TOKEN configured**: Skips verification (line 85–87, treated as open relay)

### Gaps

- ❌ No test for base64url padding removal (`replace(/=+$/, "")`)
- ❌ No test for URL-safe characters (`-`, `_` vs `+`, `/`)
- ❌ No edge case: empty `id` or `secret`
- ❌ No concurrent signing/verification race test
- ❌ **Manual verification only**: curl webhook to tunnel, watch logs

---

## Forwarding Logic — No Automated Tests

### Implementation (src/forward.ts, 56 lines)

```typescript
export async function executeForward(
  db: D1Database,
  hitId: number | null,
  forwardUrl: string,
  body: string,
  originalHeaders: Headers,
): Promise<void> {
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

### Tested Paths (Manual Only)

1. **Success (2xx)**: Webhook forwarded, DB updated with `forward_status`
2. **Error (5xx)**: Caught, `error` string logged to DB
3. **Timeout**: `AbortSignal.timeout(10_000)` kills fetch after 10s
4. **No hitId**: Forward attempt but DB row skipped (lines 50–55)

### Gaps

- ❌ No mock fetch server (would need miniflare + HTTP stub)
- ❌ No test for header passthrough (content-type, x-github-event)
- ❌ No test for timeout boundary (9.999s vs 10.001s)
- ❌ No test for malformed URLs (invalid schema, DNS failure)
- ❌ No test for DB write failures during forward (hitId = null branch)
- ❌ Performance measurement logic untested (timing precision, rounding)

---

## GitHub Event Parser — No Automated Tests

### Implementation (src/github.ts, 93 lines)

Pure functions mapping GitHub event types (push, pull_request, issues, etc.) to human-readable summaries.

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
        lines.push(`  - ${c.message?.split("\n")[0] ?? "(no message)"`);
      }
      if (commits.length > 5) lines.push(`  ... and ${commits.length - 5} more`);
      return lines.join("\n");
    }
    // 7 more cases: pull_request, issues, issue_comment, star, release, ping, create, delete, workflow_run, + default
    ...
  }
}
```

### Tested Paths (Manual + Type Safety)

- ✅ **Type-checked parameters** (TypeScript)
- ✅ **All case branches present** (fallback default case catches unknown events)
- ✅ **Safe chaining** (`payload.ref ?? ""`, defensive defaults)
- ❌ **No snapshot tests** of actual GitHub payloads
- ❌ **No corpus of real payloads** (GitHub docs only)
- ❌ **No malformed JSON test** (try/catch in worker.ts line 125–129, not in parser itself)

### Manual Testing

```bash
# curl command to test /github endpoint
curl -X POST http://localhost:5173/w/github/TOKEN \
  -H "X-GitHub-Event: push" \
  -H "Content-Type: application/json" \
  -d '{"repository":{"full_name":"owner/repo"},"ref":"refs/heads/main","commits":[{"message":"Fix bug"}],"pusher":{"name":"alice"}}'
```

---

## React Component Tests

### Status: None (no testing-library, no vitest dom)

**Components** (frontend/src/components/):
- ForwardConfig.tsx — form to create/edit forwarding rules
- GenerateUrl.tsx — button to generate signed webhook URL
- HitsTable.tsx — table of recent webhook payloads
- PollBadge.tsx — status indicator (polling active)
- StatsGrid.tsx — card grid with metrics (requests, DB size)
- WebhookFeed.tsx — real-time feed of hits
- Nav.tsx — navigation header

**Pages** (frontend/src/pages/):
- Dashboard.tsx — main view (hits, stats, forward rules)
- Aliases.tsx — manage LINE ID aliases
- Today.tsx — daily hits view
- About.tsx — info page
- Landing.tsx — unauthenticated home

### Testing Approach

- **No unit tests** — no testing-library/react, no vitest dom environment
- **No component isolation** — components render only in full app context
- **Manual E2E only**:
  ```bash
  npm run dev
  # Open http://localhost:5173 → click, inspect dashboard
  ```
- **No visual regression** — no Playwright or Percy
- **No accessibility audit** — no axe or jest-axe
- **No form validation tests** — input constraints enforced in React state only

### Example: GenerateUrl Component (Manual Test)

```typescript
// frontend/src/components/GenerateUrl.tsx
export default function GenerateUrl() {
  const [id, setId] = useState("");
  const [loading, setLoading] = useState(false);
  const [url, setUrl] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const handleGenerate = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/generate-url?id=${encodeURIComponent(id)}`);
      if (res.ok) {
        const data = await res.json();
        setUrl(data.url);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <input value={id} onChange={(e) => setId(e.target.value)} />
      <button onClick={handleGenerate} disabled={loading}>{loading ? "..." : "Generate"}</button>
      {url && <textarea value={url} readOnly />}
      <button onClick={() => { navigator.clipboard.writeText(url); setCopied(true); }}>Copy</button>
    </div>
  );
}
```

**Manual test steps**:
1. Start dev server
2. Type endpoint name (e.g. "line")
3. Click "Generate" button
4. Verify URL appears in textarea
5. Click "Copy" button
6. Paste in another app to verify content

**No automated assertion**.

---

## Coverage Approach

### Measured?

- ❌ **No coverage tool** — no nyc, c8, or vitest --coverage
- ❌ **No threshold** — no coverage gates in CI
- ❌ **No reports** — no coverage badge or artifact

### Estimated Coverage (by inspection)

| Module | Lines | Likely Covered | Status |
|--------|-------|---|--------|
| `worker.ts` | 443 | ~40% | Happy-path routing; auth skipped if no API_TOKEN; error branches untested |
| `github.ts` | 93 | ~20% | Only 1–2 cases tested (push, PR) if at all; fallback case never verified |
| `forward.ts` | 57 | ~30% | Success path only; error handling untested; timeout untested |
| `stats.ts` | 68 | ~50% | Queries assumed working (manual db:studio); no edge case (empty DB, old data) |
| `auto-alias.ts` | ? | <10% | Not audited; LINE API integration likely untested |
| `mcp-handler.ts` | ? | <10% | JSON-RPC adapter untested |
| `frontend/` | ~800 | <5% | React components never unit-tested; manual E2E only |

**Real coverage likely: 15–25%**

---

## Notable Test Utilities & Helpers

### None

The repo has no test infrastructure, so there are no:
- ❌ Test fixtures (mock webhooks, sample payloads)
- ❌ Builders (webhook event factories)
- ❌ Mocks (fetch, crypto, DB)
- ❌ Test helpers (auth context, token generators)

### Workaround Patterns Used

1. **Type safety as guardrail** — TypeScript strict mode catches null/undefined before runtime
2. **Defensive defaults** — `?? "fallback"` in JSON parsing
3. **Manual inspection** — Drizzle Studio for DB state
4. **Local dev as simulator** — Wrangler dev server + tunnel for integration testing

---

## Testing Gaps (Honest Assessment)

### Critical Gaps

1. **No auth tests** — `checkAuth()` function (3 branches: Bearer, cookie, none) untested
   - What if `API_TOKEN` is empty string? Whitespace? Special characters?
   - What if cookie is malformed? `api_token=; Path=/` edge case?

2. **No webhook ingress validation** — line 84–111 (POST /w/:id/:token)
   - What if body is > 4096 bytes? (Truncated, not tested)
   - What if JSON is invalid? (Caught at line 301, not tested)
   - What if endpoint is special char? (No validation)

3. **No D1 integration** — no test of actual DDL/DML
   - Migrations assumed to work (no test harness)
   - Drizzle schema → D1 mapping untested
   - Unique constraint on `aliases.value` — never violated in test

4. **No HTTP error handling** — forward.ts catch block (line 43–46)
   - Network timeout: untested
   - DNS failure: untested
   - CORS error: untested
   - Invalid URL: untested

5. **No GitHub payload corpus** — parser lacks real-world samples
   - Nested objects assumed present (defensive chaining works, but never proven)
   - String truncation (line 38, 2048 chars) never validated

### Medium Gaps

6. **No cookie parsing edge cases** — `getCookie()` (line 44–51)
   - Multiple cookies: assumed splitting works
   - Semicolon in value: unquoted, no escaping

7. **No timezone handling tests** — GMT+7 offset (line 386–400)
   - DST transitions: untested
   - Browser vs server timezone misalignment: not addressed

8. **No MCP tests** — mcp-handler.ts untested
   - 12 tools (generate_webhook_url, webhook_hits, etc.) assumed working
   - No JSON-RPC error cases tested

9. **No React form validation** — alias creation allows empty strings?
   - frontend/src/components/ForwardConfig.tsx line checks `!body.forward_url` but client-side validation missing
   - No XSS prevention in alias labels

### Minor Gaps

10. **No performance tests** — response_ms logging assumes accuracy
11. **No concurrent request handling** — D1 write limits untested
12. **No secret rotation** — API_TOKEN change breaks all in-flight requests
13. **No audit logging** — who changed a forwarding rule? Not tracked.

---

## Cleanest Code (Well-Structured, Testable If Needed)

### 1. GitHub Event Parser (github.ts)

**Why it's clean**:
- Pure function (no side effects)
- Exhaustive switch with default fallback
- Defensive chaining (`??`)
- Easy to snapshot-test

```typescript
export function parseGitHubEvent(event: string, payload: any): string {
  const repo = payload.repository?.full_name ?? payload.organization?.login ?? "unknown";
  switch (event) {
    case "push": { /* ... */ }
    case "pull_request": { /* ... */ }
    // ... etc
    default: { /* safe fallback */ }
  }
}
```

**To test**: Create test fixtures from GitHub webhook docs, run parser, assert output format.

### 2. Token Generation (worker.ts, lines 24–42)

**Why it's clean**:
- Deterministic (same inputs → same output)
- Uses standard crypto API
- URL-safe encoding applied consistently

```typescript
async function generateWebhookToken(id: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(/* ... */);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(id));
  return btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}
```

**To test**: 
```typescript
const token1 = await generateWebhookToken("line", "secret123");
const token2 = await generateWebhookToken("line", "secret123");
expect(token1).toBe(token2); // deterministic
expect(token1).toMatch(/^[A-Za-z0-9\-_]+$/); // URL-safe
```

### 3. Stats Aggregation (stats.ts, lines 22–67)

**Why it's clean**:
- Clear data flow (query → aggregate → return)
- Uses Drizzle ORM (type-safe)
- Defensive: handles null results

```typescript
export async function getStats(db: D1Database) {
  const d = getDb(db);
  const todayISO = new Date(new Date().setUTCHours(0, 0, 0, 0)).toISOString();

  const [totals] = await d
    .select({ total_requests: count(), avg_response_ms: avg(webhookHits.response_ms) })
    .from(webhookHits);

  // ... multiple queries, all typed
  return { total_requests: totals.total_requests ?? 0, /* ... */ };
}
```

**To test**: 
```typescript
// Insert test data
await recordHit(db, { endpoint: "test", /* ... */ });
const stats = await getStats(db);
expect(stats.total_requests).toBe(1);
expect(stats.recent.length).toBeLessThanOrEqual(50);
```

---

## Summary: What Would Need to Happen to Add Tests

### Phase 1: Setup (1–2 hours)

- Add vitest + @cloudflare/vitest-environment-miniflare to package.json
- Create vitest.config.ts with local D1 bindings
- Add test script to package.json (`"test": "vitest"`)
- Set up GitHub Actions workflow for CI (`.github/workflows/test.yml`)

### Phase 2: Core Tests (4–6 hours)

- **Webhook signature**: 10 tests for generateWebhookToken + verifyWebhookToken
- **GitHub parser**: 12 tests (one per event type + fallback + malformed)
- **Forward logic**: 8 tests (success, timeout, error, header passthrough, no DB update)
- **Auth check**: 6 tests (Bearer, cookie, none, empty token, malformed)
- **Stats queries**: 5 tests (total_requests, today filter, empty DB, old data purge)

### Phase 3: Integration & E2E (6–10 hours)

- **Worker routes**: POST /w/:id/:token with various payloads
- **Database migrations**: Verify Drizzle → D1 schema matches
- **React components**: Add testing-library + 20 component tests
- **MCP tools**: Mock fetch to test 12 tools

### Phase 4: CI/CD & Coverage (2–3 hours)

- Add coverage badge (c8)
- Set threshold (e.g., 70% for critical paths)
- Add pre-commit hook (`husky` + `lint-staged`)
- Add Playwright E2E against deployed staging

**Total: ~15–20 hours of engineering work**

---

## Conclusion

**webhook-relay-oss has zero automated tests.** It relies on:

1. **TypeScript strict mode** for type safety
2. **Manual integration testing** via `npm run dev` + tunnel
3. **Code inspection** (no formal review process)
4. **Cloudflare's Workers runtime** (assumed reliable)

This is typical for small open-source projects and internal tools. The code is **reasonably defensive** (null coalescing, try/catch blocks) but **untested at boundaries** (crypto, HTTP, DB, auth).

**Risk**: Database corruption, webhook loss, or auth bypass would be caught only in production.

**Recommendation for Captain**: If webhook-relay becomes mission-critical (handles sensitive LINE/GitHub webhooks in prod), prioritize:
- Token generation/verification tests (security)
- Forward egress tests (data loss scenarios)
- Auth tests (access control)
- Database schema migration tests

For now, Type checking + manual testing + good error logging are sufficient.
