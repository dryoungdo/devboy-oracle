# webhook-relay-oss — Learning Index

## Source
- **Origin**: ./origin/ (symlink to ghq mirror, gitignored)
- **GitHub**: https://github.com/Soul-Brews-Studio/webhook-relay-oss

## What it is

Webhook receiver/forwarder on Cloudflare Workers. Stores incoming webhook hits in D1 SQLite, forwards them to configured endpoints, exposes a React dashboard for review, and ships an MCP server with 12 tools so Claude Code can query history. Auth is HMAC-SHA256 signed URLs (Discord-style `/w/{id}/{token}`) — no API keys to leak in headers, the proof is in the URL itself.

## Stack

- **Worker**: Hono (router) + Cloudflare Workers (runtime) + Drizzle ORM + D1 SQLite
- **Frontend**: React + Tailwind CSS v4 + Vite
- **MCP server**: JSON-RPC 2.0 over `POST /mcp`, 12 tools
- **Build**: Wrangler + Vite, `npm run dev` for local + Cloudflare Tunnel for external testing

## Explorations

### 2026-05-09 1355 (deep, 5 agents)

- [2026-05-09/1355_ARCHITECTURE.md](2026-05-09/1355_ARCHITECTURE.md) — Directory structure, entry points, core abstractions, data flow (4 paths), 24 routes, 12 MCP tools categorised, build pipeline, failure modes
- [2026-05-09/1355_CODE-SNIPPETS.md](2026-05-09/1355_CODE-SNIPPETS.md) — Hono entry + middleware, HMAC token gen/verify, Drizzle schema, forwarder, LINE triage (Thai+EN keywords), GitHub event parser, MCP JSON-RPC dispatcher, auto-alias via `waitUntil()`, React poll loop
- [2026-05-09/1355_QUICK-REFERENCE.md](2026-05-09/1355_QUICK-REFERENCE.md) — Install, env vars / D1 binding, hello-world from clone to first hit, common ops (add forward rule, alias, purge), MCP setup (stdio + remote HTTP), gotchas + footguns + security notes
- [2026-05-09/1355_TESTING.md](2026-05-09/1355_TESTING.md) — **Zero automated tests** (no vitest, no miniflare, no playwright, no test scripts in package.json). Manual testing only via wrangler dev + curl. ~15-20 hours estimated to add proper coverage. Cleanest pure functions to test first: `parseGitHubEvent()`, `generateWebhookToken()`, `getStats()`
- [2026-05-09/1355_API-SURFACE.md](2026-05-09/1355_API-SURFACE.md) — 19 HTTP routes (3 webhook receive variants, auth, URL gen, forward rules CRUD, aliases CRUD, hits query, stats/purge, MCP), 12 MCP tools with full request/response shapes, Drizzle schema (3 tables), extension points

**Key insights**:

1. **Signed URL auth pattern** — embeds HMAC-SHA256 token directly in path (`/w/{id}/{token}`). Works because external webhook providers can't be relied on to send custom headers; the URL itself is the credential. Trade-off: rotating the signing key invalidates every issued URL.
2. **`executionCtx.waitUntil()` everywhere for side-quests** — auto-alias LINE user/group resolution runs in background after the response is already sent. Pattern: respond fast, enrich async. Important for staying inside Workers' CPU budget.
3. **D1 client-side filtering** because D1 SQLite's JSON support is weak — the dashboard pulls a window then filters in TypeScript. Real constraint of the platform leaking through into the architecture.
4. **GMT+7 hardcoded** — Bangkok timezone bakes into stats date bucketing. Localized for the team building it; would need refactor for multi-region. Honest "ship it for us first" choice.
5. **Zero automated tests is the surprising finding** — for a project with HMAC crypto, MCP tool surface, and webhook timing semantics, lack of vitest/miniflare coverage is a real gap. Either intentional (manual testing via tunnel works for the team) or technical debt waiting to bite.
6. **MCP-as-API** — same backend exposes both HTTP endpoints and JSON-RPC tools to Claude. The 12 tools are essentially an LLM-readable mirror of the dashboard's REST surface. Pattern worth stealing for any service that wants AI-agent access.

— MLBOY 🔥⚗️ (the Crucible)
