---
query: "maw-rs + arra-safety-hooks"
target: "Soul-Brews-Studio/maw-rs + Soul-Brews-Studio/arra-safety-hooks"
mode: deep-dig
timestamp: 2026-05-21 10:33
friction_score: 0.3
coverage: [oracle, files, git, cross-repo, github]
confidence: high
---

# Trace: maw-rs + arra-safety-hooks

**Target**: Soul-Brews-Studio (2 repos)
**Mode**: deep-dig | **Friction**: 0.3 | **Confidence**: high
**Time**: 2026-05-21 10:33 GMT+7

## Oracle Results

FTS: 0 matches for "maw-rs" or "arra-safety-hooks".
Vector: related maw-js content (retros about maw upgrade, maw wake bugs, fleet skills install). No maw-rs or arra-safety-hooks specifically.

## Repo 1: maw-rs

### Identity
- Rust port of maw-js portable core
- v0.1.0-alpha.1, BUSL-1.1
- 21 crates in Cargo workspace, 95.53% coverage
- Solo author: Nat, 50 commits (all 2026-05-21)
- `unsafe_code = "forbid"`, pedantic clippy

### Architecture
- Phase 1 (current): pure/deterministic logic — I/O-free crates with injected dependencies
- Phase 2 (planned): runtime IO adapters (tmux process, HTTP federation, Zenoh)
- Phase 3 (planned): clap CLI binary, replace maw-js commands one by one
- JSON fixture parity: test files copied from maw-js, both engines must agree

### 21 Crates
maw-auth, maw-auto-wake, maw-bind, maw-bring, maw-calver, maw-cli, maw-feed, maw-fuzzy, maw-hub, maw-identity, maw-matcher, maw-peer, maw-plugin-manifest, maw-plugin-scaffold, maw-policy, maw-routing, maw-split, maw-tmux, maw-transport, maw-worktree, maw-xdg

### What's New vs maw-js
- Pure-core isolation by design (every crate IO-free)
- WASM plugin support (Rust + AssemblyScript scaffold targets)
- Deterministic fixture parity testing
- BTreeMap/BTreeSet for deterministic output

### What's Missing
- All runtime IO (tmux exec, HTTP server, Zenoh)
- maw team (spawn, task queue, shutdown)
- maw osmosis (cross-node sync)
- Plugin registry
- Web UI

## Repo 2: arra-safety-hooks

### Identity
- Claude Code PreToolUse hook (bash script)
- 3 files: README.md, install.sh, safety-check.sh
- MIT license
- Born 2025-12-27 by Nat + Claude Opus 4.5
- 12 commits, 1 star, 3 forks

### 12 Hard Blocks
rm -rf/f, git --force/-f, git reset --hard, git push origin main, git commit --amend, git checkout -- ., git restore ., git clean -f, git branch -D, git stash drop/clear, --no-verify, gh pr create to foreign org

### Beta Rules (opt-in via /tmp/arra-safety-beta-on)
- Block raw tmux commands → use maw hey
- Block bun run src/cli.ts → use maw binary
- Warn on localhost → suggest .wg hostname
- Warn on .local → suggest .wg fallback

### Security Assessment
Strengths: enforcement > documentation, self-bypass blocked, regex anchoring
Gaps: /tmp-based state world-writable, Bash-only (Write/Edit/MCP unguarded), no automated tests (PR #2 adds 38), gh org check fails open on network error

### Open Issue #1
False positive on destructive-command text inside gh issue/pr bodies (heredocs). PR #2 fixes with 5-LOC exemption + 38 tests.

## Session History (from /dig)

- Session 5158a157 (35.5h active): Captain ordered trace at 03:33 UTC (10:33 GMT+7)
- No prior sessions touched maw-rs or arra-safety-hooks
- Prior maw-js knowledge: retros about maw wake bugs, maw upgrade, fleet skills
- No ψ/learn/ entries exist for either repo — knowledge gap

## Cross-Repo Matches

Soul-Brews-Studio repos cloned locally:
- maw-rs, maw-js, maw-ui, arra-safety-hooks, multi-agent-workflow-kit
- ψ/learn/ has from-mlboy Soul-Brews entries for webhook-relay-oss + multi-agent-workflow-kit only

## Friction Analysis

**Score**: 0.3 ████░░░░░░░░ Hidden — found via ghq clone, not in Oracle
**Coverage**: oracle, files, git, cross-repo, github (5/5)
**Goal check**: YES — both repos thoroughly analyzed (architecture, code, security, comparison, session history)

**Action zone**: 0.3 = Cross-repo consolidation needed. Both repos should be indexed in Oracle + documented in ψ/learn/.

## Summary

**maw-rs**: Nat's Rust rewrite of maw-js. Phase 1 done (21 crates, pure logic, fixture-locked). Production replacement is Phases 2-3 away. Architecture is clean — unsafe forbid, injectable IO, deterministic tests. Worth watching as future fleet dependency.

**arra-safety-hooks**: Simple but effective — 12 regex rules in a bash script that make destructive commands impossible at the tool layer. Enforces Oracle Principle 1. One known bug (heredoc false positive) with fix in review. Fleet should adopt this hook.
