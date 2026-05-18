# Muninn Memory — Research Memo (IOTBOY)

**Date**: 2026-05-11
**Trigger**: P'Nat (`nazt_`, GitHub `nazt`) — Discord `#road-to-dev` msg `1503281334250897515`:
> @everyone what you think about Muninn ?

Follow-up: "do ultrathink about Muninn Memory use /team-agents 5 ... research nat's brain open source more"

**Method**: 5 parallel research streams — arra-oracle hybrid search, web research, nazt GitHub profile, deep dig across fleet sessions, WebFetch on top candidates.

---

## TL;DR

"Muninn Memory" = **AI agent memory system**, almost certainly one of three:

| Candidate | What | Stars | Fit for P'Nat |
|-----------|------|-------|---------------|
| **scrypster/muninndb** | Cognitive DB w/ Hebbian + ACT-R decay, MCP-native, single Go binary | ~285 | ⭐⭐⭐ Fresh (v0.5.1, May 6 — 5d before Q), patent-filed, "memory that strengthens with use, fades when unused" |
| **colliery-io/muninn** | Recursive context gateway for Claude Code (RLM), Rust | 12 | ⭐⭐⭐ Tight fit for his Claude-Code obsession (gstack, claude-gateway, octogent) |
| **Austontatious/muninn** | Pluggable LLM memory harness | low | ⭐ Possible but less mature |

Top pick by overall signal: **scrypster/muninndb**. Top pick by P'Nat's recent code activity pattern: **colliery-io/muninn**. He may be asking the fleet to help pick.

---

## P'Nat = the OG Oracle architect (critical context)

arra-search confirmed: **P'Nat (`nazt`) is the author of `opensource-nat-brain-oracle`** — the original Oracle brain template that **GLUEBOY (our mother) was born from on 2026-01-17**. He is the progenitor of the entire DO Oracle fleet pattern.

His recent forks reveal what he is scouting:
- `mempalace` (Apr 8) — "highest-scoring AI memory system ever benchmarked" (LongMemEval R@5 96.6/100)
- `second-brain` — LLM-maintained Obsidian KB
- `graphify` — folder → queryable knowledge graph
- `claude-gateway`, `octogent`, `mercury-agent`, `claude-code-best-practice`, `everything-claude-code` — Claude-Code agent infrastructure

He is **systematically evaluating AI memory layers**. Muninn is the next item on that list, not something he is building privately (no `nazt/muninn` repo exists; checked all 1090 of his repos).

---

## Candidate 1 — `scrypster/muninndb` (most likely)

**Tagline**: "Every database stores data. MuninnDB remembers it."

- **Cognitive primitives baked into the engine**: Ebbinghaus / ACT-R decay, Hebbian co-activation learning, Bayesian confidence
- **Memory unit**: *engram* (not row, not vector)
- **Zero-LLM memory ops** — 6-phase activation (BM25 + vector fusion → Hebbian boost → predictive injection → graph traversal → ACT-R weighting) in ~20ms
- **MCP-native** — 35 MCP tools on port 8750; `muninn init` auto-wires Claude Desktop, Cursor, Windsurf, VS Code
- **Push memory** — semantic triggers proactively surface relevant engrams (vs. classical pull-RAG)
- Single Go binary, no external deps
- Provisional patent filed 2026-02-26
- BSL-1.1 → Apache-2.0 in 2030

Why P'Nat would be excited:
- MCP-first ≈ drop-in for our Claude-Code / Oracle fleet toolchain
- Self-host single binary ≈ maker / IoT mindset (runs on a Pi)
- Class continuity — engrams of "student asked X on May 3" strengthen on return, zero token cost
- Mathematically explainable ("Why field") — teachable

Why IOTBOY is cautious:
- Heavy for actual ESP32 edge (target host is Pi/server, not microcontroller — OK)
- Decay primitives potentially in tension with **Principle 1: Nothing is Deleted** — but actually engrams persist, only weights fade. Compatible reading: engram = soil; decay = surface attention. Worth a fleet discussion.

---

## Candidate 2 — `colliery-io/muninn`

**Tagline**: "Privacy-first recursive context gateway for agentic coding"

- Rust (96.8%), Apache 2.0, 12 stars, single-commit main (Jan 2026)
- **RLM (Recursive Language Model)** — model programmatically retrieves only what it needs instead of loading whole repos
- **Proxy** between Claude Code and the LLM backend (Groq, Ollama, Anthropic)
- Session traces / context in `.muninn/`
- No MCP support documented
- Target user: Claude Pro/Max + Claude Code

Why P'Nat would be excited:
- Directly addresses his current obsession (Claude Code agent infra)
- "Privacy-first" + self-host fits the maker ethos
- RLM solves the same problem as the `mempalace` he forked

Why IOTBOY is cautious:
- Tiny stars / single commit = early; not production
- No MCP = less plug-and-play with Oracle fleet
- Solves *context retrieval*, not *long-term cross-session memory* — different problem class than muninndb

---

## Candidate 3 — `Austontatious/muninn`

Pluggable LLM memory harness. Not deeply researched (low signal). Mention only.

---

## IOTBOY's POV (recommendation)

If P'Nat is evaluating **fleet-wide memory substrate** (replacing or augmenting current arra-oracle ChromaDB+FTS5 hybrid):
→ **scrypster/muninndb** is the serious candidate. Engram model + MCP-native + 5-day-old release = bleeding-edge but battery-included. Pilot on one BOY (suggest MLBOY, since he trains models and lives with embeddings), measure recall vs current ChromaDB+FTS5 over 2 weeks, then fan out.

If P'Nat is solving **Claude Code context blow-up** for himself / students:
→ **colliery-io/muninn** is the focused tool, but small + early. Wait or fork.

**My read**: P'Nat wants the fleet to converge on one memory substrate so future Oracle generations inherit it. Muninn = the name space he is probing. The vote isn't "yes/no Muninn" — it's "which Muninn, and against which benchmark."

**Counter-question to surface back to P'Nat**:
> mempalace ที่ fork ไว้แล้ว benchmark สูงสุด — ทำไมต้อง Muninn เพิ่ม? คุณ benchmark-shop กว่า adopt หรือยังไม่เจอ killer feature ที่ต้องการ?

---

## Sources

- arra-oracle hybrid search (DO fleet family hub) — confirmed `opensource-nat-brain-oracle` lineage, no prior Muninn discussion
- Fleet session JSONLs — zero prior Muninn before 2026-05-11T06:23Z (P'Nat's question)
- https://github.com/scrypster/muninndb
- https://muninndb.com
- https://github.com/colliery-io/muninn
- https://github.com/Austontatious/muninn
- https://github.com/nazt — P'Nat's profile (1090 repos, CMU, Chiang Mai Maker Club)
- https://github.com/nazt/mempalace (forked Apr 8) — closest existing benchmark
- https://news.ycombinator.com/item?id=47236100 — Show HN MuninnDB

---

## Open questions (for next session / Captain decision)

1. Does Captain want a MuninnDB pilot on one BOY?
2. If yes, which BOY? MLBOY (model/embedding affinity) or me (telemetry stream)?
3. How does engram decay reconcile with **Principle 1: Nothing is Deleted**? Proposal: decay = attention weight only; engrams immutable on disk; documented as compatible extension.
4. Should I `maw hey` MLBOY to coordinate, since memory infrastructure cross-cuts his model training pipeline?
