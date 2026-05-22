---
type: learning
topic: maw team-agent quick reference — Thai+English cheat sheet
source: pnat
maturity: raw
retrieval_terms: [maw-team-agent-cheatsheet, team-agent-quick-ref, spawn-patterns]
date: 2026-05-22
---

# maw team-agent — Quick Reference

## Flow ทั้งหมด (5 ขั้น)

```
1. สร้าง UUID     →  maw team-agent uuid --bare
2. สร้าง team     →  maw team-agent create <team> "desc" --session-id <uuid>
3. spawn agents   →  maw team-agent spawn <team> <name>@<path>:<color> [--system-prompt] [--mission]
4. ส่งงาน         →  maw team-agent msg <team> <name> "task"
5. ปิด            →  maw team-agent shutdown/cleanup
```

## 3 แบบ spawn

| แบบ | ใช้เมื่อ | command |
|-----|---------|---------|
| Identity + Task | รู้ทั้ง WHO + WHAT | `spawn ... --system-prompt "..." --mission "..."` |
| Identity only | spawn ไว้ก่อน ส่งงานทีหลัง | `spawn ... --system-prompt "..."` แล้ว `msg` ทีหลัง |
| Task only | worker ธรรมดา one-shot | `spawn ... --mission "..."` |

## เทียบกับ maw team เดิม

| เรื่อง | maw team (เดิม) | maw team-agent (ใหม่) |
|--------|-----------------|------------------------|
| session link | ไม่มี (tmux เฉยๆ) | `--parent-session-id` จริง |
| identity | ไม่มี | `--system-prompt` persist ตลอด |
| ส่งงานทีหลัง | ทำไม่ได้ | `msg` ได้ |
| recovery | restart ใหม่ | session-id resume ได้ |

## Spawn format

```
maw team-agent spawn <team> <name>@<path>:<color>
```

- `<name>` = ชื่อ agent (reviewer, writer, etc.)
- `<path>` = working directory
- `<color>` = สี tmux pane (green, cyan, magenta, etc.)

## ⚠️ gotcha

- `--dangerously-skip-permissions` = child ได้ full access ทุก tool ไม่ต้อง approve
- ยังไม่มี per-agent permission boundary
- design doc stage — P'Nat implement แล้ว แต่ยังไม่ได้ test บน DO fleet
