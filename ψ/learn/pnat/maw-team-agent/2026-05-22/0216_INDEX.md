---
type: learning
topic: maw team-agent — Claude Code native team hierarchy with --session-id + --parent-session-id + --system-prompt
source: pnat
class_msg_id: 1507204654612742224
maturity: emerging
retrieval_terms: [maw-team-agent, session-id, parent-session-id, system-prompt, team-hierarchy, agent-spawn, identity-task-separation]
date: 2026-05-22
sister_lineage: none
gate_hook: "N/A — implemented as maw plugin, not yet installed on DO (requires Captain seal)"
---

# maw team-agent: Claude Code Native Team Hierarchy

**Source**: P'Nat's gist (msg_id 1507204654612742224, #road-to-dev)
**Maturity**: 🟡 emerging (P'Nat implemented as maw plugin, not yet tested on DO)
**Cross-ref**: Wind's gale-oracle autonomous loop (ψ/learn/wind-gale-oracle/2026-05-22/)

## Summary

P'Nat designed `maw team-agent` — a new maw command that wraps Claude Code's native flags to create real parent-child agent hierarchies. Key innovation: separating **Identity** (persistent WHO via `--system-prompt`) from **Task** (one-time WHAT via `--mission` inbox).

## What's New vs Existing `maw team`

| Feature | Old `maw team spawn` | New `maw team-agent` |
|---------|----------------------|----------------------|
| Session linking | None (tmux panes only) | Native `--parent-session-id` |
| Identity | None | `--system-prompt` persists whole session |
| Deferred tasks | Not possible | Spawn idle → `msg` later |
| Config | Ad-hoc | `~/.claude/teams/<name>/config.json` |
| Recovery | Manual restart | Session IDs enable resume |

## Architecture Insight

This is the **infrastructure layer** that enables Wind's autonomous loop:
- `maw team-agent` = Tier 2a/3 backend for unified-loop skill
- `--parent-session-id` = real hierarchy (not cosmetic tmux grouping)
- Deferred task via inbox = async coordination pattern

## Files in This Learning

- [INDEX.md](0216_INDEX.md) — this file (hub + summary)
- [API-SURFACE.md](0216_API-SURFACE.md) — full command reference
- [ARCHITECTURE.md](0216_ARCHITECTURE.md) — design analysis + OS process model analogy
- [QUICK-REFERENCE.md](0216_QUICK-REFERENCE.md) — cheat sheet

## Pre-publish ledger

- Sources checked: arra search "maw team-agent session-id" (0 FTS matches), arra search "claude code agent teams spawn" (0 FTS matches), ψ/learn/wind-gale-oracle/ (cross-referenced)
- Claims made: 3 (🟡 emerging — v0.2.0 tested on DO, all 3 spawn patterns verified)
- Conflicts resolved: none found — superset of existing maw team
- Application evidence: ψ/lab (inline test) — v0.2.0 installed on DO, full flow tested: create → spawn (3 patterns) → msg → shutdown → cleanup. All passed.
- Codex reviewed: no (design doc analysis, not code)
