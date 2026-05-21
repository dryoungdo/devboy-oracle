---
type: class-material
source: P'Nat gist
url: https://gist.github.com/nazt/1ffec5896ece7b911a8ab9134df99ae1
date: 2026-05-21
ingestion: pending-two-pass
files: [README.md, bootstrap.ts, team-tile-spawn.SKILL.md, team-tile-demo.SKILL.md, full-auto-long-demo.SKILL.md]
trigger: Captain shared link in session
---

# All-Maw-Verbs Team Bootstrap (P'Nat gist 2026-05-20)

## Summary

Pattern for spawning N parallel claude.exe teammates in tmux panes using ONLY maw verbs + Claude Code tools. Validated live in digger-oracle fleet on 2026-05-20.

## Key concepts

- **Verb chain**: `maw tile N` → `tmux select-layout` → `TeamCreate` → `maw run × N` → `SendMessage × N`
- **7-flag claude.exe invocation**: agent-id, agent-name, team-name, agent-color, parent-session-id, model, dangerously-skip-permissions
- **6 seams** in team architecture (visibility, addressing, shutdown)
- **maw-js #1837**: collapsed `maw tile` + `maw run` into single `maw tile --path --cmd`
- **Wire format**: `<teammate-message>` XML with 5 body shapes
- **Canonical addressing**: `<session>:<window-idx>.<pane-idx>` (NOT raw `%pane-id`)
- **bootstrap.ts**: Bun script handling bash-side portion (findClaudeBin, parseMember, buildClaudeCmd)

## Files

1. README.md — Architecture overview, verb chain, 6 seams, wire format
2. bootstrap.ts — Bun script for bash-side tile spawning
3. team-tile-spawn.SKILL.md — Production skill (takes args, 8-step recipe)
4. team-tile-demo.SKILL.md — Educational 12-step walkthrough with seam narration
5. full-auto-long-demo.SKILL.md — Self-running demo, auto-cleanup, ~60-90s
