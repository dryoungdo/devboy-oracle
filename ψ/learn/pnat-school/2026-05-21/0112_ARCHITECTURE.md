---
type: learning
topic: Team-Tile Architecture — 6 seams, wire format, filesystem transport
source: pnat-gist
maturity: emerging
retrieval_terms: [teammate-message, wire-format, seam, xml-protocol, filesystem-transport, shutdown]
date: 2026-05-21
---

# Architecture: Team-Tile Bootstrap

## Wire Format

Regex (extracted from claude.exe binary):
```
\s+teammate_id="([^"]+)"(?:\s+color="([^"]+)")?(?:\s+summary="([^"]+)")?>\n?([\s\S]*?)\n?</
```

XML envelope:
```xml
<teammate-message teammate_id="<role>" color="<color>" summary="<one-line>">
  <body — markdown OR JSON>
</teammate-message>
```

### 5 Body Shapes (emergent, no schema)

| # | Shape | When |
|---|-------|------|
| 1 | Verbose markdown | Full analysis replies |
| 2 | Short text ack | Simple acknowledgments |
| 3 | JSON `idle_notification` | Teammate waiting for work |
| 4 | JSON `shutdown_request` | Lead requesting shutdown |
| 5 | JSON `shutdown_approved` | Teammate confirming shutdown |

### Missing from Protocol
- **No timestamp** — ordering via filesystem mtime only
- **No message_id** — no request-response correlation
- **No type discriminator** — body shape detected by content parsing

## Filesystem Transport

Unique among multi-agent frameworks: Claude Teams uses **filesystem as message transport**.

```
~/.claude/teams/<team>/
├── config.json          # team registry
├── inboxes/
│   ├── <role-a>.json    # pending messages for role-a
│   └── <role-b>.json    # pending messages for role-b
└── tasks/               # shared task list
```

**Strength**: Messages survive process crashes (tmux pane can be re-attached).
**Weakness**: No flock — two simultaneous writes to same inbox = last-write-wins race.

## The 6 Seams

| # | Seam | Severity | Description | Mitigation |
|---|------|----------|-------------|------------|
| 1 | maw-workon ↔ team substrate | Medium | /maw-workon workers lack formal team membership | Proposed /maw-team-workon (open) |
| 2 | GitHub issues ↔ teams | Low | No formal binding between issues and teams | Manual assignment; babysit-prs pattern |
| 3 | XML render requires --agent-id | Low | Non-teammate sessions never see teammate-message | By design — correct scoping |
| 4 | Cross-session = auth boundary | Medium | Filesystem access = message injection capability | Unix user isolation only |
| 5 | maw ls blind to raw-spawn | Medium | Fleet dashboard shows incomplete picture | maw-js #1837 closes this |
| 6 | shutdown_approved ≠ process kill | **High** | Zombie processes after TeamDelete | tmux kill-pane follow-up required |

### Seam 6 Deep Dive (highest severity)
- `shutdown_approved` signals the framework to stop coordinating
- Does NOT send SIGTERM/SIGKILL to the claude.exe process
- Teammate may linger in tmux pane consuming tokens
- **Required mitigation**: always `tmux kill-pane -t <addr>` after shutdown_approved

## Security Model

- `--dangerously-skip-permissions` propagates from lead to ALL teammates
- All teammates run as same Unix user — no per-teammate sandboxing
- Any teammate can write to any file the user owns
- Any teammate can inject messages into other teammates' inboxes (Seam 4)
- Security boundary = OS user isolation, not protocol-level

## Comparison to Other Wire Formats

| Dimension | Claude Teams | OpenAI Swarm | CrewAI | LangGraph |
|-----------|-------------|-------------|--------|-----------|
| Transport | Filesystem | In-memory | In-memory | State graph |
| Addressing | teammate_id | Agent handoff | Role delegation | Node names |
| Persistence | File-survived | None | None | Checkpoint |
| Schema | None (emergent) | Typed functions | Pydantic models | TypedDict |
| Multi-machine | No | No | No | Yes (remote) |

## Why maw Verbs, Not Raw tmux

> P'Nat's iotboy learning (2026-05-11): tmux send-keys = anti-pattern.
> 4 failure modes: no federation log, no delivery receipt, hooks bypass, silent failure.

`maw tile` solves seam #3: panes created by `maw tile` are registered in maw's agents map with canonical addresses. Raw `tmux split-window` panes are invisible to `maw ls`, `maw peek`, `maw hey`, and the federation UI.
