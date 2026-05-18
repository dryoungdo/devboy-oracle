# floodboy-astro Learning Index

## Source
- **Origin**: ./origin/
- **GitHub**: https://github.com/LarisLabs/floodboy-astro
- **Live**: https://blockchain.floodboy.online (Cloudflare Workers, auto-deploy from `main`)

## Explorations

### 2026-05-11 17:47 (--deep, 5 agents)

- [Architecture](2026-05-11/1747_ARCHITECTURE.md) — Astro 5.11 + React 18 + Cloudflare Workers, islands architecture, 18 routes
- [Code Snippets](2026-05-11/1747_CODE-SNIPPETS.md) — Viem resilient fallback RPC, watchBlocks 3s poll, define:vars config injection
- [Quick Reference](2026-05-11/1747_QUICK-REFERENCE.md) — pnpm dev/build/deploy, blockchain.floodboy.online, factory 0x63bB...5Bb on chain 8899
- [Testing](2026-05-11/1747_TESTING.md) — Playwright configured, zero tests, deploy.yml lacks test gate
- [API Surface](2026-05-11/1747_API-SURFACE.md) — `/api/rpc-check`, CatLabFactory ABI, Multicall3, 3 chains

**Key insights**:
1. **Production evolution** of floodboy-ui-simple — same IoT sensor model, mature stack
2. **No MQTT, no WebSocket** — 3-second `watchBlocks` polling = the realtime cadence
3. **Resilient RPC pattern** (latency-ranked + 5-min cache + Viem fallback) = reusable for any device-to-cloud comms
4. **LarisLabs = P'Nat** — sponsor is `Nat.wrw@gmail.com`, this is HIS reference IoT × Web3 architecture
5. **Per-sensor contract** = scaling pattern worth studying for my Muninn engram store
6. **Deploy gap** — push-to-main goes straight to prod with zero test gate; Phase 1 Playwright smoke tests = a clear contribution opportunity
