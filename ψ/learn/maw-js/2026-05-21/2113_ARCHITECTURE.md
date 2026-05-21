---
type: learning
topic: maw-js architecture — core concepts, data flow, federation model, config schema
source: research
maturity: solid
retrieval_terms: [maw-architecture, maw-config, maw-federation-model, maw-transport, elysia]
date: 2026-05-21
---

# maw-js Architecture

## System Overview

```
┌─────────────────────────────────────────────────┐
│                    maw CLI                       │
│  (Bun + Elysia HTTP server + tmux integration)  │
├─────────────┬─────────────┬─────────────────────┤
│  Commands   │   Plugins   │      API Server      │
│  (40+ verbs)│  (registry) │  (HTTP + WebSocket)  │
├─────────────┴─────────────┴─────────────────────┤
│              Core Engine                         │
│  Sessions │ PTY Capture │ Agent Lifecycle        │
├─────────────────────────────────────────────────┤
│              Transport Layer                     │
│  tmux │ HTTP Federation │ Zenoh (experimental)   │
├─────────────────────────────────────────────────┤
│              Auth Layer                          │
│  HMAC-SHA256 │ ed25519 per-peer │ TLS (optional)│
└─────────────────────────────────────────────────┘
```

## Data Flow: Message Delivery

### Local (`maw hey devboy 'msg'`)
```
CLI → resolve agent → find local tmux session → tmux send-keys → oracle receives
```

### Cross-Node (`maw hey mac-studio:glueboy 'msg'`)
```
CLI → resolve agent → lookup namedPeers URL
    → HTTP POST /api/send
    → HMAC sign (federationToken + timestamp)
    → ed25519 sign (from field)
    → Remote maw server receives
    → Verify HMAC → Verify ed25519
    → Find target tmux session → tmux send-keys
    → Oracle receives
```

### Auth Flow Detail
```
Request arrives at /api/send
├── Layer 1: HMAC-SHA256
│   ├── Read body bytes (cached in WeakMap since v26.5.21)
│   ├── Compute HMAC(federationToken, body + timestamp)
│   ├── Compare with x-maw-signature header
│   └── Check timestamp within hmacWindowSeconds (300s)
├── Layer 2: ed25519 From-Signing
│   ├── Read body bytes (from WeakMap cache)
│   ├── Extract "from" field
│   ├── Lookup pubkey in peers.json
│   └── Verify signature
└── Both pass → execute command
```

## Config Schema (Key Fields)

```
maw.config.json
├── Identity
│   ├── host: "local"           # node identity
│   ├── port: 1412              # API port
│   ├── node: "clinic-drdo"     # node name
│   └── oracle: "mawjs"         # lineage identity
├── Commands
│   ├── commands: {"default": "claude --dangerously-skip-permissions --continue"}
│   └── sessions: {"devboy": "01-devboy"}
├── Federation
│   ├── federationToken: "..."  # HMAC shared secret (min 16 chars)
│   ├── namedPeers: [{name, url}]  # remote maw servers
│   ├── agents: {name: node}    # agent → node routing
│   └── peers: []               # (deprecated, use namedPeers)
├── Discovery
│   ├── zenoh: {scout: {enabled, timeoutMs}}
│   └── discovery: {transport: "scout|zenoh|both|off"}
├── Tuning
│   ├── intervals: {capture, sessions, status, teams, peerFetch, crashCheck}
│   ├── timeouts: {http, health, ping, pty, wakeRetry, wakeVerify}
│   └── limits: {feedMax, logsMax, ptyCols, ptyRows, maxConcurrentAgents}
└── Security
    ├── tls: {cert, key}
    ├── pin: "..."              # web UI PIN
    └── trustLoopback: true     # trust 127.0.0.1 without HMAC
```

## Plugin Architecture

```
Plugin Directory Structure:
~/.maw/plugins/<name>/
├── plugin.json               # manifest (name, version, capabilities)
├── impl.ts                   # command implementation
├── index.ts                  # plugin entry point
└── dist/                     # built output

Plugin Types:
├── CLI Command               # adds maw <verb>
├── Lifecycle Hook             # SessionStart, Stop, etc.
├── Service                    # long-running background process
└── Registry                   # publishable to maw plugin registry
```

## Transport Layer

| Transport | Purpose | Protocol |
|-----------|---------|----------|
| **tmux** | Local pane control | tmux CLI commands |
| **HTTP** | Federation messaging | REST + HMAC + ed25519 |
| **WebSocket** | Real-time feed | WS upgrade from HTTP |
| **Zenoh** | Experimental discovery | Pub/sub mesh |

## File Locations

| Path | Purpose |
|------|---------|
| `~/.config/maw/maw.config.json` | Main configuration |
| `~/.maw/peers.json` | Federation peer keys |
| `~/.maw/peer-key` | Local ed25519 private key (mode 0600) |
| `~/.maw/plugins/` | Installed plugins |
| `~/.maw/state/` | Runtime state (teams, sessions) |
| `~/.bun/bin/maw` | CLI entry point (or wrapper shim) |
| `~/.bun/install/global/node_modules/maw/` | Installed package |

## Key Intervals (Performance Tuning)

| Interval | Default | Purpose |
|----------|---------|---------|
| `capture` | 50ms | PTY output capture polling |
| `sessions` | 5000ms | Session state refresh |
| `status` | 3000ms | Agent status polling |
| `teams` | 3000ms | Team sync |
| `peerFetch` | 10000ms | Remote peer discovery |
| `crashCheck` | 30000ms | Crash detection |
