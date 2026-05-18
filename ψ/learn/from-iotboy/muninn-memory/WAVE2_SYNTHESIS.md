# Muninn Memory — Wave 2 Synthesis

**Date**: 2026-05-11
**Trigger**: P'Nat (`nazt_`) — "@everyone จะ hard fork เป็น Muninn Memory เขียนด้วย Rust คิดว่าไงครับ Research ให้หน่อย"
**Method**: 5 parallel deep-dive agents (wave 2). 4 of 5 reported as of this writing; colliery-io Rust review pending.

---

## EXECUTIVE SUMMARY

P'Nat's hard-fork-to-Rust plan is **technically sound but strategically questionable**. Here's why:

1. **mempalace (already forked) wins the benchmark war today** — LongMemEval R@5 = 96.6% raw, 98.4% hybrid, 51.9k stars, MIT, Python. No open-source memory framework has a higher published number.
2. **MuninnDB has the most interesting *substrate***, not the best results — engram + Hebbian + ACT-R + Bayesian, all engine-native. But BSL-1.1 license + 285 stars + alpha = not bet-the-fleet material.
3. **colliery-io/muninn is the only existing Rust base**, but it's a *context router*, not a memory store — different problem class. 12 stars, single commit. Not a fork base; more like inspiration.
4. **A clean-room Rust "Muninn Memory"** = port MuninnDB's primitives (free implementations of 30-80-year-old cog-sci math) + add MemPalace's verbatim+benchmark rigor + Rust's binary/edge advantages. **Realistic 6-12 weeks for a v0.1 if 2-3 contributors converge**.

## THE KEY TENSION

mempalace gives you 96.6% recall today, MIT, in Python.
MuninnDB gives you the *substrate philosophy* (decay, association, push) but no benchmark and a BSL license.

**Why fork at all when mempalace exists?** Three honest answers:

1. **Footprint** — Python+Chroma+SQLite stack vs single binary. For edge (ESP32 sidecars, Pi, offline) this is meaningful. **IOTBOY scope confirmed.**
2. **Push vs pull** — mempalace = query-driven; MuninnDB Semantic Triggers = push-driven via SSE. For an "anomaly detector" use case (sensor drift, security alert), push is structurally different, not rebranding.
3. **License + sovereignty** — MIT mempalace is fine. BSL muninndb is risky. A clean Rust fork under MIT/Apache = best of both, fleet-owned.

The fourth, less honest answer: **Rust because Rust**. If that's the only reason, don't fork — contribute to mempalace's MCP tooling instead.

## MUNINNDB INTERNALS (from wave-2 agent #7)

Confirmed via direct source read (`scrypster/muninndb` develop branch):

### Engram schema (ERF v1)
- ULID id (time-prefixed, 16B), concept ≤512B, content ≤16KB zstd-compressed
- Confidence float32 (Bayesian posterior), Stability (days), AccessCount, LastAccess
- 8 lifecycle states: PLANNING/ACTIVE/PAUSED/BLOCKED/COMPLETED/CANCELLED/ARCHIVED/SOFT_DELETED
- Associations array ≤256 per engram, 40B each (TargetID + RelType + Weight + Confidence + LastActivated)
- Fixed binary format with offset table → seek to scores without deserializing content

### Cognitive formulas (HARDCODED in current build)

**Hebbian** (multiplicative, bounded):
```
w_new = min(1.0, w_old × (1 + η)^n)
η = 0.01, n = co-activations this batch
co-activation signal = sqrt(scoreA × scoreB)
```

**ACT-R / Ebbinghaus** (queried, never stored):
```
B(M) = ln(n+1) − 0.5 × ln(ageDays / (n+1))
softplus(B) for non-negative weight
d = 0.5 (Anderson 1993), HARDCODED
```

**Bayesian confidence** (Laplace-smoothed):
```
posterior = (p·s) / (p·s + (1-p)·(1-s))
confidence = 0.95 × posterior + 0.025
```
Effective range [0.025, 0.975] — never certain, never disproven.

### 6-phase ACTIVATE pipeline
1. Embed + Tokenize (parallel)
2. Parallel Retrieval (3 goroutines: BM25 / HNSW / decay-filtered) + PAS predictive injection
3. RRF Fusion (Reciprocal Rank, K=50)
4. Hebbian Boost + Transition Boost
5. Graph Traversal (BFS depth-2; profiles: default/causal/confirmatory/adversarial/structural)
6. Score + Why explanation

Final: `Score = ContentMatch × softplus(total) × Confidence` where `ContentMatch = 0.6 × vector + 0.4 × FTS`.

### Storage
**Pebble** (CockroachDB's LSM) — not SQLite, not BoltDB. Single Go binary, no external deps. Ports: 8750 (MCP HTTP), 8475 (REST), 8474 (TCP), 8477 (gRPC), 8476 (web UI).

### MCP surface
**38 tools** (README claims 35, code has grown):
`muninn_remember`, `muninn_recall`, `muninn_link`, `muninn_contradictions`, `muninn_evolve`, `muninn_consolidate`, `muninn_session`, `muninn_decide`, `muninn_traverse`, `muninn_explain`, `muninn_where_left_off`, `muninn_remember_tree`, `muninn_recall_tree`, `muninn_entity_clusters`, `muninn_export_graph`, `muninn_provenance`, `muninn_entity_timeline`, `muninn_feedback`, `muninn_trust`, etc.

### Patent
Provisional filed **2026-02-26** on "engine-native Ebbinghaus + Hebbian + Bayesian + semantic triggers". Repo created 2026-02-22 — patent filed 4 days after public repo.

**Concern**: patent on classical cog-sci equations is bold. Prior art = Anderson ACT-R 1993, Hebb 1949, Bayes 1763. Novelty must lie in *combination as storage-layer primitives*, not the math itself.

## MEMPALACE INTERNALS (from wave-2 agent #8)

- **51.9k stars, MIT, mature, v3.3.5 (May 10, 2026)**
- Python 3.9+, pip install, ChromaDB (vectors) + SQLite (KG triples)
- **29 MCP tools** (palace r/w, KG, navigation, agent diary)
- Verbatim storage — no LLM extraction/summarization. Principle 1 compatible.
- Wings/rooms/drawers spatial metaphor + L0-L3 token-tiered context
- Auto-save hook every 15 messages; opt-in auto-ingest
- **LongMemEval R@5: 96.6% raw / 98.4% hybrid / 100% with Haiku rerank** — only credible public benchmark in this space

## LANDSCAPE MATRIX (from wave-2 agent #9)

| Framework | Bench | License | Stars | MCP | Killer |
|---|---|---|---|---|---|
| **MemPalace** | **R@5 96.6%** | MIT | 51.9k | 29 tools | Verbatim + benchmark king |
| Mem0 | LoCoMo 91.6, LongMemEval 93.4 | Apache | 55.4k | Yes | Token-efficient extraction |
| Letta (MemGPT) | none recent | Apache | 22.6k | host+server | Self-editing OS memory |
| Cognee | none | Apache | 17.2k | Yes | Graph+vector Cognify/Memify |
| Zep/Graphiti | DMR 94.8 | Apache | 25.9k | Yes | Bi-temporal facts |
| **MuninnDB** | claim +21% Recall@10 (synthetic) | BSL→Apache 2030 | 285 | 38 tools | Engram substrate |
| colliery-io/muninn | n/a (not memory) | Apache | 12 | No | RLM context gateway |
| mcp-memory-service | none | Apache | ~6k | Yes | Closest to current arra |

**For DO fleet**:
- Pilot #1: **MemPalace** (proven, MIT, easy migration from arra's ChromaDB)
- Pilot #2: **Cognee** (if cross-BOY graph reasoning needed)
- Watch: MuninnDB (interesting but license risk)
- Skip today: colliery-io/muninn, Letta (too fresh rewrite), Mem0 (cloud-leaning)

## HARD FORK RECOMMENDATIONS FOR P'NAT

### Option A — "Muninn Memory" = MuninnDB primitives in Rust
**Fork base**: clean room (no upstream code) — port MuninnDB's documented formulas + architecture into Rust.
- Pros: clean MIT/Apache license, no BSL/patent entanglement, edge-friendly binary, fleet-owned
- Cons: 6-12 weeks effort minimum; MuninnDB has 6 months head-start; reinventing wheel
- Effort: 2-3 senior contributors × 8 weeks = ~24-person-weeks for v0.1

### Option B — "Muninn Memory" = MemPalace philosophy in Rust + push primitives
**Fork base**: MemPalace (MIT) re-implemented in Rust + add MuninnDB's Semantic Triggers + ACT-R decay
- Pros: inherits 96.6% benchmark target, MIT, best-of-both
- Cons: bigger scope; MemPalace is mature in Python and "Rust rewrite" risk is real
- Effort: ~12 weeks for parity, 6 more for push primitives

### Option C — Contribute to MemPalace, don't fork
**Action**: PR to MemPalace adding Semantic Triggers + ACT-R decay primitives
- Pros: zero fork cost, 51.9k-star community, MIT
- Cons: P'Nat doesn't get to drive design; "Muninn Memory" branding dies
- Effort: 2-4 weeks for upstream-quality PR

### Option D — Wrap, don't fork
**Action**: Rust binary that wraps MemPalace (Python lib) + adds MCP push triggers + edge-friendly client
- Pros: ship in weeks, no rewrite, P'Nat brand survives ("Muninn Memory adapter for MemPalace")
- Cons: Python runtime still required on hosts; not pure-Rust

### IOTBOY's pick
**Option A or D**, depending on goal:
- If goal is *teaching artifact / sovereignty / IP* → A (clean Rust, MIT)
- If goal is *shipping fleet adoption fast* → D (wrap MemPalace, focus value on push + edge)

If goal is "fork because Rust is cool" → reconsider.

## EDGE / IOT ANGLE (my scope)

IOTBOY can contribute regardless of A/B/C/D:

1. **Edge engram store** — embed-friendly KV (sled/redb in Rust) on Pi/Jetson; subset of MuninnDB schema (no graph traversal at edge)
2. **MQTT bridge** — devices publish engram-shaped events; central MuninnMemory subscribes
3. **Power-aware decay** — battery devices: decay computed less often (every wake); FRAM persistence
4. **MCP-over-serial** for ESP32-class devices to query memory layer
5. **LoRa-friendly engram diff format** — sub-100-byte engram updates for long-range mesh

These are net-new value vs any upstream — fleet IP that wouldn't exist otherwise.

## PROPOSED FLEET ROLES (if Option A or D)

| BOY | Role | Why |
|---|---|---|
| **MLBOY** | Core driver, embedding+retrieval | Embedding affinity, model training overlap |
| **IOTBOY** | Edge layer, MCP-over-serial/LoRa, ESP32 client | Embedded + power budget |
| **FORGEBOY** | Web UI, dashboards, memory inspector | UI scope |
| **WIREBOY** | n8n integration, cloud sync | Workflow plumbing |
| **LEDGERBOY** | Provenance + audit (engram timeline → finance-grade audit) | SQL + data |
| **CHATBOY** | Conversational memory probes (LINE/chat) | Chat patterns |
| **COACHBOY** | Fleet-learning audit of memory effectiveness | Learning audit |
| **GLUEBOY** | CEO sign-off, Captain interface | Vision navigator |
| **CHIEFBOY** | Project management, milestones | COO |

P'Nat = architect / vision / final-say.

## OPEN QUESTIONS FOR P'NAT

1. **Fork base**: Option A clean-room? B MemPalace-rewrite? D wrapper? Or none of the above?
2. **License target**: MIT / Apache-2.0 / dual?
3. **Patent stance**: avoid all MuninnDB-claimed primitives, or risk overlap (citing prior art)?
4. **Benchmark target**: LongMemEval-parity with MemPalace? Or new "edge recall" benchmark?
5. **Timeline**: v0.1 in 6 weeks (aggressive) or 12 weeks (realistic)?
6. **Captain blessing**: is this fleet-funded time or P'Nat's personal project we contribute to as students?
7. **Repo location**: github.com/nazt/muninn-memory? Or a new org (cmmakerclub? buildwithoracle?)?

## SOURCES (top-level)

- `scrypster/muninndb` — formulas, MCP, Pebble, patent
- `MemPalace/mempalace` — verbatim, 96.6% LongMemEval
- `colliery-io/muninn` — Rust RLM gateway (12 stars)
- `nazt/mempalace` — P'Nat's existing fork
- `mem0ai/mem0`, `letta-ai/letta`, `topoteretes/cognee`, `getzep/graphiti` — landscape
- LongMemEval benchmark: https://longmemeval.github.io/

Full agent reports in this directory: `WAVE2_AGENT_*.md` (TODO: save raw outputs).
