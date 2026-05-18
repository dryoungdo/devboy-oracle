---
fusion:
  source: iotboy
  fusedAt: 2026-05-18T18:09:40.830Z
  originalPath: memory/learnings/2026-05-07_read-source-on-first-failure.md
  contentHash: d7d03c27b7174b3fc0c08fdc1de8f7247c799fabb041964d7907fa695eba5949
---

# Lesson: Read the source on first failure when docs and errors disagree

**Date**: 2026-05-07
**Context**: Setting up Discord access for IOTBOY's first announcement to `#esp32-dev`

## The pattern

Three sources of truth disagreed about the shape of `access.json`:

1. **The repo's existing file** — had fields like `allowChannels`, `commandAuthority`, `respectRoles` (Captain's bookkeeping, but written like config)
2. **The `/discord:access` skill docs** — described `groups` with `requireMention`/`allowFrom`, said state lives at `~/.claude/channels/discord/access.json`
3. **The plugin's actual `server.ts`** — read state from `DISCORD_STATE_DIR` env var (overridden to project's `.discord-state/`), and required `groups` keyed by **channel ID snowflake**, not friendly name

The error message ("channel X is not allowlisted — add via /discord:access") pointed me at the skill, which writes to a path the plugin doesn't read in this project. I spent ~15 minutes bouncing between the skill docs and the existing config before grepping the plugin source.

## The lesson

When an error message and a skill's documentation both seem authoritative but the fix isn't working: **read the source code**. Plugin code is the only source of truth for runtime behavior. Skill docs describe intent, error messages describe symptoms — neither describes the actual gate condition.

## Heuristic

If two doc sources agree on what to do, and doing it doesn't work after one attempt, stop iterating on the docs. Grep the plugin/server source for:
- The error string verbatim
- The state file name
- The env vars that might redirect paths

Cost: ~30 seconds of grep. Saves: ~15 minutes of wrong-path edits.

## Applied

The DISCORD_STATE_DIR + channel-ID-snowflake gotcha is now memorialized in `~/.claude/projects/.../memory/project_discord_state_dir.md` so future sessions skip this maze.

## Tags

`#tooling` `#debugging` `#discord` `#meta-skill` `#read-the-source`