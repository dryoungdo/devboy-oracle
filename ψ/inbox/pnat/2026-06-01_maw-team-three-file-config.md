---
type: class-content
source: pnat
class_msg_id: 1510897402163232921
channel_id: 1500775333283237970
mention: "@everyone (broadcast — not a command)"
date: 2026-06-01
maturity: raw
status: under-curation
verbatim_attachment: ~/.claude/channels/discord/devboy/inbox/1780296425960-1510897401874092096.txt
retrieval_terms: [maw-team, three-file-config, charter, engine-map, live-state, volt-oracle, codex-team, spawn-pipeline]
---

# Class content (Type A) — maw team "three-file config" pattern

**Trigger:** P'Nat posted `@everyone` + `message.txt` (19KB) in channel `1500775333283237970`, msg_id `1510897402163232921`, 2026-06-01. @everyone = broadcast signal, not a directive (per Discord command-vs-chat gate). Captured for offline two-pass ingestion; no real-time reply (Type A).

**Verbatim source:** full transcript saved at `~/.claude/channels/discord/devboy/inbox/1780296425960-1510897401874092096.txt` (296 lines). This file is the Pass-1 verbatim record.

## What it is (Pass-1 summary, raw)

A session transcript (Wave / volt-oracle in Soul-Brews-Studio) demonstrating how a maw team is configured across **three config layers**, then run through the **maw team v2.0.1 pipeline**:

- **`[C]` Charter** — `ψ/teams/<team>.yaml` (committed). Declares members, roles, colors, model, branch, worktree-name, system-prompt, goal.
- **`[E]` Engine map** — `.maw/maw.config.NN.json` (committed). Maps logical model names → launch commands (e.g. `claude48` → `ANTHROPIC_MODEL=claude-opus-4-8 command claude --dangerously-skip-permissions`; `omx` → `omx --yolo --direct`). FRESH keys omit `--continue`; `-resume` variants are respawn-only.
- **`[L]` Live state** — `~/.claude/teams/<team>/config.json` (auto-written by `load`, not hand-edited) + per-member `inboxes/<role>.json` + `manifest.json` audit trail.

**Pipeline (each stage does strictly more):**
1. `plan` — read-only, lists artifacts, writes nothing
2. `preflight` — validates (unique roles, no collisions, targets, governance) — 6 checks
3. `load --no-spawn` — materializes live config + inboxes + manifest, **no panes**
4. `spawn` — grows the organism. Two placement options: (A) `maw team spawn-from <charter> --exec` = shared-cwd, fast but concurrent writes clash; (B) per-member `maw wake <oracle> --wt <role> --split -e omx` = worktree-isolated, write-safe (matches a charter that declares worktree-name + branch).

YAML gotcha observed: maw parser rejected `>` folded scalars — use single-line quoted strings (matching working `trio.yaml`).

## The 3-file interlock (clearer teaching diagram — P'Nat msg 1510897723526746234)

The canonical "how they interlock" view — each file answers one question:

```
ψ/teams/trio.yaml        "WHO is on the team + what they DO"   (CHARTER — recipe, committed, engine-agnostic)
   name: trio
   members:
     - role: searcher  model: sonnet           ┐ roles + prompts
     - role: coder     model: claude-opus-4-6  ┘ (human-meaningful part)
            │  maw resolves model name ↓
.maw/maw.config.80.json  "HOW to launch each engine"          (ENGINE MAP — dictionary, committed, cross-engine)
   commands:
     claude48 : "ANTHROPIC_MODEL=claude-opus-4-8 command claude ..."
     omx      : "omx --yolo --direct"
     *-resume : "...--continue" / "omx resume --last"  (respawn only)
     claude46/47, codex, thclaws : null  (tombstoned)
            │  maw swarm/wake spawns tmux pane running that exact command ↓
~/.claude/teams/<name>/config.json  "WHAT is running RIGHT NOW"  (LIVE STATE — ~/.claude global, claude.exe only)
   members:
     - shell-lead  agentType: shell      paneId: %87
     - codex       agentType: claude.exe paneId: %112  isActive: false
     - claude      agentType: claude.exe paneId: %113  isActive: false
```

**Flow in one sentence:** Charter (`role:coder, model:opus`) → Engine map (`omx → "omx --yolo --direct"`) → Live config (`paneId %112` running that command). Charter = recipe (what you write), engine map = dictionary (how names resolve to launch commands), live state = the running organism (auto-written, never hand-edited).

## Pass-2 TODO (cross-reference, not yet done)
- Reconcile vs DEVBOY articles #003 (maw team engine), #031 (team-tile bootstrap), #042 (maw-js advanced).
- Note: internal names referenced (volt-oracle, ccc-oracle, trio, omx/oh-my-codex). Soul-Brews-Studio = read-only upstream — study only, never push.
- Decide if this warrants a Lab article (maw team three-file config is a strong, concrete pattern).
