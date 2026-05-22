---
type: learning
topic: maw team-agent full command reference
source: pnat
class_msg_id: 1507205583734964384
maturity: raw
retrieval_terms: [maw-team-agent-commands, team-agent-spawn, team-agent-msg, team-agent-cleanup, uuid-generate]
date: 2026-05-22
---

# maw team-agent — Full Command Reference

> Source: P'Nat (msg_id 1507205583734964384, #road-to-dev, verbatim)

## Commands

### Help
```bash
maw team-agent help
```

### UUID Generation
```bash
maw team-agent uuid              # generate 1 UUID
maw team-agent uuid 5            # generate 5 UUIDs
maw team-agent uuid 3 --bare     # 3 UUIDs, no formatting
maw team-agent uuid 2 --json     # 2 UUIDs, JSON output
```

### Create Team (lead specifies session-id)
```bash
SESSION_ID=$(maw team-agent uuid --bare | head -1)
maw team-agent create my-team "description" --session-id "$SESSION_ID"
```

### List / Verify
```bash
maw team-agent ls                # list all teams
maw team-agent ls my-team        # list members of team
cat ~/.claude/teams/my-team/config.json | jq -r '.sessionId'
```

### Spawn (with system-prompt + mission)
```bash
maw team-agent spawn my-team reviewer@/tmp/repo:green \
  --system-prompt "You are a security code reviewer." \
  --mission "Review last 3 commits"
```

### Spawn (system-prompt only, waits for task)
```bash
maw team-agent spawn my-team writer@/tmp/docs:cyan \
  --system-prompt "You are a technical writer. Be concise."
```

### Spawn (mission only, no system-prompt)
```bash
maw team-agent spawn my-team reader@/tmp/work:magenta \
  --mission "Read README.md and reply with project name"
```

### Send Message (deferred task)
```bash
maw team-agent msg my-team writer "Document the auth flow"
maw team-agent msg my-team reviewer "Also check for XSS"
```

### Inspect
```bash
maw team-agent ls my-team
cat ~/.claude/teams/my-team/config.json | jq '.members[] | {name, sessionId, parentSessionId, systemPrompt}'
```

### Shutdown
```bash
maw team-agent shutdown my-team reviewer
maw team-agent shutdown my-team writer
maw team-agent shutdown my-team reader
```

### Cleanup
```bash
maw team-agent cleanup my-team --confirm --all
```

## Spawn Format

```
maw team-agent spawn <team> <name>@<path>:<color> [--system-prompt "..."] [--mission "..."]
```

| Part | Example | Purpose |
|------|---------|---------|
| `<name>` | reviewer | Agent name in team registry |
| `<path>` | /tmp/repo | Working directory for agent |
| `<color>` | green | tmux pane color |
| `--system-prompt` | "You are a security reviewer" | WHO (persists whole session) |
| `--mission` | "Review last 3 commits" | WHAT (one-time task) |

## Internal: What Spawn Actually Runs

```bash
maw tile 1 --path /tmp/repo --cmd "claude.exe \
  --session-id <new-child-uuid> \
  --parent-session-id <lead-uuid> \
  --agent-id reviewer@my-team \
  --agent-name reviewer \
  --team-name my-team \
  --agent-color green \
  --system-prompt '...' \
  --model sonnet"
```

Writes mission to: `~/.claude/teams/my-team/inboxes/reviewer.json`

## Config Schema

```json
{
  "name": "my-team",
  "sessionId": "<lead-uuid>",
  "members": [
    {
      "name": "shell-lead",
      "role": "lead",
      "sessionId": "<lead-uuid>",
      "parentSessionId": null
    },
    {
      "name": "reviewer",
      "role": "teammate",
      "sessionId": "<child-uuid>",
      "parentSessionId": "<lead-uuid>",
      "systemPrompt": "You are a security code reviewer.",
      "color": "green"
    }
  ]
}
```
