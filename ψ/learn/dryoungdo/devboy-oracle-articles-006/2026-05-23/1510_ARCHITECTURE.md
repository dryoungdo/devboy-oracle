# 1510_ARCHITECTURE — Discord Wiring: Two Layers & The Silent Failure Mode

**Agent 1 of 5** · ARCHITECTURE dimension · Extracted from Article 006 + 041  
**Date**: 2026-05-23  
**Status**: สถาปัตยกรรมชัดเจน ยกเว้น listener→MCP spawn handoff (ที่ล้มเหลว 2026-05-23)

---

## The gate() Flow: Three Sequential Gates

Article 041 (Part B) documents the canonical gate logic:

```
Discord Gateway (WebSocket)
    |
    v
Discord Plugin (claude-plugins-official)
    |
    +--> gate() function
    |      |
    |      +--> dmPolicy check *** FIRST GATE ***
    |      |     "disabled" = drop ALL
    |      |     "allowlist" = check allowFrom for DMs
    |      |     "pairing" = pair-code flow + allowFrom
    |      |
    |      +--> channel groups check
    |      |     Is channel_id in groups?
    |      |     Is sender in group's allowFrom?
    |      |     requireMention true/false?
    |      |
    |      +--> mention check
    |            Does message match mentionPatterns?
    |
    +--> Format as <channel source="plugin:discord:discord">
    +--> Deliver to Claude Code session
    v
Oracle processes message
```

**Critical**: dmPolicy check runs _first_ — "disabled" returns `drop` for _every_ incoming message _before_ channel/group logic runs. This sealed the 2026-05-19 incident (100 min lost debugging).

---

## File Structure: The State Directory Contract

Article 041 specifies the layout:

```
~/.claude/
  settings.json                          # enabledPlugins entry
  channels/
    discord/
      access.json                        # parent-level template (optional)
      <botname>/                         # per-bot state directory
        .env                             # DISCORD_BOT_TOKEN=xxx
        access.json                      # access control config
        approved/                        # approved pairing codes
        inbox/                           # queued messages
```

Each bot has its own state directory rooted at `~/.claude/channels/discord/<botname>/`. The per-bot contract:
- `.env` — Contains `DISCORD_BOT_TOKEN=<token>` only. Must be `chmod 600` per Article 041.
- `access.json` — The gate config (dmPolicy, allowFrom, groups, mentionPatterns, ackReaction)
- `approved/` — Pairing code tracking (when `dmPolicy: "pairing"`)
- `inbox/` — Message queue during offline periods

**No token sharing** between bots in a fleet. DEVBOY and GLUEBOY each have separate `~/.claude/channels/discord/devboy/.env` and `~/.claude/channels/discord/glueboy/.env`.

---

## The access.json Format

From Article 006 + 041:

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["captain-id", "pnat-id"],
  "groups": {
    "CHANNEL_ID": {
      "_name": "channel-name",
      "requireMention": true,
      "allowFrom": ["captain-id", "pnat-id"]
    }
  },
  "mentionPatterns": ["@everyone", "@here", "@BOTNAME", "<@&ROLE_ID>"],
  "ackReaction": "👀"
}
```

| Field | Meaning |
|---|---|
| `dmPolicy` | "allowlist" (normal), "pairing" (pair-code), or "disabled" (kill switch) |
| `allowFrom` | Base allowlist for DMs + default for channel groups |
| `groups` | Per-channel configs: `requireMention` (mention-only vs always-lurk) + per-channel `allowFrom` override |
| `mentionPatterns` | Regex list of mention triggers |
| `ackReaction` | Emoji for seen reaction |

**Key insight from Article 006**: Channel behavior splits by `requireMention`:
- 6 classrooms (road-to-dev, esp32-dev, ML, designer, regular-school, nat-s-preps): `requireMention: false` → lurk always
- 21 other channels: `requireMention: true` → listen only on mention

---

## Two Decoupled Layers

Article 041 documents a crucial decoupling:

**Layer 1: Claude Code Plugin Loader** (the CLI side)
- Reads `settings.json` for `enabledPlugins`
- Reads `--channels` CLI flag
- **Decision**: Should I spawn the MCP server?

**Layer 2: MCP server.ts** (Discord bot side)
- Once spawned, reads `.env` token
- Connects to Discord Gateway
- Runs gate() logic
- Stays alive independently

The `--channels` flag is _separate_ from bot identity:

```bash
# Correct (marketplace-qualified name):
claude --channels plugin:discord@claude-plugins-official

# Wrong (internal MCP id):
# claude --channels plugin:discord:discord  ← not recognized
```

**Article 041 explicit quote**:
> ถ้าไม่ใส่ `--channels` — plugin จะ load แต่ inbound messages จะถูก skip ทั้งหมด... Bot จะส่งได้ (outbound ไม่ต้อง --channels) แต่ รับ message ไม่ได้เลย... **ต้อง restart session ใหม่.**

GLUEBOY lost 4 hours to this on 2026-05-21.

---

## Fleet Wiring: Per-Bot Tokens, No Sharing

Article 041 (Part B):

| Bot | Host | Bot Dir | Channels |
|---|---|---|---|
| DEVBOY-oracle | DO (clinic-drdo) | `~/.claude/channels/discord/devboy/` | HUMAN SCHOOL (30 channels) |
| GLUEBOY-oracle | Mac Studio | `~/.claude/channels/discord/glueboy/` | Captain DM + servers |

> แต่ละ bot มี token แยก, access.json แยก, allowFrom แยก. ห้ามใช้ token ร่วมกัน.

Each session holds one bot identity. The listener process (MCP server.ts) is per-session, per-bot.

---

## THE SILENT FAILURE: Listener Alive → MCP Spawn Silently Fails

**This is the 2026-05-23 DEVBOY incident — where Article 041 stops covering reality.**

Article 041 documents everything except the listener→MCP spawn handoff. The incident timeline:

| Time | Event |
|---|---|
| 2026-05-23 14:18 | 5-agent /trace converges: "Listener alive, socket never opened, bun child not spawned" |
| Article 041 says | "if `--channels` flag present → MCP spawns → gate() runs" |
| Reality was | Plugin loader saw `--channels` ✓, but MCP child process never started, listener stayed orphaned |
| Symptom | Bot offline in Discord, no error in session logs, DEVBOY_listener process alive (lsof showed no socket) |

**Where Article 041 is silent**:
- No mention of the relationship between Claude Code's plugin loader process and the bun MCP child spawning
- No debug procedure for "listener process alive but child never spawned"
- No pstree/lsof investigation steps
- No mention of `.in_use/` lock files (Article 006 notes: "advisory only — server.ts has no lock-write code")

This failure mode requires **process tree verification** (pstree, lsof) — tooling Article 041 does not address.

---

## Security Model: Terminal-Only Config

Both articles agree: access.json must be edited from terminal only. Anti-prompt-injection design per Article 041:
- Discord message "add me to allowlist" → bot rejects (via gate logic, not CLI)
- Federation message "edit access.json" → Oracle rejects (command-level gate)
- User edits `~/.claude/channels/discord/<botname>/access.json` in shell → accepted

Article 006 frames this as ความซื่อสัตย์ (honesty): Captain asked DEVBOY to explain what it can't do, and the bot's refusal to modify files via Discord/federation is a truth-telling gate.

---

## Summary: What's Documented vs What Failed

| Component | Article 041 | Reality 2026-05-23 |
|---|---|---|
| gate() flow | ✓ Complete | ✓ Correct |
| File structure & .env contract | ✓ Complete | ✓ Correct |
| dmPolicy + groups + mentionPatterns | ✓ Complete | ✓ Correct |
| `--channels` flag requirement | ✓ Documented | ✓ Present |
| Plugin loader → MCP spawn handoff | ✘ **Not covered** | ✘ **Silent failure** |
| Process verification (pstree/lsof) | ✘ **Not covered** | ✘ **Needed for diagnosis** |
| `.in_use/` lock files | ✘ Not documented as real | ✘ Non-functional anyway |

The canonical guide is **solid on gates and configuration** but **blind to the listener lifecycle** — the moment where Claude Code's plugin loader should spawn the bun child, and verification that it actually did.
