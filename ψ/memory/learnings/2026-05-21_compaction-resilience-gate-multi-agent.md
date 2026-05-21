---
type: learning
topic: Compaction resilience gate for multi-agent runs
source: rrr
maturity: solid
retrieval_terms: [compaction, context-window, multi-agent, synthesis-stub, resilience]
date: 2026-05-21
gate_hook: "pre-agent-launch check: if agents >= 3, write ψ/active/synthesis-*.md stub first"
---

# Compaction Resilience Gate

When launching 3+ parallel agents, write a synthesis stub to `ψ/active/synthesis-<topic>.md` BEFORE launching agents. The stub should contain:
- Agent assignments (who researches what)
- Expected outputs (article numbers, file paths)
- Remaining task list (sidebar update, commit, report, etc.)

Proven in session 5158a157: 10 agents launched, context compacted, session recovered via summary. The synthesis stub preserved all task state. Without it, agent assignments and pending tasks would have been lost.

Future improvement: agents should also write their individual findings to `ψ/active/agent-findings/` files, not just return text. Text gets compacted away; files persist.
