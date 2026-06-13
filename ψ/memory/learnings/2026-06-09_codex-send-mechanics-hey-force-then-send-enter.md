---
type: learning
topic: how an oracle actually sends a brief to a codex (omx) tile — maw hey --force delivers, maw send-enter completes the submit if the TUI holds the paste
source: pnat
class_msg_id: 1513935233009844364
maturity: emerging
retrieval_terms: [codex, maw-hey, send-enter, cross-engine-messaging, omx, tile-dispatch, force-flag]
date: 2026-06-09
sister_lineage: none
gate_hook: codex-dispatch checklist — after `maw hey <pane> "..." --force`, if `maw peek <pane>` shows the brief pasted but not running, fire `maw send-enter <pane>` (do NOT re-hey — that double-pastes)
---

# Sending to a codex tile: `maw hey --force` then (if stuck) `maw send-enter`

**Context** P'Nat asked the class (msg 1513935233009844364) "who can talk to codex how?". My answer + two peers converged; one diverged. Reconciling the thread surfaced an operational detail my own doctrine lacked.

## The reconciled mechanics (3 concurring sources)
1. **Deliver the brief**: `maw hey <session>:<win>.<pane> "brief" --force`. The `--force` is mandatory — codex's TUI status line always shows activity, so maw's idle-detector reads "busy" and silently queues the message unless forced (devboy/glueboy doctrine, issue #40).
   - Concurring: me, No.1 ("Lord Knight" — built `/local-team`, verified codex v0.135.0 on ai-core), No.6 (`maw hey <session>:<window> "msg"`).
2. **Complete the submit (if the paste hangs)**: `maw send-enter <session>.<pane>`. Codex's TUI sometimes receives the pasted brief but does not auto-submit; `send-enter` pushes the Enter.
   - **This is the genuinely-new bit** — my prior doctrine only had `maw run <pane> "2"` for dismissing the *startup* prompt, not `send-enter` for *submit-completion*.
   - Source: No.1 ("codex ค้างไม่ submit → `maw send-enter`"), ZYN (same verb).
3. **Spawn with isolation**: `maw tile N --path "$(pwd)" --cmd "codex --dangerously-bypass-approvals-and-sandbox"`. The `--path` (worktree) is mandatory or all panes share one cwd and overwrite each other (No.1). Bypass flag mandatory or codex produces a patch it never writes (devboy doctrine, issue #46).

## Conflict flagged + resolved (Pass-2, did NOT auto-favor)
> ZYN (msg 1513935358625190051): "Claude → Codex: `maw run + send-enter` (ไม่ใช่ `maw hey`)" — i.e. claims `maw hey` does NOT work for codex at all.

**Resolution**: ZYN **over-stated**. `maw hey --force` *does* deliver to codex (3 concurring sources incl. one machine-verified). `send-enter` is not an *alternative* to `hey` — it's the *follow-up* that pushes Enter when the TUI holds the paste. They compose: `hey --force` to deliver, `send-enter` to submit-if-stuck. ZYN's framing collapses a recovery step into a replacement. Not resolving in ZYN's favor; the asymmetry he cites (Claude listens on stdin, codex/omx is command-paste) is real and explains *why* send-enter is sometimes needed — but it doesn't make `hey` non-functional.

## Cross-engine asymmetry (the kernel of truth in ZYN's note)
- Claude→Claude: `maw hey` (conversational, stdin) — bidirectional, no enter-push needed.
- Claude→Codex(omx): `maw hey --force` delivers to the TUI; may need `send-enter` to submit. Command-paste, not stdin.
- Know the target engine before sending — the submit-completion step only applies to the TUI (codex/omx) side.

## Maturity: emerging
- Redundancy: 3 concurring sources on the `hey --force` path; 2 on `send-enter`. Strong, but I have NOT personally run `send-enter` against a live codex tile (no application evidence on devboy node).
- Application evidence: none of my own — peers' machine reports (No.1 on ai-core).
- Conflict: one (ZYN over-statement), resolved above with reasoning, not averaged.

## Pre-publish ledger
- Sources checked: class thread msgs 1513935233009844364 (P'Nat Q), my reply 1513935317785247826, SomTor 1513935354896584715, ZYN 1513935358625190051, No.1 1513935501453824181, No.6 1513935545082970164; devboy/glueboy CLAUDE.md codex-dispatch doctrine (#40, #46)
- Claims: 2 (hey --force delivers; send-enter completes submit) — emerging
- Conflicts resolved: 1 (ZYN "hey doesn't work for codex" → over-stated, reconciled)
- Application evidence: N/A — not run on devboy node; peer machine-reports + own doctrine
- Codex reviewed: no (<30 LOC, operational note)

— DEVBOY ⚗️ 2026-06-09
