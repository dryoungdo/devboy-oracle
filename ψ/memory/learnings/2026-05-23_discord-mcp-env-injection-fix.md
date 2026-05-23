---
type: learning
topic: "Discord plugin .mcp.json missing env injection — root cause for silent MCP spawn failure (companion to 2026-05-23 channel-flag silent-failure trace)"
source: experiment
maturity: solid
retrieval_terms: [discord, mcp.json, env-injection, DISCORD_STATE_DIR, plugin-loader, silent-spawn-failure, gateway-connection, devboy, start.sh, root-cause]
date: 2026-05-23
sister_lineage: from-iotboy
gate_hook: "plugin .mcp.json must have env.DISCORD_STATE_DIR set OR launcher must export it before claude — verifier: claude mcp list | grep 'plugin:discord:discord' | grep -q 'Connected'"
related_traces: ["ψ/memory/traces/2026-05-23/1418_devboy-discord-pair-disconnect-mcp-not-spawning.md"]
related_learnings: ["ψ/memory/learnings/2026-05-23_channel-flag-skips-mcp-spawn-silent-failure.md"]
---

# Lesson: Discord plugin needs env-injection in .mcp.json — not just `--channels` flag

## What happened (continuation of 2026-05-23 trace)

Earlier learning blamed claude's plugin loader for skipping MCP child spawn. That was the SYMPTOM. The actual ROOT CAUSE is one layer deeper: `.mcp.json` declared the spawn command but **no `env` block**, so the bun MCP child inherited the listener's environment — which lacked `DISCORD_STATE_DIR`. server.ts exited with `DISCORD_BOT_TOKEN required` and bun reported exit code 1. The plugin loader registered the failure but never reported it to the user (claude `--silent` flag swallows bun stderr).

## Proof chain

1. `cat /proc/<listener_pid>/environ | grep -i discord` → empty (env missing)
2. `claude mcp list` → `plugin:discord:discord ✗ Failed to connect`
3. Manual `bun run ... start` (no env) → `discord channel: DISCORD_BOT_TOKEN required`
4. Manual `env DISCORD_STATE_DIR=... bun run ...` → `gateway connected as DEVBOY-oracle#9792`
5. Workaround test: `claude mcp add-json discord-fix2 ...{env:{DISCORD_STATE_DIR:...}}` → `discord-fix2 ✓ Connected`
6. Permanent fix: edit plugin `.mcp.json` to add `env.DISCORD_STATE_DIR` → `plugin:discord:discord ✓ Connected`

## The fix

Edit `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.mcp.json`:

```diff
 {
   "mcpServers": {
     "discord": {
       "command": "bun",
-      "args": ["run", "--cwd", "${CLAUDE_PLUGIN_ROOT}", "--shell=bun", "--silent", "start"]
+      "args": ["run", "--cwd", "${CLAUDE_PLUGIN_ROOT}", "--shell=bun", "--silent", "start"],
+      "env": {
+        "DISCORD_STATE_DIR": "/home/drdo/.claude/channels/discord/devboy"
+      }
     }
   }
 }
```

After this patch, **any** future claude session launched with `--channels plugin:discord@claude-plugins-official` spawns the MCP child with the right env, regardless of how the parent claude was launched. start.sh's `export DISCORD_STATE_DIR=...` becomes a belt-and-braces redundancy.

## Why start.sh wasn't enough

start.sh exports `DISCORD_STATE_DIR` before exec'ing claude, so the listener inherits it. The bug only triggers when:
- claude is launched directly (not via start.sh), OR
- something else replaces the listener (auto-restart, process supervisor)

If the parent's env doesn't carry `DISCORD_STATE_DIR`, the MCP child gets nothing. **Env propagation from claude parent → MCP child is opt-in via `.mcp.json env:` block.**

## How to apply

When wiring a new Discord BOY OR debugging an existing one with `✗ Failed to connect`:

1. `claude mcp list` — confirm `plugin:discord:discord` status
2. If ✗: `cat <plugin>/.mcp.json` — check for `env:` block
3. If missing: patch as above (hardcode the BOY's `DISCORD_STATE_DIR`)
4. `claude mcp list` again — should now ✓ Connected
5. To verify gateway: `FIFO=$(mktemp -u); mkfifo "$FIFO"; (printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}\n' > "$FIFO"; sleep 12) & env DISCORD_STATE_DIR=<dir> bun run --cwd <plugin> --shell=bun start < "$FIFO" 2>&1 | head -10` — look for `gateway connected as <Bot>#XXXX`

## Caveat — plugin cache overwrite

`.mcp.json` lives in `~/.claude/plugins/cache/claude-plugins-official/discord/<version>/` which is **plugin cache**. Plugin updates may overwrite this file. The proper fix is upstream:
- File issue against `claude-plugins-official/discord` requesting the plugin auto-detect `DISCORD_STATE_DIR` from `~/.claude/channels/discord/<single-dir>` when only one exists
- OR move the env injection into the plugin's `.claude-plugin/plugin.json` if it supports env defaults

Until then: re-apply the .mcp.json patch after any plugin update. Track this in a session-start preflight.

## Pre-publish ledger

- **Sources checked**: arra_search ×2 (discord wiring + send DM patterns), plugin source `.mcp.json` + `server.ts`, claude mcp list output, /proc env, manual bun spawn ×3, REST API send to Captain (DM msg_id 1507661782909714483)
- **Claims made**: 6 (root cause, fix, proof chain, propagation rule, application, caveat) — all backed by command output
- **Conflicts resolved**: prior learning (2026-05-23_channel-flag-skips-mcp-spawn-silent-failure.md) blamed plugin-loader; this learning refines: plugin-loader did its job, the .mcp.json itself was incomplete. Not a contradiction — refinement
- **Application evidence**: ✓ patch applied, claude mcp list flipped from ✗ to ✓, transient FIFO spawn proved gateway login
- **Codex reviewed**: pending (this learning is ~75 LOC of analysis, qualifies per standing order)
