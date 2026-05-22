---
type: learning
topic: maw team-agent architecture — identity/task separation, OS process model, hierarchy design
source: pnat
maturity: raw
retrieval_terms: [identity-task-layer, process-model, parent-child-hierarchy, session-persistence, async-team-coordination]
date: 2026-05-22
---

# maw team-agent Architecture Analysis

## The Two-Layer Model

```
┌──────────────────────────────────────────────┐
│              IDENTITY LAYER                   │
│  --system-prompt "You are a code reviewer"    │
│  Persists entire session                      │
│  = WHO you are, HOW you behave               │
├──────────────────────────────────────────────┤
│              TASK LAYER                       │
│  --mission "Review PR #42"                    │
│  One-time per message                         │
│  = WHAT to do right now                      │
└──────────────────────────────────────────────┘
```

### OS Process Model Analogy

| OS Concept | maw team-agent Equivalent |
|------------|---------------------------|
| Executable binary | `--system-prompt` (persistent identity) |
| argv / stdin | `--mission` (one-time task input) |
| PID | `--session-id` |
| PPID | `--parent-session-id` |
| Process group | Team (`--team-name`) |
| fork() | `maw team-agent spawn` |
| kill() | `maw team-agent shutdown` |
| pipe / IPC | `maw team-agent msg` |

This is not just analogy — Claude Code's `--parent-session-id` creates real hierarchy in the runtime. The parent session can:
- Track which children it spawned
- Receive status from children
- Coordinate work across the team

### Auto-resolve: parent-session-id is IMPLICIT

> P'Nat (msg_id 1507206952608862320): "ไม่ต้องระบุ parent ตอน spawn — มัน auto-resolve จาก config.sessionId ของ team"

When you `spawn`, the plugin reads `config.sessionId` from the team config and passes it as `--parent-session-id` automatically. You never manually specify `--parent-session-id`.

```bash
# create locks session-id as team identity
SESSION_ID=$(maw team-agent uuid --bare | head -1)
maw team-agent create my-team "desc" --session-id "$SESSION_ID"

# spawn auto-resolves parent from config.sessionId
maw team-agent spawn my-team worker@/tmp/work:cyan --mission "..."
# internally: --parent-session-id = $SESSION_ID (from config)
```

Optional: `--session-id` at create time. If omitted → auto-generated.

### Hierarchy Topology

```
Lead (shell-lead)
├── session-id: <lead-uuid>       ← fixed at create time
├── parent-session-id: null (root)
│
├── reviewer
│   ├── session-id: <child-uuid-1>       ← auto-generated at spawn
│   ├── parent-session-id: <lead-uuid>   ← AUTO from config.sessionId
│   └── system-prompt: "security reviewer"
│
├── writer
│   ├── session-id: <child-uuid-2>
│   ├── parent-session-id: <lead-uuid>   ← AUTO
│   └── system-prompt: "technical writer"
│
└── reader
    ├── session-id: <child-uuid-3>
    ├── parent-session-id: <lead-uuid>   ← AUTO
    └── system-prompt: (none)
```

## Three Spawn Patterns

### Pattern 1: Identity + Task (most common)
```bash
maw team-agent spawn my-team reviewer@/tmp/repo:green \
  --system-prompt "You are a security reviewer" \
  --mission "Review last 3 commits"
```
Agent starts immediately with both WHO and WHAT.

### Pattern 2: Identity only (deferred task)
```bash
maw team-agent spawn my-team writer@/tmp/docs:cyan \
  --system-prompt "You are a technical writer"
# Later:
maw team-agent msg my-team writer "Document the auth flow"
```
Agent spawns idle with identity, waits for task. This enables **async team coordination** — spawn your team first, assign work when ready.

### Pattern 3: Task only (ad-hoc worker)
```bash
maw team-agent spawn my-team reader@/tmp/work:magenta \
  --mission "Read README.md and reply with project name"
```
No persistent identity. Simple one-shot worker.

## Connection to Wind's Autonomous Loop

```
Wind's gale-oracle loop:
  /goal → spawn workers → monitor → cleanup → /rrr → idle
                ↑
    maw team-agent is THIS layer
```

| Unified-loop Tier | maw team-agent Role |
|-------------------|---------------------|
| Tier 1 (single agent) | No team-agent needed |
| Tier 2a (coordinated) | `spawn` with `--system-prompt` + `--mission` |
| Tier 2b (parallel swarm) | Multiple `spawn` with same `--mission` |
| Tier 3 (persistent) | `spawn` with identity only → `msg` over time |

## Security Consideration

`--dangerously-skip-permissions` on spawn gives child **full tool access without approval prompts**. In a team context:
- Lead spawns reviewer with `--dangerously-skip-permissions`
- Reviewer can write/delete any file, run any command
- No per-action approval from human

Design question: should permission boundaries be per-agent or inherited from lead? Current design inherits from spawn command — no per-agent sandboxing.

## Session Persistence (Recovery)

Session IDs stored in `~/.claude/teams/<name>/config.json` enable:
- **Resume after crash**: re-attach to existing session-id
- **Audit trail**: know which agent did what via session history
- **Cross-reference**: link agent output back to team lead's context
