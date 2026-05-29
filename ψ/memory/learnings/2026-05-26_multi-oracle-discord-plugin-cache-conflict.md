---
type: learning
topic: Multi-oracle Discord plugin cache conflict — per-oracle registry isolation
source: experiment
maturity: emerging
retrieval_terms: [discord-mcp, multi-oracle, plugin-cache, DISCORD_STATE_DIR, start.sh]
date: 2026-05-26
gate_hook: "start.sh setup_local_plugin_cache() + patch_shared_plugin_env() fallback"
---

# Multi-Oracle Discord Plugin Cache Conflict

## Problem

Two oracles (DEVBOY + OFFICEBOY) on same machine (DO clinic-drdo) share `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.mcp.json`. Each oracle's start.sh patches `env.DISCORD_STATE_DIR` to its own state dir. Last one to start overwrites the other's value → the other oracle's Discord MCP reads the wrong state dir.

## What Doesn't Work

1. **`mcpServers` in project settings.json** — schema validation rejects it ("Unrecognized field: mcpServers"). Claude Code settings.json does NOT support MCP server definitions.
2. **`--channels plugin:discord@${FULL_PATH}`** — the `@` part only accepts registry names (e.g., `claude-plugins-official`), not filesystem paths.

## Solution (implemented, emerging)

Per-oracle plugin cache with separate registry directory:

```
~/.claude/plugins/cache/discord-officeboy/   # separate "registry"
  discord/                                    # plugin name (must match)
    0.0.4/                                   # version (copied from shared)
      .mcp.json                              # patched with officeboy's state dir
```

Channel flag: `--channels plugin:discord@discord-officeboy`

Fallback: if local cache setup fails, patch the shared `.mcp.json` and use `@claude-plugins-official` (proven DEVBOY pattern — "last to start wins").

## Key Insight

MCP child processes inherit env at spawn time. Patching `.mcp.json` after an oracle's MCP child is already running does NOT affect it. So "last to start wins" is safe for the shared-cache fallback — both oracles run with correct state dirs as long as they start sequentially (which maw ensures).

## Pre-publish ledger

- Sources checked: DEVBOY start.sh, Claude Code settings.json schema error, plugin cache directory structure
- Claims made: 3 (settings.json no mcpServers: solid; @-notation is registry-only: solid; per-oracle registry works: emerging — unverified in live boot)
- Conflicts resolved: none found
- Application evidence: officeboy-oracle start.sh committed, syntax validated, but live boot pending
- Codex reviewed: no
