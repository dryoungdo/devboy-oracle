---
type: learning
topic: "Claude Code --channels flag can silently skip MCP child spawn; listener alive ≠ Discord alive"
source: experiment
maturity: solid
retrieval_terms: [discord, mcp, channels-flag, silent-failure, listener-alive-bot-deaf, bun-child-missing, gateway-socket, devboy, plugin-loader, restart-procedure]
date: 2026-05-23
sister_lineage: from-iotboy
gate_hook: "start.sh post-launch verifier: sleep 12s; pstree $PID | grep -q 'bun.*discord' && ss -tnp | grep -q gateway.discord.gg || retry-once"
related_traces: ["ψ/memory/traces/2026-05-23/1418_devboy-discord-pair-disconnect-mcp-not-spawning.md"]
related_retros: ["ψ/memory/retrospectives/2026-05/23/14.26_devboy-discord-pair-disconnect-trace-5agent.md"]
---

# Lesson: Listener alive ≠ Discord alive — verify bun child + gateway socket

## What happened

Captain reported DEVBOY's Discord bot was disconnected. Channel listener (`claude --channels plugin:discord@claude-plugins-official`, PID 555863) was alive and had been running 3:30 minutes. The natural reflex was to assume the bot was healthy and the disconnect was transient. **It wasn't.** The listener had no `bun` child running the plugin's `server.ts`, therefore no `gateway.discord.gg` socket, therefore the bot was deaf and mute despite the parent process being up.

## Why this is the rule

Claude Code's `--channels` flag and the MCP server spawn defined in the plugin's `.mcp.json` are **decoupled**. The flag tells claude the channel is enabled for the session; the MCP child is spawned later by the plugin loader. If the plugin loader skips the spawn (for any reason — install error, race, version mismatch, plugin-loader bug), the parent claude process stays alive and looks healthy, but no Discord process exists.

There is **no log surface** for this failure as of plugin v0.0.4:
- `~/.claude/logs/` is empty
- Plugin's `.mcp.json` uses `bun run --silent` which suppresses bun install errors
- `server.ts` itself is fine — proven by manual spawn succeeding (`DEVBOY-oracle#9792` connects to gateway in ~3s with the same `.env`)

The only diagnostic surface is **process inspection**:
- `pstree -spnal <listener-PID>` must show a `bun … server.ts` child
- `lsof -i -p <listener-PID>` (or `ss -tnp`) must show a TCP connection to `gateway.discord.gg:443` (or its IP)

If either is missing, the listener is a zombie placeholder. Restart is required.

## How to apply

**When debugging a Discord disconnect on any fleet BOY**:

1. Do NOT trust `ps` alone — listener-alive is necessary but not sufficient.
2. Run `pstree -spnal $(pgrep -f "claude.*channels plugin:discord" | head -1)` — confirm a `bun.*discord` child exists.
3. Run `ss -tnp | grep -iE "discord|gateway.discord.gg"` — confirm an outbound 443 socket.
4. If either is missing, the listener is broken regardless of uptime. Restart.
5. **Before assuming token/access.json/dmPolicy is the cause**: spawn `server.ts` manually with the same `.env` and check if it logs `discord channel: gateway connected as <Bot>#XXXX`. This rules out 90% of hypotheses in ~3 seconds.

```bash
# 3-second diagnostic — confirms server.ts + token + Discord permissions all work
timeout 8 env DISCORD_BOT_TOKEN=$(grep -oP 'DISCORD_BOT_TOKEN=\K.+' ~/.claude/channels/discord/<bot>/.env) \
  bun --cwd ~/.claude/plugins/cache/claude-plugins-official/discord/<version>/ run start 2>&1 | head -20
```

If that prints `gateway connected as <Bot>#XXXX`, the root cause is **claude's plugin loader did not spawn the MCP child**, not the plugin/token/config. Restart the listener.

## Gate hook (mandatory per CLAUDE.md Shield #8)

The "remember harder" mitigation is not enough. The gate is a **post-launch verifier** baked into `start.sh`:

```bash
# pseudo-code addition to start.sh after the exec
# (can't put after exec — must wrap the exec or run as background watcher)

start_listener() {
  # NOTE: model pin is intentional per Captain (2026-05-23). Do not bump without seal.
  exec claude --model claude-opus-4-6 --dangerously-skip-permissions \
    --channels plugin:discord@claude-plugins-official &
  local listener_pid=$!

  sleep 12  # give plugin loader time to spawn bun child + connect gateway

  if ! pstree -spnal "$listener_pid" 2>/dev/null | grep -q "bun.*discord"; then
    echo "❌ bun MCP child missing 12s after launch — listener is a zombie placeholder" >&2
    kill "$listener_pid"
    return 1
  fi
  if ! ss -tnp 2>/dev/null | grep -q "pid=$listener_pid.*443"; then
    echo "❌ no outbound 443 socket from listener — gateway never connected" >&2
    kill "$listener_pid"
    return 1
  fi
  echo "✅ Discord listener healthy (bun child + gateway socket)"
  wait "$listener_pid"
}

start_listener || start_listener  # one retry
```

(The exact shape depends on how Captain wants start.sh to behave under failure — fail-fast vs retry vs notify. The point is: the absence of a bun child or gateway socket 12s after launch must be a detectable, actionable signal — not a 15-minute live-investigation puzzle.)

## Ruled-out hypotheses (don't waste time on these next incident)

When the listener is alive but the bot is silent:

| Hypothesis | Symptom that DOES match | Reality |
|---|---|---|
| dmPolicy="disabled" bug (2026-05-19) | Bot online in Discord, deaf to messages | Check access.json — if "allowlist", NOT the cause |
| Token rotated/invalid | Bot offline in Discord | Manual `bun run start` test will fail at `client.login` if true |
| Missing Message Content Intent | Bot online, receives metadata but no content | Manual test logs `gateway connected as ...` if intent is OK |
| Recent codex/bud disrupting config | Other BOY birth in past 24h | `git log -p` access.json + plugin dir; if no changes, NOT the cause |
| Parallel channel dir collision | Two channel dirs in `~/.claude/channels/discord/` | `ls` shows the truth in 1 second |
| Stale `.in_use/` lock blocking startup | Plugin claims to be already-in-use | server.ts has NO lock-write code; locks are advisory only — NOT a blocker |

## Pre-publish ledger

- **Sources checked**:
  - `arra_search("discord MCP server.ts not spawning gateway disconnect devboy listener", limit=10)` — 10 results, 2 directly relevant (Article 041, dmPolicy post-mortem)
  - `arra_search("devboy-codex birth discord channel conflict bot token migration", limit=8)` — 8 results, codex birth confirmed unrelated
  - Live process inspection: `ps`, `pstree`, `lsof`, `ss`
  - File reads: `server.ts` (Agent B mapped 6 failure paths), `access.json`, `.env`, `.mcp.json`, `package.json`, `ACCESS.md`, `README.md`, `start.sh`
  - Git log on devboy-oracle, past 8 days
  - Session jsonl mining via Agent D
- **Claims made**: 7 (all marked with confidence)
- **Conflicts resolved**: 6 hypotheses ruled out with evidence (see table above + trace log)
- **Application evidence**: Agent E reproduction — manual `bun run start` connected to gateway as `DEVBOY-oracle#9792` in 3s. Trace log `ψ/memory/traces/2026-05-23/1418_devboy-discord-pair-disconnect-mcp-not-spawning.md` documents the proof.
- **Codex reviewed**: pending — restart plan + gate_hook script should be Codex-reviewed before applying per standing order (≥30 LOC of analysis)
