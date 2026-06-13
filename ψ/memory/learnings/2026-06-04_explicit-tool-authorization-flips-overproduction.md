---
type: learning
topic: Explicit tool authorization flips the over-production rule; arra_learn draft-pattern-first gate
source: rrr 2026-06-04 (Tesla×Porsche business-lens chapter)
maturity: solid
retrieval_terms: [over-production, workflow, authorization, arra_learn, gate_hook, business-dna, sizing-the-ask]
date: 2026-06-04
gate_hook: "pre-call check — draft the arra_learn `pattern` string in message text BEFORE invoking the tool (copy-not-compose)"
---

# Explicit tool authorization flips the over-production rule

## The pattern
Yesterday's lesson: "don't over-produce an 11-agent workflow on a vague conceptual directive ('dynamic workflow')." Today P'Nat (a commander) said **"/workflows ด้วย"** explicitly → spawning a 4-agent sonnet literature-review workflow was *correct*, sized to the task, and produced a better genome than solo synthesis (real sourced principles: von Holzhausen rejecting the fake Model S grille; Cybertruck faceting as material truth).

**The discipline is not "never spawn heavy work" — it's "read whether the heavy tool was actually asked for."**
- Vague conceptual directive ("morph", "dynamic workflow") → default lighter, escalate on confirmation.
- Commander names the tool explicitly ("/workflows", "swarm this") → use it, sized to the task.

## Two sub-lessons (operational)
1. **Workflow output parsing**: the returned value is nested — `json.load(output_file)['result']` (and that may itself be a JSON string needing a second `json.loads`). The top-level keys are `summary/agentCount/logs/result`, NOT the script's return shape.
2. **arra_learn empty-call recurrence**: invoked `arra_learn` with no parameters 4× in a row (the `pattern.substring` undefined error) before constructing it right — a repeat of an already-logged failure. **Gate (gate_hook above)**: draft the `pattern` text in the response first, then issue the call as copy-not-compose. The failure mode is calling the tool "to fill in later" instead of after the content exists.

## Bonus: desire() is polymorphic across business lenses
Gucci (heritage-maximalist, gold) and Tesla×Porsche (engineered-minimalist, no gold) are two opposite implementations of the same `desire(object)` interface. The [[morph]] / polymorphism framework generalizes from artist DNAs to **business/brand genomes**. For a *tech* object, luxury = subtraction (earned taper, one periphery accent, machined hairline, monochrome, software-first), not ornament. See `ψ/reference/business-dna-tesla-porsche.md` + `ψ/reference/business-dna-gucci.md`.

## Pre-publish ledger
- Sources checked: this session's workflow wf_ae9aa01d-c21 output; prior retro 15.20 (over-production lesson)
- Claims made: 3 (authorization-flip ✅ solid — applied + worked this session; output-parse ✅ solid — hit + fixed; arra gate 🟡 emerging — gate named, not yet auto-enforced)
- Conflicts resolved: reconciles with yesterday's "size the ask" — not a contradiction, a refinement (authorization is the discriminator)
- Application evidence: workflow ran + genome shipped (msg 1512046809726455859); arra_learn succeeded after drafting pattern first
- Codex reviewed: no (retro learning, < 30 LOC)
