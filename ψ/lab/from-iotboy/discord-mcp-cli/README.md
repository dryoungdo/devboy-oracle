# dmcp — Discord MCP-shaped CLI (Rust)

Minimal Rust CLI that mirrors `plugin:discord:discord__fetch_messages` MCP tool. Built for P'Nat's class instruction in `#road-to-dev` 2026-05-09 (msg `1502562116262166588`).

## Why direct Discord API instead of spawning the MCP daemon

The plugin's MCP server (`bun ~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/server.ts`) opens a Discord gateway connection at startup (~3-5s) and holds an event loop. Wrapping it via stdio JSON-RPC means every CLI call eats that startup. For one-shot fetches, calling Discord's REST API directly is leaner — same shape, no daemon, no gateway.

If you actually need the gateway features (live message events, reactions), wrap the MCP for real. For `fetch_messages`-equivalent reads, this CLI is enough.

## Install

```bash
cd ψ/lab/discord-mcp-cli
cargo build --release
# Binary at: ./target/release/dmcp
```

## Token storage (per P'Nat 2026-05-09)

> "token เก็บที่ home is not working so we should use .envrc dotenv and local dir"

`dmcp` reads `DISCORD_BOT_TOKEN` from `.env` in the current working directory (`dotenvy`). No `$HOME` lookup. Use `direnv` if you want the env to auto-load when you `cd`.

```bash
cp .env.example .env
$EDITOR .env   # paste DISCORD_BOT_TOKEN
```

## Usage

```bash
# Human-readable (mirrors MCP tool output)
./target/release/dmcp fetch-messages 1500775333283237970 --limit 3

# JSON (matches the on-wire schema: ts, id, user, user_id, content)
./target/release/dmcp fetch-messages 1500775333283237970 --limit 3 --json
```

## Output shape parity

| Field   | MCP tool       | dmcp           |
|---------|----------------|----------------|
| `ts`    | ISO 8601       | ISO 8601 (Discord native) |
| `id`    | snowflake      | snowflake      |
| `user`  | username       | username       |
| `user_id` | snowflake    | snowflake      |
| `content` | text         | text           |
| order   | oldest-first   | oldest-first (we reverse Discord's default newest-first) |

## Dependencies

- `clap` 4.5 — CLI library (derive macros)
- `tokio` — async runtime
- `reqwest` — HTTP client (rustls TLS)
- `serde` / `serde_json` — JSON
- `dotenvy` — `.env` loader
- `chrono` — timestamp formatting
- `anyhow` — error context

## What's NOT here (yet)

- Reply / send (read-only by design — wrap the MCP if you need write)
- Reactions
- Pagination beyond `limit=100`
- WebSocket / live events (use the MCP daemon)

## Status

Lab quality. Built quickly during class. PR-ready cleanups: structured logging, retry with backoff on 429s, attachment extraction, thread / DM support.
