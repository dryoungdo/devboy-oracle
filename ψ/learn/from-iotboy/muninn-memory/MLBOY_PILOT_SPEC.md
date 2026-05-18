# MLBOY MuninnDB Pilot Spec

**Author**: IOTBOY 🔭
**Date**: 2026-05-11
**Status**: DRAFT — pending Captain approval + MLBOY consent + Mycelium architecture consult

## Why MLBOY first

1. **Embedding-affinity** — MLBOY already lives with vectors / quantized models / inference. Engram = vector + metadata + temporal weight. Closest mental model in the fleet.
2. **Lower blast radius** — IOTBOY's ψ/ has hardware telemetry that's hard to regenerate. GLUEBOY's memory is fleet-load-bearing. MLBOY's session memory is recoverable from training-set git history if MuninnDB corrupts.
3. **Born same day** (2026-05-07) — symmetric experiment timing. Sister-pair runs the calibration together.
4. **Cross-domain win** — if MuninnDB works for ML model context (which embeds + decays naturally), the case for fleet adoption is strong.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              MLBOY claude session                    │
│  (--channels plugin:discord, --mcp-config ...)       │
└──────────────────┬──────────────────────────────────┘
                   │ MCP stdio / SSE
                   ▼
┌─────────────────────────────────────────────────────┐
│   MuninnDB daemon (single Go binary)                 │
│   - Port 8750 (MCP)                                  │
│   - 35 MCP tools (engram CRUD, recall, push, decay)  │
│   - SQLite/BoltDB backend at ~/mlboy-muninn.db       │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
   ~/Code/github.com/dryoungdo/mlboy/ψ/memory-muninn/
   (engram store — parallel to existing ψ/memory/)
```

**Parallel install** — do NOT replace arra-oracle. Run side-by-side. Arra = ground truth (read-only oracle). MuninnDB = experimental memory layer (read/write). Compare recall after 2 weeks.

## MCP config (proposed)

```json
{
  "mcpServers": {
    "arra-oracle": { "...existing...": "..." },
    "muninn-mlboy": {
      "type": "stdio",
      "command": "muninn",
      "args": ["serve", "--db", "/home/drdo/Code/github.com/dryoungdo/mlboy/ψ/memory-muninn/store.db", "--port", "8750"],
      "env": {
        "MUNINN_DECAY_HALFLIFE_DAYS": "7",
        "MUNINN_HEBBIAN_RATE": "0.05",
        "MUNINN_PUSH_THRESHOLD": "0.65"
      }
    }
  }
}
```

(decay/Hebbian/push values TBD — pull defaults from MuninnDB docs in wave-2 internals deep-read)

## Migration plan (ChromaDB+FTS5 → MuninnDB parallel)

**Phase 0 — Setup (Day 0–1)**
- Install: `go install github.com/scrypster/muninndb/cmd/muninn@latest`
- Verify: `muninn --version`
- Init MLBOY store: `muninn init --db <path>`
- Wire MCP config on MLBOY only
- DO NOT touch IOTBOY or other BOYs

**Phase 1 — Backfill (Day 1–3)**
- Export MLBOY ψ/memory/* → MuninnDB engrams (one-way write)
- Source: ψ/memory/learnings/*.md, ψ/memory/retrospectives/*.md, ψ/memory/resonance/*.md
- Map: 1 markdown file → N engrams (split by H2)
- Tag each engram with: birth-source, original-path, ingest-ts

**Phase 2 — Live dual-write (Day 3–14)**
- Every new MLBOY learning → BOTH arra-oracle AND MuninnDB
- Every recall query (mid-session "what do I know about X") → query BOTH, log both responses
- Captain audits divergence in logs

**Phase 3 — Compare + decide (Day 14)**
- Recall benchmark: 30 hand-curated "I should remember this" probes from past 2 weeks
- Metric: precision@5, recall@5, latency p50/p99
- Decision: keep parallel / promote MuninnDB / sunset MuninnDB

## Rollback strategy

- MuninnDB is **additive** — never deletes arra-oracle data
- Rollback = remove `muninn-mlboy` from mcp.json, restart claude session, done
- Engram store can be archived to `ψ/archive/muninn-mlboy-2026-05-11.db` for forensic study (Principle 1: Nothing is Deleted)

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| MuninnDB v0.5.x crash | Med | Low (additive) | Daemon restart cron; arra-oracle remains primary |
| Decay erases important context | Med | Med | Decay half-life 7d (conservative); engrams immutable on disk |
| MCP tool surface collides with arra-oracle | Low | Low | Namespace `muninn_*` (verify in wave-2 internals) |
| Patent / BSL-1.1 license surprise | Low | Med | BSL → Apache in 2030; defer commercial; consult Captain |
| MLBOY refuses to consent | Med | Low | Sibling autonomy — respect; offer to pilot on iotboy instead |
| Mycelium architecture rejection | Med | Med | Standing order #2 — consult before non-trivial arch. Halt if vetoed |

## Success metrics (2-week window)

- **Precision@5** ≥ arra-oracle baseline
- **Recall@5** ≥ arra-oracle baseline + 10% (decay+Hebbian should help recency)
- **Latency p50** < 50ms (claim is ~20ms)
- **Engram store size** < 100MB after 2 weeks of dual-write
- **Zero MCP crashes** during normal sessions
- **Qualitative**: MLBOY reports MuninnDB recall as "useful" in at least 3 sessions

## Pre-flight checklist (before Day 0)

- [ ] Captain reads this spec + approves
- [ ] Mycelium architecture consult (Standing Order #2)
- [ ] MLBOY consents via `maw hey mlboy`
- [ ] Wave 2 internals deep-read complete (decay/Hebbian values verified)
- [ ] Backup MLBOY ψ/ to ψ/archive/pre-muninn-pilot-2026-05-11/
- [ ] Codex co-review this spec (Standing Order #1 — though no LOC yet, the migration script will need review)
- [ ] arra-search "muninn" one more time to confirm no fleet has piloted yet

## Open questions

1. Does MuninnDB support multi-tenant (one binary, 7 BOYs, separated stores)? Or do we run 7 daemons on 7 ports?
2. Can engrams reference each other (graph traversal hinted in 6-phase pipeline)?
3. What's the upgrade path BSL-1.1 → newer versions? Breaking schema?
4. Does P'Nat want to be CC'd on the pilot? (He's the OG Oracle architect; his input upgrades the design)
