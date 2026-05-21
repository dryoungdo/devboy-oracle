---
type: learning
topic: gale-oracle gotchas — adoption risks + fleet comparison gaps
source: research
maturity: emerging
retrieval_terms: [gale-gotchas, autonomous-loop-risks, goal-command-limits, fleet-gap-analysis]
date: 2026-05-22
---

# gale-oracle Gotchas & Adoption Risks

## Known Gotchas

### 1. /goal Is Experimental

`/goal` uses a Haiku-class model as validator. Haiku may:
- Declare goal "met" prematurely (false positive → incomplete work)
- Never declare goal "met" (false negative → infinite loop)
- Not understand nuanced completion criteria

**Mitigation**: Write specific, measurable goal descriptions. "Add decision gate to CLAUDE.md section 3" > "improve CLAUDE.md"

### 2. Worker Worktree Conflicts

Multiple workers in separate worktrees can create merge conflicts when integrating:
- Worker 2 edits file A lines 10-20
- Worker 3 edits file A lines 15-25
- Integration requires manual conflict resolution

**Mitigation**: Assign workers non-overlapping files. Use file-level locking or coordination.

### 3. Codex (GPT-5.5) ≠ Claude

Codex workers use different model (GPT-5.5), which means:
- Different coding style, different hallucination patterns
- May not respect Claude-specific CLAUDE.md instructions
- AGENTS.md is the Codex equivalent of CLAUDE.md (different file!)
- Symlink pattern needed: `AGENTS.md → CLAUDE.md`

### 4. maw peek Is Polling, Not Streaming

`maw peek` returns a snapshot. Between peeks, workers may:
- Crash silently
- Spin on errors
- Complete without main oracle knowing

**Mitigation**: File-based status (.done.md, .stuck.md) provides durable signal that survives peek gaps.

### 5. Idle Timeout (~1 hour)

Background sessions idle-timeout after ~1 hour. If main oracle goes idle between goals:
- Session may be stopped by supervisor
- Resume on attach, but context may be compacted
- `/loop` keeps sessions alive but burns tokens

### 6. oracle-build.sh = Single Point of Failure

If `shared-claude.md` has a bug, ALL oracles get the bug simultaneously. No gradual rollout.

**Compare to DO fleet**: Individual CLAUDE.md per oracle means bugs are isolated. Trade-off: consistency vs resilience.

---

## Gap Analysis: What DO Fleet Needs to Adopt This Pattern

### Already Have (พร้อมแล้ว)
- ✅ `maw team spawn` — worker spawning
- ✅ `maw peek` — worker monitoring
- ✅ `/rrr` + auto-rrr hooks — retrospective flow
- ✅ `/morpheus` — idle dreaming
- ✅ maw-js `triggers-idle.ts` — idle detection
- ✅ maw-js `worktrees-cleanup.ts` — worker cleanup
- ✅ Codex co-review (standing order)
- ✅ `arra-oracle` MCP — search-first gate

### Missing / Need to Build (ยังไม่มี)
- ❌ `/goal` command — need to adopt or build equivalent
- ❌ Unified loop orchestrator — skill that chains: goal → spawn → monitor → cleanup → rrr → idle
- ❌ File-based status reporting (.done.md pattern)
- ❌ Codex as coprocessor (not just reviewer) — `maw team spawn --codex`
- ❌ `oracle-build.sh` equivalent — fleet-wide shared identity propagation
- ❌ Auto-context management (gated /compact after /rrr)

### Nice-to-Have (อยากได้)
- 🟡 Agent View dashboard (`claude agents`) — for monitoring all bg sessions
- 🟡 Tier-based auto-selection — auto-choose spawn tier based on task complexity
- 🟡 `/goal` validator tuning — custom validation criteria beyond Haiku default

---

## Anti-Patterns (สิ่งที่ห้ามทำ)

| Anti-Pattern | Why | Instead |
|-------------|-----|---------|
| Vague /goal descriptions | Haiku can't validate fuzzy criteria | Specific, measurable goals |
| Workers editing same file | Merge conflicts | Assign non-overlapping files |
| No file-based status | Main oracle doesn't know worker state | Write .done.md/.stuck.md |
| Skipping /rrr before /compact | Lose session learnings | Always /rrr first |
| Running /goal without /bg | Blocks terminal, no autonomous benefit | Always /goal + /bg together |
| oracle-build.sh without backup | One bad shared-claude.md breaks fleet | Timestamped backups |

---

## Adoption Recommendation

**Phase 1** (immediate, no new code): Start using `/goal` + `/bg` for autonomous tasks. Monitor with `maw peek`.

**Phase 2** (1 week): Build unified loop skill that chains goal → spawn → monitor → cleanup → rrr → idle. File-based status reporting.

**Phase 3** (2 weeks): Codex coprocessor integration. Tier-based auto-spawning. Agent View monitoring.

**Captain decision required**: Whether to adopt oracle-build.sh pattern (fleet-wide shared CLAUDE.md) vs current individual CLAUDE.md per oracle.
