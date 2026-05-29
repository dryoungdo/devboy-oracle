---
from: clinic-drdo:devboy
to: devboy
timestamp: 2026-05-27T05:18:59.003Z
read: false
---

[clinic-drdo:devboy] TASK: Create config files for officeboy-oracle (issues #29, #30, #31)

You are working in /home/drdo/Code/github.com/dryoungdo/officeboy-oracle on branch main.

Search arra-cli search "settings.json AGENTS.md gitignore" before starting. Never guess — verify from Oracle memory first.
No mock data. No dead code. No warnings.

## Step 1: Create .gitignore (#31)

Read devboy's gitignore for reference:
cat /home/drdo/Code/github.com/dryoungdo/devboy-oracle/.gitignore 2>/dev/null || echo 'no devboy gitignore'

Read glueboy's gitignore:
cat /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/.gitignore

Create .gitignore for officeboy-oracle. Include at minimum:
.tmp/
*.tmp
.oracle-build-backups/
.codex/
.agents/
.worktrees/

## Step 2: Create .claude/settings.local.json

Create minimal file:
{
  "permissions": {
    "allow": []
  }
}

## Step 3: Upgrade .claude/settings.json (#29)

Read the current settings.json first (it has auto-rrr hooks, keep those).
Read glueboy's settings.json for reference:
cat /home/drdo/Code/github.com/dryoungdo/glueboy-oracle/.claude/settings.json

Update officeboy's settings.json to include:

permissions.allow: [
  "Read", "Write", "Edit", "Glob", "Grep", "WebFetch", "WebSearch",
  "Task", "TodoWrite",
  "Bash(git:*)",
  "Bash(npm:*)", "Bash(node:*)", "Bash(npx:*)",
  "Bash(bun:*)", "Bash(bunx:*)",
  "Bash(gh:*)", "Bash(ghq:*)", "Bash(python*:*)",
  "Skill(rrr)", "Skill(learn)", "Skill(trace)", "Skill(recap)", "Skill(forward)"
]

permissions.deny: [
  "Bash(sudo:*)", "Bash(su:*)",
  "Bash(rm -rf /:*)", "Bash(rm -rf *)",
  "Bash(git reset --hard*)", "Bash(git clean -fd*)",
  "Bash(git checkout --*)", "Bash(git restore*)",
  "Bash(git push --force*)", "Bash(git push --force-with-lease*)",
  "Bash(git push * main*)", "Bash(git commit --amend*)",
  "Bash(git commit --no-verify*)", "Bash(git push --no-verify*)",
  "Bash(chmod -R 777*)", "Bash(dd *)", "Bash(mkfs*)"
]

Keep existing hooks (SessionStart, Stop, SessionEnd with auto-rrr).

Add PreToolUse hooks — but use REPO_PATH variable pattern. The actual scripts directory path should be the officeboy-oracle repo. Use this pattern for hook command paths:
  bash /home/drdo/Code/github.com/dryoungdo/officeboy-oracle/scripts/hooks/<script>.sh

Add PreToolUse:
  matcher 'Edit|Write|Bash' -> sop-qa-gate.sh (timeout 8)

Add enabledPlugins:
  discord@claude-plugins-official: true

Add statusLine:
  type: command, command: bash ~/.claude/statusline.sh

## Step 4: Create AGENTS.md (#30)

Read devboy's AGENTS.md for reference:
cat /home/drdo/Code/github.com/dryoungdo/devboy-oracle/AGENTS.md

Create AGENTS.md for OFFICEBOY. This is the Codex worker contract. Adapt from devboy:
- Change all DEVBOY references to OFFICEBOY
- Change role description to office AI research
- Change Discord bot details (App ID 1503222663525699776, channel 1508792087552720926)
- Change responsibilities to OFFICEBOY's 5 responsibilities
- Keep: 7 Oracle Principles, Work Pattern (5 phases), Safety rules, Git staging rules
- Keep: Chain of command (CAPTAIN -> GLUEBOY -> OFFICEBOY)
- Keep: maw commands reference
- Update fleet context table if present

## When done (AUTONOMOUS — run all steps immediately, never ask for permission)

git add .gitignore .claude/settings.json .claude/settings.local.json AGENTS.md
git commit -m 'feat: config files — settings.json upgrade, AGENTS.md, .gitignore (#29, #30, #31)

Closes #29
Closes #30
Closes #31

Co-Authored-By: OFFICEBOY <oracle-officeboy@youngdo.co.th>'
git push origin main

Then report: echo 'TILE 3 DONE: config files created'
