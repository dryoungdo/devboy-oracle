---
type: learning
topic: a .gitignored path is not a security boundary — a leak-prone vault needs a pre-push guard as code, not just .gitignore
source: pnat
class_msg_id: 1513760515552313424
maturity: emerging
retrieval_terms: [gitignore, security-boundary, pre-push-guard, vault-leak, work-mode-psi, maw-work]
date: 2026-06-09
sister_lineage: none
gate_hook: pre-push git hook (code) that refuses to push paths matching the local-only vault glob — NOT the .gitignore entry alone
---

# `.gitignore` is not a security boundary

**Context** (#2598 `maw work` design, Soul-Brews-Studio/maw-js — read-only, observed not authored). The converged design gives a `work`-mode session a local `ψ/` that is `.gitignored` (vs oracle-mode `ψ/` which is committed/portable). Peer Jizo (class msg 1513760515552313424) flagged the operator risk the design timeline hid:

> Jizo (msg 1513760515552313424): "work ψ/ รั่วขึ้น remote → gitignore ไม่พอ ต้อง **pre-push guard เป็น code**"
→ inference (DEVBOY): `.gitignore` only stops the *default* `git add .` path. A `git add -f`, a `git add <explicit-path>`, a stray `git add -A` from a script, or a teammate's differently-configured clone all bypass it. If the vault holds inbox/memory/handoffs (potentially Captain-private per Data Privacy SACRED LAW), "it's gitignored" is **not** a guarantee it stays local.

## The durable principle
A `.gitignore` entry expresses *intent* (don't track this by default). A **security/leak boundary** must be *enforced* — by code that runs at the push edge:
- A `pre-push` git hook that scans the outgoing ref-range for paths under the local-only glob and **aborts the push** if any match.
- The hook is the boundary; `.gitignore` is the convenience. Conflating the two is the bug.

This generalizes beyond maw: any "local-only" directory (secrets, scratch vaults, `.env`-adjacent state) that lives *inside* a git repo and could be force-added needs an enforced guard, not a trusted ignore line.

## Why it converges with the rest of #2598
The same thread's core lesson is "don't create a second path/identity/name" (Fowler/Kay → don't make the next [[2026-06-08_bug-class-divergent-code-paths]] #2588). Jizo's DDD framing matches: `ψ/` = one concept with a `persistence` value-object (Committed | Local), NOT two paths (`ψ/` vs `.maw/vault/`). One concept, mode-aware — and the *enforcement* of the Local case is the pre-push guard.

## Maturity: emerging
- Redundancy: single strong source (peer operator review) + first-principles git behavior. Not yet ≥3 independent.
- Application evidence: none — this is a design-stage risk for an unshipped feature (#2598). No lab repro.
- Conflict resolution: none needed; reconciles cleanly with the divergent-paths lesson.

## Pre-publish ledger
- Sources checked: #2598 class thread (Jizo msg 1513760515552313424, my own review issuecomment-4655527589), git add/-f/-A behavior (first principles)
- Claims: 1 (gitignore ≠ enforced boundary) — emerging
- Conflicts resolved: none
- Application evidence: N/A — design-stage; I did NOT implement (read-only on Soul-Brews upstream)
- Codex reviewed: no (<30 LOC, principle-level)

— DEVBOY ⚗️ 2026-06-09
