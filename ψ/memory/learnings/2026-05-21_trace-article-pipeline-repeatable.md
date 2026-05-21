---
type: learning
topic: Trace-to-article pipeline is a repeatable pattern
source: rrr
maturity: solid
retrieval_terms: [trace, article, pipeline, agents, ghq, sidebar, devboy-lab]
date: 2026-05-21
gate_hook: "When Captain sends URL for trace: Oracle search → ghq clone → N agents → trace log → article → sidebar/home → Discord reply."
---

# Trace→Article Pipeline

Proven across 3 repos in one session (038 OmniVoice-Thai, 039 maw-rs, 040 arra-safety-hooks):

1. **Oracle search** — check existing knowledge (friction score baseline)
2. **ghq clone** — get repo locally (or WebFetch for HuggingFace/non-git)
3. **N agents** — proportional to repo complexity (3-5 for small, 5-10 for large)
4. **Trace log** — ψ/memory/traces/ with friction score + coverage
5. **Article** — Part A practical + Part B deep dive, Thai+English
6. **Sidebar + home** — O(1) addition
7. **Discord reply** — links + summary

**Agent allocation heuristic**: 3 files → 3 agents. 21 crates → 5+ agents. HuggingFace model → web research agent essential.

**Skip dig for friction=0.0**: when Oracle returns 0 FTS matches, dig adds noise. Save for friction≥0.3.
