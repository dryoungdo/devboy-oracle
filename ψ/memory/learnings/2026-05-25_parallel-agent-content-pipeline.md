---
type: learning
topic: Parallel agent pipeline for batch article creation
source: experiment
maturity: emerging
retrieval_terms: [parallel-agents, content-pipeline, batch-articles, write-agents, research-agents]
date: 2026-05-25
sister_lineage: none
gate_hook: "sidebar.js must be reserved for main agent — no concurrent edits"
---

# Parallel Agent Content Pipeline

## Pattern

1. Spawn N research agents (one per topic cluster) → each returns structured report
2. Spawn M write agents (one per 2-3 articles) → each converts research to HTML
3. Main agent handles shared resources (sidebar.js, commit, push)

## Evidence

Session 1e1b78ca: 5 research agents + 4 write agents produced 9 articles (~137K HTML) in ~1 hour wall time.

## Gotcha

Multiple write agents editing sidebar.js concurrently = race condition. Last write wins. Fix: reserve shared files for main agent only.

## Pre-publish ledger
- Sources checked: 5 research agent reports covering 6+ repos
- Claims made: 1 (emerging — pattern works but quality review gap noted)
- Conflicts resolved: none found
- Application evidence: ψ/memory/retrospectives/2026-05/25/09.34_ccc-academy-website-upgrade.md
- Codex reviewed: no
