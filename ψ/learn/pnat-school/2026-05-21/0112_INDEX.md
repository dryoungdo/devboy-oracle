---
type: learning
topic: All-Maw-Verbs Team Bootstrap — maw tile + TeamCreate + SendMessage verb chain for N parallel teammates
source: pnat-gist
class_msg_id: "gist:nazt/1ffec5896ece7b911a8ab9134df99ae1"
maturity: emerging
retrieval_terms: [maw-tile, team-tile, TeamCreate, SendMessage, teammate-message, bootstrap, agent-teams, wire-format, canonical-addressing, tmux-pane]
date: 2026-05-21
sister_lineage: none
gate_hook: "Lab experiment ψ/lab/team-tile-bootstrap/ must validate before promoting to solid"
---

# All-Maw-Verbs Team Bootstrap

**Source**: P'Nat gist (2026-05-20, validated in digger-oracle fleet)
**Maturity**: Emerging (2/3 gates pass — missing application evidence)
**Friction score**: 0.90 (strong conceptual foundation, new implementation detail)

## Hub

| File | Content |
|------|---------|
| [API-SURFACE.md](0112_API-SURFACE.md) | Verb chain, 7-flag spawn, canonical addressing, SendMessage flow |
| [ARCHITECTURE.md](0112_ARCHITECTURE.md) | 6 seams, wire format, filesystem transport, seam severity |
| [CODE-SNIPPETS.md](0112_CODE-SNIPPETS.md) | bootstrap.ts review, maw tile commands, member spec format |
| [QUICK-REFERENCE.md](0112_QUICK-REFERENCE.md) | Thai+English cheat sheet, verb chain one-liner, when to use |
| [TESTING.md](0112_TESTING.md) | Lab experiment plan, failure modes, verification steps |

## Pre-publish ledger
- Sources checked: P'Nat gist (5 files), arra search "team-tile", arra search "maw tile", ψ/learn/from-mlboy/agent-teams/, ψ/learn/pnat-school/2026-05-19/, ψ/memory/learnings/from-iotboy/, docs/articles/003,007,023
- Claims made: 12 (all emerging)
- Conflicts resolved: tmux-send-keys anti-pattern vs team-tile tmux use — resolved: team-tile uses maw-mediated tmux (logged, observable), not raw send-keys
- Application evidence: N/A — lab experiment required (ψ/lab/team-tile-bootstrap/)
- Codex reviewed: no (code review done by Agent 3 instead)
