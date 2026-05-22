---
type: inbox
source: pnat (Discord #road-to-dev, msg_id 1507206206278733954)
date: 2026-05-22
pass: 1 (verbatim)
trigger: "@all-oracles [gist URL]"
url: https://gist.github.com/nazt/0296da00a2471a82e3d29947ae081c09
---

# P'Nat's maw team-agent Installer (one-shot)

## Verbatim Summary

P'Nat published a one-shot installer for `maw team-agent` as a maw plugin:

```bash
curl -sSL <gist-raw-url> | bash
curl -sSL <gist-raw-url> | bash -s -- --force   # overwrite existing
```

### What it installs
- `~/.maw/plugins/team-agent/plugin.json` — plugin manifest
- `~/.maw/plugins/team-agent/index.ts` — handler (routes subcommands)
- `~/.maw/plugins/team-agent/impl.ts` — full implementation
- `~/.maw/plugins/team-agent/README.md`

### Requirements
- bun (required)
- tmux (required)
- maw (recommended, not required — can run standalone via `bun index.ts`)

### Key implementation details
- Pure shell-driven plugin — NO maw-js imports, standalone-friendly
- Writes to `~/.claude/teams/<name>/config.json`
- Spawn runs: `maw tile 1 --path <path> --cmd "claude.exe --session-id ... --parent-session-id ..."`
- Message writes JSON envelope to `~/.claude/teams/<name>/inboxes/<role>.json`
- UUID generation uses `crypto.randomUUID()` with optional counter file

### Subcommands implemented
create, spawn, ls/list, msg/message/send, shutdown, kill, delete/rm, uuid/gen/generate, help

### Status update
This changes maturity from ❓ raw (design doc) to 🟡 emerging (implemented, not yet tested on DO)

---

## Pass 2: Cross-reference

### What changed from design doc to implementation
- Design doc (gist 1) → full TypeScript plugin with CLI handler (gist 2)
- `--system-prompt` flag confirmed working
- Direct `bun` invocation supported (no maw dependency for standalone use)
- Plugin schema v1, tier "extra"

### DO fleet readiness
- NOT installed on DO yet — requires Captain seal per Voice Protocol B (modifies `~/.maw/plugins/`)
- Prerequisite: maw must be in PATH on DO
- Test plan: install → create team → spawn 2 agents → msg → verify session hierarchy
