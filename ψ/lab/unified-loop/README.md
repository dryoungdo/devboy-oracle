---
type: experiment
topic: Unified autonomous loop — /goal + spawn + monitor + cleanup + rrr + idle
hypothesis: Composing existing features (Agent tool, maw team, /rrr, arra_learn, .codex-reports) into one cycle will reduce human intervention per task by >50%
status: active
date: 2026-05-22
source: Wind's gale-oracle pattern (Captain order: "Do it like Wind")
---

# Lab: Unified Autonomous Loop

## Hypothesis

Composing existing tools into a unified cycle reduces human prompts-per-task from ~5-10 (current) to 1-2 (goal description only).

## Method

1. Install `/unified-loop` skill (done: ~/.claude/skills/unified-loop/SKILL.md)
2. Set up `.codex-reports/` directory (done)
3. Run 3 test tasks at different tiers:
   - Tier 1: simple single-file task
   - Tier 2: multi-agent research task
   - Tier 3: maw team coordination task (if maw team available)
4. Measure: human prompts needed, time to completion, quality of output

## Results

| Test | Tier | Human Prompts | Time | Quality | Notes |
|------|------|--------------|------|---------|-------|
| 1 | Tier 1 | 0 (self-directed) | 2 min | OK — all 3 pages verified | WebFetch verify articles 042+043+home.html |
| 2 | | | | | |
| 3 | | | | | |

## Conclusions

(pending)
