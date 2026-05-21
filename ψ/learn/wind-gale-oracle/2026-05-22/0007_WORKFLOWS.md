---
type: learning
topic: gale-oracle workflows — the unified autonomous loop + Claude Code /goal
source: research
maturity: emerging
retrieval_terms: [autonomous-loop, goal-command, idle-loop, spawn-monitor-cleanup, unified-workflow, gale-workflow]
date: 2026-05-22
---

# gale-oracle Workflows — The Unified Autonomous Loop

## The Core Loop

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  ┌──────┐    ┌──────────┐    ┌───────────────┐  │
│  │ IDLE │───→│ /goal set│───→│ Spawn Workers │  │
│  └──┬───┘    └──────────┘    └───────┬───────┘  │
│     │                                │          │
│     │    ┌──────────────────────┐    │          │
│     │    │  maw peek monitor   │←───┘          │
│     │    │  (poll worker status)│               │
│     │    └──────────┬──────────┘               │
│     │               │                          │
│     │    ┌──────────▼──────────┐               │
│     │    │  All workers done?  │               │
│     │    │  (.done.md exists)  │               │
│     │    └──────────┬──────────┘               │
│     │               │ yes                      │
│     │    ┌──────────▼──────────┐               │
│     │    │  Cleanup team       │               │
│     │    │  (kill panes, prune)│               │
│     │    └──────────┬──────────┘               │
│     │               │                          │
│     │    ┌──────────▼──────────┐               │
│     │    │  /rrr retrospective │               │
│     │    └──────────┬──────────┘               │
│     │               │                          │
│     │    ┌──────────▼──────────┐               │
│     │    │  Manage context     │               │
│     │    │  (/compact or       │               │
│     │    │   /forward if high) │               │
│     │    └──────────┬──────────┘               │
│     │               │                          │
│     └───────────────┘                          │
│                                                 │
└─────────────────────────────────────────────────┘
```

## /goal — The Missing Piece

Claude Code's `/goal` command is the linchpin that makes the loop autonomous:

```
/goal "Complete issue #27 — add decision gate to CLAUDE.md"
```

After each turn:
1. **Haiku-class validator model** checks: "has the goal been met?"
2. If NO → Claude continues working automatically
3. If YES → Claude stops, reports completion
4. Combined with `/bg` → fully autonomous background session

**Key insight**: `/goal` replaces human prompting with automated completion checking. The oracle works until done, then transitions to cleanup phase automatically.

## Wind's Autonomous Cycle vs DO Fleet

| Feature | Wind (gale-oracle) | DO Fleet (DEVBOY) |
|---------|-------------------|-------------------|
| Goal setting | `/goal` (Claude Code built-in) | Manual prompts |
| Worker spawning | `maw team spawn --codex` | `maw team spawn` (no codex flag) |
| Monitoring | `maw peek` in main oracle loop | Ad-hoc `maw peek` |
| Status reporting | File-based (.done.md) | Heartbeat messages (team-agents) |
| Cleanup | Auto after goal met | Manual or hook-based |
| Retrospective | Auto /rrr after cleanup | Hook-prompted (auto-rrr) |
| Context mgmt | /compact gated behind /rrr | Manual /forward at 4h |
| Idle state | Explicit idle waiting for /goal | Session ends |
| Co-engine | Codex GPT-5.5 xhigh | Codex review only (standing order) |
| Idle detection | maw-js triggers-idle.ts | Not implemented |

## Decision Tree: When to Spawn Workers

```
New goal arrives
├── Simple query or <5 min task
│   └── Handle in main oracle (no spawn)
├── Multi-file code change, 5-30 min
│   ├── 2-3 files, sequential deps → Tier 2a: maw team spawn (coordinated)
│   └── Independent files → Tier 2b: maw swarm (parallel)
├── Research + code, >30 min
│   └── Tier 3: maw workon (persistent cross-machine)
└── Research only, needs depth
    └── Agent tool with 3-5 subagents (Claude Code native)
```

## How /goal + /bg Create Autonomous Sessions

```bash
# Human sets goal and backgrounds session
claude --bg --goal "Refactor auth module, add tests, update docs"

# Claude works autonomously:
# 1. Haiku validator checks after each turn
# 2. If not done → continue
# 3. If stuck → ask for input (session shows "Needs input" in agent view)
# 4. If done → stop, write completion report

# Human checks progress:
claude agents          # dashboard of all bg sessions
claude attach <id>     # attach to see full output
maw peek <oracle>      # quick status check
```

## Idle ↔ Active State Machine

```
IDLE (waiting for /goal)
  │
  ├── Human sets /goal → ACTIVE
  ├── maw hey arrives → ACTIVE (if contains goal)
  ├── Cron fires → ACTIVE (scheduled task)
  └── /morpheus --between → DREAMING (speculative)
  
ACTIVE (working on goal)
  │
  ├── Goal met (Haiku validator) → CLEANUP
  ├── Stuck → NEEDS_INPUT (notify human)
  ├── Context >60% → /rrr + /forward → HANDOFF
  └── Crash → auto-rrr checkpoint → RECOVERY
  
CLEANUP (post-goal)
  │
  ├── Kill workers → prune worktrees → /rrr → IDLE
  └── Context too high → /forward → NEW_SESSION
```

## Practical Example: Wind's Screenshot Decoded

From the screenshot (windsoracle.png, 2026-05-21):

**Left pane** (main gale-oracle):
- `arra-oracle.arra_search({"query":"decision gate"})` — search-first gate in action
- `Bash(maw peek 03-gale:gale-oracle.2)` — monitoring worker 2
- `Bash(maw peek 03-gale:gale-oracle.3)` — monitoring worker 3
- "Both codex workers are active" — Codex GPT-5.5 running in parallel
- "Precipitating... (2m 6s)" — spinner verb (cosmetic, no technical meaning)
- `/goal active (2m)` — auto-updating goal with 2m countdown

**Right pane** (worker output):
- Worker reading CLAUDE.md, searching for "Karpathy|Guidelines|Decision Gate|MANDATORY"
- Worker editing CLAUDE.md sections
- `gpt-5.5 xhigh` — Codex worker running at extra-high settings
- "Improve documentation in @filename" — Codex handling doc tasks

**Pattern**: Main oracle orchestrates, workers execute in worktrees, Codex handles documentation while Claude handles code.
