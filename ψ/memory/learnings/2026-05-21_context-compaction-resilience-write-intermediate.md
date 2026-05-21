---
type: learning
topic: Write intermediate synthesis to files before context compaction
source: rrr-session-friction
maturity: emerging
retrieval_terms: [context-compaction, intermediate-results, agent-synthesis, session-resilience]
date: 2026-05-21
gate_hook: "Before spawning 3+ parallel agents for synthesis: create ψ/active/synthesis-<topic>.md stub. After each agent completes, append findings to the stub file. Don't keep agent results only in context."
---

Running 5+ parallel agents produces excellent analysis but results live only in context memory. If context compacts before synthesis, agent results are lost — requires re-running agents in continuation session (~10 min wasted).

**Evidence**: Session 5158a157 (2026-05-20) — 5 agents completed hermes-agent/thClaws trace. Context compacted. Had to re-run 2 Explore agents in continuation to recover data.

**Gate**: Before spawning 3+ agents for a synthesis task, create `ψ/active/synthesis-<topic>.md` stub. After each agent completes, write key findings to file immediately. Don't defer synthesis to "after all agents complete" if context is >60% full.

**Why this matters**: context is a finite resource. Agent results that exist only in context are ephemeral. Files survive compaction. The overhead of writing intermediate results (~30 seconds per agent) is cheaper than re-running agents (~5 minutes each).
