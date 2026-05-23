# devboy-oracle-articles-006 — Learning Hub

## Source
- **Article 006**: https://dryoungdo.github.io/devboy-oracle/articles/006-discord-config.html (Discord Config & ความซื่อสัตย์)
- **Article 041**: https://dryoungdo.github.io/devboy-oracle/articles/041-discord-plugin-wiring.html (Discord Plugin Wiring Guide)
- **Local**: `docs/articles/006-discord-config.html` + `docs/articles/041-discord-plugin-wiring.html`

## Explorations

### 2026-05-23 1510 (--deep, 5 agents)

Sources:
- [[2026-05-23/source_article-006|Article 006 (verbatim, 3.4K)]]
- [[2026-05-23/source_article-041|Article 041 (verbatim, 14.1K)]]

Extracted dimensions:
- [[2026-05-23/1510_ARCHITECTURE|Architecture]] — gate() flow, file layout, decoupled plugin-loader↔MCP layers
- [[2026-05-23/1510_CODE-SNIPPETS|Code Snippets]] — setup commands, templates, diagnostic one-liner, live extensions
- [[2026-05-23/1510_QUICK-REFERENCE|Quick Reference]] — 8-step checklist, dmPolicy table, troubleshooting matrix, incident timeline
- [[2026-05-23/1510_TESTING|Testing]] — 3-layer verification (canonical flowchart + process probes + proposed gate_hook for start.sh)
- [[2026-05-23/1510_API-SURFACE|API Surface]] — access.json schema, MCP tool surface, Voice Protocol B gates

**Key insights**:
1. **Article 041 documents the gate() flow + setup + 6 common mistakes** but is silent about the "listener alive, MCP child not spawned" failure mode the 2026-05-23 incident exposed.
2. **`--channels` flag is necessary but not sufficient** — the flag is parsed, listener starts, but the MCP spawn handoff can still silently fail. Process inspection (`pstree` + `ss`) is the only diagnostic.
3. **Voice Protocol B is hard-gated at access.json** — only `allowFrom` user IDs can command; access.json itself is terminal-edit-only (anti-prompt-injection design proven in DEVBOY↔GLUEBOY 2026-05-21 case study).

## Cross-references

- Trace: `ψ/memory/traces/2026-05-23/1418_devboy-discord-pair-disconnect-mcp-not-spawning.md`
- Retro: `ψ/memory/retrospectives/2026-05/23/14.26_devboy-discord-pair-disconnect-trace-5agent.md`
- Learning: `ψ/memory/learnings/2026-05-23_channel-flag-skips-mcp-spawn-silent-failure.md`
- Prior: `ψ/memory/learnings/2026-05-21_discord-plugin-wiring-guide-article-041-complet.md`
- Prior: `ψ/memory/learnings/2026-05-21_discord-plugin-dmpolicy-disabled-is-a-whole-bot.md`
