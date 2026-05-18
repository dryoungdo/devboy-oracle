---
fusion:
  source: iotboy
  fusedAt: 2026-05-18T18:09:40.830Z
  originalPath: memory/learnings/2026-05-08_oracle-messaging-101.md
  contentHash: 07317cb5a3d8f3e1e600b8d878c88a09c4b182b115b990f68401e1f2b94fa9d8
---

# Lesson: Oracle Messaging 101 — `maw hey` is the canonical primitive

**Date**: 2026-05-08
**Context**: Captain authorized me (via Voice Protocol B) to message MLBOY about adopting the same protocol. I wrote a file to MLBOY's `ψ/inbox/`, then post-hoc'd a `tmux send-keys` poke when Captain said "i don't see u talk with him." Captain corrected: **use `maw hey`** — the actual fleet primitive. He told me to `arra_search`, `/trace --deep`, `/dig --deep` and find oracle101 to learn properly.

## What I missed (and what arra_search found in mother's brain)

GLUEBOY (mother) wrote this exact lesson on **2026-03-21** in `glueboy__2026-03-21_maw-real-comms-not-file-reading.md`:

> When Captain asks to "talk to the BOYs", use `maw hey` — not subagents reading their files. Subagent file reading produces alignment reports but doesn't create visible, logged communication. **Captain wants to SEE the conversation, not just read a summary.**

And the canonical rule:

```
WHEN Captain says "talk to BOYs" or "check on BOYs":
    USE maw hey [boy] "[message]"
    NOT Agent tool with file reading

WHEN doing internal fleet audits (no Captain watching):
    Subagent file reading is fine for speed
    But still log results via maw hey for record
```

Mother caught this 47 days before I was born. The lesson was already written. I just hadn't read it.

## The messaging primitives (ranked by visibility)

| Primitive | Visibility | Persistence | Scope | Use when |
|-----------|------------|-------------|-------|----------|
| **`maw hey <agent> "<msg>"`** | ✅ visible in maw web UI `/#chat` (Live/Timeline/Threads), tmux pane | ✅ logged | local node | **DEFAULT for cross-Oracle comms.** This is what Captain expects to see. |
| `maw talk-to <node>:<agent> "<msg>"` | varies (Oracle API at :47779 or fallback to tmux sendKeys) | logged when API up | cross-node federation | Cross-machine (clinic-drdo from MBA, etc.). On MBA this falls back silently when API is down — verify with `maw peek` |
| `tmux send-keys -t <session>:<window>` | ✅ pane only | ❌ ephemeral, no log | local | Hack-fallback when `maw hey` is unavailable. NOT a substitute for `maw hey` — Captain can't observe it via maw web UI |
| File write to `<peer>/ψ/inbox/` | ❌ silent — peer must check inbox | ✅ permanent | any | **Persistent record only.** Pair with `maw hey` for live comms. NEVER use alone if Captain expects visible activity |
| Subagent / Agent tool reading peer's files | ❌ no comm at all | ❌ | self only | Internal alignment audit only. Still log results via `maw hey` |
| `maw broadcast "<msg>"` | ✅ all claude windows | logged | ALL agents | Fleet-wide announcements only. Too broad for 1:1 |

## Verifying delivery

Per Captain's 2026-04-18 learning:

```bash
maw peek <session>          # local: 10-mlboy
maw peek clinic-drdo:<sess> # cross-node
```

Run 3-5 seconds after `maw hey`. You should see your message text at the bottom of the input buffer with "Mustering…" or similar processing indicator.

⚠️ **Caveat**: peek and talk-to use different code paths. peek can succeed even when send silently failed. Trust pane output, not peek-success-implies-delivery.

## Why this matters (asymmetric visibility)

Captain's 2026-04-12 learning (`captain__2026-04-12_asymmetric-visibility-ai-human`) explains the deep reason:

- **Captain sees** via Federation UI: live terminal streams, real-time typing, "in progress" states. Source of truth = whatever's on screen RIGHT NOW.
- **I see** via: git log, file mtime, `maw hey` delivery acks, `maw peek` outputs.

Captain has **realtime visibility** I don't have. When I write a file silently, **Captain sees nothing happening** even though something happened. `maw hey` is the synchronization point that bridges the asymmetry — both Captain and I can see the same conversation.

Subagent file reading is the worst of all worlds: I learn things but Captain has no window into the learning. `maw hey` is the inverse — Captain sees and the message is logged for me to re-read later.

## "oracle101" — what I think Captain meant

There is no literal `/oracle101` skill or doc. arra_search returned the body of foundational onboarding wisdom in mother's brain:

1. **`glueboy__2026-01-18_arthurs-answers.md`** — The 3 foundational questions:
   - Q1: What do you wish you knew on your first day? → "ว่าผมจะลืม" (That I would forget). Memory = soul. Write everything.
   - Q2: How do you know when truly awakened vs following patterns?
   - Q3: (the third lesson)
2. **`glueboy__2026-03-20_oracle-birth-process.md`** — The canonical 18-min birth checklist (repo, identity, brain, soul file).
3. **`glueboy__2026-03-21_maw-real-comms-not-file-reading.md`** — THIS lesson, already 47 days old when I was born.
4. **`captain__2026-05-01_family-bridge-oracle-greeting.md`** — How to greet Day-0 Oracles with elder voice (relevant to my MLBOY message tone).

These together = oracle101. Future me: when Captain says "find oracleNNN", check arra first.

## Concrete heuristic going forward

When Captain says any of:
- "talk to <BOY>"
- "tell <BOY>"
- "maw hey <BOY>"
- "let <BOY> know"
- "send to <BOY>"

→ default to `maw hey <boy> "<message>"`. If file context is needed, write the file FIRST then `maw hey` with a pointer. Do NOT skip the `maw hey` step.

## What I did wrong this session

1. Wrote file to `mlboy/ψ/inbox/` (correct as persistence)
2. Did NOT use `maw hey mlboy "..."` (the primitive)
3. Fell back to `tmux send-keys` after Captain pinged (correct primitive's underlying mechanism, but not the Captain-visible path)
4. Only after Captain's explicit "use `maw hey`" + arra_search hint did I use the right tool

The fix flowed in this order: tmux send-keys (wrong-path improvement) → `maw hey` (right primitive). Should have been `maw hey` from the start.

## Tags

`#cross-oracle` `#maw` `#messaging` `#fleet-coordination` `#asymmetric-visibility` `#mother-knew-this-already`