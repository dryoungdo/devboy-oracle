# Fleet Symmetry Audit — clinic-drdo Inventory

**Node**: clinic-drdo (DO DigitalOcean droplet)
**BOY**: DEVBOY (R&D Incubator)
**Collected**: 2026-05-21 17:00 GMT+7
**System**: Linux 6.8.0-111-generic x86_64, 2 vCPU, 8GB RAM, 160GB disk

---

## 1. maw

| Field | Value |
|-------|-------|
| Version | v26.5.21-alpha.1608 (8aa1bbd3) built 2026-05-21 |
| Remote | `github.com/Soul-Brews-Studio/maw-js.git` (upstream) |
| Install path | `~/.bun/install/global/node_modules/maw/` |
| Binary | `~/.bun/bin/maw` → `maw-wrapper.sh` → `maw-real` (symlink to src/cli.ts) |
| Port | 1412 |
| Node name | clinic-drdo |
| Federation token | `2QHmsYh-1UamE10V8mec0t5w0bGNHEZJ` |
| Peer key | `~/.maw/peer-key` (64 bytes, mode 0600) |
| PM2 process | `maw` (pid 193711, online, ~100MB) |

### maw config (`~/.config/maw/maw.config.json`)

```json
{
  "host": "local",
  "port": 1412,
  "oracleUrl": "http://localhost:47779",
  "commands": {
    "default": "claude --dangerously-skip-permissions --continue",
    "*-oracle": "claude --dangerously-skip-permissions --continue"
  },
  "sessions": {
    "glueboy": "02-glueboy",
    "forgeboy": "03-forgeboy",
    "ledgerboy": "04-ledgerboy",
    "wireboy": "05-wireboy",
    "chatboy": "06-chatboy",
    "coachboy": "07-coachboy",
    "chiefboy": "08-chiefboy",
    "wallet": "09-wallet"
  },
  "namedPeers": [
    {"name": "clinic-nat", "url": "http://127.0.0.1:3457"},
    {"name": "mba", "url": "http://10.20.0.2:3456"},
    {"name": "mac-studio", "url": "http://10.20.0.4:3456"}
  ],
  "agents": {
    "mycelium": "clinic-nat",
    "mother": "clinic-nat",
    "glueboy": "mac-studio",
    "testboy": "clinic-drdo",
    "metricboy": "clinic-drdo",
    "wallet": "clinic-drdo",
    "crucible-test": "clinic-drdo",
    "testboy-oracle": "clinic-drdo",
    "crucible-test-oracle": "clinic-drdo",
    "metricboy-oracle": "clinic-drdo",
    "devboy": "clinic-drdo"
  }
}
```

### maw peers (`~/.maw/peers.json`)

| Peer | Node | URL | Pubkey (prefix) |
|------|------|-----|-----------------|
| mac-studio | mac-studio | http://10.20.0.4:3456 | 892d2f66e210... |

### maw plugins (93 symlinks → Soul-Brews-Studio/maw-js/src/)

about, absorb, archive, artifact-manager, assign, attach, attach-ssh, avengers, awaken, bg, broadcast, bud, capture, check, cleanup, completions, consent, contacts, costs, cross-team-queue, demo, discover, doctor, done, dream, federation, find, fleet, health, inbox, incubate, init, kill, learn, locate, ls, mega, messages, on, oracle, oracle-skills, oracle-workon, overview, pair, pane, panes, park, peek, peers, ping, plugin, pr, profile, project, pulse, rename, restart, resume, reunion, run, scope, send, send-enter, send-text, session, setup, shellenv, signals, sleep, soul-sync, split, stop, stream, swarm, tab, tag, take, talk-to, team, tile, tmux, token, transport, triggers, trust, ui, view, wake, whoami, workon, workspace, zenoh-scout, zoom

### maw wrapper shim

`~/.bun/bin/maw` → `maw-wrapper.sh` — intercepts `maw hey` to detect ACK/DONE patterns and write `.pulse` files to chiefboy tasks directory. Pattern: Manager Clock Lock fix (T-20260418-007).

---

## 2. Claude Code

| Field | Value |
|-------|-------|
| Version | 2.1.112 |
| Model | opus (Claude Opus 4.6) |
| Effort level | xhigh |
| Skip dangerous mode prompt | true |
| Global CLAUDE.md | 1 line (`@RTK.md`) |
| RTK.md | 29 lines |

### settings.json (`~/.claude/settings.json`)

- **Model**: `opus[1m]`
- **Effort**: xhigh
- **Hooks**: PreToolUse → Bash → `block-tmux.sh` + `rtk hook claude`
- **Enabled plugins**: `discord@claude-plugins-official`, `pordee@pordee`
- **Custom marketplace**: `pordee` → `github:kerlos/pordee`
- **Spinner verbs**: custom (Forging signal, Burning noise, Trace-then-claim, etc.)
- **Spinner tips**: custom Thai+English tips (arra search, cite-then-claim, etc.)
- **Env**: `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=0`

### settings.local.json (`~/.claude/settings.local.json`)

Permissions allow:
- `Bash(arra-cli *)`, `Bash(maw bud:*)`, `Bash(maw hey:*)`, `Bash(maw ls)`, `Bash(maw peek:*)`, `Bash(maw soul-sync:*)`
- `mcp__arra-oracle__*`
- YD_GENCODE paths (Read/Write/Edit/Bash)

### Hooks

| Hook | Location | Purpose |
|------|----------|---------|
| `block-tmux.sh` | `~/.claude/hooks/block-tmux.sh` | Blocks direct tmux session control (send-keys, capture-pane, etc.) — forces maw abstraction. P'Nat directive 2026-05-11. |
| `rtk hook claude` | PreToolUse → Bash | RTK token-saving proxy |
| `hooks.json` | **MISSING** (no `~/.claude/hooks.json`) | — |
| Project hooks | **MISSING** (no `.claude/hooks.json` in repo) | — |

### Installed Claude Plugins

| Plugin | Version | Scope | Installed |
|--------|---------|-------|-----------|
| discord@claude-plugins-official | 0.0.4 | user | 2026-05-07 |
| pordee@pordee | 80310d44b3d1 | user | 2026-05-11 |
| ralph-loop@claude-plugins-official | 1.0.0 | project (glueboy) | 2026-04-07 |

### Global MCP Servers

- **No `~/.claude/.mcp.json`** — MCP servers are NOT configured globally
- arra-oracle MCP is available via `arra-oracle-skills` npm package (`~/.bun/install/global/node_modules/arra-oracle-skills/`)

---

## 3. Skills (`~/.claude/skills/` — 50 skills)

about-oracle, auto-retrospective, awaken, bampenpien, bud, bye, codex-review, contacts, create-shortcut, dig, dream, feel, fleet, fleet-delegation-template, forward, forward-lite, go, harden, i-believed, inbox, incubate, learn, machines, mailbox, morpheus, oracle-family-scan, oracle-soul-sync-update, philosophy, project, recap, recap-lite, release, resonance, rrr, rrr-lite, schedule, skills-list, standup, talk-to, team-agents, trace, vault, warp, watch, where-we-are, who-are-you, work-with, worktree, wormhole, xray

### KNOWN MISSING SKILLS (confirmed absent)

| Skill | Status |
|-------|--------|
| **/goal** | **MISSING** — GLUEBOY has it, DEVBOY does not |
| /pordee | **MISSING as skill** — exists as plugin only (`pordee@pordee`) |

### Repo-level skills (`.claude/skills/`)

**NONE** — no `.claude/skills/` directory in devboy-oracle repo

---

## 4. devboy-oracle Repo

| Field | Value |
|-------|-------|
| CLAUDE.md | 407 lines (v2.1, comprehensive identity + protocol) |
| AGENTS.md | **MISSING** |
| .claude/settings.json | **MISSING** (no project-level settings) |
| .claude/.mcp.json | **MISSING** (no project-level MCP) |
| .claude/hooks.json | **MISSING** (no project-level hooks) |
| .claude/skills/ | **MISSING** (no repo-level skills) |
| start.sh | Present — Discord wire start script (claude --model claude-opus-4-6 --channels plugin:discord@claude-plugins-official) |
| ψ/ structure | active/, archive/, inbox/, lab/, learn/, memory/, outbox/, writing/ |
| ψ/reference/ | **MISSING** |
| oracle-build | **NOT CHECKED** (no reference to oracle-build in repo) |

### Project memory (`~/.claude/projects/.../memory/`)

- MEMORY.md (index, 4 entries)
- feedback_always_trace_deep.md
- feedback_article_language.md
- feedback_discord_dmpolicy.md

---

## 5. Discord

| Field | Value |
|-------|-------|
| Bot name | DEVBOY-oracle |
| State dir | `~/.claude/channels/discord/devboy/` |
| dmPolicy | `allowlist` |
| allowFrom | Captain (721061586910838804), P'Nat (691531480689541170) |
| Groups | 29 channels configured (HUMAN SCHOOL server) |
| Autonomous channels | road-to-dev, esp32-dev, machine-learning-model, designer, regular-school, nat-s-preps (requireMention: false) |
| Mention-required channels | 23 channels |
| ClubsXai | 1 channel (classroom, allowFrom includes teachers) |
| Mention patterns | @everyone, @here, @all-oracles, @DEVBOY, @devboy, role ID |
| ackReaction | 👀 |
| Excluded channel | 👩👨🧑👧👦·human (per CLAUDE.md) |

---

## 6. System & Services

| Field | Value |
|-------|-------|
| OS | Ubuntu 24.04 (Linux 6.8.0-111-generic x86_64) |
| Node | v18.19.1 |
| Bun | 1.3.11 |
| RTK | 0.39.0 |
| ghq root | /home/drdo/Code |
| PM2 processes | maw (online), pm2-logrotate |
| tmux sessions | 01-devboy (1 window) |

### Cron jobs (active)

| Schedule | Job |
|----------|-----|
| */2 * * * * | glueboy ψ git-pull (memory sync MBA→DO) |
| 0 6 * * * | arra auto-standup |

### Cron jobs (disabled — v3 fleet migration)

- fleet-health.sh (CHIEFBOY-related)
- velocity-heartbeat (chiefboy repo deleted)
- keep-memo sweeps (CHATBOY now on Mac Studio)

---

## 7. Arra Oracle

| Field | Value |
|-------|-------|
| arra-cli | **NOT INSTALLED** as standalone CLI (`command not found`) |
| arra-oracle-skills | Installed via bun global (`~/.bun/install/global/node_modules/arra-oracle-skills/`) |
| MCP access | Via `mcp__arra-oracle__*` tools (works — used this session) |
| Database | `~/.arra-oracle-v2/oracle.db` (13.4MB SQLite) |
| Vector DB | `~/.arra-oracle-v2/lancedb/` |
| ψ link | `~/.arra-oracle-v2/ψ/` |
| Auto-standup | `~/.arra-oracle-v2/auto-standup.sh` (cron daily 6am) |

---

## 8. Known Asymmetries (self-identified)

| Item | clinic-drdo (DEVBOY) | Likely mac-studio (GLUEBOY) | Gap |
|------|---------------------|-----------------------------|-----|
| /goal skill | MISSING | Has it | DEVBOY needs /goal |
| AGENTS.md | MISSING | Likely present | DEVBOY needs AGENTS.md |
| .claude/settings.json (project) | MISSING | Likely present | No project-level permissions |
| .claude/.mcp.json (project) | MISSING | Likely present | No project-level MCP |
| .claude/hooks.json (project) | MISSING | Likely present | No project-level hooks |
| .claude/skills/ (repo) | MISSING | Likely present | No repo-level skills |
| ψ/reference/ | MISSING | Likely present | No reference docs |
| hooks.json (global) | MISSING | Unknown | — |
| ~/.claude/.mcp.json (global) | MISSING | Unknown | No global MCP config |
| maw remote | Soul-Brews-Studio (upstream) | dryoungdo (fork) | Different remotes |
| maw port | 1412 | 3456 | Different ports (expected) |
| arra-cli | NOT installed | Unknown | MCP works but no CLI |
| maw wrapper shim | Present (pulse writer) | Unknown | May be DEVBOY-only |
| start.sh | Present (Discord wire) | Unknown | — |
| RTK | 0.39.0 | Unknown | — |
| pordee plugin | Installed but NO /pordee skill | Unknown | Plugin vs skill mismatch? |
