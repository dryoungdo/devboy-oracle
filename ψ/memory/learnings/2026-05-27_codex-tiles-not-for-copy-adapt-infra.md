---
type: learning
topic: Codex tiles are wrong tool for copy-and-adapt infrastructure tasks
source: experiment
maturity: solid
retrieval_terms: [codex-tiles, swarm, oracle-birth, infrastructure-setup, solo-vs-swarm]
date: 2026-05-27
gate_hook: "swarm-by-default rule 1 already covers this — solo announcement is the mechanism"
---

# Codex Tiles — Wrong Tool for Copy-and-Adapt Infra

## Verified Behavior

Dispatched 3 Codex tiles to create OFFICEBOY's oracle infrastructure (oracle-build system, scripts, settings.json, AGENTS.md, .gitignore). All 3 exited without producing any output — no files created, no commits, no errors captured.

## Why Tiles Fail Here

1. **Sequential dependencies**: oracle-build.sh must exist before CLAUDE.md can be generated. Tiles can't coordinate this ordering
2. **Cross-file comprehension**: each file requires reading a reference (glueboy/devboy equivalent), understanding structure, and adapting for OFFICEBOY. This is sequential reasoning, not parallelizable labor
3. **Same-branch conflict**: 3 tiles on main → second push conflicts with first. Would need worktree branches + sequential merge
4. **DO environment**: `codex` may not be installed or accessible on clinic-drdo (unverified — tiles exited silently)

## When TO Use Tiles

- N independent code changes in N separate files (disjoint file slices)
- Each tile's work is self-contained and doesn't depend on another tile's output
- Changes can merge independently via separate branches/PRs

## When NOT to Use Tiles

- "Read repo A, understand pattern, create adapted version in repo B" tasks
- Infrastructure setup with dependency ordering between files
- Tasks requiring cross-file context that can't be captured in a brief

## Solo is Right Answer

For oracle birth / infrastructure setup: single agent reads all references, creates all files in correct order, generates dependencies (CLAUDE.md from oracle-build sources), commits atomically. One commit, one push, all issues closed.

Result: solo execution took ~15 minutes. Tiles took 0 minutes of useful work + ~10 minutes of dispatch + debug overhead.

## Pre-publish ledger

- Sources checked: this session's tile dispatch + failure observation
- Claims made: 2 (tiles wrong for copy-adapt: solid — directly observed; DO codex missing: emerging — unverified root cause)
- Conflicts resolved: none
- Application evidence: OFFICEBOY Phase 1 commit on officeboy-oracle main, 25 files, all 6 issues closed
- Codex reviewed: no (meta-ironic — this is a learning about codex failure)
