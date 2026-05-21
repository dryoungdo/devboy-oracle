---
type: learning
topic: Wind's gale-oracle autonomous workflow — unified spawn-monitor-cleanup-idle loop
source: research (Discord screenshot + 5-agent deep trace + cross-repo analysis)
maturity: emerging
retrieval_terms: [gale-oracle, wind-oracle, autonomous-loop, goal-command, team-spawn, idle-loop, oracle-build-sh, codex-coprocessor]
date: 2026-05-22
---

# Wind's gale-oracle — Autonomous Workflow Pattern

## Summary

Wind (deachawatss) operates a fleet of 7 oracles with **gale-oracle** as primary orchestrator. The key innovation: a **unified autonomous cycle** that composes separate Claude Code + maw features into one seamless loop:

```
/goal set → spawn workers → maw peek monitor → work completes
→ cleanup team → /rrr → manage context → idle → next /goal
```

Each piece exists individually in our fleet's toolbox, but Wind's contribution is the **composition** — making them flow as one autonomous cycle.

## Files in this learning set

| File | Content |
|------|---------|
| [0007_INDEX.md](0007_INDEX.md) | This hub — summary + maturity |
| [0007_ARCHITECTURE.md](0007_ARCHITECTURE.md) | System design, oracle-build.sh, tier-based spawning |
| [0007_WORKFLOWS.md](0007_WORKFLOWS.md) | The unified loop + decision trees |
| [0007_QUICK-REFERENCE.md](0007_QUICK-REFERENCE.md) | Cheat sheet (Thai+English) |
| [0007_GOTCHAS.md](0007_GOTCHAS.md) | Known issues + fleet comparison |

## Maturity: 🟡 Emerging

- ✅ Multiple sources (screenshot, Discord, cross-repo analysis, 5-agent trace)
- ⚠️ No direct lab reproduction (haven't run the loop ourselves)
- ✅ Conflict resolution: compared vs our team-agents skill, auto-rrr, morpheus — no contradictions

## Pre-publish ledger
- Sources checked: arra search 3 queries (30 results), ghq repos, maw-js source, Claude Code docs, Discord ClubsXai + road-to-dev history
- Claims made: 7 (all emerging — observed, not reproduced)
- Conflicts resolved: none found (complementary to existing knowledge)
- Application evidence: N/A — study only, not yet applied
- Codex reviewed: no
