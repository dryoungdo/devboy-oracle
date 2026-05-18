# webhook-relay-oss Learning Archive (2026-05-09)

Complete API surface and architectural documentation for [Soul-Brews-Studio/webhook-relay-oss](https://github.com/Soul-Brews-Studio/webhook-relay-oss).

**Project**: Webhook receiver + forwarder with dashboard, built on Cloudflare Workers + D1 (SQLite)  
**Stack**: Hono, Drizzle ORM, React, TypeScript  
**Archive date**: 2026-05-09  
**Commit**: Latest from main branch

## Documents

| Document | Size | Purpose |
|----------|------|---------|
| **1355_API-SURFACE.md** | 28.4K | Complete HTTP routes, MCP tools, schemas, authentication, extension points |
| 1355_ARCHITECTURE.md | 22.7K | System design, data flow, D1 schema deep-dive |
| 1355_CODE-SNIPPETS.md | 25.3K | Reference implementations and code patterns |
| 1355_QUICK-REFERENCE.md | 14.4K | Cheat sheet for all endpoints and MCP tools |
| 1355_TESTING.md | 18.6K | Test scenarios, development setup, curl examples |

## Quick Links (from 1355_API-SURFACE.md)

### HTTP Routes (19 total)
- **Webhooks**: `POST /w/:id/:token`, `/w/:id/:token/github`, `/w/:id/:token/:suffix`
- **Authentication**: `GET /api/me`, `POST /auth/login`, `GET /auth/logout`
- **URLs**: `GET /api/generate-url` (signed webhook URLs via HMAC-SHA256)
- **Rules**: `GET/PUT/DELETE /api/forward-rules/:endpoint`
- **Aliases**: `GET/PUT/DELETE /api/aliases`, `GET /api/aliases/unknown`, `POST /api/aliases/resolve`
- **Hits**: `GET /api/hits` (with date, endpoint, group filtering)
- **Stats**: `GET /api/stats`, `POST /api/purge`
- **MCP**: `POST /mcp` (JSON-RPC 2.0)

### MCP Tools (12 total)
1. `webhook_stats` — dashboard stats
2. `webhook_hits` — query hits by date/endpoint
3. `list_forward_rules` — show forwarding rules
4. `set_forward_rule` — create/update rule
5. `delete_forward_rule` — delete rule
6. `list_aliases` — list value → label mappings
7. `set_alias` — create/update alias
8. `delete_alias` — delete alias
9. `purge_old_hits` — cleanup 7+ day old data
10. `generate_webhook_url` — get signed URL
11. `line_groups` — list active LINE groups
12. `line_digest` — parse LINE messages into readable table

### Data Schema (3 tables)
- **webhook_hits** — stored webhooks (id, endpoint, suffix, received_at, body, forward status)
- **forward_rules** — routing rules (endpoint → URL, enabled, persist)
- **aliases** — ID → human label mappings (value, label, created_at)

### Key Features
- **Signed webhook endpoints** — `/w/{id}/{token}` with HMAC-SHA256 auth (no bearer token needed for senders)
- **GitHub integration** — parser for push, PR, issues, releases, workflows, etc.
- **LINE integration** — auto-resolve user/group names via Messaging API + message digest
- **Forwarding** — receive → optionally store → forward to external URL
- **MCP server** — 12 Claude Code tools (stdio or HTTP transport)

## Architecture

```
External Services (LINE, GitHub, webhook.site)
          ↓ POST /w/{id}/{token}
    CF Worker (Hono)
          ↓
     D1 (SQLite)
   ├── webhook_hits
   ├── forward_rules
   └── aliases
          ↓
    React Dashboard
    + MCP Server (12 tools)
```

## How to Use This Archive

1. **First time**: Read **1355_QUICK-REFERENCE.md** for a 2-min cheat sheet
2. **API integration**: Use **1355_API-SURFACE.md** (line numbers + exact schemas)
3. **Extending**: See "Extension Points" section in API-SURFACE.md
4. **Testing**: Follow **1355_TESTING.md** for curl examples and setup
5. **Deep dive**: Read **1355_ARCHITECTURE.md** for system design

## Key Takeaways

- **No auth overhead for senders**: The `/w/{id}/{token}` URL IS the authentication (HMAC-SHA256)
- **LINE is first-class**: Auto-aliases user/group IDs, digest parsing, group analytics
- **GitHub event summarization**: Human-readable summaries stored instead of raw JSON
- **D1 retention policy**: Hits older than 7 days are auto-deleted (manual purge available)
- **MCP-native**: 12 tools for Claude Code and other MCP clients (no SDK dependency)

## Development

```bash
# Local dev
npm install
cp .dev.vars.example .dev.vars
npm run dev  # http://localhost:5173

# Production deploy
npm run deploy
wrangler secret put API_TOKEN
```

## License

MIT (Soul Brews Studio)

---

**Archive created by**: MLBOY (Oracle, 2026-05-09)  
**Purpose**: Knowledge preservation across sessions
