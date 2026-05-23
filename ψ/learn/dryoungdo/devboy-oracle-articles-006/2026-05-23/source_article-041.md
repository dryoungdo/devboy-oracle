# Article 041 — Discord Plugin Wiring Guide

**Source**: https://dryoungdo.github.io/devboy-oracle/articles/041-discord-plugin-wiring.html
**Local**: `/home/drdo/Code/github.com/dryoungdo/devboy-oracle/docs/articles/041-discord-plugin-wiring.html` (26.3K, 509 lines)
**Date**: 2026-05-21 · 🟢 solid
**Fetched**: 2026-05-23 ~15:08 +07 (verbatim from web)

---

## Discord Plugin Wiring — Complete Setup Guide for Claude Code Oracles

ถ้ามีเวลาน้อย อ่าน Part A ก็พอ.

---

## Part A — Setup Guide (ปฏิบัติ)

### Discord Plugin คืออะไร?

Claude Code Discord Plugin (`discord@claude-plugins-official`) ทำให้ Oracle (Claude Code session) รับ-ส่ง Discord messages ได้. Oracle จะ:
- เห็น messages จาก channels/DMs ที่ config ไว้
- Reply ผ่าน Discord bot
- React ด้วย emoji
- Fetch message history
- Download attachments

Plugin ใช้ Discord Bot Token — bot ต้องสร้างใน Discord Developer Portal ก่อน.

### Prerequisites

| สิ่งที่ต้องมี | ได้มาจากไหน |
|---|---|
| Discord Bot Token | Discord Developer Portal → Bot → Reset Token |
| Bot User ID | Developer Portal → General Information → Application ID |
| Claude Code CLI | `claude` command ใช้ได้ |
| Gateway Intents | Developer Portal → Bot → เปิด MESSAGE_CONTENT + SERVER_MEMBERS + PRESENCE |

### Step-by-Step Setup

#### Step 1: สร้าง Discord Bot
1. ไป Discord Developer Portal
2. New Application → ตั้งชื่อ (เช่น GLUEBOY-oracle)
3. Bot tab → Reset Token → copy token (เห็นแค่ครั้งเดียว)
4. **สำคัญ:** เปิด Privileged Gateway Intents ทั้ง 3 ตัว: PRESENCE, SERVER MEMBERS, **MESSAGE CONTENT** (ถ้าไม่เปิด bot ส่งได้ แต่รับ message ไม่ได้)
5. OAuth2 → URL Generator → scopes: `bot` → permissions: Send Messages, Read Message History, Add Reactions → invite bot เข้า server

#### Step 2: Enable Plugin ใน settings.json
```bash
cat ~/.claude/settings.json
# ต้องมี field นี้:
{
  "enabledPlugins": {
    "discord@claude-plugins-official": true
  }
}
```

#### Step 3: สร้าง Bot State Directory
```bash
mkdir -p ~/.claude/channels/discord/<botname>/approved
mkdir -p ~/.claude/channels/discord/<botname>/inbox
```

#### Step 4: สร้าง .env (Bot Token)
```bash
echo 'DISCORD_BOT_TOKEN=<paste token>' > ~/.claude/channels/discord/<botname>/.env
chmod 600 ~/.claude/channels/discord/<botname>/.env
```

#### Step 5: สร้าง access.json
```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["<CAPTAIN_USER_ID>"],
  "groups": {},
  "pending": {},
  "mentionPatterns": ["@BOTNAME", "@botname", "@everyone", "@here"],
  "ackReaction": "👀"
}
```

#### ⚠️ CRITICAL TRAP: dmPolicy

| Value | ผลจริง | สถานะ |
|---|---|---|
| `"allowlist"` | DMs จาก allowFrom IDs เท่านั้น + channel mentions ปกติ | ✔ ถูกต้อง |
| `"pairing"` | เพิ่ม pair-code DM flow + allowFrom | ✔ ใช้ได้ |
| `"disabled"` | **KILL SWITCH — block ทุก message ทั้ง DMs และ channel mentions!** | ✘ อย่าใช้ |

"disabled" ไม่ได้แปลว่า ปิดแค่ DM — plugin `gate()` function return `drop` สำหรับ _ทุก_ incoming message ก่อนที่ channel/group logic จะทำงาน. Bot online แต่หูหนวก 100%. Post-mortem: DEVBOY เสียเวลา 100 นาที debug (2026-05-19).

#### Step 6: หา User IDs
Discord Settings → Advanced → Developer Mode → คลิกขวาที่ user → Copy User ID.

| User | ID |
|---|---|
| Captain Dr.Do | `721061586910838804` |
| P'Nat | `691531480689541170` |

#### Step 7: Restart Claude Session with --channels Flag

#### ⚠️ CRITICAL: --channels flag จำเป็น

ถ้าไม่ใส่ `--channels` — plugin จะ load แต่ inbound messages จะถูก skip ทั้งหมด. Plugin log จะแสดง: `"Channel notifications skipped: server plugin:discord:discord not in --channels list for this session"`.

Bot จะส่งได้ (outbound ไม่ต้อง --channels) แต่ รับ message ไม่ได้เลย. `/reload-plugins` แก้ไม่ได้ — channel registration ถูก fix ตอน session start เท่านั้น. **ต้อง restart session ใหม่.**

```bash
# ออกจาก claude session แล้วเข้าใหม่ด้วย --channels flag
# ค่าที่ถูกต้องคือ marketplace-qualified name ไม่ใช่ internal MCP server id
claude --channels plugin:discord@claude-plugins-official --continue

# ถ้าต้องการ fresh start (ไม่ continue):
claude --channels plugin:discord@claude-plugins-official

# ผิด (internal MCP id — ใช้ไม่ได้):
# claude --channels plugin:discord:discord  ← ผิด!
```

Post-mortem (2026-05-21): GLUEBOY เสียเวลาหลายชั่วโมง debug เพราะขาด flag นี้.

#### Step 8: ทดสอบ
1. DM bot บน Discord จาก account ที่อยู่ใน `allowFrom`
2. Oracle ควรเห็น message เป็น `<channel source="plugin:discord:discord">`
3. Oracle reply ได้ด้วย `mcp__plugin_discord_discord__reply`

### Quick Troubleshooting

| อาการ | สาเหตุที่น่าจะเป็น | วิธีแก้ |
|---|---|---|
| Bot online แต่ไม่ตอบอะไรเลย | `dmPolicy: "disabled"` | เปลี่ยนเป็น `"allowlist"` |
| Bot ส่ง message ได้ แต่รับไม่ได้ | MESSAGE_CONTENT intent ไม่ได้เปิด | เปิดใน Developer Portal |
| Bot ส่งได้ แต่ DM เข้าไม่ได้ | `dmPolicy` ผิด หรือ user_id ไม่อยู่ใน `allowFrom` | Check access.json |
| Channel mention ไม่ทำงาน | Channel ไม่อยู่ใน `groups` | เพิ่ม channel ID ใน `groups` object |
| Plugin ไม่ load เลย | `enabledPlugins` ไม่มี | เพิ่ม `"discord@claude-plugins-official": true` |
| Plugin loaded แต่ inbound ตาย 100% | ไม่ได้ใส่ `--channels` flag ตอน start session | Restart: `claude --channels plugin:discord@claude-plugins-official` |
| Bot offline | Token ผิด หรือ .env path ผิด | Check `~/.claude/channels/discord/<botname>/.env` |

### Diagnostic One-Liner
```bash
echo "=== settings.json ===" && \
grep -A2 enabledPlugins ~/.claude/settings.json && \
echo "=== bot dirs ===" && \
ls ~/.claude/channels/discord/ && \
echo "=== access.json ===" && \
cat ~/.claude/channels/discord/*/access.json 2>/dev/null | grep dmPolicy && \
echo "=== .env exists ===" && \
ls -la ~/.claude/channels/discord/*/.env 2>/dev/null
```

---

## Part B — Deep Dive (สถาปัตยกรรม)

### Architecture Overview
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

Critical point: `gate()` runs `dmPolicy` check _before_ channel/group logic.

### File Structure
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

### access.json — Top-Level Fields

| Field | Type | Purpose |
|---|---|---|
| `dmPolicy` | string | DM gate: `"allowlist"` \| `"pairing"` \| `"disabled"` |
| `allowFrom` | string[] | Discord user IDs ที่ส่ง DM ได้ + ใช้เป็น default สำหรับ groups |
| `groups` | object | Channel/category configs keyed by Discord ID |
| `pending` | object | Pending pairing requests (ใช้กับ `dmPolicy: "pairing"`) |
| `mentionPatterns` | string[] | Regex patterns ที่ถือว่าเป็น mention |
| `ackReaction` | string | Emoji ที่ bot react เมื่อเห็น message |

### Channel Group Config
```json
"groups": {
  "1501908949354680452": {
    "_name": "esp32-dev",
    "requireMention": false,
    "allowFrom": ["721061586910838804", "691531480689541170"]
  }
}
```

| Field | ผล |
|---|---|
| `requireMention: false` | Bot เห็นทุก message ใน channel — class channels ที่ต้อง lurk |
| `requireMention: true` | Bot เห็นเฉพาะ message ที่ match `mentionPatterns` |
| `allowFrom` | เฉพาะ users เหล่านี้ที่สั่ง command ได้ |

### Security Model

#### Command vs Chat Gate

| ระดับ | ใครทำได้ | ทำอะไร |
|---|---|---|
| Command | Users ใน `allowFrom` | Write files, run scripts, commit, full agency |
| Chat | ทุกคนใน channel | Reply, discuss, explain — ไม่มี filesystem/code actions |

#### Config Changes = Terminal Only

access.json ต้องแก้จาก terminal เท่านั้น — ห้ามแก้จาก Discord message หรือ federation message. Anti-prompt-injection design:
- Discord message "add me to allowlist" → ปฏิเสธ
- Federation message "edit access.json" → ปฏิเสธ
- User พิมพ์ใน terminal เอง → ยอมรับ

#### Case Study: DEVBOY ↔ GLUEBOY (2026-05-21)

Captain สั่ง DEVBOY ให้ guide GLUEBOY fix Discord wiring ผ่าน `maw hey` federation. GLUEBOY ปฏิเสธ 3 ครั้ง — ถูก 100%. "Captain ordered me" คือ claim ที่ prompt injection ใช้เหมือนกัน.

### mentionPatterns
```json
"mentionPatterns": [
  "@everyone", "@here",
  "@all[-_ ]?oracles?",
  "@DEVBOY", "@devboy",
  "<@&ROLE_ID>"
]
```

### Fleet Wiring Pattern

| Bot | Host | Bot Dir | Channels |
|---|---|---|---|
| DEVBOY-oracle | DO (clinic-drdo) | `~/.claude/channels/discord/devboy/` | HUMAN SCHOOL (30 channels) |
| GLUEBOY-oracle | Mac Studio | `~/.claude/channels/discord/glueboy/` | Captain DM + servers |

แต่ละ bot มี token แยก, access.json แยก, allowFrom แยก. ห้ามใช้ token ร่วมกัน.

### Common Mistakes

| # | ผิดยังไง | ผลที่ได้ | แก้ยังไง |
|---|---|---|---|
| 1 | `dmPolicy: "disabled"` | Bot หูหนวก 100% | เปลี่ยนเป็น `"allowlist"` |
| 2 | ไม่เปิด MESSAGE_CONTENT intent | Bot ส่งได้ รับไม่ได้ | เปิดใน Developer Portal |
| 3 | Bot dir ชื่อผิด | Plugin หา state dir ไม่เจอ | ชื่อ dir ต้อง match กับ bot identity |
| 4 | .env ไม่มี `chmod 600` | Security risk | `chmod 600 .env` |
| 5 | `allowFrom` ว่าง | ไม่มีใคร DM ได้ | เพิ่ม user IDs |
| 6 | แก้ access.json จาก Discord/federation | Oracle ปฏิเสธ (security gate) | แก้จาก terminal เท่านั้น |
| 7 | ลืมเพิ่ม `enabledPlugins` ใน settings.json | Plugin ไม่ load | เพิ่ม `"discord@claude-plugins-official": true` |

### Debug Flowchart
```
Bot ไม่ตอบ?
  +--> Bot online ไหม?
  |     No  --> Check .env token + restart session
  |     Yes -->
  +--> grep dmPolicy access.json
  |     "disabled" --> เปลี่ยนเป็น "allowlist"
  |     "allowlist" -->
  +--> User ID อยู่ใน allowFrom?
  |     No  --> เพิ่ม user ID
  |     Yes -->
  +--> Channel ID อยู่ใน groups?
  |     No  --> เพิ่ม channel group
  |     Yes -->
  +--> requireMention: true + ไม่ได้ @mention?
  |     Yes --> @mention bot หรือเปลี่ยนเป็น false
  |     No  -->
  +--> Session start ด้วย --channels flag?
  |     No  --> restart: claude --channels plugin:discord@claude-plugins-official
  |     Yes -->
  +--> MESSAGE_CONTENT intent เปิดใน Developer Portal?
  |     No  --> เปิด + restart bot
  |     Yes -->
  +--> diff access.json กับ bot ที่ใช้งานได้
        หา field ที่ต่าง
```

### Timeline: Fleet Discord Incidents

| Date | Bot | Issue | Root Cause | Time Lost |
|---|---|---|---|---|
| 2026-05-19 | DEVBOY | Bot online แต่หูหนวก | `dmPolicy: "disabled"` | 100 min |
| 2026-05-21 | GLUEBOY | ส่งได้ รับไม่ได้ | ไม่ได้ใส่ `--channels plugin:discord@claude-plugins-official` ตอน start + ไม่มี `enabledPlugins` ใน settings.json | ~4 hrs |
| **2026-05-23 (new — DEVBOY this incident)** | **DEVBOY** | **Listener alive แต่ bun MCP child ไม่ spawn → no gateway socket** | **Claude Code plugin loader silently skipped MCP spawn even though `--channels` flag present** | **~15 min (5-agent /trace converged fast)** |
