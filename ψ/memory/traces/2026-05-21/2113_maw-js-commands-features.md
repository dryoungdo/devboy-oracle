---
query: "maw-js all commands and features — advanced guide"
target: "Soul-Brews-Studio/maw-js"
mode: deep+dig
timestamp: 2026-05-21 21:13
friction_score: 0.7
coverage: [oracle, files, cross-repo, dig]
confidence: high
---

# Trace: maw-js commands and features

**Target**: Soul-Brews-Studio/maw-js
**Mode**: deep+dig | **Friction**: 0.7 | **Confidence**: high
**Time**: 2026-05-21 21:13

## Oracle Results

- maw talk-to federation pivot (GLUEBOY learning): talk-to is LOCAL only, use curl POST or maw hey for cross-node
- maw hey is primary fleet IPC (iotboy learning): canonical primitive for cross-Oracle communication
- Federation body-read-failed bug: v26.5.17 consumed body twice, v26.5.21 fixes via WeakMap cache
- PM2 PATH stripping (Apple Silicon): pm2 strips /opt/homebrew/bin, causes silent session listing failure
- Credential leak pattern: federationToken committed plaintext, needs pre-commit scanning

## Files Found

- 40+ core commands/aliases in src/commands/ and src/commands/plugins/
- 12 command plugin directories (discover, federation, fleet, oracle, plugin, session, team, tile, pane, tmux, split, swarm)
- 2 built-in plugins (mqtt-publish, shell-hooks)
- 10+ API endpoints (/api/send, /api/config, /api/feed, /api/federation/status, etc.)
- Full config schema: 40+ keys with intervals, timeouts, limits, discovery

## Session History (from /dig)

- Total session: 46h, 2774 min, 223 user prompts
- `maw team`: 816 references (heaviest usage)
- `maw hey`: 504 references (primary IPC)
- `maw wake`: 115 references
- `maw kill`: 9 references
- `maw peek`: 7 direct uses
- `maw talk-to`: 7 direct uses
- `maw bud`: 5 uses
- Federation debugging: ~2-3h of session time
- Outcome: bidirectional federation established

## Friction Analysis

**Score**: 0.7 — Found in repo files + Oracle memory + session history
**Coverage**: oracle, files, cross-repo, dig (4/5 dimensions)
**Goal check**: Yes — comprehensive inventory achieved for guide creation

## Summary

maw-js has 40+ commands across 12 plugin modules. Core workflow: `maw wake` (start) → `maw hey` (communicate) → `maw peek` (verify) → `maw kill` (stop). Advanced: `maw team` (multi-agent), `maw federation` (multi-node), `maw discover` (inventory). Guide deliverable follows.
