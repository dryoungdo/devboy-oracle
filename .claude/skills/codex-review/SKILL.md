---
name: codex-review
description: Run Codex as a second reviewer for code, issue-body, doctrine, and migration changes. Use before declaring non-trivial work done, before PR-ready claims, before public issue comments, and before database/schema changes. Select one of the bundled templates and prefer the repo wrapper at scripts/run-codex-review.sh when available.
license: Internal - Youngdo Wellness Clinic
---

# /codex-review

Use Codex as a second reviewer before calling work done. Keep scope explicit, write output to a file, and fix real findings before reporting clean.

## Shape

Invoke as:

```bash
/codex-review <code|issue-body|doctrine|migration> [scope]
```

Template selection:

| Shape | Template | Use for |
|---|---|---|
| `code` | `templates/code.md` | Source code, scripts, tests, configs, UI/API behavior |
| `issue-body` | `templates/issue-body.md` | GitHub issue bodies, upstream comments, public-facing bug reports |
| `doctrine` | `templates/doctrine.md` | CLAUDE/AGENTS/shared doctrine, workflow rules, command docs |
| `migration` | `templates/migration.md` | DB/schema/data migrations, RLS/storage policy changes |

If shape is omitted, infer it from the files changed. Prefer `migration` over `code` when any database migration or schema mutation is in scope.

## Run

Canonical repo wrapper:

```bash
scripts/run-codex-review.sh <shape> [scope]
```

Use that wrapper when the repo provides it. It is the canonical path for output capture, timeout handling, and template selection.

Fallback wrappers from the live skill:

```bash
~/.claude/skills/codex-review/scripts/review-uncommitted.sh <repo_dir>
~/.claude/skills/codex-review/scripts/review.sh <repo_dir> [base_branch]
~/.claude/skills/codex-review/scripts/exec-review.sh <repo_dir> <prompt_file>
```

Never pipe Codex output through filters during capture. Redirect to a file first, then inspect the file.

## Review Contract

Every template uses Captain-style verification:

(1) Scope: name what is being reviewed and what changed.
(2) Evidence: inspect the diff, adjacent callers/docs/tests, and any referenced commands or links.
(3) Risks: apply the shape-specific checklist.
(4) Verdict: findings first, with exact file/line references and concrete fixes. Say clean only when no actionable issue remains in the reviewed scope.

Report only actionable findings. Do not reward prose quality, restate the diff, or invent risks outside the reviewed scope.

## Trigger

Run this skill for:

- Code changes at or above small-risk size, especially new files or behavior changes.
- "Ready", "fixed", "done", "PR ready", or "safe to merge" claims.
- Public issue comments or upstream reports.
- Doctrine edits that describe current command behavior.
- Database, schema, storage, permission, or migration changes.

Skip only typo-only edits, comment-only edits, or pure markdown notes that make no operational claim.

## Output

Expected review output:

```text
FINDINGS:
- P1/P2/P3 file:line - What breaks, why it breaks, and the minimal fix.

VERDICT:
Clean / Not clean, with one sentence of scope.
```

If clean:

```text
CLEAN: no actionable findings in the reviewed scope.
```
