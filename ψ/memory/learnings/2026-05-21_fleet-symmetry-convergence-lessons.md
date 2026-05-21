---
type: learning
topic: Fleet symmetry convergence — cross-platform packaging, silent cron failures, credential leak prevention
source: experience
maturity: solid
retrieval_terms: [fleet-symmetry, tarball-symlink, cron-validation, secret-scanning, pre-commit-hook, cross-platform]
date: 2026-05-21
sister_lineage: none
gate_hook: "pre-commit secret scanning hook (trufflehog/grep-based) — proposed, not yet installed"
---

# Fleet Symmetry Convergence Lessons

## 1. Cross-platform tarball packaging breaks on symlinks

macOS `tar` preserves symlinks by default. When extracted on Linux, these become broken symlinks pointing to `/Users/...` paths that don't exist.

**Fix**: Use `tar -h` (dereference) when packaging on macOS for Linux targets. Or skip tarballs entirely — `git checkout <branch> -- <path>` extracts real files regardless of OS.

**Evidence**: `glueboy-unique-auto-rrr.tar.gz` contained a symlink to `/Users/dr.dosmacstudio/ghq/...`. Extracted on clinic-drdo as broken symlink. Had to `git checkout origin/ms-runtime-bootstrap-2026-05-17 -- .claude/skills/glueboy-unique-auto-rrr/` instead.

## 2. Silent cron failures after repo renames

Cron jobs that reference repo paths break silently when repos are renamed. `*/2 * * * * git -C ~/Code/.../glueboy pull` fails silently when repo becomes `glueboy-oracle`.

**Fix**: After any repo rename, audit crontab for stale paths. Add `|| logger "cron: glueboy-sync FAILED"` to make failures visible.

**Evidence**: glueboy-ψ sync cron was broken on clinic-drdo since the rename. Nobody noticed until fleet symmetry audit.

## 3. Credential leak prevention needs gate-layer fix

Committing plaintext secrets (federationToken, API keys) to repos is a memory-layer failure — "remember to check" doesn't scale. Pre-commit hooks scanning for secrets fire automatically.

**Fix**: Install `trufflehog` or grep-based pre-commit hook fleet-wide. The pattern: `grep -rn 'Token.*[A-Za-z0-9_-]{20,}' --include='*.md' --include='*.json'` catches most credential patterns.

**Evidence**: federationToken committed in plaintext to `clinic-drdo-inventory.md` (commit b31a74f). Caught by GLUEBOY/Codex co-review, not by DEVBOY. Redacted in 418f1e1.

## Pre-publish ledger

- Sources checked: direct experience during fleet symmetry audit session
- Claims made: 3 (all solid — each backed by specific incident + fix)
- Conflicts resolved: none found
- Application evidence: all 3 fixes applied during this session (tar workaround, cron fix, token redaction)
- Codex reviewed: no (lessons are operational, not code)
