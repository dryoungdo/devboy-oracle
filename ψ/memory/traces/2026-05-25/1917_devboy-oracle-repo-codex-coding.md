---
query: "devboy-oracle repo structure + codex coding hands"
target: "devboy-oracle"
mode: deep
timestamp: 2026-05-25 19:17
friction_score: 0.7
coverage: [oracle, files, git, github]
confidence: high
---

# Trace: devboy-oracle repo structure + codex coding hands

**Target**: devboy-oracle
**Mode**: deep (3 parallel agents) | **Friction**: 0.7 | **Confidence**: high
**Time**: 2026-05-25 19:17 ICT

## Repo Architecture

**Classification: Knowledge management + Discord bot — NOT a production codebase.**

```
devboy-oracle/
├── CLAUDE.md              (62 KB) — DEVBOY identity + operating doctrine
├── AGENTS.md              (1.9 KB) — Codex worker contract
├── start.sh               (1 KB) — Discord bot launcher (claude --model claude-opus-4-6 --channels)
├── scripts/
│   └── oracle-build.sh    (2.9 KB) — Generates CLAUDE.md from oracle-build/ templates
├── oracle-build/          — Identity source templates (shared-claude.md + oracle-devboy-claude.md)
├── docs/                  — Static HTML knowledge site
│   ├── articles/          (58 HTML files — published knowledge articles)
│   ├── css/style.css      (584 LOC)
│   └── js/                (auth.js + search.js + sidebar.js = 292 LOC)
├── ψ/                     — Oracle memory system
│   ├── memory/            (learnings, retrospectives, traces, dreams, audits)
│   ├── inbox/             (19 handoff files)
│   ├── lab/               (experimental work)
│   ├── learn/             (structured knowledge)
│   └── outbox/            (bud signals to GLUEBOY)
├── .codex-reports/        — Codex review outputs (GOAL.md, done reports)
└── .claude/               — Claude Code config (settings.json, settings.local.json)
```

## Actual Code Inventory

| Layer | Files | LOC | Purpose |
|-------|-------|-----|---------|
| Frontend JS | auth.js, search.js, sidebar.js | 292 | Article site functionality |
| CSS | style.css | 584 | Site theme + layout |
| HTML | 58 articles | ~137K | Knowledge journal |
| Bash | oracle-build.sh, start.sh | ~100 | Build + launch |
| **Total runtime code** | **6 files** | **~976 LOC** | |

**Zero backend code.** No package.json, no Cargo.toml, no build system. The "backend" is Claude Code itself running as a Discord bot via `start.sh`.

## Codex Coding Hands

**DEVBOY has Codex (GPT-5.5) as co-reviewer, NOT as primary coder.**

- Standing order: Codex review if ≥30 LOC produced
- `.codex-reports/GOAL.md` tracks goal-driven work (status/tier/worker fields)
- `AGENTS.md` = Codex worker contract (stripped of Claude-specific sections: Discord, MCP, subagents)
- Twin-engine protocol: Claude owns direction/judgment, Codex handles code-heavy implementation + second-engine review

**What DEVBOY has actually built (git history):**
- 58 HTML knowledge articles (CCC Academy, Anthropic guides, fleet docs)
- Hybrid client-side search (docs/js/search.js)
- Dynamic sidebar navigation
- Password gate + Thai language support
- oracle-build/ pattern (deterministic CLAUDE.md generation)
- Discord MCP env injection fix (.mcp.json patch)

**What DEVBOY does NOT do:**
- Ship production code (that's FORGEBOY)
- Build backend services
- Deploy infrastructure
- Make architecture decisions for production

## Git History Summary

- **71 commits** total (57 from DO, 11 from Mac Studio, 3 from dryoungdo)
- **2 merged PRs**: Phase B mlboy+iotboy absorption, DEVBOY identity v2.1
- **3 open issues**: #3 Discord .mcp.json, #4 MCP health verifier, #5 WireGuard peers
- Key phases: Birth (2026-05-19) → maw fusion (absorb mlboy+iotboy) → site build → CCC Academy articles → Anthropic deep trace

## Oracle Memory

- **19+ learnings** in ψ/memory/learnings/
- **5+ retrospectives** in ψ/memory/retrospectives/
- **Key patterns documented**: parallel agent content pipeline, Discord env injection root cause, Anthropic docs domain map, article language style

## Friction Analysis

**Score**: 0.7 — Visible (files + high confidence)
**Coverage**: oracle, files, git, github (4/5 dimensions)
**Goal check**: YES — fully answered. DEVBOY is a knowledge system with small frontend, not a coding repo. Codex is used as reviewer, not primary builder. "Coding hands" = articles + scripts + site JS, not production software.

## Summary

DEVBOY is a **learning machine**, not a coding machine. Its output is:
1. **Knowledge articles** (58 and growing) — the primary deliverable
2. **Oracle memory** (7,014 Arra docs) — fleet-searchable learnings
3. **Bud signals** — when knowledge matures, GLUEBOY spawns a production BOY

The "codex coding hands" are limited to:
- Co-reviewing code >30 LOC before commit
- Goal-driven work tracking via .codex-reports/
- Twin-engine protocol (Claude leads, Codex reviews)

**DEVBOY learns. Production BOYs ship.**
