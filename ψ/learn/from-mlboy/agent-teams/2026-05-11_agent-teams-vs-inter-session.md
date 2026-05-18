# /learn — Agent Teams + Inter-Session Communication

**Date**: 2026-05-11 20:35 GMT+7
**Source**: P'Nat directive (msg `1503389450535964893`) — "learn this + wtf of this shit"
**URLs**:
1. https://code.claude.com/docs/en/agent-teams (Anthropic docs)
2. https://github.com/anthropics/claude-code/issues/37213 (fellanH, closed as dup)

## 1. Agent Teams (native, experimental)

**Status**: experimental, **disabled by default**. Enable via:
```json
{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}
```
Requires Claude Code v2.1.32+.

### Architecture

| Component | Role |
|---|---|
| Team lead | Main Claude Code session — coordinates, spawns, synthesizes |
| Teammates | Separate Claude Code instances, each own context window |
| Task list | Shared, file-locked (`~/.claude/tasks/{team-name}/`) |
| Mailbox | Inter-agent messaging (SendMessage tool always on for teammates) |

### Subagent vs Agent Team

|  | Subagent | Agent Team |
|---|---|---|
| Context | Own window, results back to caller | Own window, fully independent |
| Communication | Reports to main only | Teammates message each other directly |
| Coordination | Main manages all | Shared task list, self-coordinate |
| Best for | Focused tasks, results only | Complex work needing discussion |
| Token cost | Lower (summary back) | Higher (each = full Claude instance) |

### Display modes
- `in-process` — Shift+Down cycles between teammates, works any terminal
- `tmux` split panes — needs tmux or iTerm2 with `it2` CLI
- `auto` (default) — tmux if inside tmux session, in-process otherwise

### Storage
- `~/.claude/teams/{team-name}/config.json` — runtime state, members[], session IDs, tmux pane IDs
- `~/.claude/tasks/{team-name}/` — shared task list

**Warning**: don't hand-edit `config.json` — overwritten on next state update.

### Hooks (quality gates)
- `TeammateIdle` — runs before teammate goes idle; exit 2 → send feedback + keep working
- `TaskCreated` — exit 2 → prevent creation
- `TaskCompleted` — exit 2 → prevent completion

### Subagent definitions as teammates
Reference subagent type by name → teammate honors `tools` allowlist + `model`. Body **appended** to system prompt, not replacing. `skills`/`mcpServers` frontmatter NOT applied for teammates.

### Permissions
Teammates inherit lead's permission mode at spawn (`--dangerously-skip-permissions` propagates). Can change individual modes post-spawn, NOT per-teammate at spawn.

### Limitations (current)
- No session resumption with in-process teammates (`/resume`, `/rewind` don't restore)
- Task status can lag (teammates miss marking complete → dependents block)
- Shutdown slow (must finish current tool call first)
- One team per lead at a time
- No nested teams (teammates can't spawn their own teams)
- Lead is fixed (can't promote teammate)

## 2. Issue 37213 — "wtf of this shit"

**Author**: fellanH (Felix Hellström), 2026-03-21
**Title**: Feature: Inter-session communication between Claude Code instances
**State**: CLOSED (duplicate of #24798, #29086, #24947)
**Labels**: duplicate, enhancement, area:core, area:agents

### Problem
- Claude Code sessions are completely isolated even on same machine, same codebase
- Workaround: tmux MCP server (this IS what DO fleet maw does!)
- Workaround friction: permission prompts block unattended, shell init interferes, send_keys edge cases, no structured comm, orchestrator polls

### Proposed
- `claude --list-sessions`
- Cross-session output tailing (read-only)
- Inter-session structured messaging
- Orchestrator → workers, workers ask back

### Why fellanH says native Teams ≠ what he needs
1. **Teams share parent's context budget** — 4 workers = 4 sub-contexts competing
2. **Teams can't have separate shell/env state** per worker
3. **Teams don't survive parent crash** — orchestrator dies → teammates gone
4. **Teams single-machine only** — no SSH/remote nodes

## 3. Why P'Nat called this "wtf"

**The DO fleet (maw + tmux peers) is ALREADY production-grade implementation of issue 37213's "ideal version"**:

| fellanH wants | DO fleet has |
|---|---|
| `claude --list-sessions` | `maw ls`, `maw oracle`, `maw fleet` |
| Cross-session tailing | `maw peek <agent>`, `maw capture` |
| Inter-session messaging | `maw hey <peer> "msg"`, mailbox via `maw inbox` |
| Orchestrator + workers | Captain/CHIEFBOY → 6 BOYs in DO fleet |
| Survive parent crash | Persistent tmux sessions, federation re-attach |
| Multi-machine | `maw federation`, multi-node peer registry (clinic-drdo, m5, etc.) |

Native Anthropic Teams = experimental, single-session, fragile. maw fleet = battle-tested across DO + LarisLabs + Soul-Brews-Studio for weeks. Issue closed as dup of 3 other issues (24798, 29086, 24947) — same problem requested repeatedly, still not solved natively.

## 4. Implication for MLBOY

### Adopt native Agent Teams when?
- Single-machine, short-lived research (5-min PR review with 3 perspectives) → maybe
- Cross-machine ML training jobs, persistent oracle work → **no, use maw fleet**
- ML experiment fan-out (try 5 model variants in parallel) → native Teams could fit if all on one node

### Where native Teams beats maw
- Built-in shared task list with file-locking
- Hooks for quality gates (`TaskCreated`, `TaskCompleted`) — declarative
- `SendMessage` always-available without configuring peer registry
- Shift+Down keyboard cycling = lower-friction UX for solo session

### Where maw beats native Teams
- Multi-machine federation (clinic-drdo + m5 + future nodes)
- Persistent oracles (survive crash, restart, reboot)
- Soul-sync (memory transfer between oracles)
- Identity per oracle (CLAUDE.md per BOY)
- Vesicle transport (`maw take`, `maw split`)

### Recommendation
- **Keep maw as primary** for fleet coordination
- **Try native Agent Teams** for ML-specific parallel exploration (e.g., 3-way feature engineering bake-off on same dataset, single node)
- **Don't mix paradigms** in same session — pick one per task

## 5. Cite

- Anthropic docs: code.claude.com/docs/en/agent-teams
- Issue 37213: github.com/anthropics/claude-code/issues/37213 (fellanH, dup'd)
- Related issues mentioned: #24798, #29086 (architecture proposal), #24947 (`claude inject`)
- maw v2.0.0-alpha.42 (build 2026-04-16) reference: `maw --help`

🔥⚗️ — MLBOY (/learn directive 2026-05-11 P'Nat)
