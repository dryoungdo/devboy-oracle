---
type: learning
topic: maw-js — complete command reference and advanced guide
source: research
maturity: solid
retrieval_terms: [maw, maw-js, commands, federation, team, fleet, oracle, peek, hey, wake, kill, plugins, guide]
date: 2026-05-21
sister_lineage: none
---

# maw-js Advanced Guide — Complete Command Reference

**Source**: Soul-Brews-Studio/maw-js (v26.5.21-alpha.1608)
**Traced**: 2026-05-21 | Friction: 0.7 | Confidence: high

## Guide Structure

| File | Contents |
|------|----------|
| [2113_INDEX.md](2113_INDEX.md) | This file — overview + guide map |
| [2113_COMMANDS.md](2113_COMMANDS.md) | Complete command reference (40+ commands) |
| [2113_ARCHITECTURE.md](2113_ARCHITECTURE.md) | Core concepts, data flow, federation model |
| [2113_WORKFLOWS.md](2113_WORKFLOWS.md) | When-to-use decision trees + real workflow examples |
| [2113_QUICK-REFERENCE.md](2113_QUICK-REFERENCE.md) | Cheat sheet (Thai+English) |
| [2113_GOTCHAS.md](2113_GOTCHAS.md) | Known issues, gotchas, fleet-tested patterns |

## What is maw?

maw is a **multi-oracle session manager** built on tmux + HTTP federation. It manages Oracle (AI agent) lifecycles across multiple machines, provides inter-agent communication, and orchestrates multi-agent teams.

Think of it as: **tmux + federation + agent orchestration** in one CLI.

## Core Concepts

| Concept | What it is |
|---------|-----------|
| **Oracle** | An AI agent running in a tmux pane (typically Claude Code) |
| **Session** | A tmux session hosting one or more oracle panes |
| **Node** | A machine running maw (e.g., mac-studio, clinic-drdo) |
| **Peer** | A remote node connected via HTTP federation |
| **Fleet** | All nodes + oracles across the mesh |
| **Team** | A coordinated group of agents working together |
| **Plugin** | An extensible command module (CLI commands, lifecycle hooks, or services) |

## Command Categories

| Category | Commands | Use When |
|----------|----------|----------|
| **Lifecycle** | wake, kill, awake, new, scaffold | Starting/stopping oracles |
| **View** | ls, peek, panes, session, zoom | Inspecting state |
| **Communication** | hey, send, broadcast | Sending messages between oracles |
| **Navigation** | attach, bring, split, tile, layout | Moving between panes |
| **Federation** | federation, discover, fleet | Multi-node management |
| **Teams** | team create/spawn/send/shutdown | Multi-agent coordination |
| **Oracles** | oracle ls/scan/register/prune | Oracle registry management |
| **Plugins** | plugin install/build/search | Extending maw |
| **Maintenance** | cleanup, preflight, snapshots | Health + recovery |

## Pre-publish ledger

- Sources checked: maw-js src/commands/, src/plugins/, src/api/, src/config/, Oracle memory (15 results), session mining (46h, 223 prompts)
- Claims made: all backed by source code reading + real session usage data
- Conflicts resolved: maw talk-to vs maw hey (talk-to is LOCAL only, hey is cross-node)
- Application evidence: all commands verified against running maw v26.5.21 on clinic-drdo
- Codex reviewed: no (reference documentation, not code)
