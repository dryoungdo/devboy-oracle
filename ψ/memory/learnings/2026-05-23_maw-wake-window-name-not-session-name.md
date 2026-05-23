---
type: learning
topic: "maw wake resolves spawn command via WINDOW name, not session name; FleetSession schema does NOT support command override — overrides live in global maw.config.json commands.<window-name>"
source: experiment
maturity: solid
retrieval_terms: [maw, maw-wake, fleet-config, command-override, commands-default, window-name, devboy, addDiscordChannelsForClaude, discord-marker, schema-verification]
date: 2026-05-23
sister_lineage: from-iotboy
gate_hook: "before recommending fleet/<name>.json edits, verify FleetSession schema in /home/drdo/Code/github.com/Soul-Brews-Studio/maw-js/src/commands/shared/fleet-load.ts — fields: name, windows[], skip_command?, sync_peers?, project_repos?. NO command field."
related_retros: ["ψ/memory/retrospectives/2026-05/23/22.08_maw-wake-investigation-and-start-sh-continue-patch.md"]
related_learnings: ["ψ/memory/learnings/2026-05-23_discord-mcp-env-injection-fix.md"]
---

# Lesson: maw wake command resolution + how to actually override per-oracle

## What I got wrong (twice)

In the 2026-05-23 15:33 `/forward` plan I wrote: "create `~/.config/maw/fleet/devboy.json` override command = `bash start.sh`" as if it were schema-supported. Then in conversation I said "maw wake devboy = respawn session ตาม fleet config (น่าจะวิ่ง start.sh)". Both wrong. The schema doesn't accept a `command` field, and `maw wake` does NOT call start.sh by default — it spawns `commands.default` ("claude --dangerously-skip-permissions --continue") unless a more specific glob matches.

## How it actually works (verified against source)

`maw wake <oracle>` flow:

1. Resolve oracle → tmux session (`sessions.devboy = "01-devboy"`)
2. Enumerate windows in that session (e.g. `devboy-oracle`)
3. For each window, call `buildCommandInDir(windowName, cwd, engine)` in `src/config/command-logic.ts`
4. `buildCommandFromConfig` resolves command via:
   - If `engine` matches a key, use `commands[engine]`
   - Else: start with `commands.default`, iterate `Object.entries(commands)`, **first glob match against `windowName` wins** (not session name, not oracle name — the **window name**)
   - `matchGlob`: exact match, OR `*X` suffix, OR `X*` prefix
5. **Auto-inject `--channels plugin:discord@claude-plugins-official`** if:
   - `cwd/.discord/` directory exists
   - Command contains `claude` keyword
   - Command does not already have `--channels` flag
6. Inject `--resume <sessionId>` or replace `--continue` if `sessionIds[agentName]` is configured

## How to actually override per-oracle

Edit **global** `~/.config/maw/maw.config.json`, insert exact window-name key BEFORE any `*-oracle` glob so first-match wins:

```json
"commands": {
  "default": "claude --dangerously-skip-permissions --continue",
  "devboy-oracle": "CLAUDE_CONTINUE=1 bash /home/drdo/Code/github.com/dryoungdo/devboy-oracle/start.sh",
  "*-oracle": "claude --dangerously-skip-permissions --continue"
}
```

Order matters — JSON Object.entries iteration follows insertion order. If `*-oracle` comes first, it matches `devboy-oracle` and breaks before the exact key is ever tested.

## What FleetSession actually supports

```ts
// src/commands/shared/fleet-load.ts:7
export interface FleetWindow {
  name: string;
  repo: string;
}
export interface FleetSession {
  name: string;
  windows: FleetWindow[];
  skip_command?: boolean;
  sync_peers?: string[];
  project_repos?: string[];
}
```

**No `command` field.** No per-window command. The `~/.config/maw/fleet/<name>.json` files declare *what windows exist + how they relate to repos and peers*. They do NOT declare *how to launch claude inside them*.

## Bonus: `.discord/` marker auto-injects --channels

If a repo wants the discord plugin loaded automatically without editing global commands, just create an empty `.discord/` directory at the repo root. `shouldAutoDiscordChannels(cwd)` checks `existsSync(join(cwd, ".discord"))` and appends `--channels plugin:discord@claude-plugins-official` to the command. Lightweight and self-documenting. **DEVBOY repo currently has no `.discord/`** — adding one would be an alternative to the global `commands.devboy-oracle` override, but loses the model 4.6 pin and `DISCORD_STATE_DIR` export from start.sh.

## How to apply

When asked "how do I make maw wake X use a custom launcher":

1. `grep "agentName\|buildCommand" /home/drdo/Code/github.com/Soul-Brews-Studio/maw-js/src/commands/shared/wake-cmd.ts` — confirm window-name (not session-name) is the matched key
2. Check `~/.config/maw/maw.config.json` `.commands` — list current globs + their order
3. Insert exact-match key for the window name BEFORE any catching glob
4. If the custom launcher is a wrapper script that runs claude with extra flags, prefix with env vars (`FOO=1 bash /path/to/script`) — tmux sendText treats the whole string as a single shell command

When asked "edit fleet/<name>.json to override the command":

- **Don't.** That schema doesn't support it. Tell the user the override lives in global maw.config.json and explain why.

## Pre-publish ledger

- **Sources checked**: `maw --help` + `maw sleep|wake|restart|done --help`, `/home/drdo/Code/github.com/Soul-Brews-Studio/maw-js/src/config/command-logic.ts`, `/home/drdo/Code/github.com/Soul-Brews-Studio/maw-js/src/commands/shared/fleet-load.ts`, `/home/drdo/Code/github.com/Soul-Brews-Studio/maw-js/src/commands/shared/wake-cmd.ts`, current `~/.config/maw/maw.config.json`, current `~/.config/maw/fleet/*.json` (3 templates: testboy, metricboy, crucible-test — none have `command` field)
- **Claims made**: 6 (resolution flow, schema fields, override location, glob order, .discord/ auto-inject, what NOT to do)
- **Conflicts resolved**: my own prior plan (`/forward` 15:33) had the wrong fix. This learning supersedes that plan's option-2. Updated.
- **Application evidence**: applied to `~/.config/maw/maw.config.json` (`commands.devboy-oracle` inserted before `*-oracle`); applied to `start.sh` (commit `d2dcaa6`). Not yet runtime-tested via actual `maw sleep` + `maw wake` cycle — that test belongs to the next session in a fresh tmux pane.
- **Codex reviewed**: start.sh patch reviewed clean (`/tmp/codex-review-dryoungdo-drdo-20260523-220549.md`); maw.config.json change reasoned-but-not-codex-reviewed (3-line insert outside repo).
