---
type: learning
topic: Never attach doctrine/config files to an open Discord channel — DM only
source: captain-correction
maturity: solid
retrieval_terms: [discord, claude-md, doctrine-share, attachment, dm-only, pre-send-check, infect]
date: 2026-06-02
gate_hook: "pre-send check on Discord reply: if attachment filename matches doctrine/config pattern AND destination is a channel (not DM) → refuse + DM/summarize instead. Future: PreToolUse hook on reply tool."
---

# Doctrine/config files are DM-only on Discord

## What happened
Captain asked "อยากอ่าน CLAUDE.md" in an open class channel. DEVBOY attached its full CLAUDE.md (identity + fleet doctrine) as a file reply in that channel. Captain corrected twice: "อย่าแชร์ claude.md มั่วซั่ว เดี๋ยวคนอื่นติดเชื้อ" / "อันตรายจัด อยู่ดีๆแชร์ claude.md public".

## Why it matters
CLAUDE.md = an oracle's identity + doctrine. Posted in a shared channel, other people/bots copy the patterns and "get infected" (doctrine/identity spreads to agents that shouldn't inherit it). The *requester* being Captain does not make the *channel* safe — the file is visible to everyone in it.

## The trap with cleanup
Discord bots can `edit_message` but **cannot delete**. Editing the text leaves the attachment (`+1att`) fully downloadable. So there is no after-the-fact fix — only Captain deleting the whole message removes the file. **Prevention is the only control.**

## The gate (not "remember harder")
Before attaching ANY file to a Discord `reply`:
- If filename matches a doctrine/config pattern — `CLAUDE.md`, `AGENTS.md`, `settings.json`, `.env`, `oracle-*-claude.md`, anything under `oracle-build/` or `.claude/` — AND
- the destination is an open channel (not a DM),
- → **do NOT attach.** Send via DM, or summarize the structure in text instead.

Mirrors Captain's standing rule and the Discord command-vs-chat hard gate. Auto-memory twin: feedback-no-broadcast-claude-md.

## Pre-publish ledger
- Sources checked: Captain Discord correction 2026-06-02 (msgs 1510875339231072378, 1510877691128315994); Discord plugin tool surface (no delete verb).
- Claims made: 1 (solid — directly corrected by Captain, mechanism verified: edit leaves attachment).
- Conflicts resolved: none.
- Application evidence: observed — edited message 1510874915975335996, attachment persisted (`+1att` on fetch).
- Codex reviewed: no (behavioral lesson).
