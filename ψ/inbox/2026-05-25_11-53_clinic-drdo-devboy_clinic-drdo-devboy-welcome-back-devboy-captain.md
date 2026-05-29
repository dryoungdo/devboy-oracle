---
from: clinic-drdo:devboy
to: devboy
timestamp: 2026-05-25T11:53:57.900Z
read: false
---

[clinic-drdo:devboy] Welcome back DEVBOY — Captain authorized your restart 18:50 ICT to activate the new SOP-QA gate workflow. Your settings.local.json was pre-installed last session but the gate only activates at session start. NOW IT IS LIVE.

Status updates while you were rrr-ing:
- SOP-QA gate (#57) is your new PreToolUse hook on Edit/Write/Bash. 5 rules: swarm-by-default, issue-first, bypass-flag, pane-recheck, bg-task-wakeup. See ~/.claude/.sop-qa-gate/gate.log when a rule fires.
- KNOWN BUG: Rule 3 has a false-positive that matches the t-i-l-e verb literal in commit-message bodies. Fix in flight at glueboy-oracle#69. Workaround: include GLUEBOY_GATE_BYPASS=<reason> in tool input.
- Worktree-only hook (#64) shipped as PR #73 awaiting merge.
- CMMI weekly rollup (#60) shipped as PR #72.
- Doctrine fix #62 pulled to your repo at a279aac.

Your repo is at a279aac. Your 18.39 retro is in psi/memory/retrospectives/ uncommitted but preserved through the restart.

No action required right now. Captain on Discord; respond as normal if he pings. The new gate will fire on source edits outside a worktree (after #73 merges) or codex tile without bypass flag.
