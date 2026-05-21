---
type: learning
topic: gale-oracle architecture — oracle-build.sh, tier spawning, codex coprocessor
source: research
maturity: emerging
retrieval_terms: [oracle-build-sh, shared-claude-md, tier-spawning, codex-coprocessor, file-based-status, gale-oracle-arch]
date: 2026-05-22
---

# gale-oracle Architecture

## System Overview

```
┌─────────────────────────────────────────────────┐
│              gale-oracle (main)                  │
│  Claude Opus 4.6 · /goal validator · arra MCP   │
├─────────────┬─────────────┬─────────────────────┤
│  /goal      │  maw peek   │  oracle-build.sh    │
│  (Haiku     │  (monitor   │  (identity          │
│   validator)│   workers)  │   generator)        │
├─────────────┴─────────────┴─────────────────────┤
│              Worker Layer                        │
│  .2 Claude │ .3 Codex (GPT-5.5) │ .N workers   │
├─────────────────────────────────────────────────┤
│              maw-js Runtime                      │
│  team spawn │ triggers-idle │ worktree-cleanup  │
├─────────────────────────────────────────────────┤
│              Persistence Layer                   │
│  ψ/memory │ arra-oracle MCP │ git + ghq        │
└─────────────────────────────────────────────────┘
```

## oracle-build.sh — Identity Generator

Wind's key innovation: **generated CLAUDE.md** from modular parts.

```bash
# Conceptual flow (from doctor-oracle analysis):
cat shared-claude.md > CLAUDE.md        # fleet-wide rules
cat oracle-<name>-claude.md >> CLAUDE.md # per-oracle identity
# Backup with timestamp precision
cp CLAUDE.md .oracle-build-backups/CLAUDE.md.$(date +%s)
```

**Why**: One `shared-claude.md` propagates principles across all 7 oracles. Per-oracle identity file adds role-specific rules. Rebuild = consistent fleet-wide behavior.

**Compare to DO fleet**: We use individual CLAUDE.md per oracle, sync via `git pull` from glueboy canonical. Wind's approach is more DRY but requires the build script as single point of failure.

## Tier-Based Agent Spawning

```
Task arrives
├── <5 min, single file → Tier 1: Single-agent (main oracle handles)
├── 5-30 min, multi-file → Tier 2a: maw team spawn --codex (coordinated workers)
├── Parallelizable batch → Tier 2b: maw swarm codex codex codex (raw parallel)
└── >30 min, persistent → Tier 3: maw workon / maw wake (cross-machine)
```

### Worker Naming Convention

Workers are named `<session>:<oracle>.N` where N is auto-incremented:
- `03-gale:gale-oracle` — main
- `03-gale:gale-oracle.2` — worker 2
- `03-gale:gale-oracle.3` — worker 3

This is a **maw naming convention**, not Claude Code built-in. Claude Code's Agent View uses hex IDs.

### Codex Coprocessor

Wind runs **GPT-5.5 xhigh** alongside Claude Opus:
- Claude = orchestrator + primary worker
- Codex = parallel worker for documentation, review, secondary tasks
- Both access same ψ/ vault and arra-oracle MCP
- Status visible via `maw peek` from main oracle

## File-Based Status Reporting

Workers signal completion via filesystem, not messages:
```
.codex-reports/
├── <role>-done.md    # worker completed successfully
├── <role>-stuck.md   # worker hit blocker
└── <role>-progress.md # intermediate status
```

Enables **async orchestration** — main oracle polls files instead of blocking on message responses.

## 6-Phase Work Cycle (per Worker)

```
SEARCH → EXPLORE → PLAN → IMPLEMENT → VERIFY → REPORT
```

Each phase has explicit gates:
1. **SEARCH**: arra_search mandatory before any exploration
2. **EXPLORE**: read files, understand codebase
3. **PLAN**: write plan, get alignment
4. **IMPLEMENT**: code changes in worktree
5. **VERIFY**: run tests, smoke-test endpoints
6. **REPORT**: write findings to .codex-reports/ or ψ/

## Context Management

| Mechanism | When | What |
|-----------|------|------|
| `/goal` | Start of work | Set completion condition |
| `/rrr` | ~50% context | Session retrospective |
| `/forward` | ~60% context | Handoff to next session |
| `/compact` | Manual | Context hygiene (gated behind /rrr) |
| Handoff docs | End of session | ψ/inbox/handoff/ with commits, pending, key files |

## Safety Hooks

PreToolUse hooks block dangerous operations:
- `rm -rf` → blocked
- `git push --force` → blocked
- `git commit --amend` on pushed commits → blocked
- File permissions changes on sensitive paths → blocked
