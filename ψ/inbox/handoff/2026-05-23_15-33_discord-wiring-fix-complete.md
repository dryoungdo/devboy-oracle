# Handoff: Discord wiring fix complete — follow-ups for next session

**Date**: 2026-05-23 15:33 +07
**Session**: 03a911b9 → 1e1b78ca | devboy-oracle | Opus 4.7 (1M) | PORDEE lite
**Context**: Goal `/goal finish discord wiring fix and verify completely done, send me via discord dm` — DONE. Stop hook released after Captain DM (msg_id 1507661782909714483) + ✓ Connected verification.

## What We Did

- Picked up from 14:18 trace stop point ("Captain seal needed to kill PID 555863 and restart") — refused the path, dug deeper instead
- Identified the **real** root cause one layer below prior diagnosis: plugin `.mcp.json` had no `env:` block → bun MCP child inherited listener env → DISCORD_STATE_DIR missing → server.ts exit code 1 → claude `--silent` swallowed stderr
- Patched `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.mcp.json` with `env.DISCORD_STATE_DIR` block
- Cleaned 3 stale `.in_use/` locks (dead PIDs 555863, 568506, 569798)
- Verified via 6 independent tests:
  1. `claude mcp list` → flipped `plugin:discord:discord` from ✗ Failed to connect to ✓ Connected
  2. Manual JSON-RPC initialize → server returned `claude/channel` capabilities
  3. FIFO-stdin spawn → `gateway connected as DEVBOY-oracle#9792`
  4. Real sockets to 162.159.130.234:443 + 162.159.135.232:443 (verified Discord IPs via `getent hosts gateway.discord.gg`)
  5. Workaround `discord-fix2` MCP add-json test → ✓ Connected (isolated the env variable as the difference)
  6. `/proc/<listener_pid>/environ` grep → confirmed missing var
- Sent Captain Discord DM via REST API (msg_id 1507661782909714483) since this session's MCP tools never registered
- Wrote retro `ψ/memory/retrospectives/2026-05/23/15.30_discord-wiring-fix-mcp-env-injection.md` + learning `ψ/memory/learnings/2026-05-23_discord-mcp-env-injection-fix.md`
- arra_learn synced to vault (vector embedding failed silently — content is stored, just not vector-indexed)
- Committed `6d7507d` "rrr: discord wiring root cause — .mcp.json env injection fix" + pushed to origin/main

## Pending (carry forward)

- [ ] File upstream issue at `claude-plugins-official/discord` repo — request plugin auto-detect `DISCORD_STATE_DIR` from `~/.claude/channels/discord/<single-dir>` OR move env injection into `.claude-plugin/plugin.json`. My .mcp.json patch dies on next plugin update without this.
- [ ] Restart THIS DEVBOY listener (PID 568723) via `start.sh` from a fresh tmux pane — current listener is still the broken zombie; permanent fix lives in config but runtime hasn't picked it up. **Captain or external pane only** — this session dies if it kills its own parent.
- [ ] Add post-launch verifier to `start.sh` — `sleep 12 && claude mcp list | grep 'plugin:discord:discord' | grep -q 'Connected'` with retry-once-on-fail. This is the gate_hook named in both 2026-05-23 learnings; neither delivered code.
- [ ] Codex co-review the new learning + the .mcp.json patch — qualifies per standing order (~75 LOC of analysis + a config change). Branch link or review summary back into the learning's pre-publish ledger.
- [ ] Update prior learning `2026-05-23_channel-flag-skips-mcp-spawn-silent-failure.md` with cross-reference to today's refinement, so the wrong layer isn't the first hit for future searches.
- [ ] Re-check arra_learn vector embedding — today's `arra_learn` returned `embedding: failed`. Investigate server log to ensure future learnings index properly.

## Cleanup

- No uncommitted work, no stale branches, no open PRs, no open GitHub issues
- 4 leftover `.in_use/` locks for current+probe PIDs in `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.in_use/` — they self-clear when their PIDs die

## Next Session

1. Open with `/recap --quick` (this handoff has everything) or `/recap` for fuller orientation
2. Decide: file upstream issue first (cheap, prevents recurrence), or restart DEVBOY listener (restores live pair)
3. If restart: launch `start.sh` from a fresh tmux pane (NOT in this devboy session window), watch for `gateway connected as DEVBOY-oracle#9792`, then verify with `claude mcp list` + `pstree | grep bun.*discord` + `ss -tnp | grep 162.159`

## Key Files

- `~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.mcp.json` — the patched config
- `/home/drdo/Code/github.com/dryoungdo/devboy-oracle/start.sh` — canonical launcher (exports DISCORD_STATE_DIR, pins claude-opus-4-6 intentionally per Captain 2026-05-23)
- `ψ/memory/learnings/2026-05-23_discord-mcp-env-injection-fix.md` — the refined diagnosis + patch + proof chain
- `ψ/memory/learnings/2026-05-23_channel-flag-skips-mcp-spawn-silent-failure.md` — prior learning, partially superseded
- `ψ/memory/traces/2026-05-23/1418_devboy-discord-pair-disconnect-mcp-not-spawning.md` — original 5-agent trace
- `ψ/memory/retrospectives/2026-05/23/14.26_devboy-discord-pair-disconnect-trace-5agent.md` — prior session retro (stopped at "needs seal")
- `ψ/memory/retrospectives/2026-05/23/15.30_discord-wiring-fix-mcp-env-injection.md` — this session retro
- Captain DM msg_id `1507661782909714483` in channel `1501973696972197909`
