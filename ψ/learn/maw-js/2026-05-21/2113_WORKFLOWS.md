---
type: learning
topic: maw-js workflows — decision trees and real usage patterns from fleet sessions
source: research + experience
maturity: solid
retrieval_terms: [maw-workflow, when-to-use, decision-tree, maw-hey-vs-talk-to, fleet-patterns]
date: 2026-05-21
---

# maw-js Workflows — When to Use What

## Decision Tree: "I Want To..."

### Start an Oracle

```
Need to start an oracle?
├── Fresh oracle (never initialized) → maw scaffold <name> + maw wake <name>
├── Existing oracle, new session → maw wake <name>
├── Side-by-side with current work → maw bring <name> (or: maw wake <name> --split)
├── Wake everything → maw wake --all
└── Plain shell workspace (no oracle) → maw new <name>
```

### Send a Message to Another Oracle

```
Need to communicate?
├── Cross-node (different machine) → maw hey <node>:<session>:<pane> '<msg>'
├── Local (same machine, same maw) → maw hey <agent> '<msg>'
├── Fleet-wide announcement → maw broadcast '<msg>'
├── Raw tmux typing (automation) → maw send <target> '<text>'
└── Verify delivery → maw peek <target> (3-5s after send)
```

**NEVER use `maw talk-to` for cross-node** — it only sees local tmux sessions. Use `maw hey`.

### Inspect State

```
What's happening?
├── All running sessions → maw ls
├── All registered oracles → maw oracle ls
├── What a specific oracle sees → maw peek <target>
├── All panes across sessions → maw panes
├── Federation connectivity → maw federation status
├── Full fleet inventory → maw discover
├── Fleet health → maw fleet health
└── Pre-flight diagnostics → maw preflight
```

### Multi-Agent Work

```
Need coordinated agents?
├── Create team workspace → maw team create <name>
├── Add agents to team → maw team spawn <team> <role> --model <model>
├── Send task to agent → maw team send <team> <role> '<task>'
├── Check who's alive → maw team lives <team>
├── Stop everything → maw team shutdown <team>
└── Clean zombie panes → maw team cleanup --zombie-agents
```

### Debug & Maintenance

```
Something broken?
├── Federation auth failure → maw federation status --verify
├── Oracle not responding → maw peek <target> (check if alive)
├── Stale agents → maw oracle scan --stale + maw oracle prune
├── Zombie panes → maw cleanup
├── Config issues → maw fleet validate + maw fleet doctor --fix
├── After crash → maw fleet restore
└── Full health check → maw preflight
```

---

## Real Workflow Examples (Fleet-Tested)

### Workflow 1: Morning Fleet Startup

```bash
# 1. Check what's running
maw ls

# 2. Wake the fleet
maw wake --all

# 3. Verify federation
maw federation status --verify

# 4. Check for stale state
maw preflight
```

### Workflow 2: Cross-Node Communication (DEVBOY → GLUEBOY)

```bash
# 1. Send message
maw hey mac-studio:11-glueboy:glueboy-oracle 'DEVBOY: status update [clinic-drdo:devboy]'

# 2. Verify delivery (wait 3-5s)
maw peek mac-studio:11-glueboy:glueboy-oracle

# 3. Check for response (poll or wait for incoming maw hey)
```

**Key learning**: Always sign messages with `[node:handle]` so the recipient knows who sent it.

### Workflow 3: Federation Setup (New Node)

```bash
# On NEW node:
# 1. Edit ~/.config/maw/maw.config.json — add namedPeers entry
# 2. Set federationToken (must match existing fleet)
# 3. Add peer
maw peers add <existing-node>

# On EXISTING node:
# 4. Add peer back (mutual handshake!)
maw peers add <new-node>

# 5. Verify both directions
maw federation status --verify
maw hey <new-node>:<agent> 'test ping [my-node:my-handle]'
```

**Gotcha**: Federation auth has TWO layers — HMAC (federationToken) + ed25519 (per-peer keys). Both must pass. If you get 401, check `pm2 logs maw --err` for "missing_signature" vs "invalid_signature" vs "body-read-failed".

### Workflow 4: Multi-Agent Research Team

```bash
# 1. Create team
maw team create deep-research --description "5-agent parallel research"

# 2. Spawn agents with roles
maw team spawn deep-research analyst --model opus --prompt "You analyze papers"
maw team spawn deep-research coder --model sonnet --prompt "You write code examples"
maw team spawn deep-research reviewer --model opus --prompt "You review and critique"

# 3. Assign tasks
maw team send deep-research analyst "Find papers on RAG architecture"
maw team send deep-research coder "Build minimal RAG example with LanceDB"
maw team send deep-research reviewer "Review analyst and coder output when ready"

# 4. Monitor
maw team lives deep-research
maw peek deep-research:analyst

# 5. Shutdown when done
maw team shutdown deep-research
```

### Workflow 5: Plugin Development

```bash
# 1. Scaffold
maw plugin init my-plugin --ts

# 2. Develop (watch mode)
maw plugin dev ./my-plugin

# 3. Build
maw plugin build ./my-plugin --types

# 4. Install locally
maw plugin install ./my-plugin/dist/my-plugin.tgz

# 5. Publish to peer
maw plugin search my-plugin --peers  # verify visibility
```

### Workflow 6: Recovery After Crash

```bash
# 1. Check what survived
maw ls

# 2. List recovery snapshots
maw fleet snapshots list

# 3. Restore
maw fleet restore --all

# 4. Doctor check
maw fleet doctor --fix

# 5. Verify federation
maw federation status --verify
```

---

## Command Frequency (Real Fleet Data)

From 46h of actual session data (DEVBOY, 2026-05-19 to 2026-05-21):

| Command | References | Use Pattern |
|---------|-----------|-------------|
| `maw team` | 816 | Multi-agent coordination (heaviest) |
| `maw hey` | 504 | Cross-node IPC (daily essential) |
| `maw wake` | 115 | Oracle lifecycle |
| `maw federation` | 12 | Setup + debugging |
| `maw kill` | 9 | Cleanup |
| `maw peek` | 7 | Delivery verification |
| `maw talk-to` | 7 | Local messaging (deprecated for cross-node) |
| `maw run` | 7 | Remote command execution |
| `maw bud` | 5 | Oracle spawning |
| `maw ls` | 2 | Session listing |

**Insight**: `maw team` and `maw hey` account for 90%+ of daily usage. Master these two and you've mastered maw.

---

## Anti-Patterns (What NOT to Do)

| Anti-Pattern | Why | Instead |
|-------------|-----|---------|
| `maw talk-to` for cross-node | Only sees local tmux | `maw hey` |
| `maw send` for cross-node | No federation auth | `maw hey` |
| `maw hey` without `[node:handle]` sig | Recipient can't identify sender | Always sign |
| `maw hey` without `maw peek` follow-up | No delivery confirmation | Peek 3-5s after |
| `maw kill --all` without checking | Kills everything blindly | `maw ls` first |
| Editing `maw.config.json` while maw runs | Config not reloaded | `pm2 restart maw` after |
| One-way `maw peers add` | Federation is mutual | Add on BOTH nodes |
| Trusting `maw talk-to` delivery | Silent no-op if Oracle API down | Verify with `maw peek` |
