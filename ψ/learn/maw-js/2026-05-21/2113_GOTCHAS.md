---
type: learning
topic: maw-js known gotchas, bugs, and fleet-tested patterns
source: experience + oracle-memory
maturity: solid
retrieval_terms: [maw-gotchas, maw-bugs, federation-auth, body-read-failed, maw-troubleshooting]
date: 2026-05-21
---

# maw-js Gotchas & Known Issues

## Critical Gotchas

### 1. Federation Auth Has TWO Layers

maw federation requires BOTH auth layers to pass:

1. **HMAC-SHA256**: Uses `federationToken` from `maw.config.json`. Signs request body + timestamp. Window: 300s.
2. **ed25519 per-peer**: Uses keys from `~/.maw/peers.json`. Signs the `from` field.

**Symptom**: 401 errors even with correct federationToken
**Diagnosis**: Check `pm2 logs maw --err` for:
- `missing_signature` → peer not added (run `maw peers add`)
- `invalid_signature` → key mismatch (re-add peer)
- `body-read-failed` → body consumed twice (upgrade to v26.5.21+)

### 2. Body-Read-Failed Bug (v26.5.17)

**Root cause**: In `elysia-auth.ts`, HMAC layer calls `c.req.raw.clone().arrayBuffer()`. Then from-signing layer tries `request.clone().arrayBuffer()` again → "Body already used" → 401.

**Fix**: v26.5.21 adds `readBodyBytesForAuth()` with WeakMap cache — body bytes read once, shared across auth layers.

**Action**: Upgrade to v26.5.21+. Both nodes must be on same version.

### 3. Mutual Peer Handshake Required

Federation pairing is ONE-WAY by design. `maw peers add mac-studio` on clinic-drdo only registers mac-studio's pubkey on clinic-drdo. mac-studio still doesn't trust clinic-drdo.

**Fix**: Run `maw peers add` on BOTH nodes. Always.

### 4. `maw talk-to` Is LOCAL ONLY

`talk-to` calls `findWindow(target)` which only sees local tmux sessions. On MBA, `clinic-drdo:08-chiefboy` returns null because chiefboy's tmux is on DO, not local.

**Symptom**: Silent no-op. No error, no delivery.
**Fix**: Use `maw hey` for cross-node. `talk-to` is only for same-machine oracles.

### 5. PM2 PATH Stripping (Apple Silicon)

pm2-spawned maw process inherits a stripped PATH missing `/opt/homebrew/bin`. tmux binary not found.

**Symptom**: `/api/sessions` returns `[]` silently (no 500 error). All pane operations fail.
**Fix**: Prepend `/opt/homebrew/bin:/opt/homebrew/sbin` to pm2 env. Or set in maw.config.json `env` field.

### 6. Config Changes Need pm2 Restart

Editing `maw.config.json` while maw is running has no effect. Config is loaded at startup.

**Fix**: `pm2 restart maw` after any config change.

### 7. federationToken in Config File

The token is plaintext in `maw.config.json`. If this file gets committed to a repo, the token is leaked.

**Prevention**: Never commit `maw.config.json`. Add to `.gitignore`. Use pre-commit secret scanning hooks.

### 8. Peer Key File Permissions

`~/.maw/peer-key` must be mode 0600. If world-readable, maw may refuse to start or log security warnings.

---

## Operational Patterns

### Pattern 1: Send-Then-Verify

```bash
maw hey <target> '<msg>'
sleep 3
maw peek <target>           # verify message appeared
```

Never trust delivery without peek verification. `maw hey` returns "delivered" based on HTTP 200 from the target's maw server — but that only means the server received it, not that the oracle processed it.

### Pattern 2: Federation Health Check

```bash
maw federation status --verify
# Check for:
# - All peers showing "online"
# - Latency < 100ms for LAN peers
# - Auth status: "ok" (not "expired" or "missing")
```

### Pattern 3: Post-Upgrade Verification

After upgrading maw:
```bash
pm2 restart maw
maw preflight
maw federation status --verify
maw hey <peer> 'test ping [my-node:my-handle]'
maw peek <peer>
```

### Pattern 4: Debugging 401 Errors

```bash
# 1. Check error type
pm2 logs maw --err --lines 20

# 2. Based on error:
# missing_signature → maw peers add <peer> (on BOTH nodes)
# invalid_signature → re-add peer (key mismatch)
# body-read-failed → upgrade to v26.5.21+
# expired → check system clocks (HMAC window is 300s)

# 3. Verify fix
maw federation status --verify
```

### Pattern 5: Cron Path Validation

After any repo rename, audit cron jobs:
```bash
crontab -l | grep -E 'maw|glueboy|devboy'
# Verify all paths exist
```

---

## Version Compatibility

| Version | Key Changes |
|---------|-------------|
| v26.5.17 | Body-read-failed bug in from-auth layer |
| v26.5.21 | Fixes body-read via WeakMap cache. Mutual peer handshake |
| v26.5.21+ | Recommended minimum for fleet stability |

**Rule**: All nodes in the fleet MUST be on the same maw version. Mixed versions cause auth failures.
