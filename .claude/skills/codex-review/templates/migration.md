# Codex Review Template: Migration

Review database, schema, storage, and data migrations. Focus on data safety, reversibility, and production rollout risk.

Verify:

(1) Scope: identify each migration file, schema change, data backfill, policy/RLS change, and application code that depends on it.

(2) Evidence: inspect migration order, current schema assumptions, affected tables/indexes, reads/writes, rollback path, and verification queries.

(3) Risks:
- Data loss: destructive DDL/DML, column drops, type casts, truncates, overwrites, or deletes without backup/verification.
- Rollout safety: non-idempotent statements, missing transactions, long locks, table rewrites, backfills without batching, or expand-contract steps collapsed into one deploy.
- Compatibility: application code reads new schema before migration lands, old code breaks after migration, defaults/nullability mismatch existing rows.
- Integrity/security: missing constraints/indexes, broken foreign keys, RLS/storage policy drift, tenant isolation regressions, or permissions widened.
- Verification gaps: no preflight counts, post-migration checks, rollback plan, or production-data edge-case handling.

(4) Verdict: list findings first with severity, exact file/line, failure mode, and safer migration sequence. If clean, say `CLEAN: no migration safety issue found in reviewed scope.`

Prefer expand, backfill, verify, switch, contract for risky production changes.
