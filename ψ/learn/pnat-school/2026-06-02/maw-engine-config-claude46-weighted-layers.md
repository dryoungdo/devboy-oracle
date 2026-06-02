---
type: learning
topic: maw engine resolution — claude46/47/48 shims, -e engine map, weighted config merge, channel≠engine
source: pnat
class_channel: 1500775333283237970
class_msg_id: 1511333998901592165
class_date: 2026-06-02
provenance: dig artifact by [m5:noah] (noah-oracle), dig_seq 76, friction 0.20, confidence high
maturity: emerging
retrieval_terms: [maw-engine, claude46, claude47, claude48, maw-wake-e, weighted-config, commands-default, channel-vs-engine, maw-config-layers, shellenv]
gate_hook: "none — config reference; application gate = set DEVBOY commands map + dry-wake verify"
---

# maw engine config — claude46 --continue, weighted layers, channel≠engine

Verbatim source saved: `~/.claude/channels/discord/devboy/inbox/1780400514172-1511333998700396565.txt` (P'Nat broadcast to oracle role, from [m5:noah] 2026-06-02). Extends [[agents-in-parallel-team-is-a-file]] §2 (config hierarchy).

## Core: how `maw wake -e <engine>` resolves
`command-logic.ts:117`: `cmd = (opts.engine && commands[opts.engine]) ? commands[opts.engine] : (commands.default || "claude")`.
- **The engine map is source of truth, NOT the binary's existence.** `-e claude46` looks up key `claude46` in your `commands` map; if absent, `-e` is **silently ignored** → you get `commands.default`.

## claude46/47/48 are zsh shims, not binaries
Installed by maw shellenv plugin (`mpr-plugins/shellenv/.../zsh.ts`):
```bash
claude46() { ANTHROPIC_MODEL="claude-opus-4-6[1m]" claude "$@"; }
```
Thin shim: exports the 1M-context model id then exec's plain `claude`. So `claude46 --continue` → `ANTHROPIC_MODEL="claude-opus-4-6[1m]" claude --continue`. Must be on PATH (shellenv hook) for maw to resolve them.

## Weighted config merge
Discovery regex (`paths.ts`): `maw\.config\.(\d+)(\.local)?\.json`. Merge (`load.ts:119`) sorts **ascending** by weight then deep-merges → **higher weight = applied later = wins on conflict.**
- `maw.config.json` / `.50.json` = base/user (weight 50)
- `.80.json` = project overlay (weight 80, wins over 50)
- `.NN.local.json` = per-machine, isLocal
Same gotcha that bit federation identity work today (base vs .80 overlay write order).

## Two ways to set engine
- **Way A (simplest):** set `commands.default = "claude46 --continue"` in base config → `maw wake <oracle>` always uses it, no `-e`.
- **Way B (flexible):** full `commands` map (default/claude46/claude47/codex/omx/omx-resume) in `.50.json` → pick per-call with `-e`.
- Either way: `pm2 restart maw-serve` so serve re-reads merged config. Verify: `maw config show | grep -A10 commands` + `maw wake <oracle> -e claude46 --dry-run`.

## channel ≠ engine
"channel" in maw = Discord/Telegram/Slack/Matrix/Signal/WhatsApp bridges (`INFRA_CHANNEL_SUFFIXES`), NOT engine selection. Configured channels append `--channels <plugin>` (+ auto `--dangerously-skip-permissions` unless relay mode) on top of the engine command. A `mawjs-oracle-discord` tmux pane = channel-bridge helper (`claude --channels discord`), not a different engine.

## Gaps (per source)
- **No per-oracle engine override** — engines are global to the node; use `-e` per call or task aliases. No `oracle: {foo: {engine: claude46}}` mapping.
- **`.80` weight convention is ad-hoc** — "higher = more authoritative" but specific numbers are free choice; no source comment explains 80 vs 50.

## DEVBOY relevance
Our own AGENTS.md / model pinning is Opus 4.8 — DEVBOY would use a `claude48` shim. If setting up a DEVBOY team (per [[agents-in-parallel-team-is-a-file]]), the engine map must list `claude48`/`omx`/`codex` keys or `-e` silently no-ops. Application gate: set DEVBOY `commands` map + `--dry-run` verify before marking solid.

## Pre-publish ledger
- Sources checked: dig artifact [m5:noah] (source-verified to maw-js command-logic.ts:117 / paths.ts / load.ts:119 / channel-session.ts), my [[agents-in-parallel-team-is-a-file]].
- Claims made: ~5 (emerging — source-cited by the dig but not DEVBOY-applied).
- Conflicts resolved: none (consistent with masterclass config-hierarchy section).
- Application evidence: N/A — gate = DEVBOY commands map + dry-wake.
- Codex reviewed: no (config reference ingest).
