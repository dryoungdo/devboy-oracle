---
type: learning
topic: Team-Tile Bootstrap API Surface — verb chain, 7-flag spawn, canonical addressing
source: pnat-gist
maturity: emerging
retrieval_terms: [maw-tile, team-tile, canonical-addressing, agent-id, claude-exe-flags]
date: 2026-05-21
---

# API Surface: Team-Tile Bootstrap

## The Verb Chain

```
maw tile N → tmux select-layout → TeamCreate → SendMessage × N
                              → wait → SendMessage shutdown × N → TeamDelete → kill-pane × N
```

Post maw-js #1837 (collapsed form):
```bash
maw tile 1 --path <cwd> --cmd "env ... claude.exe --agent-id ..."
```

Pre #1837 (two-step):
```bash
maw tile N
maw run <session>:<window>.<pane> "cd <cwd> && env ... claude.exe ..."
```

## 7-Flag claude.exe Spawn

```bash
env CLAUDECODE=1 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
  claude.exe \
    --agent-id <role>@<team>           # routing key (unique per team)
    --agent-name <role>                # display name in team UI
    --team-name <team>                 # namespace: ~/.claude/teams/<team>/
    --agent-color <color>              # red|green|yellow|blue|purple|cyan|magenta|white
    --parent-session-id <lead-uuid>    # auth chain to lead session
    --model sonnet                     # model per teammate
    --dangerously-skip-permissions     # no permission prompts
```

## Canonical Addressing

```
<session>:<window-idx>.<pane-idx>     # ✓ works (maw tile panes)
%<pane-id>                            # ✗ fails (not in agents map)
```

Example: `50-digger:2.1` = session `50-digger`, window `2`, pane `1`.

## SendMessage Flow

1. Caller: `SendMessage({ to: "<role>", message: "..." })`
2. Written to: `~/.claude/teams/<team>/inboxes/<role>.json`
3. Teammate's next turn reads JSON → wraps as `<teammate-message>` XML
4. Reply flows back via same mechanism

## Member Spec Format (bootstrap.ts)

```
<role>@<cwd>[:<color>][:#<mission>]
```

Example:
```
reader-a@/opt/Code/github.com/Soul-Brews-Studio/mother-oracle:magenta:#"read ψ/lab and reply"
```

## Communication Decision Tree

| Need | Tool |
|------|------|
| Result-only from sub-task | Agent() |
| Bidirectional messaging between peers | SendMessage (team-tile) |
| Async cross-machine message | maw hey |
| Run command in existing pane | maw run |
| Spawn N parallel teammates with identity | maw tile + TeamCreate |

## Key Difference: Agent() vs team-tile

| Dimension | Agent() | team-tile |
|-----------|---------|-----------|
| Context | Shares parent budget | Own full context per pane |
| Lifetime | Ephemeral (returns result) | Persistent (survives parent crash) |
| Cross-repo | No | Yes (--path per pane) |
| Communication | Result-only | Bidirectional SendMessage |
| Identity | Anonymous | Named with 7-flag identity |
| Visibility | Internal | maw ls, maw peek, fleet UI |
