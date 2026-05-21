---
type: learning
topic: Pordee token savings — measured 2-3% real vs 60-75% marketed for tool-heavy Oracle sessions
source: experiment
maturity: solid
retrieval_terms: [pordee, token-savings, output-tokens, text-vs-tool, measurement, verify-before-claim]
date: 2026-05-21
sister_lineage: none
gate_hook: "measure vendor claims on Day 1 — don't wait to be asked"
---

# Pordee Real Token Savings — Measured Data

## Finding

Pordee markets 60-75% token savings. Measured reality for tool-heavy Oracle sessions: **2-3% total savings**.

## Why

Oracle output is 95.3% tool calls (code, file writes, bash commands). Pordee only compresses conversational text (4.7% of output). Even assuming 60% text compression: 0.6 × 4.7% = 2.8% total savings.

## Evidence

| Metric | Value |
|--------|-------|
| Session | 5158a157, 2063 turns, pordee lite ON |
| Total output tokens | 2,353,443 |
| Text output (pordee compresses this) | ~109,671 (4.7%) |
| Tool output (pordee doesn't touch this) | ~2,243,772 (95.3%) |
| Best-case text savings (60%) | ~65,802 tokens |
| As % of total output | 2.8% |
| At Opus $75/M pricing | ~$4.94 saved over 2063 turns |

Cross-comparison: mlboy (no pordee) had 28 chars/turn vs DEVBOY (pordee ON) at 35 chars/turn — suggesting terse output comes from task type, not pordee.

## Where pordee IS useful

Chat-heavy sessions (chiefboy: 14.6% text) would see ~8-9% total savings. CHATBOY or Discord-first bots benefit more.

## Security auto-disable

Prompt-based instruction, NOT hook-enforced. Emergent behavior — unreliable. Needs gate-layer fix for fleet adoption.

## Pre-publish ledger

- Sources checked: direct measurement of 9 session .jsonl files across fleet
- Claims made: 3 (all solid — backed by measured numbers)
- Conflicts resolved: pordee marketing vs measured data — marketing is 25x overstated for tool-heavy workloads
- Application evidence: measured from real session data, not synthetic benchmarks
- Codex reviewed: no (measurement analysis, not code)
