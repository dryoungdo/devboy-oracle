---
type: learning
topic: Discord bridge patterns — OAuth refresh 1-use, prompt-capability alignment, arra HTTP fallback
source: clubsxai (B3 Oracle + TC1, msg_id 1506997353834483873, 1506999142751404185)
maturity: emerging
retrieval_terms: [discord-oauth, refresh-token, prompt-capability, arra-http-fallback, bridge-discord, over-refuse]
date: 2026-05-21
gate_hook: "pre-bud check: verify system prompt matches actual tool availability"
---

# Discord Bridge Patterns (from B3 Oracle fleet experience)

## 1. Discord OAuth Refresh Token = 1-Use (🟡 emerging)

Login on machine B immediately expires machine A's refresh token. No grace period.

**Impact**: Codex on Boom 128 stuck on expired token after Master Bo logged in elsewhere.
**Mitigation**: Track which machine holds active OAuth. Re-login explicitly when switching.
**Source**: B3 Oracle, 2026-05-21, ClubsXai channel

## 2. System Prompt Must Match Capability (✅ solid)

TC1 had `discord_read` capability via discord.py client but system prompt said "STATELESS, cannot access Discord API." Result: Gemma 4 over-refused every Discord request.

**Pattern**: Same class as DEVBOY's dmPolicy bug — config/prompt says one thing, actual capability differs.
**Fix (B3 v15)**: Added 2 bridge functions (`discord_read`, `discord_post`) AND updated system prompt to say "TC1 HAS Discord read/post via discord.py."
**Rule**: When adding capability to a bridge/wrapper, ALWAYS update system prompt simultaneously.

## 3. arra HTTP API Fallback (❓ raw)

When arra-cli isn't installed locally, use HTTP API directly: `http://100.89.8.109:47778`
Single data point from B3 — arra-First Reflex still works via HTTP route.

## Pre-publish ledger
- Sources checked: ClubsXai channel messages, ψ/memory/ feedback_discord_dmpolicy.md
- Claims made: 3 (1 emerging, 1 solid, 1 raw)
- Conflicts resolved: prompt-capability = same class as dmPolicy bug (confirmed, not conflicting)
- Application evidence: N/A — observed from sibling fleet, not reproduced in lab
- Codex reviewed: no
