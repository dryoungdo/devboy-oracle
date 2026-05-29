---
from: clinic-drdo:devboy
to: devboy
timestamp: 2026-05-27T05:18:26.063Z
read: false
---

[clinic-drdo:devboy] TASK: Copy essential scripts + hooks for officeboy-oracle (issue #32)

You are working in /home/drdo/Code/github.com/dryoungdo/officeboy-oracle on branch main.

Search arra-cli search "save script push-memory" before starting. Never guess — verify from Oracle memory first.
No mock data. No dead code. No warnings.

## Step 1: Copy scripts from devboy-oracle

cp /home/drdo/Code/github.com/dryoungdo/devboy-oracle/scripts/codex-pr-body.sh scripts/codex-pr-body.sh
cp /home/drdo/Code/github.com/dryoungdo/devboy-oracle/scripts/run-codex-review.sh scripts/run-codex-review.sh
chmod +x scripts/codex-pr-body.sh scripts/run-codex-review.sh

## Step 2: Copy push-memory.sh from glueboy-oracle

cp /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/scripts/push-memory.sh scripts/push-memory.sh
chmod +x scripts/push-memory.sh

## Step 3: Copy hook scripts from glueboy-oracle

mkdir -p scripts/hooks
cp /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/scripts/hooks/sop-qa-gate.sh scripts/hooks/sop-qa-gate.sh
cp /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/scripts/hooks/pre-claim-gate.sh scripts/hooks/pre-claim-gate.sh
cp /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/scripts/hooks/iterm-ask-when-remote-gate.sh scripts/hooks/iterm-ask-when-remote-gate.sh
chmod +x scripts/hooks/*.sh

If there's a sop-qa-rules/ directory in glueboy's hooks, copy that too:
cp -r /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/scripts/hooks/sop-qa-rules scripts/hooks/sop-qa-rules 2>/dev/null || true

## Step 4: Create save-officeboy.sh

Read glueboy's save script for the pattern:
cat /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/scripts/save-glueboy.sh

Create scripts/save-officeboy.sh adapted for OFFICEBOY. Changes from glueboy version:
- Script name references: save-glueboy -> save-officeboy
- Check script: check-glueboy-config.sh -> skip (we don't have this yet, comment it out)
- SAVE_PATHS should include: CLAUDE.md, AGENTS.md, .claude/, oracle-build/, scripts/, .gitignore, and all psi paths (same as glueboy but remove glueboy-specific paths like HOW-TO-SET-UP-GLUEBOY.md)
- Commit message default: 'chore: save officeboy memory and config'
- Oracle name in output messages: GLUEBOY -> OFFICEBOY

chmod +x scripts/save-officeboy.sh

## Step 5: Fix any hardcoded paths in copied scripts

Check all copied scripts for hardcoded references to glueboy-oracle or devboy-oracle paths and update them to officeboy-oracle where appropriate. Specifically:
- grep -r 'glueboy' scripts/ and fix any glueboy-specific paths
- grep -r 'devboy' scripts/ and fix any devboy-specific paths
- The hook scripts may reference repo paths — update to officeboy-oracle

## When done (AUTONOMOUS — run all steps immediately, never ask for permission)

git add scripts/
git commit -m 'feat: essential scripts — save, push-memory, codex-review, hooks (#32)

Closes #32

Co-Authored-By: OFFICEBOY <oracle-officeboy@youngdo.co.th>'
git push origin main

Then report: echo 'TILE 2 DONE: scripts + hooks copied and adapted'
