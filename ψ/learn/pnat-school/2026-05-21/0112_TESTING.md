---
type: learning
topic: Team-Tile Testing — lab experiment plan, failure modes, verification
source: pnat-gist
maturity: emerging
retrieval_terms: [team-tile-testing, lab-experiment, failure-modes, verification]
date: 2026-05-21
---

# Testing: Team-Tile Bootstrap

## Lab Experiment Plan

**Hypothesis**: team-tile can spawn 2 panes on DO server, each cd'd into a different repo, and exchange one SendMessage round-trip successfully.

**Location**: `ψ/lab/team-tile-bootstrap/`

### Steps

1. Verify prerequisites on DO:
   ```bash
   tmux -V          # expect 3.4+
   bun --version    # expect 1.x
   maw --version    # expect v26.x
   echo $CLAUDE_SESSION_ID  # must be set
   ```

2. Test `maw tile` verb exists:
   ```bash
   maw tile --help 2>&1 | head -5
   ```

3. Test maw-js #1837 collapsed form:
   ```bash
   maw tile 1 --path /tmp --cmd "echo hello"
   # If fails, fall back to maw tile + maw run two-step
   ```

4. Full team-tile spawn (2 teammates):
   ```bash
   bun bootstrap.ts --team devboy-test \
     --member reader-a@/home/drdo/Code/github.com/dryoungdo/devboy-oracle:magenta \
     --member reader-b@/home/drdo/Code/github.com/dryoungdo/devboy-oracle:cyan \
     --dry-run
   ```

5. If dry-run looks correct, remove --dry-run and execute

6. From lead Claude session:
   ```
   TeamCreate({ team_name: "devboy-test" })
   SendMessage({ to: "reader-a", message: "reply with 'hello from pane 1'" })
   ```

7. Verify reply arrives as `<teammate-message>` XML

8. Cleanup:
   ```
   SendMessage({ to: "reader-a", message: { type: "shutdown_request" } })
   TeamDelete({})
   tmux kill-pane -t <addr>
   ```

### Success Criteria
- [ ] maw tile spawns addressable panes
- [ ] claude.exe boots with 7-flag identity
- [ ] SendMessage delivers to teammate inbox
- [ ] Reply arrives as `<teammate-message>` XML
- [ ] shutdown + kill-pane cleans up completely

### Expected Time: ~15 min

## Failure Modes Table

| Symptom | Cause | Fix |
|---------|-------|-----|
| `maw tile` not recognized | maw-js version too old | Check `maw --version`, may need `maw-js` update |
| `maw tile --path --cmd` fails | #1837 not in installed version | Use two-step: `maw tile N` + `maw run` |
| Pane spawns but claude.exe not found | findClaudeBin paths wrong for DO | Pass `--claude-bin $(which claude)` |
| TeamCreate fails | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not set | Export env before session |
| SendMessage timeout | Teammate not booted yet | Increase --boot-wait to 15-20s |
| Zombie process after shutdown | Seam #6 | Always tmux kill-pane after shutdown_approved |
| Partial spawn (2/3 panes) | No rollback in bootstrap.ts | Manual kill-pane for spawned panes |

## Verification Commands

```bash
# Check pane addresses
tmux list-panes -F '#{pane_index} #{pane_current_command} #{pane_current_path}'

# Check team config
cat ~/.claude/teams/devboy-test/config.json | jq '.members[].name'

# Check teammate identity in pane
maw peek <session>:<window>.<pane>

# Check inbox
ls -la ~/.claude/teams/devboy-test/inboxes/
```

## Edge Cases to Test

1. **Spawn with path containing spaces** — does shellQuote handle it?
2. **Multiple teams simultaneously** — namespace collision?
3. **Teammate in same repo as lead** — works but is it useful?
4. **Network disconnect during teammate work** — does filesystem transport survive?
5. **Context overflow in teammate** — does it gracefully shutdown or hang?
