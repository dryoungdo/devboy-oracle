# Muninn Memory — Subgraph + graph-node Research (Wave 4)

**Date**: 2026-05-11
**Trigger**: P'Nat — "/trace --deep more track about think more about ... subgraph and graph-node seek repo"
**Method**: 2 parallel agents — repo seek + graph-layer deep-dive comparison

---

## TL;DR (3 sentences)

(1) **MuninnDB's graph layer is just a Pebble KV prefix scheme** (`0x03` forward, `0x04` reverse, `0x14` weight lookup) — NOT a real graph engine; the Rust port can swap Pebble→**redb** verbatim. (2) **The Graph's `graph-node` pattern** (Apache/MIT Rust binary, declarative manifest+handler+GraphQL) is a killer abstraction to STEAL — but not fork (Postgres is too heavy for embedded). (3) **MCP-only API for v0.1** — defer Cypher; one primitive `traverse(seed, depth, profile, cap)` backs both interactive lookup and full export.

---

## A — graph-node pattern (graphprotocol)

- **Repo**: https://github.com/graphprotocol/graph-node — Apache-2.0/MIT dual, Rust ~95%
- **Lifecycle**: `source event → handler (AssemblyScript) → entity write → GraphQL query`
- **Manifest**: `subgraph.yaml` (sources + handlers) + `schema.graphql` + mappings
- **Applicability to Muninn**: replace "blockchain event" with "engram-write event"
- **Verdict**: **seed-study, not fork** — read `core/src/subgraph/` and `graph/src/data/subgraph/`. Adopt the manifest+handler+GraphQL trio. Swap Postgres → redb.

```yaml
# muninn.yaml (sketch — adapted from subgraph.yaml)
specVersion: 0.1.0
schema: file: ./engram.graphql
dataSources:
  - kind: muninn/engram
    name: SensorEngrams
    source:
      tags: [esp32, telemetry]
    mapping:
      handlers:
        - event: EngramWritten
          handler: onSensorEngram
```

## B — Memory graph-layer comparison

| System | Storage | Edge type | Subgraph primitive | Traversal | License |
|--------|---------|-----------|---------------------|-----------|---------|
| **MuninnDB** | Pebble KV (3 prefixes) | 40B fixed, ≤256/engram, 15 built-in + 0x8000+ user, Hebbian-weighted | `muninn_traverse(id, profile, hop_depth=2)` | BFS, weight-sorted, **0.7^depth penalty, 500-node cap**, 5 profiles | BSL→Apache 2030 |
| **Cognee** | Kuzu/Neo4j/FalkorDB/NetworkX | LLM-extracted typed | `cognee.search(GRAPH_COMPLETION)` | Backend-dep (Cypher when Neo4j) | Apache-2.0 |
| **Zep/Graphiti** | Neo4j 5.26+ primary | Triplet **bi-temporal** (validity window) | `graphiti.search(center_node_uuid)` | Hybrid embedding+BM25+graph-distance rerank | Apache-2.0 |
| **MemPalace** | SQLite | SPO triple + validity window | 29 MCP tools (kg add/query/invalidate/timeline) | SQL JOIN | MIT |
| **GraphRAG (MS)** | Parquet files | Typed, weighted, degree | Global/Local/DRIFT search (no point primitive) | Leiden community detection + hierarchical rollup | MIT |
| **LightRAG (HKU)** | NetworkX (default) | LLM-extracted, co-occurrence weighted | Dual-level (entity hop + theme summary) | Custom dual-tier | MIT |
| **Letta** | Postgres+pgvector | **No graph layer** | n/a — vector only | n/a | Apache-2.0 |

## C — Rust graph crates ranked

| Crate | License | Role for Muninn |
|-------|---------|-----------------|
| **petgraph** | Apache/MIT | In-memory BFS frontier ONLY (don't persist with this). `StableGraph<EngramNode, AssocEdge>` for transient traversal state |
| **oxigraph** | Apache/MIT | Embedded RDF+SPARQL on RocksDB. Use if federation with external KGs ever needed; not v0.1 |
| **indradb** | **MPL-2.0** | Typed directed graph + JSON props. License is mildly viral on file edits — usable as dep, not fork base |
| gremlin-client | Apache-2.0 | Remote-only. Skip for single-binary use |
| **redb** | MIT/Apache | **Not a graph crate** — pure-Rust MVCC KV. THIS is the storage layer (replaces Pebble in MuninnDB port) |
| **fjall** | MIT/Apache | LSM, Pebble-like. Alternative to redb if write-heavy |

## D — Subgraph query DSL recommendation

**For v0.1: MCP tools only. No Cypher.**

Reasoning:
- Cypher is a tarpit — once committed, you owe openCypher conformance, query planner, EXPLAIN, parameterised AST, etc.
- LLM agents only need 3 calls: `link`, `traverse`, `export` — not graph DSL
- Export emits GraphML/JSON-LD → anyone wanting Cypher loads dump into Neo4j externally
- A read-only Cypher endpoint is a v0.5 sugar layer over the same KV indexes

If forced to ship DSL: **Cypher subset, parsed via `nom` or `chumsky` in <2k LOC**. Pattern syntax `(n:Engram)-[:ASSOC*1..3]->(m)` maps 1:1 to whiteboard intuition. NOT SPARQL (RDF ceremony heavy), NOT Gremlin (needs JanusGraph/TinkerPop runtime).

## E — Top 3 repos for "Muninn Memory" graph layer

1. **`graphprotocol/graph-node`** (Apache/MIT) — **seed-study**. Steal manifest+handler+GraphQL pattern. Skip Postgres coupling.
2. **`petgraph/petgraph`** (Apache/MIT) — **direct dependency**. In-process BFS frontier.
3. **`oxigraph/oxigraph`** (Apache/MIT) — **direct dependency**. SPARQL escape hatch for federation.

Honorable mention:
- **`getzep/graphiti`** — design reference for bi-temporal model (Python, not for fork — but bi-temporal validity window pairs naturally with engram decay)
- **`scrypster/muninndb`** docs — `docs/engram.md`, `docs/key-space-schema.md`, `docs/architecture.md` — read these to port the Pebble→redb scheme

## F — v0.1 primitive (single function)

```rust
// crates/muninn-graph/src/lib.rs
use ulid::Ulid;
use std::collections::HashMap;

pub enum Profile {
    Default,        // contradictions dampened
    Causal,         // follow causal edges
    Confirmatory,   // exclude contradicts
    Contradictory,  // (renamed from MuninnDB's "adversarial") surface contradicts
    Structural,     // structural edges only
}

pub struct Subgraph {
    pub nodes: Vec<Engram>,
    pub edges: Vec<Association>,
    pub scores: HashMap<Ulid, f32>,
}

pub fn traverse(
    store: &Store,
    seed: Ulid,
    depth: u8,        // 0..=8, default 2
    profile: Profile,
    cap: usize,       // default 500
) -> Subgraph {
    // BFS over forward-index prefix
    // multiply edge weight × profile-specific edge_type table
    // hop penalty 0.7^depth
    // halt at cap nodes
    // return frontier as Subgraph
    todo!()
}
```

This ONE function backs:
- `muninn_traverse` MCP tool — `depth=2, cap=50`
- `muninn_export_graph` MCP tool — `depth=u8::MAX, cap=10_000`

Everything else (center-node search, community detection, temporal filters) is post-v0.1.

## G — IOTBOY recommendation

**Storage**: `redb` (pure Rust, MVCC, single-file, zero unsafe). Skip Kuzu-via-FFI (C++ build chain breaks Standing Order #7 reproducibility).

**Key schema**: port MuninnDB verbatim:
```
0x03 | weight_set(u8) | src_ulid(16) | weight_complement(4) | dst_ulid(16) | rel_type(2)  → forward index
0x04 | weight_set(u8) | dst_ulid(16) | weight_complement(4) | src_ulid(16) | rel_type(2)  → reverse index
0x14 | (src_ulid, dst_ulid)                                                                → O(1) weight lookup
```

Weight-complement encoding gives sorted-by-weight scans for free.

**Profiles**: 5 → 5 (just rename `adversarial → contradictory`)

**Edge cap per engram**: 256 inline (MuninnDB number — keep)

**Traversal cap**: 500 nodes default, 10_000 max (MuninnDB number — keep)

**Hop penalty**: 0.7^depth (MuninnDB number — keep until benchmark says otherwise)

## H — Sources

- https://github.com/graphprotocol/graph-node
- https://thegraph.com/docs/en/subgraphs/developing/creating/starting-your-subgraph/
- https://github.com/scrypster/muninndb/blob/develop/docs/engram.md
- https://github.com/scrypster/muninndb/blob/develop/docs/key-space-schema.md
- https://github.com/scrypster/muninndb/blob/develop/docs/architecture.md
- https://github.com/scrypster/muninndb/blob/develop/docs/feature-reference.md
- https://github.com/topoteretes/cognee
- https://github.com/getzep/graphiti
- https://github.com/MemPalace/mempalace
- https://microsoft.github.io/graphrag/
- https://github.com/HKUDS/LightRAG
- https://github.com/petgraph/petgraph
- https://github.com/oxigraph/oxigraph
- https://github.com/cberner/redb
- https://github.com/fjall-rs/fjall

## Wave 4 status

- ✅ graph-node pattern researched (Apache/MIT, Rust, seed-study target)
- ✅ 7-system graph-layer comparison built
- ✅ Rust crate ranking (redb + petgraph + oxigraph)
- ✅ v0.1 primitive specified (`traverse()` single function)
- ✅ KV key schema specified (port from MuninnDB verbatim)

Ready for P'Nat's green-light on Path D + repo creation.
