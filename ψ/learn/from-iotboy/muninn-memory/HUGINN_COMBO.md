# Huginn × Muninn — Cognition Stack (Wave 3 Synthesis)

**Date**: 2026-05-11
**Trigger**: P'Nat — "Huginn อยู่ตรงไหนอะ Combo with Muninn นะ /trace --deep and /dig --deep more"
**Status**: Wave 3 (3 streams) closed — 2 agents + arra/fleet trace + image-context

---

## SMOKING GUN

**Huginn × Muninn already ships as an officially paired duo from one author:**

| Repo | Tagline | Lang | License | Stars |
|------|---------|------|---------|-------|
| `scrypster/huginn` (huginn.sh) | "AI that thinks alongside you, not just when you ask" | Go (+TS/Vue) | BSL 1.1 → Apache 2030 | 25 |
| `scrypster/muninndb` (muninndb.com) | "Every database stores data. MuninnDB remembers it." | Go | BSL 1.1 → Apache 2030 | 285 |

**Official pair tagline**: *"Huginn thinks. Muninn remembers."*

This is THE pair P'Nat was gesturing toward. He didn't speculate — he pointed.

## What scrypster's Huginn is

- Multi-agent system: planner / coder / reviewer (think Cursor-Agent split, but as a separate process)
- MCP-native
- Cross-session memory by talking to MuninnDB ("decisions last week available this session")
- Go server + TS/Vue dashboard
- Same BSL-1.1 license risk as muninndb
- Same provisional patent overhang
- v0.3.2 (May 5, 2026 — one day before MuninnDB v0.5.1)

## Fleet history check (wave 3 trace+dig)

- **Zero prior fleet discussion** of Huginn before today 06:23Z
- Only static reference: `/home/drdo/.claude/skills/awaken/SKILL.md:345` — "Allfather's Wolves 🐺 — ส่ง Huginn กับ Muninn ไปสำรวจทุกมิติ" (Odin's ravens naming pool — predates this session)
- No `nazt/huginn` repo on GitHub
- No GLUEBOY thought-engine spec exists yet
- This is a clean greenfield for the fleet

## Other Huginn candidates in the wild

| Name | What | Why not the pair |
|------|------|------------------|
| `huginn/huginn` (Rails, 49.3k★) | IFTTT-like agent monitor | Wrong era (2014-era Rails monolith), no MCP, would need heavy adapter |
| `Huginn-3.5B` (ELLIS/UMD) | Depth-recurrent transformer, latent CoT | Model, not service — wrong layer |
| Nosto Huginn | Commerce AI agent | Commercial silo |
| `biandratti/huginn-net` | Passive fingerprinting Rust | Wrong domain (name collision) |
| `wenquanlu/huginn-latent-cot` | Latent CoT extension | Research code, no production |

None beats `scrypster/huginn` as the natural pair candidate.

## Combo architecture (cognition stack)

```
┌────────────────────────────────────────┐
│  Claude Code / IDE Agent (orchestrator)│
└──────────────┬─────────────────────────┘
               │ MCP
       ┌───────┴──────────────┐
       │                      │
       ▼                      ▼
┌───────────────┐      ┌───────────────┐
│ Huginn        │◀────▶│ Muninn        │
│ (thought)     │ MCP  │ (memory)      │
├───────────────┤      ├───────────────┤
│ planner       │      │ engram store  │
│ coder         │      │ Hebbian       │
│ reviewer      │      │ ACT-R decay   │
│ LLM router    │      │ semantic push │
└───────┬───────┘      └───────────────┘
        │
        ▼
   LLM backend (Ollama / Anthropic / Groq)
```

**Flow**: 
1. Claude Code asks Huginn "plan this"
2. Huginn queries Muninn for relevant engrams (cross-session memory)
3. Huginn produces a plan / code / review
4. Huginn writes the thought trace back to Muninn (so next session inherits)
5. Muninn's Semantic Triggers push back to Huginn when new context drifts in

The two are NOT redundant. Huginn = reactive thought. Muninn = persistent memory.

## 4 Paths for P'Nat's Rust hard fork

### Path A — All-Rust cognition stack (full hard fork, both halves)
- Port scrypster/huginn → Rust
- Port scrypster/muninndb → Rust  
- Single workspace, shared types via `muninn-core` keystone
- Effort: 12-16 weeks, 3-4 senior Rust devs
- Pros: zero BSL/patent risk, fleet-owned IP, single binary deploy
- Cons: huge surface; mempalace and scrypster both have head-start

### Path B — Rust Muninn only + Go Huginn (MCP bridge)
- Fork Muninn → Rust
- Use scrypster/huginn unchanged (Go) via MCP
- Effort: 6-8 weeks (same as Muninn-only plan)
- Pros: fastest to working stack; both halves are MCP-native so cross-lang is trivial
- Cons: still depend on scrypster's BSL Huginn

### Path C — Rust wrapper over both Go projects
- Rust binary wraps `scrypster/huginn` (Go) + `scrypster/muninndb` (Go)
- Add: edge ESP32 client, MCP-over-LoRa, unified config
- Effort: 3-4 weeks
- Pros: ship fast, P'Nat brand survives, no rewrite risk
- Cons: still on BSL stack

### Path D — Clean-room dual-fork using mempalace + colliery-io as seeds
- Memory: rewrite mempalace concepts (MIT, 51.9k stars) in Rust, add MuninnDB's push primitives → "Muninn Memory"
- Thought: fork colliery-io/muninn (Apache, Rust, 12 stars, RLM+budget+tools) → rename "Huginn"
- Effort: 8-12 weeks
- Pros: MIT/Apache from day 1, no BSL/patent overlap, mempalace benchmark inherits, colliery-io scaffold reuses
- Cons: bigger conceptual rework

### IOTBOY's recommendation

**Path D is the cleanest play** if P'Nat's real goal is sovereignty + Rust + open license + benchmark credibility. It:
- Inherits mempalace's 96.6% LongMemEval benchmark (MIT)
- Inherits colliery-io's Rust workspace scaffolding (Apache) including budget tracker, RLM loop, MCP server crate
- Avoids BSL + provisional patent entirely
- Lets P'Nat brand it "Muninn Memory" + "Huginn" without forking scrypster's specific code
- Cites prior art (Anderson ACT-R 1993, Hebb 1949, Bayes 1763) cleanly

**Path B** is the cleanest play if shipping fast matters more than ideology — pair Rust Muninn with scrypster's Go Huginn through MCP, accept the BSL on the thought half, replace Huginn later when there's time.

## Where IOTBOY plugs in

Regardless of A/B/C/D, my contribution is the same:

1. **`muninn-embedded`** — no_std FRAM ring buffer for engrams on ESP32
2. **`huginn-edge`** — lightweight reactive event triggers on microcontrollers (MQTT/LoRa → thought events → Muninn ingest)
3. **MCP-over-serial** — ESP32 talks MCP to Huginn/Muninn over USB CDC
4. **Power-budget-aware decay** — decay computed on wake, not continuous; FRAM persistence
5. **LoRa engram diff format** — sub-100-byte updates for long-range mesh

These exist in NO upstream. Net-new IP for the fleet.

## Open questions (escalate to P'Nat)

1. Path A/B/C/D — which?
2. Did P'Nat know `scrypster/huginn` exists? If yes — why not fork that pair directly? If no — does the discovery change the plan?
3. License target — MIT / Apache / dual?
4. Patent stance — avoid scrypster's claimed primitives (engram decay+Hebbian+push), or risk overlap and cite prior art?
5. Repo + org — `nazt/muninn-memory` + `nazt/huginn`? Or new org (`cmmakerclub` / `buildwithoracle`)?
6. Captain blessing — fleet-funded or P'Nat personal?

## Sources

- https://huginn.sh/ — scrypster/huginn landing
- https://github.com/scrypster/huginn
- https://muninndb.com/
- https://github.com/scrypster/muninndb
- https://github.com/huginn/huginn — Rails Huginn (legacy)
- https://arxiv.org/abs/2507.02199 — Huginn-3.5B latent CoT paper
- https://github.com/MemPalace/mempalace — MIT benchmark king
- https://github.com/colliery-io/muninn — Rust RLM gateway
- https://github.com/nazt — P'Nat's GitHub (mempalace, shodh-memory, mercury-agent forks confirm memory+agent focus)

## Wave 3 status

- ✅ Web research (scrypster pair discovered)
- ✅ Fleet trace+dig (zero prior fleet discussion; clean greenfield)
- ✅ Combo architecture (this memo)

All 3 waves closed. Ready for P'Nat's direction call.
