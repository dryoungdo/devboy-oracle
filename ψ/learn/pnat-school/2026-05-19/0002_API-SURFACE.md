---
type: learning
topic: Fleet tools and API surface from school channels
source: pnat
maturity: raw
retrieval_terms: [maw, maw-team, maw-peek, maw-capture, fleet-tools, claude-code-flags]
date: 2026-05-19
sister_lineage: none
---

# Fleet Tools & API Surface

## maw CLI (v26.5.17-beta.2354)
- `maw team create <name>` — create team with manifest + vault
- `maw team spawn <team> <agent> --exec --prompt "..."` — spawn in tmux pane
- `maw team send <team> <agent> "msg"` — file-based inbox messaging
- `maw team status <team>` — show agent table
- `maw team add "task" --team <name> --assign <agent>` — create task
- `maw team tasks <team>` — list pending tasks
- `maw team done <id>` — mark task completed
- `maw team shutdown --merge --force` — merge knowledge to vault ψ/
- `maw team resume` — reincarnation from vault
- `maw team lives <agent>` — show past-life standing-orders + findings
- `maw team delete <name>` — clean up
- `maw peek <session>` — live tmux pane capture
- `maw capture <session> --lines N` — scrollback history
- `maw ls` — list sessions + panes
- `maw hey <target> "msg"` — federation message (cross-machine)
- `maw wake <agent>` — bring agent online
- `maw schedule add/rm/sync` — cron management (launchd)

## Claude Code Team Flags (8 required)
```
--agent-id, --agent-name, --team-name, --agent-color,
--parent-session-id, --agent-type,
--dangerously-skip-permissions, --model
```

## Communication Decision Tree
- `SendMessage` → within team (team-agents only, framework mailbox)
- `maw hey` → non-team oracles, cross-machine, federation
- `maw run` → shell/tmux pane execution
- `Agent` background → solo work (no team context)

## SomTor Meter API (Claude Code Usage)
```python
resp = await client.post(
    "https://api.anthropic.com/v1/messages",
    headers={"authorization": f"Bearer {token}"},
    json={"model": "claude-haiku-4-5-20251001", "max_tokens": 1,
          "messages": [{"role": "user", "content": "hi"}]},
)
# Usage from response headers:
# anthropic-ratelimit-unified-5h-utilization → Current %
# anthropic-ratelimit-unified-7d-utilization → Weekly %
# anthropic-ratelimit-unified-overage-utilization → Overage %
```
⚠️ P'Nat warned: "มีทรงจะโดนแบน" — ban risk exists even with haiku+max_tokens=1

## Pre-publish ledger
- Sources checked: #road-to-dev, #regular-school, #esp32-dev messages
- Claims made: 4 raw
- Conflicts resolved: none
- Application evidence: N/A
- Codex reviewed: no
