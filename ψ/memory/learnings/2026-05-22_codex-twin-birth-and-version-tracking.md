---
type: learning
topic: Codex twin-engine birth process + learning version tracking
source: experiment
maturity: solid
retrieval_terms: [maw-scaffold, devboy-codex, twin-engine-birth, codex-review, agents-md, version-tracking]
date: 2026-05-22
gate_hook: "codex-review standing order: always review cross-engine identity files for attribution consistency"
---

# Codex Twin-Engine Birth + Version Tracking

## Lesson 1: maw scaffold + AGENTS.md for Codex oracles

`maw scaffold` generates CLAUDE.md but NOT AGENTS.md. For Codex (GPT-5.5) oracles:
1. `maw scaffold <name> --from <parent>` — creates repo + ψ/
2. Manually create AGENTS.md adapted from parent's CLAUDE.md
3. Strip Claude-specific sections (Discord, MCP, subagents, /rrr)
4. Add Codex capabilities/limitations + twin-engine protocol
5. Run codex-review on the result — caught commit trailer mismatch

## Lesson 2: Codex co-review catches cross-engine bugs

CLAUDE.md had `Co-Authored-By: Claude Opus 4.6` but AGENTS.md said `Co-Authored-By: GPT-5.5 Codex`. Without codex-review, devboy-codex would have committed with wrong attribution forever.

## Lesson 3: Learning files need version tracking

P'Nat shipped v0.2.0 → v0.7.0 in 3 hours. Our learning files captured v0.2.0 only. For fast-moving teachers, add version field to frontmatter and batch updates with explicit version deltas.
