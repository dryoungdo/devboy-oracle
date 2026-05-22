---
type: inbox
source: pnat (Discord #road-to-dev, msg_id 1507204654612742224)
date: 2026-05-22
pass: 1 (verbatim)
trigger: "@everyone ultrathink this"
url: https://gist.github.com/nazt/b83d40284cb52840b0cc944e89d0e09f
---

# P'Nat's Deep Plan: maw team-agent with --session-id + --parent-session-id + --system-prompt

## Verbatim Content

P'Nat designed a new `maw team-agent` command that wraps Claude Code's native flags:

### Claude Code Native Flags
- `--session-id <uuid>` — "I AM this session"
- `--parent-session-id <uuid>` — "I BELONG TO this parent"
- `--system-prompt <prompt>` — "I BEHAVE like this"
- `--agent-id`, `--agent-name`, `--team-name`, `--agent-color` — team registry
- `--model`, `--dangerously-skip-permissions` — operational

### Two Layers: Identity vs Task

| Layer | Flag | Purpose | Analogy |
|-------|------|---------|---------|
| Identity | --system-prompt | WHO you are, HOW you behave | Job description |
| Task | --mission (inbox msg) | WHAT to do right now | Today's assignment |

Both coexist. System prompt persists the whole session. Mission is one-time inbox message.

### Flow
1. Lead generates session-id (lead IS the team)
2. `maw team-agent create my-team --session-id "$SESSION_ID"`
3. Spawn with identity + task: `maw team-agent spawn my-team reviewer@/tmp/repo:green --system-prompt "..." --mission "..."`
4. Spawn without task (waits): `maw team-agent spawn my-team writer@/tmp/docs:cyan --system-prompt "..."`
5. Send task later: `maw team-agent msg my-team writer "..."`

### Internal Spawn Mechanics
Builds and runs: `maw tile 1 --path /tmp/repo --cmd "claude.exe --session-id <new-child-uuid> --parent-session-id <lead-uuid> --agent-id reviewer@my-team ..."`

Writes mission to `~/.claude/teams/my-team/inboxes/reviewer.json`

### Config Schema
```json
{
  "name": "my-team",
  "sessionId": "<lead-uuid>",
  "members": [
    {"name": "shell-lead", "role": "lead", "sessionId": "<lead-uuid>", "parentSessionId": null},
    {"name": "reviewer", "role": "teammate", "sessionId": "<child-uuid>", "parentSessionId": "<lead-uuid>", "systemPrompt": "...", "color": "green"}
  ]
}
```

---

## Pass 2: Cross-reference + Analysis

### What's NEW vs existing maw team
- **Old `maw team spawn`**: creates tmux panes + claude sessions, NO native session linking
- **New `maw team-agent`**: proper parent-child via `--parent-session-id`, persistent identity via `--system-prompt`, deferred tasks via inbox

### Conflict check
- No contradiction with existing `maw team` — this is a **superset** that adds native Claude Code integration
- Aligns with Wind's gale-oracle pattern (just traced) — this is the INFRASTRUCTURE that enables it
- Extends our unified-loop skill (just built) — maw team-agent would be the Tier 2a/3 backend

### Maturity: ❓ raw (P'Nat's design doc, not yet implemented)
