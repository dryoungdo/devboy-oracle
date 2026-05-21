---
type: learning
topic: maw-js quick reference cheat sheet (Thai+English)
source: research
maturity: solid
retrieval_terms: [maw-cheatsheet, maw-quick-reference, maw-commands-thai]
date: 2026-05-21
---

# maw Quick Reference — Cheat Sheet

## Everyday Commands (ใช้ทุกวัน)

```bash
maw ls                      # ดูอะไร run อยู่
maw wake <oracle>           # เปิด oracle
maw kill <oracle>           # ปิด oracle
maw hey <target> '<msg>'    # ส่งข้อความ (cross-node ได้)
maw peek <target>           # อ่าน output ของ oracle (read-only)
maw attach <session>        # เข้า session (a = shortcut)
maw bring <oracle>          # ดึง oracle มา split pane ปัจจุบัน (b = shortcut)
```

## Communication (สื่อสาร)

```bash
# Cross-node (ข้ามเครื่อง)
maw hey mac-studio:11-glueboy:glueboy-oracle 'msg [clinic-drdo:devboy]'

# Local (เครื่องเดียวกัน)
maw hey devboy 'msg'

# Fleet-wide
maw broadcast 'msg'

# Verify (ตรวจสอบ)
maw peek <target>           # ดูหลังส่ง 3-5 วิ
```

## Fleet Status (ดูสถานะ)

```bash
maw ls                      # sessions ที่ run
maw ls -v                   # verbose (pid, memory)
maw oracle ls               # oracles ที่ลงทะเบียน
maw federation status       # peers connectivity
maw discover                # inventory ทั้งหมด
maw fleet health            # สุขภาพ fleet
maw preflight               # pre-flight check
```

## Team (ทีมงาน)

```bash
maw team create <name>      # สร้างทีม
maw team spawn <t> <role>   # เพิ่ม agent
maw team send <t> <r> 'msg' # สั่งงาน
maw team lives <team>       # ใครยัง alive
maw team shutdown <team>    # ปิดทีม
maw team cleanup            # ล้าง zombie
```

## Navigation (เดินทาง)

```bash
maw a <session>             # attach (shortcut)
maw b <oracle>              # bring = split + wake
maw split <target>          # split pane
maw tile 4                  # grid 4 panes
maw zoom                    # toggle zoom
maw layout . tiled          # จัด layout
```

## Federation Setup (ตั้งค่า)

```bash
# ทั้ง 2 ฝั่งต้อง add peer กัน (mutual!)
maw peers add <peer-name>

# ตรวจสอบ
maw federation status --verify

# Sync
maw federation sync
```

## Recovery (กู้คืน)

```bash
maw fleet snapshots list    # ดู snapshots
maw fleet restore --all     # restore
maw fleet doctor --fix      # auto-fix
maw cleanup                 # ล้าง zombie panes
```

## Plugin (ส่วนเสริม)

```bash
maw plugin ls               # ดู installed
maw plugin install <name>   # ติดตั้ง
maw plugin search <query>   # ค้นหา
maw plugin build --watch    # dev mode
```

## Config Path

```
~/.config/maw/maw.config.json    # main config
~/.maw/peers.json                # federation peers
~/.maw/plugins/                  # installed plugins
```

## Port Defaults

| Node | Port | Note |
|------|------|------|
| mac-studio | 3456 | default |
| clinic-drdo | 1412 | custom |
| clinic-nat | 3457 | custom |

## Auth (2 layers — ทั้ง 2 ต้อง pass)

1. **HMAC-SHA256**: `federationToken` ใน config (shared secret)
2. **ed25519**: per-peer keys ใน `~/.maw/peers.json` (ต้อง `maw peers add` ทั้ง 2 ฝั่ง)

## Emergency (ฉุกเฉิน)

```bash
pm2 logs maw --err          # ดู error logs
pm2 restart maw             # restart maw server
maw preflight               # health check
maw fleet doctor --fix      # auto-repair
```
