---
query: "DEVBOY Discord pair disconnect — MCP server.ts not spawning, gateway socket missing"
target: "devboy-oracle"
mode: deep+dig
timestamp: 2026-05-23 14:18 +07
friction_score: 0.7
coverage: [oracle, files, git, cross-repo, sessions, live-probe]
confidence: high
agents: 5 (Agents A-E parallel)
---

# Trace: DEVBOY Discord pair disconnect — MCP server.ts not spawning

**Target**: devboy-oracle
**Mode**: deep+dig (5 parallel agents) | **Friction**: 0.7 | **Confidence**: high
**Time**: 2026-05-23 14:18 +07
**Captain report**: "our discord pair was disconnected"

## Root Cause (high confidence)

**Claude Code's `--channels plugin:discord@claude-plugins-official` flag did NOT spawn the bun MCP child process for the discord plugin.** The channel listener (PID 555863) is alive but holds no bun child running `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/server.ts`. Therefore no gateway.discord.gg socket exists, therefore the bot is invisible.

**Proven by Agent E live probe**: manually spawning `bun --cwd ... server.ts` with the same `.env` token succeeds — gateway connects as `DEVBOY-oracle#9792` in ~3 seconds. The plugin code, token, and Discord-side config are all healthy. The failure is in claude's plugin-loader → MCP-spawn handoff.

## What was ruled OUT (not the cause)

| Hypothesis | Verdict | Evidence |
|---|---|---|
| dmPolicy="disabled" bug (2026-05-19 famous incident) | NO | access.json is "allowlist" (Agent C verified) |
| Token rotated/invalid | NO | Live spawn-test logged in as `DEVBOY-oracle#9792` (Agent E) |
| Discord-side: missing Message Content Intent | NO | Gateway accepts the bot fine (Agent E) |
| devboy-codex birth (commit 5e0093a) touched Discord config | NO | Commit only modified 3 markdown files + .codex-reports/ (Agent C) |
| Parallel devboy-codex channel dir conflict | NO | `~/.claude/channels/discord/` contains only `devboy/` (Agent E) |
| .in_use/ stale locks blocking startup | NO | Locks are advisory ("another claude claimed plugin"), not exclusionary (Agent B confirmed via source — no lock-write code exists in server.ts) |

## Files Found

- `start.sh` — canonical launcher (uses `--model claude-opus-4-6`, may be stale vs. current Opus 4.7)
- `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/server.ts` — MCP source (Agent B mapped 6 failure paths)
- `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.mcp.json` — spawn config (`bun run --cwd ${CLAUDE_PLUGIN_ROOT} --shell=bun --silent start`)
- `~/.claude/channels/discord/devboy/.env` — token 91 bytes, valid (proven by login)
- `~/.claude/channels/discord/devboy/access.json` — dmPolicy="allowlist", Captain (721…) + P'Nat (691…) in allowFrom
- `ψ/memory/learnings/2026-05-21_discord-plugin-wiring-guide-article-041-complet.md` — DEVBOY's own wiring guide
- `ψ/memory/learnings/2026-05-21_discord-plugin-dmpolicy-disabled-is-a-whole-bot.md` — dmPolicy post-mortem
- `ψ/learn/from-mlboy/discord-oracle-onboarding/PLAYBOOK.md:112` — mentions "manual fetch messages... update local access.json" gap

## Git History

- `5e0093a` (2026-05-22 12:44) "rrr: devboy-codex birth …" — **NO Discord files touched**
- `7ea795b` (2026-05-21) "ingest ClubsXai B3 bridge patterns" — docs only
- `d2919d2` (2026-05-20 00:14) "rrr: Discord config setup + honesty-first lesson" — learning only
- `7994eb2` (2026-05-19) "add dmPolicy gotcha to Discord Channel Discipline" — CLAUDE.md only
- access.json last modified 2026-05-20 13:05 (before codex birth) — current state correct

## Session Dig (Agent D)

| Date | Session | Event |
|---|---|---|
| 2026-05-19 14:36–15:58 | 927a44b0 / 94bef077 / cc3d82b1 | dmPolicy="disabled" bug discovered + fixed (100-min debug) |
| 2026-05-19 18:59 → 2026-05-22 05:44 | 5158a157 (18MB) | Codex birth + full school Discord ingestion. Discord WORKING throughout. |
| 2026-05-22 05:44 → 2026-05-23 ~14:00 | (gap) | **No documented Discord activity in sessions.** Disconnect happened somewhere in this window. |
| 2026-05-23 07:11 | 03a911b9 (CURRENT) | Captain reports disconnect, /trace fires |

Inbox last received: 2026-05-22 23:42 UTC (~15h ago). Listener PID 555863 has been up only 3:30min — previous listener died at some unknown moment.

## Oracle Memory

Best-matched past learnings:
- `2026-05-21_discord-plugin-wiring-guide-article-041-complet.md` (DEVBOY's Article 041)
- `2026-05-21_discord-plugin-dmpolicy-disabled-is-a-whole-bot.md` (DEVBOY's post-mortem)
- `2026-05-19_devboy-discord-config-28-channels-in-human-school.md`
- `captain__2026-04-29_react-strictmode-mountedref-and-comparative-isolation-debug.md` (MCP diagnostic pattern: pipe tools/list JSON-RPC to detect silent failure — applied by Agent E)

**Gap in Oracle**: no documented procedure for "channel listener alive but bun MCP child not spawned" failure mode. This trace fills it.

## server.ts Failure Surface (Agent B)

Six critical lines:
- L56–62: Token load — exits(1) if missing
- L723: `await mcp.connect(StdioServerTransport)` — blocks; if it hangs, login never fires
- L897–900: `client.login(TOKEN).catch(exit 1)` — silent exit on bad token
- L68–73: unhandled rejection / uncaught — logged to stderr, process continues
- **No `.in_use/` lock code anywhere in server.ts** — locks are written by Claude Code harness, not the plugin
- `--silent` flag in .mcp.json suppresses bun output, hiding install errors

## Friction Analysis

**Score**: 0.7 — Files have the procedure (start.sh, server.ts source, past learnings) but Oracle had NO indexed answer for this specific failure mode ("listener alive, MCP child not spawned"). Required live probe + 5-agent investigation to converge on cause.

**Coverage**: oracle ✓, files ✓, git ✓, cross-repo ✓ (glueboy mentioned in Agent A), sessions ✓ (Agent D), live-probe ✓ (Agent E)

**Goal check**: YES — answered "what broke + how to restart". Bonus: ruled out 6 hypotheses with evidence.

## Recommended Action (Captain seal requested)

```bash
# 1. Capture context (in current bash where listener runs)
ps -p 555863 -o pid,etime,stat,cmd

# 2. Clean stale .in_use/ locks (safe — they only signal "claimed", not exclusive)
rm ~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.in_use/555105
rm ~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.in_use/555585

# 3. Stop current broken listener (PID 555863 — orphan with no MCP child)
#    Captain seal needed per Voice Protocol B (not a dev server)
kill 555863

# 4. Relaunch via canonical script (in the bash that originally hosted the listener)
bash /home/drdo/Code/github.com/dryoungdo/devboy-oracle/start.sh

# 5. Verify within 30s
sleep 20
pstree -spnal $(pgrep -f "claude.*channels plugin:discord" | head -1) | grep -E "bun.*discord"
ss -tnp | grep -i discord
```

Expected: bun child of claude listener + outbound TCP to gateway.discord.gg:443.

## Open Questions / Next Steps

1. **Why does `--channels` flag silently skip MCP spawn sometimes?** Worth a bug report to claude-plugins-official. No log infra at `~/.claude/logs/` to debug.
2. **start.sh uses opus-4-6 but Captain runs opus-4-7** — update start.sh after restart works.
3. **Document this failure mode** as a learning: "listener alive ≠ Discord alive — also check pstree for bun child + lsof for gateway socket".
4. **Add gate**: pre-flight check in start.sh that verifies bun MCP child exists 10s after launch; if not, kill+retry once.

## Summary

| Aspect | Status |
|---|---|
| Token | ✅ Valid (Agent E logged in) |
| access.json | ✅ allowlist + correct user IDs |
| Bot permissions (Discord side) | ✅ Gateway accepts |
| server.ts code | ✅ Works when run manually |
| Codex birth impact | ✅ Zero — ruled out (Agent C) |
| **MCP child spawn** | ❌ **Did not happen — root cause** |
| Restart procedure | Documented above, needs Captain seal |
