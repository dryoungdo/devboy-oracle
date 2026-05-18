# floodboy-ui-simple Learning Index

## Source
- **Origin**: ./origin/
- **GitHub**: https://github.com/LarisLabs/floodboy-ui-simple

## Explorations

### 2026-05-11 17:47 (--deep, 5 agents)

- [Architecture](2026-05-11/1747_ARCHITECTURE.md) — zero-build HTML + CDN, 2 standalone apps (p5.html + blockchain.html)
- [Code Snippets](2026-05-11/1747_CODE-SNIPPETS.md) — FloodboyVisualization (p5 ref pattern), Viem ESM imports, event-driven state reconstruction
- [Quick Reference](2026-05-11/1747_QUICK-REFERENCE.md) — install/run via run.sh, multi-chain Viem 2.21.19, dual sensor modes
- [Testing](2026-05-11/1747_TESTING.md) — zero tests today, proposed Vitest+Playwright phased plan
- [API Surface](2026-05-11/1747_API-SURFACE.md) — DEPLOYER_ABI + STORE_ABI, EIP-1193 wallet, RecordStored events

**Key insights**:
1. LarisLabs (P'Nat's org via `Nat.wrw@gmail.com`) = IoT × Web3 reference architecture for the fleet
2. Sensor data model: water_depth + air_height + installation_height — matches ultrasonic ToF mounting
3. NO MQTT — sensors write directly to smart contracts (factory + per-store pattern, 100 stores on JIBCHAIN L1)
4. CDN-only zero-build → fast iteration but no testing infra at all
5. This is the **prototype**; floodboy-astro is the **production** evolution
