---
type: learning
topic: Team-Tile Quick Reference — Thai+English cheat sheet
source: pnat-gist
maturity: emerging
retrieval_terms: [team-tile-cheatsheet, maw-tile-quick, verb-chain-summary]
date: 2026-05-21
---

# Quick Reference: Team-Tile Bootstrap

## Verb Chain (one-liner)

```
maw tile N → layout → TeamCreate → SendMessage × N → wait → shutdown × N → TeamDelete → kill-pane
```

## เมื่อไหร่ใช้อะไร

| ต้องการ | ใช้ |
|--------|-----|
| Sub-task ใน repo เดียว ผลลัพธ์กลับ | `Agent()` |
| N teammate คุยกันได้ ข้าม repo | `maw tile` + TeamCreate |
| ส่ง message ข้ามเครื่อง async | `maw hey` |
| สั่ง command ใน pane ที่มีอยู่ | `maw run` |

## Spawn 1 Teammate (post #1837)

```bash
maw tile 1 --path <repo-path> --cmd "env CLAUDECODE=1 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude.exe --agent-id <role>@<team> --agent-name <role> --team-name <team> --agent-color <color> --parent-session-id $CLAUDE_SESSION_ID --model sonnet --dangerously-skip-permissions"
```

## Addressing

```
50-digger:2.1     ✓ canonical (session:window.pane)
%107              ✗ raw pane-id ใช้ไม่ได้กับ maw
```

## 6 Seams (จำง่าย)

1. maw-workon ไม่เห็น team — Medium
2. GitHub issues ไม่ผูก team — Low
3. XML render ต้องมี --agent-id — Low (by design)
4. Cross-session = auth ไม่ใช่ protocol — Medium
5. maw ls ไม่เห็น raw pane — Medium (#1837 แก้)
6. **shutdown_approved ≠ process kill** — High (ต้อง kill-pane ตาม)

## Wire Format

```xml
<teammate-message teammate_id="reader-a" color="magenta" summary="found 3 patterns">
markdown body หรือ JSON body
</teammate-message>
```

5 body shapes: markdown, text ack, idle_notification, shutdown_request, shutdown_approved

## Cleanup Recipe

```
SendMessage shutdown_request → wait shutdown_approved → TeamDelete → tmux kill-pane
```

## Prerequisites

- tmux (อยู่ใน tmux session)
- $CLAUDE_SESSION_ID (ต้อง set)
- maw-js (maw CLI)
- bun (สำหรับ bootstrap.ts)
- CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

## สิ่งที่ต้องระวัง

- `--dangerously-skip-permissions` = teammate ทำอะไรก็ได้ในระบบ
- shutdown ไม่ kill process จริง → ต้อง `tmux kill-pane` เสมอ
- inbox ไม่มี flock → 2 message พร้อมกันอาจ race
- findClaudeBin hardcode NVM version → อาจพังเมื่อ upgrade Node
