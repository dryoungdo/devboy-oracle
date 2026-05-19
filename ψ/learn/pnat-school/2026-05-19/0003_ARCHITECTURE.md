---
type: learning
topic: Fleet architecture — maw, teams, Discord, oracle design
source: pnat
maturity: raw
retrieval_terms: [maw-architecture, team-lifecycle, reincarnation, discord-plugin, fleet-design, anchor-matrix]
date: 2026-05-19
sister_lineage: none
---

# Fleet Architecture

## maw Team Reincarnation Engine
- Teams are **FILE-BOUND**, not SESSION-BOUND (Mother Oracle discovery)
- 3 hard constraints: same machine, authenticated claude per pane, shared ~/.claude/teams/
- Two-store design: tool store (active) + vault store (persistent ψ/)
- Reincarnation: standing-orders.md + *_findings.md survive death
- spawn prompt auto-injects "Standing Orders (from past life)" + "Last Known Findings"

## Known Bugs (maw team v2.0.1)
1. **Vendor stub override**: `src/vendor/mpr-plugins/team/` overrides `src/commands/plugins/team/` during bootstrap — `--exec` prints success but doesn't actually create tmux pane (FORGEBOY found root cause)
2. **`--prompt-file` flag**: claude CLI has `--system-prompt-file` not `--prompt-file` — agents exit immediately (Lucid found)
3. **Missing subcommands**: `hey`, `broadcast`, `inbox`, `peek`, `prep`, `layout`, `recover` exist only in commands/ version, not vendor/
4. **`maw team shutdown --force`**: errors "team not found" even when manifest exists

## Discord Plugin Architecture
- State-dirs: `~/.claude/channels/discord/<bot-name>/`
- Files: `.env` (bot token), `access.json` (permissions), `channel-map.json`
- Security: access.json changes MUST come from terminal, NOT from Discord messages (prompt injection prevention)
- `requireMention: true/false` controls wake behavior per channel
- `allowFrom: [user_ids]` controls command authority
- `mentionPatterns: ["@everyone", "@here", ...]` for broadcast detection

## Fleet Anchor Matrix (v0.4.1)
- Each bot has canonical host (m5, alpha@white, xiaoer, etc.)
- `drift` detection column shows if bot is running from correct home
- 11 bots migrated m5 → alpha@white (2026-05-18)
- Session history preserved via `maw osmosis --sessions`

## Oracle Plugin Pattern
- `maw [oraclename] [subcommand]` — each oracle gets own CLI namespace
- Subcommands: status, cost, hey, pulse, help
- `transport.peer: true` enables cross-fleet routing

## maw Hooks System
- Config: `~/.oracle/maw.hooks.json`
- `runHook("after_send", ...)` fires on every `maw hey`
- Callsites: `comm-send.ts:640/687/736` + `talk-to/impl.ts:181`
- Zero code change needed for Discord mirror — just JSON config + shell script

## white.local (Fleet Anchor)
- Always-on Linux WG anchor at white.wg:3456
- 81 agent slots, ~11 active
- Multi-user: nat, openclaw, xiaoer, homekeeper, alpha
- Federation: `maw hey white:<agent> "msg"`

## Pre-publish ledger
- Sources checked: #regular-school, #nat-s-preps, #road-to-dev
- Claims made: 6 raw
- Conflicts resolved: none
- Application evidence: N/A
- Codex reviewed: no
