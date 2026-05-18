# /learn — multi-agent-workflow-kit (MLBOY perspective, ML angle)

**Date**: 2026-05-11 20:42 GMT+7
**Repo**: github.com/Soul-Brews-Studio/multi-agent-workflow-kit (cloned via gq)
**Version**: v0.5.1
**Source**: P'Nat directive (msg `1503390978755788861`) — "multi agent workflow kit ก็ทำก่อน"
**Cross-ref**: glueboy/ψ/learn/Soul-Brews-Studio/multi-agent-workflow-kit/ (2026-03-16 deep study)

## 1. What it is (1 line)

Predecessor to current `maw` v2 — Python/Bash kit using git worktrees + tmux to run multiple Claude Code/Codex agents in parallel on the same codebase.

## 2. Tech profile

```
Language:     Python 3.12
Package:      multi-agent-kit v0.5.1 (uvx-installable)
Status:       Proof of Concept (kit label)
Bootstrap:    uvx --from git+...@v0.5.1 multi-agent-kit init
Prereqs:      git ≥2.5, tmux ≥3.2, yq, uvx
Activates:    `source .envrc` → `maw attach`
Supports:     Claude Code + Codex agents (.claude/, .codex/ both managed)
```

Recent commits (last 10): CI smoke tests, v0.5.1 release, AGENTS.md → MAW-AGENTS.md rename, uninstall cleanup. Maintainer is active.

## 3. Architecture (vs maw v2 we use)

| Concept | kit v0.5.1 (this) | maw v2 (DO fleet) |
|---|---|---|
| Language | Python + Bash | Rust core + TS plugins (v2.0.0-alpha.42) |
| Isolation | git worktree | tmux session per oracle + worktree on demand |
| Coordination | shared tmux session, manual ψ | persistent peer registry, `maw hey`, federation |
| Identity | none — generic agents | CLAUDE.md per oracle (BOY identity) |
| Memory | none built-in | ψ/memory/ + auto-memory + arra Thread |
| Multi-machine | ❌ | ✅ (clinic-drdo + m5 + future) |
| Soul/lineage | ❌ | ✅ arra Thread #2 (family) |
| Plugins | hardcoded scripts | 54 dynamic plugins (legacy + symlink) |
| Skill system | n/a | arra-oracle-skills-cli, /dig, /trace, /learn |
| Setup cost | `uvx init` | `maw bud <name>` (we just used this 20:35 GMT+7) |

**Verdict**: kit is the seed; maw v2 is the tree. Same DNA, different generation.

## 4. What's still relevant for MLBOY

### Borrowable patterns
1. **`.envrc` + `source .envrc` bootstrap** — already in MLBOY (per local-config lesson `8e56d51`). Kit pattern validated.
2. **`uvx --from git+...` install** — bootstrap mechanism MLBOY could use for installing ML training kits (`uvx --from git+huggingface/transformers fine-tune ...` pattern)
3. **`.codex/` dual-support** — kit treats Codex + Claude as peers; MLBOY's Codex co-review (Standing Order #1) follows same spirit
4. **uninstall hygiene** — kit auto-cleans `.codex`/`.claude` on remove; MLBOY's `/forward` + `/rrr` should leave similar clean state

### Not borrowable (we've moved past)
- Manual tmux session management — `maw wake`/`maw sleep` already abstracts
- Generic agent identity — MLBOY's BOY identity + Soul-Brews-Studio Thread is richer

## 5. ML angle — does kit help MLBOY workflows?

**Yes — for parallel ML experiments on single machine**:
- Fan-out: 3 git worktrees, each fine-tuning a different model variant (LR/regularization sweep)
- Each agent in own worktree = no checkpoint collision
- Shared tmux = Captain can see all 3 train at once
- Result: pick winner, merge to main

**No — for cross-machine GPU work**:
- kit is single-machine; ML training needs GPU node access
- Use maw federation instead

**Hybrid**: use **kit's worktree pattern WITHIN one MLBOY session** for sweep experiments, while maw v2 handles cross-BOY communication. Don't install kit globally — extract the `git worktree add ../wt-${variant}` pattern as a one-off script for ψ/lab/sweep/.

## 6. Direct comparison to maw v2 `maw bud`

We just ran `maw bud crucible-test --org dryoungdo --blank` 7 min ago. Same effect as kit's `multi-agent-kit init` BUT:
- maw bud creates a REAL Oracle (CLAUDE.md, ψ/, GitHub repo, federation membership)
- kit init creates a generic worktree session (no identity, no memory, ephemeral)

→ For DO fleet style (persistent BOY oracles), `maw bud` > `kit init`.
→ For ephemeral parallel exploration (3 worktrees, 1 PR review, done), `kit init` is lighter.

## 7. Recommendation — DON'T install kit, EXTRACT pattern

1. **Skip `uvx ... init`** in MLBOY (would conflict with maw fleet's tmux session naming)
2. **Borrow worktree-sweep pattern** to `ψ/lab/sweep/template.sh` when ML experiments need parallel
3. **Watch kit evolution** — it's the public lineage of maw; if it stabilizes past PoC, may inform what maw v2 should expose externally
4. **No new dependencies installed** — Rule: minimum surface area for ML environment

## 8. Cite

- multi-agent-workflow-kit: github.com/Soul-Brews-Studio/multi-agent-workflow-kit @ v0.5.1
- glueboy prior /learn: 2026-03-16 deep study (ψ/learn path)
- maw v2 today: `maw --help` (v2.0.0-alpha.42 built 2026-04-16)
- `maw bud crucible-test` run: 2026-05-11 ~20:35 GMT+7

🔥⚗️ — MLBOY (P'Nat directive, kit-first ordering respected)
