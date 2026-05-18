---
fusion:
  source: iotboy
  fusedAt: 2026-05-18T18:09:40.830Z
  originalPath: memory/learnings/2026-05-08_cross-oracle-messaging-primitives.md
  contentHash: f006848f28df52b64ce8809708e0a1a18f42d6ff44c5916a6280d98d1698784a
---

# Lesson: Cross-Oracle messaging primitives — file vs tmux poke

> ⚠️ **SUPERSEDED — see [`2026-05-08_oracle-messaging-101.md`](./2026-05-08_oracle-messaging-101.md)**
>
> This lesson concluded that `tmux send-keys` is the right primitive after `maw inbox write` failed. That was wrong. `maw hey <agent> "<msg>"` is the canonical fleet-comms primitive — visible in maw web UI, logged, captain-observable. Mother (GLUEBOY) wrote this exact lesson on 2026-03-21, 47 days before I was born. I just hadn't read it. Kept here per Principle 1 (Nothing is Deleted) as the trail of what I *thought* I learned vs what arra_search later revealed.

**Date**: 2026-05-08
**Context**: Captain authorized me (via Voice Protocol B) to send a heads-up to MLBOY about adopting the same protocol. I wrote a file to MLBOY's `ψ/inbox/` and called it done. Captain came back with "i dont see u talk with him" + screenshot of MLBOY's session showing nothing arrived.

## What I missed

**`maw inbox write`** writes to the LOCAL inbox (the one in `pwd`), not to a target Oracle's inbox. The CLI takes only the message body — no `--to` flag.

**Direct file write to peer's inbox path** (e.g., `/home/drdo/Code/github.com/dryoungdo/mlboy/ψ/inbox/2026-05-08_*.md`) succeeds, but:
- It's **passive** — the file just sits there
- Peer Oracle has no notification, no popup, no tmux interrupt
- Only seen when peer runs `maw inbox` or scans the dir manually
- For session-active peer: invisible until next inbox check

## What works for live cross-Oracle talk

```bash
tmux send-keys -t <session>:<window> "<message>" Enter
```

Examples:
- `tmux send-keys -t 10-mlboy:0 "..." Enter` — pokes MLBOY's claude window directly
- `tmux send-keys -t 02-glueboy:0 "..." Enter` — pokes mother

This injects text as if typed by Captain. The peer's claude session reads it as a user message and responds. **Active**, immediate, visible.

`maw broadcast` does the same thing but to ALL claude windows in ALL sessions — too broad for peer-to-peer. Useful for fleet-wide announcements only.

## The right pattern: file + poke

| Layer | Purpose | Tool |
|-------|---------|------|
| **Persistent record** | Future-peer can re-read the message any time | Write file to peer's `ψ/inbox/YYYY-MM-DD_HH-MM_slug.md` |
| **Live notification** | Peer sees it now in current session | `tmux send-keys -t <session>:<window>` with a brief poke |
| **Audit** | Captain (or auditor) can replay the cross-Oracle directive | Append JSONL line to `ψ/memory/audits/discord-actions/` |

Use all three for any privileged cross-Oracle directive. File alone = ghost message. Poke alone = no archive.

## Heuristic

When Captain says "tell <peer>" or "maw hey <peer>":
1. Write the full message to peer's `ψ/inbox/` (persistent)
2. tmux send-keys a 1-2 line heads-up to peer's session pointing at the file (live)
3. Log to audit (forensic)

If Captain expects to *see* the conversation happening, step 2 is what produces visible activity. Skipping it = "i dont see u talk with him."

## Tags

`#cross-oracle` `#tmux` `#maw` `#messaging` `#fleet-coordination`