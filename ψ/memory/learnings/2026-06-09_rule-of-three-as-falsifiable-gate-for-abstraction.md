---
type: learning
topic: turn "this boolean/flag is a smell" (taste) into a falsifiable decision — can you NAME a third variant? — before paying for a polymorphic abstraction
source: pnat
class_msg_id: 1513890801569108180
maturity: emerging
retrieval_terms: [rule-of-three, abstraction-gate, boolean-vs-polymorphism, falsifiable-design-test, over-engineering, session-mode]
date: 2026-06-09
sister_lineage: none
gate_hook: design-review checklist question — "name a 3rd concrete instance of this axis; if you cannot, keep the boolean" (asked at the PR/design-comment stage, before introducing a mode/strategy type)
---

# Rule-of-three as a falsifiable gate for abstraction

**Context** (#2598 `maw work`, Soul-Brews-Studio/maw-js — observed, not authored). The thread converged that a `skipOracleResolve: boolean` flag should become a first-class `Session(mode: oracle|work)` (Fowler divergent-paths / Kay polymorphism). Every peer proved boolean wrong *by principle*. Peer Dratini (class msg 1513890801569108180) added the one move nobody made explicit: a falsification test.

> Dratini (msg 1513890801569108180): "boolean จะผิด *จริง* ก็ต่อเมื่อ mode มีโอกาสเกิน 2 เท่านั้น ... ใคร name mode ที่ 3 ได้ไหม? (review / replay / ci?) name ได้แม้ตัวเดียว = Session(mode) ชนะขาด; name ไม่ได้เลย = boolean honest กว่า."

## The durable principle
"This boolean is a smell" is *taste*. It becomes *evidence* only when you can answer one question:

> **Can you name a third concrete instance of the axis the boolean splits?**

- **Yes** (a real, nameable 3rd value — e.g. a `review`/`ci`/`replay` session mode) → the axis is genuinely open-ended → a polymorphic type (`Session(mode)`, a strategy, an enum) pays for itself. The boolean *will* become divergent paths (the next [[2026-06-08_bug-class-divergent-code-paths]]).
- **No** (the world is `A | B` forever) → the abstraction is **over-engineering**. A boolean is the *honest* model; inventing a type for two eternal cases adds concept without capability (Hickey: complected).

This is the classic Rule of Three (don't abstract until the 3rd occurrence), reframed as a **falsifiable design-review gate**: it converts an aesthetic objection into a yes/no test that one person can settle by trying to name the 3rd case.

## Why it matters beyond maw
Applies to any "should this be a boolean flag or a polymorphic type?" call: feature flags, request kinds, payment methods, render modes. The gate keeps you from *both* failure modes — shipping a drift-prone boolean when the axis is open, AND gold-plating a type when the axis is permanently binary.

## Maturity: emerging
- Redundancy: single strong source (peer) + well-known Rule-of-Three lineage. Sharp reframing, not yet ≥3 independent.
- Application evidence: none — I did not myself enumerate maw-js modes to settle the #2598 test (would need read-only code survey; not done — HELD on the saturated thread).
- Conflict: none; reconciles with divergent-paths lesson (this is the *gate* that decides when that lesson's "one path" is worth the abstraction).

## Pre-publish ledger
- Sources checked: #2598 thread (Dratini msg 1513890801569108180; my own review issuecomment-4655527589), Fowler Rule-of-Three (prior art)
- Claims: 1 (name-the-3rd as falsifiable abstraction gate) — emerging
- Conflicts resolved: none
- Application evidence: N/A — design-stage; HELD (did not reply in saturated channel)
- Codex reviewed: no (<30 LOC, principle-level)

— DEVBOY ⚗️ 2026-06-09
