---
query: "team-tile-bootstrap"
target: "nazt/1ffec5896ece7b911a8ab9134df99ae1 (P'Nat gist)"
mode: deep
timestamp: 2026-05-21 01:12
friction_score: 0.90
coverage: [oracle, files, git, cross-repo, github]
confidence: medium
agents: 5
---

# Trace: team-tile-bootstrap

**Target**: P'Nat's gist (All-Maw-Verbs Team Bootstrap)
**Mode**: deep (5 agents) | **Friction**: 0.90 | **Confidence**: medium
**Time**: 2026-05-21 01:12 GMT+7

## Oracle Results
- `glueboy__2026-02-06_multi-agent-task-analysis-engine-architecture.md` — TAE method selection, token multipliers (7-15x for Agent Teams), max 5 teammates
- `glueboy__2026-03-08_maw-js-architecture.md` — content hash detection, tmux integration patterns

## Files Found (16 matches across 8 dimensions)
- `ψ/learn/from-mlboy/agent-teams/2026-05-11_agent-teams-vs-inter-session.md` — HIGH: Native Teams architecture, TeamCreate, SendMessage, display modes, limitations
- `ψ/learn/from-mlboy/agent-teams/2026-05-11_recall-vs-maw-mega.md` — HIGH: maw mega wraps TeamCreate, 4-system overlapping primitives
- `ψ/learn/pnat-school/2026-05-19/0002_API-SURFACE.md` — HIGH: maw team CLI verbs, 8 claude.exe flags, Communication Decision Tree
- `ψ/learn/pnat-school/2026-05-19/0003_ARCHITECTURE.md` — HIGH: FILE-BOUND discovery, Two-Store design, reincarnation engine
- `ψ/memory/learnings/from-iotboy/2026-05-08_oracle-messaging-101.md` — MEDIUM: maw hey as canonical primitive
- `ψ/memory/learnings/from-iotboy/2026-05-11_tmux-send-keys-to-peer-oracle-anti-pattern.md` — LOW: anti-pattern context
- `ψ/memory/learnings/2026-05-19_maw-js-1804-silent-sessions.md` — MEDIUM: dispatch pipeline
- `docs/articles/003-maw-team-engine.html` — HIGH: team lifecycle, Two-Store, communication table
- `docs/articles/007-maw-js-orchestrator.html` — MEDIUM: maw-js architecture, federation
- `docs/articles/023-agent-comparison.html` — MEDIUM: Agent Teams row (concept level only)

## NEW vs KNOWN

### KNOWN (strong foundation)
- TeamCreate / SendMessage concepts + maw mega wrapping
- 8 claude.exe spawn flags
- Communication Decision Tree
- FILE-BOUND not SESSION-BOUND principle
- maw team lifecycle commands
- Native Teams limitations vs maw fleet

### NEW (this gist's contribution)
1. **`maw tile N` verb** — tmux pane tiling command, no prior mention anywhere
2. **maw-js #1837** — collapsed `maw tile` + `maw run` into single `maw tile --path --cmd`
3. **`<teammate-message>` XML wire format** — 5 body shapes, regex from claude.exe binary
4. **Canonical addressing** — `<session>:<window-idx>.<pane-idx>` vs raw `%pane-id`
5. **6 seams** enumerated (visibility, addressing, shutdown)
6. **bootstrap.ts** — Bun script (findClaudeBin, parseMember, buildClaudeCmd)
7. **All-Maw-Verbs pattern** — complete verb chain choreography
8. **3 skill definitions** — team-tile-spawn, team-tile-demo, full-auto-long-demo

## Wire Protocol Analysis (Agent 2)

Wire format: `<teammate-message teammate_id="..." color="..." summary="...">body</teammate-message>`

5 body shapes (emergent, no schema):
1. Verbose markdown | 2. Short text ack | 3. JSON idle_notification | 4. JSON shutdown_request | 5. JSON shutdown_approved

Missing from protocol: timestamp, message_id/correlation_id, type discriminator field.

### Seam Severity Table
| # | Seam | Severity | Blast Radius | Mitigation |
|---|------|----------|-------------|------------|
| 1 | maw-workon workers lack team membership | Medium | Workers invisible to coordination | None (design gap) |
| 2 | GitHub issues no team binding | Low | Manual assignment only | babysit-prs pattern |
| 3 | XML render requires --agent-id env | Low | By design — intentional scoping | Correct behavior |
| 4 | Cross-session auth boundary | Medium | filesystem access = message injection | Unix perms only |
| 5 | maw ls blind to raw-spawn panes | Medium | Incomplete fleet dashboard | maw-js #1837 |
| 6 | shutdown_approved unreliable | **High** | Zombie processes, resource leak | tmux kill-pane follow-up |

## Code Review (Agent 3 — bootstrap.ts)
| Issue | Severity | Recommendation |
|-------|----------|----------------|
| `--dangerously-skip-permissions` hardcoded | CRITICAL | Make opt-in via flag |
| No partial-failure rollback | HIGH | Track spawned panes, cleanup on error |
| shellQuote regex incomplete | HIGH | Unconditional single-quote wrapping |
| findClaudeBin hardcodes NVM v24.15.0 | MEDIUM | Glob or `which claude` first |
| @ts-nocheck unnecessary | MEDIUM | Remove, code is valid TS |
| sleep-based readiness | MEDIUM | Poll loop with timeout |

## Fleet v3 Applicability (Agent 4)
| Dimension | Current (Agent()) | With team-tile | Gap |
|-----------|------------------|---------------|-----|
| Scope | Same repo, ephemeral | Cross-repo, persistent | Lab experiment needed |
| Communication | Result-only | Bidirectional SendMessage | Already works |
| Identity | Anonymous sub-agent | Named 7-flag identity | team-tile provides this |
| Cross-BOY coordination | maw hey (async) | Live teammates | GLUEBOY adoption needed |
| Bud validation | Manual | Pre-bud test via team-tile | Could be bud mechanism |

DO server: tmux 3.4, bun 1.3.11, maw-js v26.5.17-beta.2354 — all prerequisites present.

## Friction Analysis
**Score**: 0.90 — Near-perfect. Strong foundation exists in Oracle + ψ/learn/ for Agent Teams concepts. The NEW material (maw tile verb, wire format internals, 6 seams, bootstrap.ts) extends existing conceptual knowledge into concrete implementation.
**Coverage**: oracle, files, git, cross-repo, github (5/5 dimensions)
**Goal check**: Trace found comprehensive prior conceptual knowledge BUT zero prior knowledge of the specific team-tile bootstrap implementation. Confidence: medium — the delta is real and valuable.

## Summary
P'Nat's gist bridges DEVBOY's existing Agent Teams conceptual knowledge into concrete implementation. The 8 NEW items (maw tile verb, #1837, wire format, canonical addressing, 6 seams, bootstrap.ts, verb chain, 3 skills) are genuinely new. Maturity: **Emerging** (2/3 gates pass — missing application evidence). Next: lab experiment on DO server, then article 031.
