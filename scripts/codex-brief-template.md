# CODEX BRIEF TEMPLATE

## Task

[one-line task description]

## STRATEGY announcement (REQUIRED - first thing before any Edit/Write)

- SOLO: [justification]
- OR SWARM with N child tiles: [breakdown by file, concern, or workstream]

## Context

- Repo: [owner/repo]
- Worktree: [absolute path]
- Branch: [branch name]
- Issue: [link or number]
- Required closeout: [commit / push / PR / report target]

## Scope

- Include:
  - [file or behavior]
  - [file or behavior]
- Exclude:
  - [explicit non-goal]
  - [explicit non-goal]

## Constraints

- No mock data.
- No dead code.
- No warnings.
- Stage files by name only; never `git add -A` or `git add .`.
- Preserve unrelated worktree changes.

## Review checkpoints (paste into your work cycle)

- After committing first cut: `maw hey <parent> "[codex-N] REVIEW-START: <X> staged files, scripts/run-codex-review.sh --uncommitted launched"`
- When review completes with findings: `maw hey <parent> "[codex-N] REVIEW-DONE: <X> findings, applying fixes"`
- When review completes clean: `maw hey <parent> "[codex-N] REVIEW-CLEAN: no findings, committing"`
- If review stalls past 5 min with no findings: `maw hey <parent> "[codex-N] REVIEW-STUCK: <reason>, killing review + committing without"`

## Canonical review command

```bash
bash scripts/run-codex-review.sh --uncommitted --max-runtime 900 --repo "$(pwd)"
```

When launching any hang-prone review in a parent/orchestrator session, pair the launch with a `ScheduleWakeup` at the committed kill threshold. The wrapper documents this because it cannot schedule the wakeup on behalf of the caller.

## Verify

1. [test/lint/build command]
2. [focused reproduction or smoke test]
3. `git diff --check`
4. Read your own diff before committing.

## When done (AUTONOMOUS)

1. Stage files by name.
2. Commit with issue trailer and AI co-author footer required by the parent brief.
3. Push the branch.
4. Open or update PR.
5. Write the required `.codex-reports/<role>-done.md` report.
6. Report to parent with `maw hey <parent> "[codex-N] DONE: PR #<N> ready. Tests pass. <summary>" --force`.

