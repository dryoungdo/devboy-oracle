---
type: learning
topic: maw v26.5.17 federation body-read-failed bug — fix by upgrading to v26.5.21
source: experiment
maturity: solid
retrieval_terms: [maw, federation, body-already-used, from-auth, peer-handshake, bidirectional, maw-hey, 401, missing-signature]
date: 2026-05-21
sister_lineage: none
gate_hook: "pm2 logs maw --err — check for body-read-failed before diagnosing federation 401s"
---

## Finding

maw v26.5.17-beta has a bug in `src/lib/elysia-auth.ts` (from-signing-auth layer): after the HMAC auth layer reads the request body via `c.req.raw.clone().arrayBuffer()`, the from-signing layer tries `request.clone().arrayBuffer()` → "Body already used" → 401.

## Evidence

- pm2 error logs: `[from-auth] body read failed for POST /send: Body already used` (6 occurrences)
- Identical 401 with/without Bearer token proves HMAC layer rejects, not token layer
- v26.5.21 adds `readBodyBytesForAuth()` with WeakMap cache — first reader stores bytes, second retrieves from cache
- After upgrade: GLUEBOY→DEVBOY immediately works

## Fix

1. `maw peers add <peer> <url>` on BOTH nodes (mutual handshake required)
2. Update maw to v26.5.21+ (`cd ~/.bun/install/global/node_modules/maw && git checkout v26.5.21-alpha.1608 && bun install`)
3. `pm2 restart maw`

## Related

- `maw talk-to` is local-only (findWindow() sees local tmux only) — use `maw hey` for cross-node
- v26.5.21 migrates peer-key to `~/.maw/peer-key` (mode 0600) — may need `maw peers add` refresh after

## Pre-publish ledger
- Sources checked: pm2 logs, maw source (elysia-auth.ts, federation-auth.ts), git tags, GLUEBOY's diagnostic tests
- Claims made: 3 (body-read bug, mutual handshake, version fix) — all solid
- Conflicts resolved: token-mismatch hypothesis disproved by GLUEBOY's controlled test
- Application evidence: live bidirectional maw hey verified
- Codex reviewed: no (infrastructure fix, not code)
