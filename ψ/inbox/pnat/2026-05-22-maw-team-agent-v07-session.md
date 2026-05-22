---
type: inbox
source: pnat (Discord #road-to-dev, msg_id 1507247132996931686, attachment)
date: 2026-05-22
pass: 1 (verbatim summary)
trigger: "@all-oracles [attachment: message.txt]"
---

# P'Nat's digger-oracle Session: maw team-agent v0.3 → v0.7.0

## Key Updates (v0.7.0 vs v0.2.0 we tested)

### New Subcommands (13 total, up from ~10)
- `maw team-agent init <name> [--preset]` — generate YAML scaffold
- `maw team-agent from <file.yaml> [--dry-run]` — load team from YAML charter

### 3 Ways to Spawn a Team
1. **Manual** (step by step) — create → spawn (what we tested)
2. **YAML charter** — `maw team-agent from ψ/teams/my-team.yaml` (one command)
3. **Init + edit + from** — generate template → customize → deploy

### YAML Charter (NEW)
```yaml
name: my-team
description: "${PROJECT_NAME} team"
session-id: ${SESSION_ID}
cwd: ${PROJECT_ROOT}
vars:
  SRC: ${PROJECT_ROOT}/src
members:
  - role: reviewer
    cwd: ${SRC}
    color: green
    system-prompt: "Security reviewer for ${PROJECT_NAME}"
    mission: "Review the codebase"
  - role: writer
    branch: team/writer  # auto worktree!
    color: cyan
    system-prompt: "Technical writer"
```

### 6 Presets
| Preset | Members |
|--------|---------|
| blank | 1 TODO |
| solo | helper |
| pair | reviewer + writer |
| trio | reviewer + writer + lead |
| review | security + docs |
| stack | architect + frontend + backend + tester |

### cmd print on spawn (learning tool)
Every spawn now prints the full `claude.exe` command with ALL 10 flags — copy-pasteable for learning.

### maw team vs maw team-agent comparison
- maw team: 2 flags (model + prompt-file)
- maw team-agent: 10 flags (session-id, parent, agent-id, name, team, color, model, prompt, env, perms)

### Docs shipped (3,218 lines total)
README.md (143), BASIC.md (175), TESTING.md (476), BOOK.md (706), WORKSHOP.md (712), TUTORIAL.md (977)

### Key lesson from P'Nat
"Align with platform-native APIs instead of inventing parallel concepts" — eliminated redundant team-id concept, aligned with Claude Code's native --session-id model.

---

## Pass 2: Cross-reference

### Impact on our learning files
- Our learning (ψ/learn/pnat/maw-team-agent/2026-05-22/) covers v0.2.0 — needs update for v0.7.0
- YAML charter is the big new feature — enables declarative team composition
- Auto worktree per member = git branch isolation
- Template vars = reusable team definitions

### Maturity update
- v0.2.0 (what we tested): 🟡 emerging
- v0.7.0 (P'Nat shipped): moving toward ✅ solid (11 tests, 31/31 pass, workshop verified)
