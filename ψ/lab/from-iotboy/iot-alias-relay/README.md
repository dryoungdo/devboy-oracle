# iot-alias-relay

IoT-shaped fork of [`Soul-Brews-Studio/webhook-relay-oss`](https://github.com/Soul-Brews-Studio/webhook-relay-oss) alias pattern. Lifts the Drizzle schema + idType discriminator + UI two-table layout. Swaps LINE `U.../C.../R...` for ESP32 MAC / ESP-NOW peer / sensor pin / mesh node.

## Why

Opaque hardware IDs need human labels for ops dashboards + MQTT topic readability. `clinic/24:6F:28:A1:B2:C3/celsius` is unreadable; `clinic/living-room-temp/celsius` is.

## Stack

- **Elysia** (Bun-native TS) — chosen over Hono/Workers because devices are LAN-local; edge replication isn't a benefit here, and Eden Treaty's e2e typesafety pays off when the React dashboard consumes our types directly.
- **Drizzle ORM** — portable schema, swap dialect for SQLite-local or Postgres later.
- **bun:sqlite** — embedded DB; works on a Raspberry Pi gateway with zero infra.

## Endpoints

```
GET    /api/aliases               list all
GET    /api/aliases/:value        single
PUT    /api/aliases                upsert {value, label, notes?}
DELETE /api/aliases/:value         remove
GET    /api/aliases/topic-preview  IoT-unique: substitute aliases into MQTT topic
```

## IoT-unique bits not in webhook-relay-oss

| Feature | Why we have it, they don't |
|---|---|
| MAC normalization on PUT | Devices report `aa:bb` lowercase, ops type `AA:BB` uppercase. Same MAC. |
| `topic-preview` endpoint | Ops verifies "what does my MQTT topic look like with current aliases" without subscribing. |
| `kind` discriminator stored | Filter/group by hardware class (all sensors, all mesh nodes, etc.) |
| Alias TTL hook (next iter) | ESP-NOW peer aliases must invalidate on firmware reflash; LINE IDs are forever. |

## Schema

`src/schema.ts` — `aliases` table + `idType()` regex discriminator + `aliasTopic()` substitution helper.

## Running

```bash
bun install
bun run dev       # auto-restart on save
bun run start     # production
```

Listens on `:3000` (override with `PORT`).

## Status

Lab quality. Cuts pending: frontend UI port, OTA-binding-aware alias invalidation, MQTT broker hook for live topic substitution at the broker layer (vs in the API).
