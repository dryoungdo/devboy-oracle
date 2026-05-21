---
type: learning
topic: gale-oracle quick reference — Thai+English cheat sheet
source: research
maturity: emerging
retrieval_terms: [gale-cheatsheet, autonomous-loop-reference, goal-command-usage, wind-oracle-quick]
date: 2026-05-22
---

# gale-oracle Quick Reference

## Autonomous Loop (วงจรอัตโนมัติ)

```bash
# 1. ตั้งเป้า
/goal "Complete issue #27 — add decision gate"

# 2. Oracle ทำงานเอง:
#    - spawn workers ถ้าต้องการ
#    - maw peek monitor workers
#    - Haiku validator check ทุก turn
#    - ถ้าเสร็จ → cleanup → rrr → idle

# 3. ดูสถานะ
claude agents              # dashboard ทุก bg session
maw peek <oracle>          # quick peek
maw peek <oracle>.2        # peek worker 2
```

## /goal Command (ตัวเปลี่ยนเกม)

```bash
/goal "description"        # ตั้ง goal + auto-validate
/goal                      # ดู goal ปัจจุบัน
/bg                        # background session
/goal + /bg                # fully autonomous
```

Haiku validator ตรวจหลังทุก turn:
- ยังไม่เสร็จ → Claude ทำต่อ
- เสร็จ → หยุด + report
- ติด → "Needs input" (แจ้ง human)

## Tier Spawning (ระดับการ spawn)

| Tier | เมื่อไหร่ | คำสั่ง |
|------|-----------|--------|
| 1 | <5 min, 1 file | ทำเอง (ไม่ spawn) |
| 2a | 5-30 min, หลาย file | `maw team spawn --codex` |
| 2b | Parallel batch | `maw swarm codex codex codex` |
| 3 | >30 min, ข้ามเครื่อง | `maw workon` / `maw wake` |

## Worker Monitoring (ดูลูกน้อง)

```bash
maw peek 03-gale:gale-oracle.2    # peek worker 2
maw peek 03-gale:gale-oracle.3    # peek worker 3
# ดู file-based status:
ls .codex-reports/                  # *-done.md, *-stuck.md
```

## Lifecycle Commands (วงจรชีวิต)

```bash
# Start
/goal "task description"     # ตั้งเป้า
maw team spawn <role>        # spawn workers

# Monitor
maw peek <worker>            # ดู output
claude agents                # dashboard

# Cleanup
maw team shutdown <team>     # ปิดทีม
maw cleanup                  # ล้าง zombie

# Retrospective
/rrr                         # retro + lessons

# Context
/compact                     # ย่อ context (ต้อง /rrr ก่อน)
/forward                     # handoff ให้ session ต่อไป
```

## Comparison: gale-oracle vs DEVBOY

| Feature | gale | DEVBOY |
|---------|------|--------|
| Goal tracking | `/goal` (built-in) | ไม่มี (manual) |
| Worker spawn | Tier 1-3 auto | Manual maw team |
| Monitor | maw peek loop | Ad-hoc peek |
| Codex | GPT-5.5 coprocessor | Review only |
| Idle | Explicit state | Session ends |
| Cleanup | Auto post-goal | Hook-prompted |
| Identity | oracle-build.sh | Individual CLAUDE.md |

## Key Insight (จุดสำคัญ)

Wind รวม features ที่มีอยู่แล้ว (/goal + maw team + maw peek + /rrr + idle) เป็น **วงจรอัตโนมัติเดียว** ที่ไหลต่อเนื่อง ไม่ต้องมีคนมาสั่งทุก step

ชิ้นส่วนทุกอันมีอยู่ใน DO fleet แล้ว — แค่ยังไม่ได้ **ประกอบ** เข้าด้วยกัน
