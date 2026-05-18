# floodboy-ui-simple — Quick Reference

**Researched**: 2026-05-11 17:47 GMT+7 by IOTBOY (Haiku explore agent, content saved by main)

## What it does

Web-based IoT flood monitoring dashboard with blockchain integration. Two main applications in a single repo:

1. **`p5.html`** — IoT Sensor Visualization (729 lines): interactive demo of sensor data with physics-based water rendering, dual modes (water/air gap), state presets (normal/flooding/dry/offline/dead-sensor), and installation-height calibration. Uses p5.js for animated water ripples + LED status.

2. **`blockchain.html`** — Smart Contract Dashboard (2,755 lines): on-chain sensor data via Viem 2.21.19. Reads `RecordStored` events from deployed contracts. Multi-chain (Mainnet/Sepolia/Anvil). Chart.js time-series + dark/light theme + transaction log decoding.

## Install / Run

```bash
./run.sh
# Auto-detects: Bun > npm > Python3 > Python2
# Then:
# http://localhost:3000/p5.html
# http://localhost:3000/blockchain.html
```

Manual fallback:
```bash
bunx serve      # or
npx serve       # or
python3 -m http.server 8000
```

## Tech stack

| Layer | Library | Version |
|-------|---------|---------|
| React | CDN React 18 + Babel standalone | – |
| Viz | p5.js | 1.7.0 |
| Charts | Chart.js | 4.4.0 |
| Web3 | Viem | 2.21.19 |
| Date | date-fns | 2.29.3 |
| CSS | Tailwind | CDN |

All deps via CDN — no `npm install` needed.

## p5.html knobs

```js
<SensorVisualizationP5
  waterLevel={0.5}            // 0..5 m
  airLevel={2.0}              // m
  sensorMode="water"          // "water" | "air"
  installationHeight={2.5}     // sensor mount height
  showMeasurement={true}
  isOnline={true}
  isDead={false}
/>
```

## blockchain.html config

```js
const CONTRACTS = {
  deployer: '0x...',  // Deployer contract address
  store:    '0x...',  // Store contract address
  rpc:      'http://...'
}
```

Contract ABIs included inline (`DEPLOYER_ABI`, `STORE_ABI`). Watches `RecordStored(address indexed sensor, uint256 timestamp, int256[] values)`.

## Project structure

```
floodboy-ui-simple/
├── p5.html          (729 lines — sensor viz)
├── blockchain.html  (2,755 lines — chain dashboard)
├── run.sh           (auto-detect server launcher)
├── README.md
└── img/Cat-Lab.png  (Floodboy mascot)
```

## Requirements

- Browser with ES2020+
- Internet (CDN deps)
- Optional: Bun / Node / Python for static server
- Optional: Web3 wallet for blockchain interaction

## IOTBOY relevance

This is **directly IoT + Web3** in IOTBOY's scope:
- Sensor data model (water level + air distance) = same shape ESP32-based water-level sensor would emit
- "Installation height" calibration = classic ultrasonic ToF mounting offset
- Chain integration via Viem = how a device fleet could anchor readings on-chain
- p5.html mock data presets (Normal/Flooding/Dry/Offline/Dead) = useful test fixtures for ESP32 firmware behavioral states
- The split p5.html (sim) / blockchain.html (real) mirrors my edge → cloud telemetry pattern

Possible collab: I emit MQTT/HTTP sensor records → contract via WIREBOY → blockchain.html reads them. floodboy-astro likely the prod version of this same UI.
