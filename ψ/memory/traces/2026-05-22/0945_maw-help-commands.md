---
query: "maw --help"
target: "Soul-Brews-Studio/maw-js"
mode: deep
timestamp: 2026-05-22 09:45
friction_score: 0.7
coverage: [oracle, files, git, cross-repo, github]
confidence: high
---

# Trace: maw --help

**Target**: Soul-Brews-Studio/maw-js
**Mode**: deep (5 agents) | **Friction**: 0.7 | **Confidence**: high
**Time**: 2026-05-22 09:45

## Oracle Results (arra search)

10 results found — learnings + retros mentioning maw CLI:
- CoachBoy 2026-03-29: "MAW v1.1.0 has 18+ CLI commands. We use 6."
- Captain 2026-04-16: maw update alpha, v1.5.0 → v2.0.0-alpha upgrade
- GLUEBOY 2026-03-29: "Always use maw CLI for fleet communication"
- Multiple retros about maw wake, maw hey, maw peek usage patterns

## maw --help Output (live, v26.5.21-alpha.1608)

### 101 commands in 3 tiers:

**Core (32)**: done, bud, ls, send, send-text, take, contacts, oracle, peek, awaken, run, attach, incubate, stop, health, send-enter, sleep, wake, ping, tile, swarm, init, pane, open, close, layout, bring, scaffold, awake, new, preflight, snapshots

**Standard (43)**: tag, assign, shellenv, ui, plugin, fleet, tmux, session, transport, zoom, completions, kill, split, mega, on, restart, overview, whoami, setup, view, soul-sync, discover, capture, about, panes, federation, stream, pulse, locate, inbox, find, peers, scout, project, check, learn, workon, talk-to, team, doctor, pair, cleanup, messages

**Extra (26)**: oracle-skills, triggers, costs, token, scope, reunion, archive, art, workspace, absorb, rename, tab, dream, trust, park, profile, pr, bg, oracle-workon, consent, team-agent, resume, broadcast, signals, avengers, demo

## Files Found

**maw-js repo**: `/home/drdo/Code/github.com/Soul-Brews-Studio/maw-js`
- package.json: v26.5.21-alpha.1608 (CalVer), entry src/cli.ts
- src/commands/: plugin dispatch, shared agents
- src/plugins/: 89 bundled plugin surfaces
- docs/: federation.md, testing, plugin architecture
- README.md: 302 lines, full CLI reference

**Cross-repo docs**:
- glueboy-oracle `ψ/reference/maw-commands.md` — command reference guide
- devboy-oracle `ψ/memory/traces/2026-05-21/2113_maw-js-commands-features.md` — previous deep trace (40+ commands)

## Git History

Recent commits focus on coverage + alpha cuts:
- `8aa1bbd3` Cut alpha (100% coverage head)
- `c4a19057` Close remaining alpha coverage gaps
- `ee4aceb1` Expose live pane follow (PTY bridge)
- Latest stable: v26.5.20, latest alpha: v26.5.21-alpha.1608
- CalVer adopted 2026-04-18

## GitHub Issues/PRs

- #1885: `feat(plugin-loader): InvokeContext lacks parsed flags` — open
- #1881: `maw broadcast reports '0 windows / N skipped'` — open
- PR #1884: `vendor: discord plugin v0.4.2` (nazt) — open
- PR #1883: `fix(maw): clean diagnostics and routing` — open

## Oracle Memory

11 files in devboy-oracle ψ/ mention maw:
- Learnings: silent-sessions, federation body-read bug
- Traces: 2026-05-21 deep trace (40+ commands, 46h session history)
- Inbox: team-agent design + installer, federation tests
- Lab: unified-loop references maw team as Tier 3

## Friction Analysis

**Score**: 0.7 — Visible (files + high confidence)
**Coverage**: 5/5 dimensions searched
**Goal check**: YES — complete picture of maw CLI: 101 commands across 3 tiers, version history, repo structure, known issues. Previous trace from 2026-05-21 covered 40+ commands; this updates to 101 with v26.5.21.

## Summary

maw v26.5.21-alpha.1608 has grown to 101 commands (up from 40+ at last trace). Architecture: Bun/TypeScript CLI + 89 bundled plugins + REST API + WebSocket engine. Key additions since last trace: team-agent (P'Nat, just tested), messages (SQLite ledger), scout (Zenoh discovery), stream (PTY follow). Active development: coverage hardening, plugin-loader flag parsing (#1885).
