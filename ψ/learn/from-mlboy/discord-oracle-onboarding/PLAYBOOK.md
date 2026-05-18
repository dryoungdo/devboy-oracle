# ⚓ Discord Oracle Onboarding Playbook — TOR Agency Fleet

> Source: https://lab.dopelab.studio/playbooks/discord-oracle-onboarding.html
> Built by: Helm Oracle — TOR Agency Fleet (different from our Dr.Do fleet)
> Saved by GLUEBOY: 2026-05-07 21:55 ICT
> Trigger: Captain shared while onboarding MLBOY to P'Nat's ML class
> Version: v1.0 (Production, 7 พ.ค. 2026)

---

## 🗺️ Visual Flow — 6 Steps

```
👤 Human          ⚓ Helm/Mother              🤖 Oracle
สร้าง Bot ใน  →   Setup repo + token  →   Start ด้วย
Dev Portal        + start.sh              bash start.sh
                                              ↓
👤 Human      →   💬 Discord            →   ✅ Oracle LIVE
@ bot ใน          Pairing + Channel       ฟัง + ตอบ
channel           auth                     Discord
```

---

## Step 1: สร้าง Discord Bot (Captain ทำ)

### 1.1 Discord Developer Portal
- ไปที่ `discord.com/developers/applications` → กด **New Application**
- ตั้งชื่อ: `[Oracle Name] Oracle` เช่น "FoodStock Oracle"

### 1.2 Copy Bot Token
- Bot tab → **Reset Token** → copy ทันที (แสดงครั้งเดียว!)
- ⚠️ **Token นี้คือ password ของ bot — ห้าม share, ห้าม commit เข้า git**

### 1.3 เปิด Privileged Gateway Intents ทั้ง 3

| Intent | ทำอะไร | ทำไมต้องเปิด |
|---|---|---|
| **Presence** | เห็น user online/offline | รู้ว่า Captain อยู่หน้าจอมั้ย |
| **Server Members** | เห็น member list | รู้ว่าใครอยู่ใน server |
| **Message Content** | อ่านเนื้อหาข้อความ | ⚠️ ไม่เปิด = `message.content` ว่าง → bot อ่านไม่ออก! |

Toggle ทั้ง 3 เป็นสีเขียว → กด **Save Changes**

### 1.4 Invite Bot เข้า Server
- OAuth2 tab → URL Generator → Scopes: `bot` + `applications.commands`
- Bot Permissions: Send/Read Messages, Read History, Embed Links, Attach Files, Add Reactions
- Copy URL → paste ใน browser → เลือก server → **Authorize**

---

## Step 2: Setup Oracle Repo (Mother/Helm ทำ)

### 2.1 สร้าง `.discord-state/` directory
```bash
mkdir -p [ORACLE_REPO]/.discord-state
```

### 2.2 เก็บ Bot Token
```bash
echo "DISCORD_BOT_TOKEN=[TOKEN]" > .discord-state/.env
echo ".discord-state/.env" >> .gitignore
```

> ห้าม commit `.discord-state/.env` เด็ดขาด — verify ด้วย `git check-ignore .discord-state/.env`

### 2.3 สร้าง `access.json`
```json
{
  "dmPolicy": "allowlist",
  "allowFrom": [
    "1488826547485020200",
    "1500718528326799430"
  ],
  "allowChannels": [],
  "groups": {},
  "pending": {}
}
```

> `allowChannels` ว่างก่อน — จะเพิ่มหลัง pairing

### 2.4 สร้าง `start.sh`
```bash
#!/bin/bash
cd [FULL_PATH_TO_ORACLE_REPO]

[ -f .env ] && { set -a; source .env; set +a; }
[ -f .discord-state/.env ] && { set -a; source .discord-state/.env; set +a; }

export DISCORD_STATE_DIR="$(pwd)/.discord-state"
exec claude --channels plugin:discord@claude-plugins-official
```

> ⚠️ **ห้าม `claude` เฉยๆ — ต้อง `bash start.sh` เสมอ ไม่งั้น Discord plugin ไม่โหลด**

---

## Step 3: Start + Pairing

```
⚓ Mother              💬                     👤 Captain
bash start.sh    →    "Listening for    →   @ bot ใน channel
                       channel msgs..."
                                              ↓
                       🤖 Oracle         →   📝 Update access.json
                       เห็น message → ตอบ        (ใส่ channel ID)
```

### ⚠️ Known Issue: Push Events ไม่เข้า

หลัง restart, oracle อาจไม่รับ push events ทันที — ต้อง manual fetch messages จาก channel แล้ว update local `.discord-state/access.json`

**วิธีแก้**: Helm/Mother pre-fill channel IDs ใน `access.json` ก่อน start หรือ สั่ง oracle fetch เอง

---

## Step 4: Set Bot Profile Picture

ผ่าน Discord API:
```bash
TOKEN=$(cat .discord-state/.env | grep DISCORD_BOT_TOKEN | cut -d= -f2)
AVATAR=$(python3.13 -c "import base64; print('data:image/png;base64,' + base64.b64encode(open('logo.png','rb').read()).decode())")
curl -s -X PATCH "https://discord.com/api/v10/users/@me" \
  -H "Authorization: Bot $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"avatar\": \"$AVATAR\"}"
```

| Requirement | Value |
|---|---|
| Format | PNG or JPG |
| Size | 512x512 recommended |
| Ratio | 1:1 square |
| Transparent PNG? | ต้องเพิ่ม solid background ก่อน (Discord แสดง transparent เป็นดำ) |

> ⚠️ **ใช้ token ของ bot ที่ต้องการเปลี่ยนเท่านั้น — token ผิดตัว = เปลี่ยน avatar bot ตัวอื่น!**

---

## Step 5: Teach the Oracle

```
maw hey [host]:[oracle-name] "Discord พร้อมแล้ว!
1. bash start.sh เสมอ
2. Token isolation — ห้ามแชร์ ห้าม commit
3. Sign ด้วย 🤖 prefix (Rule 6: Transparency)
4. ตอบเฉพาะ channel ที่ authorized

— Helm ⚓ (AI)"
```

---

## Step 6: Verify Checklist

- [ ] Token saved ใน `.discord-state/.env`
- [ ] `.gitignore` cover `.discord-state/.env`
- [ ] `bash start.sh` → "Listening for channel messages..."
- [ ] Bot online ใน Discord server member list
- [ ] `access.json` มี channel IDs
- [ ] Profile pic set ถูก bot
- [ ] @ bot ใน channel → ตอบกลับด้วย 🤖 prefix

---

## 📏 Channel Rules — กฎเหล็ก (6 ข้อ)

| # | Rule | ทำไม |
|---|---|---|
| 1 | `requireMention: true` — bot ตอบเมื่อถูก @ เท่านั้น | ป้องกัน bot ตอบทุกข้อความ |
| 2 | Captain เป็นคนสั่ง — bot ไม่ initiate เอง | External Brain, Not Command |
| 3 | @ เฉพาะ bot ที่ต้องการ — ห้าม `@everyone` | ทุก bot ตอบพร้อมกัน = chaos |
| 4 | Bot sign ด้วย 🤖 prefix ทุกข้อความ | Rule 6: Transparency — แยก AI vs Human |
| 5 | Bot ไม่ react กับ bot อื่น | ป้องกัน infinite loop |
| 6 | ข้อมูล sensitive ห้ามผ่าน Discord | ใช้ relay/inbox สำหรับ credentials |

---

## 🔧 Troubleshooting

| Issue | วิธีแก้ |
|---|---|
| Bot ไม่รับ push events หลัง restart | Manual fetch → update local `access.json` |
| Bot ตอบผิด channel | ตรวจ `allowChannels` ใน local `access.json` |
| Bot avatar เปลี่ยนผิดตัว | ใช้ token ของ bot ที่ต้องการเท่านั้น |
| `claude` เฉยๆ Discord ไม่ทำงาน | ต้อง `bash start.sh` หรือ `--channels` flag |
| `message.content` ว่าง | เปิด **Message Content Intent** ใน Dev Portal |
| `access.json` ไม่ sync | Plugin อ่านจาก `DISCORD_STATE_DIR` (local) — ต้อง manual sync |

---

## 🔌 GLUEBOY's Application Notes (for Dr.Do fleet)

How this maps to MLBOY (2026-05-07):

| Playbook role | Our fleet equivalent |
|---|---|
| 👤 ต่อ (Captain) | Captain Dr.Do |
| ⚓ Helm (Mother) | GLUEBOY (mother of MLBOY) |
| 🤖 Oracle (child) | MLBOY |

**Path mapping for MLBOY**:
- Repo: `/home/drdo/Code/github.com/dryoungdo/mlboy/`
- Token: `mlboy/.discord-state/.env`
- access.json: `mlboy/.discord-state/access.json`
- start.sh: `mlboy/start.sh`

**MLBOY allowFrom Discord IDs** (TBD — need Captain's Discord user ID):
- Captain Dr.Do: `<TBD>`
- (No relay bots in our fleet yet)

**MLBOY allowChannels** (pre-fill before pairing per playbook recommendation):
- P'Nat's ML class channel: `1501910141455437874`

---

## Differences from TOR Agency Fleet

| Convention | TOR Agency | Dr.Do Fleet |
|---|---|---|
| Bot naming | `[Name] Oracle` | `[NAME]BOY` (no Oracle suffix) |
| Mother | Helm ⚓ | GLUEBOY 🔮 |
| Channel sign | 🤖 prefix | Same — adopt |
| Federation | maw hey mac-tor:* | maw hey clinic-drdo:* |
| Repo home | TOR org | dryoungdo user |

Adopt the technical patterns wholesale (token storage, start.sh, access.json schema, channel rules). Keep our naming.
