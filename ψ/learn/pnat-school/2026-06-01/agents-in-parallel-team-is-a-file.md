---
type: learning
topic: P'Nat masterclass — "a team is a file" / agents-in-parallel (maw multi-agent team formation)
source: pnat
class_channel: 1500775333283237970
class_date: 2026-06-01
maturity: emerging
retrieval_terms: [maw-team, team-is-a-file, maw-wake-wt, agents-in-parallel, team-up, gather, worktree-isolation, cross-engine-messaging, config-hierarchy, voice-transcription, typhoon-asr, groq-whisper]
sister_lineage: none
gate_hook: "none yet — concept capture; application gate = run a real DEVBOY team via maw wake --wt before marking solid"
---

# P'Nat masterclass — "a team is a file" (agents-in-parallel)

Ingested per Captain directive (2026-06-02, channel 1500775333283237970): read history → list missed → learn. Full-day class (2026-06-01) where P'Nat taught fleet multi-agent team formation and every oracle (No.1, ZYN, SomBo, SomTor, B3, Dratini, Vessel, Lucid) reproduced + proved it. Published book: **https://nazt.github.io/agents-in-parallel/** (Ch.1-12).

## Thesis (SomBo capstone)
> "A team is a file; two idempotent verbs bind that file to live panes; every operation is a non-destructive move."

## 1. The 3-file pattern (only 2 are truth)
- **`[C]` Charter** — `ψ/teams/<team>.yaml` — WHO/WHAT: roles + engine per member. **committed**, engine-agnostic.
- **`[E]` Engine map** — `.maw/maw.config.80.json` — HOW: friendly name → launch cmd (e.g. `claude48`, `omx`, `sonnet`). **committed**, cross-engine.
- **`[L]` Live state** — `~/.claude/teams/<team>/config.json` + inboxes + manifest — NOW: machine-local, **auto-written, NEVER committed**.
- Asymmetry **is** the pattern: source → live, never live → source. Regrow live from the two committed files; never reverse.

## 2. Config hierarchy
`built-in → 50 (user) → 80 (project) → 80.local (wins)`. `.maw/*.local.json` = never committed (ports, tokens, oracleUrl). Restricted keys (`federationToken / peers / namedPeers / port / bind / sessions`) must live in `.50.json` or `.80.local.json` (maw warns if in project scope). `.maw/*.local.json` must be gitignored. (source-verified `paths.ts:36`, `load.ts:61-70` by No.1.)

## 3. Keystone spawn (v3 — 1 atomic command)
```bash
maw wake <Org>/<repo> --wt <slot> -e <engine> --session <sess>
```
- Does worktree + branch + pane + engine in ONE command (replaces manual `git worktree add` + `maw new --split --path`).
- **org-qualified name REQUIRED** — bare names resolve to first match silently (wrong repo).
- `--wt` creates/reuses worktree; `-e` reads engine map; `--fresh` = clean slate; existing worktrees reused by suffix match (safe respawn).

## 4. Pipeline + skills
- Pipeline: `plan` (read-only) → `preflight` (6 checks) → `load --no-spawn` (materialize, no panes) → `spawn`.
- **`/team-up`** — idempotent ensure: live→skip, dead→relaunch, missing→wake (`--gather` composes).
- **`/gather`** — join-pane members beside lead (`--scatter` back). join-pane = a MOVE (process keeps running), not a copy.
- **`/local-team`** — manual baseline (declare→spawn→prove→teardown). Fleet evolving manual → ensure/gather.

## 5. Isolation (the #1 silent trap)
Each writer needs its own worktree or they clobber with **no conflict markers — just lost work**. `maw wake --wt` = isolated (writers); `maw swarm` = shared cwd (read/review only). **PROVE isolation by walking each pane pid→cwd for distinct paths — never trust the roster.**

## 6. Liveness + messaging gotchas
- **Liveness = `pane_current_command`** (zsh/bash/sh = dead pane), NOT the ●/◌ dot (quiet-live agent reads stale). e.g. Hermes daemon shows `python` not `claude` — naive "is it claude?" check would call it dead.
- **Cross-engine messaging asymmetric**: claude member → `maw hey <addr>`; omx member → `maw run <addr>` + `send-enter` + `peek`.
- YAML: `>` folded scalar fails maw parser → single-line quoted strings. `--split` same-session breaks (#1835) → members become separate windows. `-e codex` sometimes ignores project `.maw` engine map (resolves global). Use `python3` for JSON (jq not guaranteed). tmux session+window same name can glob-collide.
- Upstream issues filed: #1971-1976 (team-up #1976, gather #1973) — gaps became native-verb roadmap.

## 7. Voice transcription (fleet survey — 07:37-07:50 thread)
P'Nat posted a 103MB video (> 25MB Discord bot limit) → `ffmpeg` to 1MB mp3 first, then transcribe. Models fleet actually used:
- **Typhoon ASR** (Thai-primary) — No.1, SomBo
- **Thai whisper local** — Lucid
- **Groq Whisper Large-v3** (cloud, OpenAI-compatible API, `whisper-large-v3`, 16kHz mono) — DEVBOY-documented; ~0.4s, 53°C vs local Pathumma medium 81°C. Needs `GROQ_API_KEY`. Fallback: `faster-whisper tiny` (local CPU). (cross-ref my [[2026-05-20_thai-voice-pipeline-lessons-from-oracle-voice-bot]] + article #038 OmniVoice-Thai.)

## Standing class exercise (P'Nat @everyone, 07:26)
> "do /loop every 60m to try create team like we learn today; use /trace --deep to find."
@everyone broadcast = class exercise, not a direct command. DEVBOY-relevance: high (maw/multi-agent = my slot). Not auto-started without direct authorization (recurring autonomous action).

## Cross-reference (Pass-2)
- DEVBOY articles #003 (maw team engine), #031 (team-tile bootstrap), #042 (maw-js advanced) — this masterclass supersedes/extends them with the v3 `maw wake --wt` keystone + team-up/gather. Candidate for a new Lab article.
- Internal repos referenced (volt-oracle, sombo-oracle, b3-oracle under Soul-Brews-Studio & others) = **read-only upstream, study only, never push**.
- Application gate (to reach `solid`): ✅ MET 2026-06-02 — stood up `devboy-codex2` (charter + engine map + plan→preflight→load), proved isolation by pid→cwd (coder-1 pid 2603473 cwd agents/1-coder-1, coder-2 pid 2603654 cwd agents/1-coder-2, distinct branches). Documented in article #071. **Gotcha found:** `maw wake -e codex` on v26.5.21 does NOT read project `.maw/maw.config.80.json` → falls to global default `claude --continue` → "No conversation found" → bash (confirms SomBo #2+#3). Engine resolution from project .maw is version-gated (newer maw only).

## Pre-publish ledger
- Sources checked: channel 1500775333283237970 full 100-msg history (2026-06-01 07:10→14:19), published book nazt.github.io/agents-in-parallel, my own voice-pipeline learning + gist inbox.
- Claims made: ~8 (emerging — captured + reasoned from class; no DEVBOY application evidence yet).
- Conflicts resolved: maw `promote` verb = Docs≠Runtime across versions (No.1: fleet `v26.5.21` lacks it, P'Nat source newer) — flagged, not averaged.
- Application evidence: N/A yet — gate = run a real team via maw wake --wt.
- Codex reviewed: no (concept ingest, not code).
