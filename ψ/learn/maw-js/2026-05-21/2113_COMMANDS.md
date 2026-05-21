---
type: learning
topic: maw-js complete command reference — 40+ commands with usage, flags, and examples
source: research
maturity: solid
retrieval_terms: [maw-commands, maw-hey, maw-wake, maw-kill, maw-peek, maw-team, maw-fleet, maw-federation, maw-plugin]
date: 2026-05-21
---

# maw-js Command Reference

## 1. Lifecycle Commands

### `maw wake <oracle>` — Start an Oracle

The primary way to start an oracle. Fuzzy-matches oracle name, auto-clones from GitHub if needed, creates tmux session.

```bash
maw wake glueboy              # wake by name (fuzzy match)
maw wake glueboy --split      # wake in split pane of current window
maw wake glueboy --model opus # override model
maw wake --all                # wake all registered oracles
```

**Flags**: `--split`, `--model <model>`, `--cwd <path>`, `--prompt <text>`, `--exec`, `--all`

**When to use**: Starting a session. Day-to-day most common entry point.

### `maw awake <oracle>` — Start Without /awaken Ritual

Like `wake` but skips the Oracle birth ceremony. For oracles that are already initialized.

### `maw kill <target>` — Stop an Oracle

Kills a tmux pane or entire session.

```bash
maw kill glueboy              # kill the oracle's pane
maw kill 01-devboy            # kill by session name
maw kill --all                # kill all sessions (careful!)
```

**When to use**: Cleaning up after work. Stopping a misbehaving oracle.

### `maw new <name>` — Create Plain Workspace

Creates a tmux session without an oracle. For shell tasks, monitoring, etc.

```bash
maw new monitoring --cmd "htop"
```

### `maw scaffold <name>` — Create Oracle Skeleton

Creates the repo structure (CLAUDE.md, ψ/, .claude/) without starting anything.

---

## 2. View & Inspection Commands

### `maw ls` — List Sessions

The fleet dashboard. Shows all running tmux sessions with agent status.

```bash
maw ls                        # compact view
maw ls -v                     # verbose (pids, memory, uptime)
maw ls -r                     # recent (sorted by activity)
maw ls -a                     # roster (all registered, running or not)
maw ls --json                 # machine-readable
```

**When to use**: "What's running right now?" First command in every session.

### `maw peek <target>` — Read-Only View

Shows the last N lines of a tmux pane. Works cross-node via federation.

```bash
maw peek devboy               # local oracle
maw peek mac-studio:11-glueboy:glueboy-oracle   # remote (node:session:pane)
maw peek devboy --lines 50    # last 50 lines
```

**When to use**: Checking what an oracle is doing without interrupting it. Verifying message delivery.

**Critical pattern**: After `maw hey`, always `maw peek` 3-5s later to verify delivery.

### `maw panes` — List All Panes

Shows all panes across all sessions.

```bash
maw panes                     # compact
maw panes -v                  # verbose (cmd, pid, size)
```

### `maw session` — Current Session Info

Prints the current tmux session name. Requires active $TMUX.

### `maw zoom [target]` — Toggle Zoom

Zooms/unzooms a pane (tmux resize-pane -Z).

---

## 3. Communication Commands

### `maw hey <target> '<message>'` — Primary IPC

**THE most important command.** Sends messages between oracles across nodes via federation. Visible in maw web UI.

```bash
# Cross-node (primary use case)
maw hey mac-studio:11-glueboy:glueboy-oracle 'status update [clinic-drdo:devboy]'

# Local
maw hey devboy 'quick question'

# Format: <node>:<session>:<pane> or just <agent-name>
```

**How it works**: HTTP POST to peer's `/api/send` with HMAC auth + from-signing. Types the message into the target's tmux pane input buffer.

**When to use**: ANY cross-oracle communication. This is the fleet's nervous system.

**Gotchas**:
- Message is typed into tmux — if target is mid-task, message gets consumed as input
- Always sign with `[node:handle]` at the end (the `/hey` skill does this automatically)
- Requires mutual peer handshake (`maw peers add` on BOTH nodes)

### `maw send <target> <text>` — Low-Level tmux Send

Injects keystrokes into a tmux pane. Lower-level than `hey` — no federation, no auth.

```bash
maw send devboy "ls -la"                    # types + Enter
maw send devboy "text" --literal            # raw keystrokes, no Enter
maw send devboy "rm -rf /" --allow-destructive  # bypass deny-list (dangerous!)
```

**When to use**: Local automation only. For cross-node, always use `hey`.

### `maw broadcast '<message>'` — Fleet-Wide Announcement

Sends to ALL agents. Too broad for 1:1 — use `maw hey` for targeted messages.

---

## 4. Navigation Commands

### `maw attach <session>` — Attach to Session

Switch to a tmux session.

```bash
maw attach 01-devboy          # attach to devboy's session
maw attach devboy --shell     # attach to shell pane (not oracle pane)
```

Shortcut: `maw a devboy`

### `maw bring <oracle>` — Bring Oracle Here

Spawns the oracle in a split pane of your current window. Alias: `maw b`.

```bash
maw bring glueboy             # split current window, wake glueboy there
```

**When to use**: When you want side-by-side work without switching windows.

### `maw split <target>` — Split Pane

Creates a split pane and attaches to a session.

```bash
maw split devboy              # horizontal split
maw split devboy --lock       # lock pane (prevent close)
```

### `maw tile [count]` — Grid Layout

Arranges panes in a grid.

```bash
maw tile                      # re-tile existing panes
maw tile 4                    # spawn 4 panes in grid
maw tile --main-vertical      # main pane left, rest stacked right
```

### `maw layout <target> <preset>` — Apply Layout

```bash
maw layout . tiled            # current window
maw layout . even-horizontal  # side by side
maw layout . main-vertical    # main + sidebar
```

### `maw open <target>` / `maw close <target>` — Show/Hide Panes

Hide panes without killing them (tmux break-pane / join-pane).

---

## 5. Federation Commands

### `maw federation status` — Peer Health

Shows all configured peers, their connectivity, latency, and auth status.

```bash
maw federation status         # or: maw federation ls
maw federation status --verify  # health check all pairs
maw federation status --json  # machine-readable
```

**When to use**: Debugging cross-node communication failures. First command when `maw hey` returns errors.

### `maw federation sync` — Synchronize Peer State

```bash
maw federation sync           # sync peer configs
maw federation sync --dry-run # preview without changing
maw federation sync --prune   # remove stale entries
maw federation sync --force   # force despite conflicts
```

### `maw discover` — Inventory Discovery

Shows all known oracles, repos, peers, and live tmux state.

```bash
maw discover                  # table view
maw discover --tree           # hierarchical
maw discover --awake          # running oracles only
maw discover --peers config   # config-only peers (no scout)
maw discover --json           # machine-readable
```

**When to use**: "What's in the fleet?" Full inventory of everything maw knows about.

### `maw peers add <peer>` — Add Federation Peer

Mutual handshake required — run on BOTH nodes.

```bash
maw peers add mac-studio      # adds peer by named-peer config
```

---

## 6. Fleet Commands

### `maw fleet ls` — Fleet Registry

```bash
maw fleet ls                  # registered fleet entries
maw fleet health              # agent health summary
maw fleet doctor              # detailed diagnostics
maw fleet doctor --fix        # auto-repair issues
```

### `maw fleet snapshot` / `maw fleet restore` — Recovery

```bash
maw fleet snapshot            # capture current state
maw fleet snapshots list      # list available snapshots
maw fleet restore             # restore latest
maw fleet restore --all       # restore all agents
```

### `maw fleet validate` — Config Integrity

Checks maw.config.json for errors, missing agents, stale entries.

---

## 7. Team Commands

### `maw team create <name>` — Create Team Workspace

```bash
maw team create research --description "parallel research team"
```

### `maw team spawn <team> <role>` — Spawn Agent Role

```bash
maw team spawn research analyst --model opus --prompt "You are a research analyst"
maw team spawn research writer --model sonnet --cwd /path/to/docs
```

### `maw team send <team> <role> <message>` — Send Task

```bash
maw team send research analyst "Find all papers on transformer architecture"
```

### `maw team shutdown <team>` — Stop All Agents

```bash
maw team shutdown research          # graceful
maw team shutdown research --force  # immediate
```

### `maw team lives <team>` — Active Agents

### `maw team list` — All Teams

### `maw team cleanup` — Kill Zombie Panes

```bash
maw team cleanup --zombie-agents
```

**When to use**: Multi-agent coordination. Research tasks, parallel work, team projects.

---

## 8. Oracle Management Commands

### `maw oracle ls` — List Registered Oracles

```bash
maw oracle ls                 # all registered
maw oracle ls --awake         # running only
maw oracle ls --stale         # stale/orphaned
maw oracle ls --org SBS       # filter by org
maw oracle ls --json          # machine-readable
```

### `maw oracle scan` — Discover New Oracles

```bash
maw oracle scan               # scan local + remote
maw oracle scan --local       # local ghq repos only
maw oracle scan --remote      # GitHub orgs only
maw oracle scan --stale       # find orphaned entries
```

### `maw oracle register <name>` — Add Oracle

### `maw oracle prune` — Remove Stale Oracles

### `maw oracle search <query>` — Find Oracle

### `maw oracle about <name>` — Oracle Metadata

### `maw oracle set-nickname <oracle> "<nick>"` — Display Name

---

## 9. Plugin Commands

### `maw plugin ls` — Installed Plugins

Shows installed plugins with tiers (core, community, local).

### `maw plugin install <source>` — Install Plugin

```bash
maw plugin install messages              # from registry
maw plugin install owner/repo@v1.2.3     # from GitHub
maw plugin install ./my-plugin.tgz       # from file
maw plugin install --pin                 # lock version
```

### `maw plugin build [dir]` — Bundle Plugin

```bash
maw plugin build                  # current dir
maw plugin build --watch          # dev mode
maw plugin build --types          # emit .d.ts
```

### `maw plugin init <name> --ts` — Scaffold Plugin

### `maw plugin search <query>` — Search Registry

```bash
maw plugin search messages
maw plugin search messages --peers       # include peer plugins
```

### `maw plugin dev [dir]` — Watch Mode

---

## 10. Maintenance Commands

### `maw preflight` — Pre-Flight Check

Version, plugins, dead agents, config validation. Run after install or upgrade.

### `maw cleanup` — Kill Zombie Panes

Removes orphaned tmux panes from dead agents.

### `maw snapshots` — Recovery Snapshots

List and inspect fleet recovery snapshots.

---

## 11. API Endpoints

maw exposes an HTTP API (default port 3456, clinic-drdo uses 1412):

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/send` | POST | Send message to oracle (federation primary) |
| `/api/config` | GET | Node identity + agents map |
| `/api/fleet-config` | GET | Fleet entries with lineage |
| `/api/feed` | GET | Live event log |
| `/api/federation/status` | GET | Peer connectivity |
| `/api/peer/exec` | POST | Signed command relay |
| `/api/teams` | GET | Active team workspaces |
| `/api/costs` | GET | Token usage & costs |
| `/api/plugin/*` | GET/POST | Plugin manifest & search |

**Auth**: HMAC-SHA256 (federationToken) + ed25519 per-peer signatures. Both layers must pass.
