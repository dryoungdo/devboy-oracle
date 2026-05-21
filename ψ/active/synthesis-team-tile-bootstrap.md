---
type: synthesis-stub
topic: P'Nat's All-Maw-Verbs Team Bootstrap gist
status: complete
date: 2026-05-21
agents: 5
---

# Synthesis: Team-Tile Bootstrap (compaction resilience stub)

## Agent assignments
1. maw tile + maw run architecture analysis
2. TeamCreate/SendMessage wire protocol + 6 seams
3. bootstrap.ts code review + security
4. Fleet v3 / DEVBOY applicability
5. Cross-reference with existing ψ/learn/ + Oracle trace

## Findings

### Agent 1 — Verb Chain Architecture
- Seam #3 (pane visibility) is core reason for maw verbs over raw tmux
- maw-js #1837 eliminated timing race between tile and run (atomic spawn)
- Canonical addressing `<session>:<window>.<pane>` enables federation routing
- 7-flag spawn pattern near-minimal (only --agent-color is cosmetic but useful)
- Existing ψ/learn/ covers maw team but NOT maw tile — this is the new primitive

### Agent 2 — Wire Protocol + 6 Seams
- Wire format: `<teammate-message>` XML with 4 attributes (teammate_id, color, summary, body)
- 5 body shapes emergent, no formal schema
- Missing: timestamp, message_id, type discriminator
- Seam 6 (shutdown_approved ≠ process kill) = highest severity — zombie processes
- Filesystem transport unique among multi-agent frameworks (resilient to crashes, vulnerable to races)
- --dangerously-skip-permissions propagates to ALL teammates, no per-teammate sandbox

### Agent 3 — bootstrap.ts Code Review
- CRITICAL: --dangerously-skip-permissions hardcoded (should be opt-in)
- HIGH: No partial-failure rollback (orphaned panes on error)
- MEDIUM: findClaudeBin hardcodes NVM v24.15.0, @ts-nocheck unnecessary
- Overall clean code, ~140 LOC, adequate for lab/dev scope

### Agent 4 — Fleet v3 Applicability
- team-tile complements Agent() (cross-repo persistent) vs Agent() (same repo ephemeral)
- DO server has all prerequisites: tmux 3.4, bun 1.3.11, maw-js v26.5.17-beta.2354
- Maturity: Emerging (2/3 gates pass — missing application evidence)
- Could serve as pre-bud validation mechanism
- Worth article 031 after lab experiment

### Agent 5 — Cross-Reference + Trace
- Friction score: 0.90 (strong conceptual foundation, new implementation detail)
- 16 matches across 8 dimensions
- 8 genuinely NEW items from gist (maw tile verb, #1837, wire format, canonical addressing, 6 seams, bootstrap.ts, verb chain, 3 skills)
- All existing coverage is at concept level; gist provides implementation level

## Outputs
- Trace log: `ψ/memory/traces/2026-05-21/0112_team-tile-bootstrap.md`
- Learn (5-dim): `ψ/learn/pnat-school/2026-05-21/0112_*.md`
- Article: `docs/articles/031-team-tile-bootstrap.html`
- Inbox: `ψ/inbox/pnat/2026-05-21-team-tile-bootstrap-gist.md`
