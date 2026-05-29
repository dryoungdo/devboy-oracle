---
type: learning
topic: Claude Code --channels @-notation only accepts official/installed plugin registries
source: experiment
maturity: solid
retrieval_terms: [claude-code-plugins, channels-flag, plugin-registry, discord-mcp, multi-oracle]
date: 2026-05-27
gate_hook: "start.sh fallback to patch_shared_plugin_env when custom registry fails"
---

# Claude Code Plugin Registry — Official Only

## Verified Behavior

`--channels plugin:<name>@<registry>` — the `<registry>` part MUST be an installed/official plugin registry name (e.g., `claude-plugins-official`). Custom directory names created manually under `~/.claude/plugins/cache/` are rejected.

**Error observed**: `plugin not installed` + `not on the approved channels allowlist`

## What Was Tested

Created directory `~/.claude/plugins/cache/discord-officeboy/discord/0.0.4/` with full plugin copy + patched `.mcp.json`. Used `--channels plugin:discord@discord-officeboy`.

Claude started but with warnings:
- `plugin:discord@discord-officeboy · plugin not installed`
- `plugin:discord@discord-officeboy · not on the approved channels allowlist`

The plugin's MCP server did NOT start from the custom registry. Claude fell back to the installed plugin from `claude-plugins-official` (using DEVBOY's state dir instead of OFFICEBOY's).

## Implication for Multi-Oracle

Per-oracle plugin isolation via custom registries is NOT possible. Must use "last to start wins" approach: patch shared `.mcp.json` at startup, use standard `@claude-plugins-official`. Safe because MCP children inherit env at spawn time.

## Pre-publish ledger

- Sources checked: live boot test on DO clinic-drdo, Claude Code v2.1.150
- Claims made: 1 (solid — directly observed)
- Conflicts resolved: none
- Application evidence: officeboy-oracle boot 2026-05-26 21:10, PID 1412727
- Codex reviewed: no
