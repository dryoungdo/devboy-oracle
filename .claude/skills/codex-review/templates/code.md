# Codex Review Template: Code

Review source-code changes for regressions. Focus on behavior, contracts, and tests. Report only actionable bugs.

Verify:

(1) Scope: identify changed source, scripts, config, tests, and generated files that affect runtime behavior.

(2) Evidence: inspect the diff plus adjacent callers, imports, env vars, CLI/API contracts, tests, and build paths.

(3) Risks:
- Source-code regressions: broken behavior, wrong defaults, async/race bugs, error handling gaps, permission changes, or compatibility breaks.
- Interface drift: changed CLI flags, env vars, exports, routes, schemas, or file paths without updating callers.
- Test gaps: missing or weakened tests for changed behavior, snapshots hiding regressions, or tests that assert implementation instead of behavior.
- Operational hazards: destructive commands, absolute local paths, secrets in logs, hidden network assumptions, or generated artifacts treated as source.

(4) Verdict: list findings first with severity, exact file/line, impact, and minimal fix. If clean, say `CLEAN: no source-code regressions found in reviewed scope.`

Do not comment on style unless it causes a real defect.
