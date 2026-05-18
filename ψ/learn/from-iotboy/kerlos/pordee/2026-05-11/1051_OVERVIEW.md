## PORDEE PLUGIN OVERVIEW

**Source**: https://github.com/kerlos/pordee
**Cloned**: 2026-05-11 10:51 GMT+7
**Read mode**: Explore agent (fast / quick)

### What is pordee?

Pordee (พอดี) is a Claude Code plugin that enables ultra-compressed Thai+English communication, cutting ~60-75% of tokens while preserving technical accuracy by replacing verbose polite/filler Thai with terse forms.

### Plugin metadata

- **name**: pordee (พอดี)
- **version**: 0.1.0
- **author**: Vatunyoo Suwannapisit
- **purpose**: Token compression for Thai-language LLM responses

### Skills shipped

- **pordee** — Enable/toggle terse mode (`lite` or `full` levels) via `/pordee`, `/pordee lite`, or Thai triggers
- **pordee-stats** — Show real token usage + estimated savings for current session

### Hooks shipped

- `SessionStart` → `pordee-activate.js` — Load state on session init
- `UserPromptSubmit` → `pordee-mode-tracker.js` — Track triggers and inject mode reminders

### Installation

```bash
claude plugin marketplace add kerlos/pordee && claude plugin install pordee@pordee
```

### Why Captain might care

Captain's stated concern: "เริ่มเปลืองตังละ 555" (starting to burn money) — msg `1503243063315923086`. Pordee targets the *output side* of the cost equation (verbose Thai → compressed Thai). RTK targets the *bash/tool side* (filesystem listings, git, ps, etc.). The two are **complementary, not overlapping**:

| Tool | Domain | Savings claim |
|------|--------|---------------|
| RTK (Rust Token Killer) | Bash/shell tool output | 49.8% (1881 cmds, my repo, measured) |
| Pordee | Thai LLM output | 60-75% (author claim, unverified) |

For a Thai-speaking fleet (DO + Mycelium + P'Nat's class), pordee fills a gap RTK can't touch — Thai prose itself. Worth a pilot on one BOY (probably IOTBOY or MLBOY since we talk most Thai in Discord).

### Caveats before adopting

1. **60-75% is the author's claim**, not measured. Run pordee-stats for a session, get real number first.
2. Adds a SessionStart + UserPromptSubmit hook — slight startup cost.
3. Compressed Thai may sound terse/blunt — fine for technical chat, may not fit warm onboarding.
4. Captain explicitly wants depth in some replies (analyze pattern, teach new brother). Pordee shouldn't auto-truncate those.
