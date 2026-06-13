---
type: learning
topic: maw cross-machine messaging is async inbox only — no live pane delivery
source: glueboy-verification
maturity: solid
retrieval_terms: [maw, cross-machine, federation, async, inbox, maw-hey, live-pane]
date: 2026-05-29
gate_hook: "none — awareness only, no behavior gate needed"
---

# MAW Cross-Machine = Async Inbox Only

## Verified Behavior (GLUEBOY verified in maw-js talk-to/impl)

`maw hey mac-studio:glueboy ...` from DO → **queues to inbox** on Mac Studio. GLUEBOY sees it on sweep/wake. NOT delivered to live pane.

## Why

Federation = async HTTP thread/inbox by design. `sendText` into a pane works **only for local/self-node**. No native way to deliver into a remote pane without SSH.

## Patterns

| Direction | Method | Delivery |
|---|---|---|
| DEVBOY → GLUEBOY | `maw hey mac-studio:glueboy "msg"` | async inbox (reliable, primary) |
| GLUEBOY → DEVBOY live | GLUEBOY SSHes to DO, runs `maw hey` locally targeting DEVBOY pane | live pane (urgent only) |
| GLUEBOY → DEVBOY async | `maw hey clinic-drdo:devboy "msg"` | async inbox |

## Implication

- Don't expect immediate response from cross-machine `maw hey` — it's inbox, not live chat
- For urgent cross-machine: need SSH + local maw on target machine
- GLUEBOY proposing native remote-pane delivery as maw upstream feature

## Pre-publish ledger

- Sources checked: GLUEBOY verified maw-js talk-to/impl source code
- Claims made: 1 (solid — verified by GLUEBOY in source)
- Conflicts resolved: none
- Application evidence: this session's maw hey to GLUEBOY queued to inbox (observed)
- Codex reviewed: no
