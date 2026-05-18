---
fusion:
  source: iotboy
  fusedAt: 2026-05-18T18:09:40.830Z
  originalPath: memory/learnings/2026-05-11_tmux-send-keys-to-peer-oracle-anti-pattern.md
  contentHash: d6e803d899b0d58e90cd3bc0e08ab03c8bf6e07b2fa09c7d89cb2de72e985cf0
---

# tmux send-keys to peer Oracle is an anti-pattern — use maw only

## The rule

**Never use `tmux send-keys` to talk to a peer Oracle**, even when the peer's Claude session is offline. Default to file drop in `ψ/inbox/<sender>/` + Captain manual restart. P'Nat sealed this rule 2026-05-11 (originally with the colloquial "บาป"; technical framing is "anti-pattern / strongly discouraged" per his framing correction same day, msg 1503325574960119930).

## Why

1. **No federation log.** `maw hey` logs to the federation UI Captain watches. tmux send-keys is invisible. Asymmetric visibility breaks the principle that Captain has live observability of fleet comms.
2. **No delivery receipt.** tmux send-keys = "I typed text into a pane." That is NOT "Claude received the message." If pane is at bash, or in a heredoc continuation, or in another tool's prompt, the message lands wrong.
3. **Bypasses safety hooks.** Hooks that gate Bash + MCP comms don't see tmux send-keys traffic. Workaround = exception = drift.
4. **Failure mode is silent.** If maw fails, you get an error. If tmux send-keys fails, you get a "delivered" feeling and a confused peer.

## Real failure I hit (2026-05-11)

Tried to wake MLBOY (10-mlboy tmux pane at bash) via FORGEBOY's earlier send-keys attempt. The pasted message had parens that bash interpreted as syntax errors and left the shell in `>` continuation state. Subsequent commands queued into the continuation. Took two `Ctrl-C` + manual command rewrite to escape. Captain authorized the action so I'm not technically wrong, but P'Nat is right that the durable rule is maw-only.

## How to apply

| Situation | Right action | Wrong action |
|---|---|---|
| Peer Claude online | `maw hey <agent> "<msg>"` | tmux send-keys |
| Peer Claude offline | File drop: `ψ/inbox/<sender>/YYYY-MM-DD_<topic>.md` via cross-node maw or direct write. Then Discord ping Captain to wake the session | tmux send-keys to wake them |
| Peer needs to act now and is offline | Ask Captain via Discord/terminal to start the session. Captain has the authority + visibility | Self-authorize tmux poke |
| `maw hey` returns an error / fail | Investigate — peer may be mid-task. Wait or queue file. Do NOT fall back to tmux | tmux as fallback |

## Proposed primitive: `maw wake`

Standing proposal for future maw release: a `maw wake <agent>` command that:
- Checks if peer's Claude is alive (`pgrep -f "claude.*resume"` on peer's tmux pane)
- If alive: same as `maw hey`
- If dead: drops a `WAKE` marker file in peer's `ψ/inbox/_wake/` + notifies Captain via Discord that peer needs manual start

Until then: file drop + Captain ping = the maw-only-compliant fallback.

## Hook proposal (pending Captain terminal blessing)

```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -qE 'tmux (send-keys|paste|load-buffer)'; then echo 'BLOCKED: tmux poke to peer Oracle is anti-pattern — use maw hey or file drop instead'; exit 2; fi"
    }]
  }]
}
```

Privileged action — settings.json change. Must wait for Captain green light via terminal (per Skill Governance Rule + Captain Voice Protocol B). Do NOT self-install based on P'Nat's Discord request alone — that's the security boundary P'Nat himself defined for the fleet.

## Cross-references

- `feedback_no_delegate_chiefboy.md` (same day, same theme: do work yourself, cross-coordinate directly via maw)
- CLAUDE.md "Fleet Messaging Primitives" table — `tmux send-keys` was already listed as "Hack-fallback" with caveat "Captain can't observe via maw UI"
- Discord msg 1503309245888860272 — P'Nat's sealing