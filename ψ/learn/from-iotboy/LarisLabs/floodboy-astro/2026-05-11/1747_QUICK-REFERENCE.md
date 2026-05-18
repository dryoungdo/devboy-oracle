# floodboy-astro — Quick Reference

**Researched**: 2026-05-11 17:47 GMT+7 by IOTBOY

## What it does

FloodBoy = real-time flood monitoring web app + multi-chain blockchain explorer for sensor data. Open-source dashboard for **Climate Change Data Center (CCDC) Chiang Mai University** flood-sensor network in Northern Thailand.

- Real-time water-depth monitoring (±2mm accuracy via IoT sensors)
- Multi-chain explorer for sensor store contracts (JIBCHAIN L1 / SiChang / Anvil)
- Interactive sensor simulator
- P5.js visualization + Chart.js historical
- Mobile-responsive

## Install / Run

```bash
pnpm install
pnpm dev      # http://localhost:4321
pnpm build    # production
pnpm preview  # local prod preview
pnpm deploy   # Cloudflare Workers
```

Auto-deploys from `main` → https://blockchain.floodboy.online

## Pages

| Path | Feature |
|------|---------|
| `/blockchain` | Browse all deployed sensor stores + factory |
| `/blockchain/[address]` | Per-store data, sensor config, water levels |
| `/simulator` | Interactive UI — water-level slider, presets |
| `/sensors` | Sensor monitoring dashboard (coming soon) |
| `/analytics` | Historical analytics (coming soon) |
| `/blog` | Updates + retros |
| `/about` | Team, sponsors, CCDC |
| `/rpc` | RPC endpoint health |

## Config

**astro.config.mjs**:
```js
site: "https://blockchain.floodboy.online"
adapter: cloudflare({ mode: 'directory', imageService: 'compile' })
redirects: { '/': '/blockchain' }
```

**src/config/blockchain.config.ts** chains:
```
8899    JIBCHAIN L1   (Production, 100 stores deployed)
700011  SiChang       (Coming soon)
31337   Anvil         (Local dev)
555888  DustBoy IoT   (Coming soon)
```

RPC: client-side `localStorage['floodboy_preferred_rpc']`. No env vars required.

## Deploy

- Platform: **Cloudflare Workers** (@astrojs/cloudflare adapter)
- Domain: blockchain.floodboy.online
- Workers URL: floodboy-astro.laris.workers.dev
- Account: `a5eabdc2b11aae9bd5af46bd6a88179e` (Nat.wrw@gmail.com)
- Trigger: push to `main` → auto-deploy

## Tech stack

| Layer | Lib | Version |
|-------|-----|---------|
| Framework | Astro + React 18 | 5.11.0 / 18.3.1 |
| Styling | Tailwind | 4.1 |
| Blockchain | Viem (NO wagmi/ethers) | 2.31.7 |
| Charts | Chart.js + react-chartjs-2 | 4.5 |
| Animation | P5.js | 2.0 |
| Deploy | Cloudflare Workers + Wrangler | 4.21 |
| Tests | Playwright (configured, no tests yet) | – |
| TypeScript | TS | 5.8 |
| State | Nanostores | 1.0.1 |

## Factory contract (production)

- Chain: **JIBCHAIN L1** (chain id 8899)
- Factory: `0x63bB41b79b5aAc6e98C7b35Dcb0fE941b85Ba5Bb`
- Stores deployed: 100 (as of 2025-07-21)
- Explorer: https://exp.jibchain.net

## IOTBOY relevance

- This is the **production version** of floodboy-ui-simple. Same sensor data model (water_depth / air_height / installation_height) but Astro + Cloudflare + TypeScript + Viem-resilient-RPC + Nanostores.
- **No MQTT**. "Realtime" = `client.watchBlocks({ pollingInterval: 3_000 })` polling on-chain events every 3s.
- IoT sensors write DIRECTLY to smart contracts on JIBCHAIN L1 — eliminates the broker layer entirely. Different model from my MQTT plan.
- RPC ranking by latency + 5-min cache = pattern I can steal for resilient device-to-cloud comms.
- Factory + Store pattern = scalable (1 factory, N store contracts, 100 deployed). Per-device contract = my Muninn-on-edge could similarly be per-device engram store.
- LarisLabs is `Nat.wrw@gmail.com` = **P'Nat's email** — this IS P'Nat's IoT × Web3 stack. Reference architecture for the fleet.
