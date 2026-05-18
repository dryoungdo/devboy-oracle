# /learn — LarisLabs/floodboy-astro (Web3 IoT Oracle)

**Source**: github.com/LarisLabs/floodboy-astro (cloned via gq)
**Date**: 2026-05-11 17:50 GMT+7
**Class trigger**: P'Nat msg `1503347217879269427` — "gq allthis ... it's about blockchain and web3" + `1503347261957210193` — "/learn --deep"
**MLBOY scope note**: outside ML domain; class assignment for outside-fleet breadth (Captain "ดูคนที่ไม่ได้อยู่ fleet เราสิ" `1503336437863551140`)

## What FLOODBOY does (1 line)

Astro-based IoT flood-monitoring system that bridges sensor networks to EVM blockchains for tamper-evident sensor data storage + dashboard.

## Tech stack

```
Framework:    Astro 5.11 + React 18 + Tailwind 4 + Cloudflare Workers
Web3 client:  Viem 2.31.7 (NOT ethers.js — modern viem pattern)
State:        Nanostores (atom + map)
Viz:          Chart.js + p5.js
Contracts:    CatLabSensorStoreFactory, CatLabSecureSensorStore (ABIs in /abis)
Chains:       JIBCHAIN L1 (id 8899) · SiChang (700011) · Anvil (31337 local)
```

## Patterns worth stealing

### 1. Resilient RPC routing (`src/utils/rpc.ts`)

Production-grade fault tolerance for Web3 Oracle work:
- Health-check all RPC URLs in parallel, rank by latency
- Cache ranking for 5 min
- Viem `fallback()` transport with 2× retry, 4s timeout
- Automatic failover when an endpoint dies

This pattern is **directly translatable to ML model-serving** — multi-region inference endpoints ranked by latency, fallback to healthy ones, 5-min cache to avoid hammering health checks.

### 2. Three view modes (`ViewModeTabs`)

- `public` — direct contract reads, no wallet needed
- `wallet` — MetaMask connection, signed reads
- `direct` — factory reads (skipping store contract)

**Translates to ML**: same data, multiple trust modes (public anonymized stats / user-authenticated personal / admin raw).

### 3. Inline ABIs + JSON ABIs hybrid

Small/stable ABIs inlined in `blockchain-constants.ts`; full factory/store ABIs as JSON files in `/abis`. Trade: type-safety inline vs maintenance scale external.

## Web3-specific lessons (not in MLBOY's daily scope)

- **Multicall3 universal address**: `0xcA11bde05977b3631...` — batched reads on most EVM chains. Pattern: don't issue N reads, issue 1 multicall.
- **viem > ethers.js for new projects**: type-safety, smaller bundle, tree-shake-friendly. ethers.js v6 still common in legacy.
- **JIBCHAIN L1** is a Thai EVM chain (id 8899) — useful context for fleet (Captain works in TH, IoT data may go on-chain).

## What MLBOY can borrow

1. **Resilient endpoint routing for inference** — copy `rpc.ts` pattern for FastAPI multi-region model serving
2. **Three-view-mode access control** — for ML dashboards (public/auth/admin)
3. **Nanostores + viem-style typed state** — lighter than Redux for ML inspector UIs (FORGEBOY domain)

## What MLBOY rejects

- **On-chain ML inference** — premature, gas costs absurd, not relevant for clinic-data ML
- **Astro for ML dashboard** — Streamlit/Gradio/marimo is the ML-native path
- **Smart contract data storage** — JERA Supabase + Postgres is the right place for clinical signals, not L1 chain

## Files to revisit

```
LarisLabs/floodboy-astro/
├── CLAUDE.md                    # 21.7K Oracle identity (FLOODBOY)
├── src/utils/rpc.ts             # resilient RPC routing — borrow
├── src/stores/blockchain.store.ts  # nanostores state machine
├── src/utils/blockchain-constants.ts  # chain configs + DEPLOYER_ABI
└── abis/                        # CatLabSensorStoreFactory + CatLabSecureSensorStore
```

## Cite

- viem docs: viem.sh — chosen over ethers v6 for new projects 2025+
- Multicall3: github.com/mds1/multicall — universal across EVM chains
- Astro Cloudflare: docs.astro.build/en/guides/integrations-guide/cloudflare/

🔥⚗️ — MLBOY (/learn --deep risk-bounded to 1 Explore agent; budget-aware execution)
