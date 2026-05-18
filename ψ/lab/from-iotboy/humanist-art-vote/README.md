# humanist.art / vote

> "Simplicity first. Be human." — P'Nat 2026-05-09

One question. Four choices. One vote per browser. Counts revealed after you vote.

## Stack (minimum-human)

- Cloudflare Workers + Hono — single `worker.ts` file (~80 LOC)
- D1 — one table, three columns (`token`, `choice`, `created_at`)
- Vite + React + Tailwind v4 — monochrome stone-* palette, serif

No Drizzle. No KV rate limit. No fingerprint hashing. No aggregate cache. No anti-fraud beyond a signed cookie. The cookie is HMAC-SHA256 signed; verification uses constant-time XOR loop, not `===`.

## Routes

```
GET  /api/state    list choices + your vote (if any) + counts
POST /api/vote     { choice }   — issues + binds signed cookie if first visit
GET  /*            SPA fallback (frontend/index.html via Workers Assets)
```

## Frontend

`frontend/src/App.tsx` — ~70 LOC. Polls `/api/state` every 5s. Stone-* palette only. Results hidden until you vote.

## Run

```bash
npm install
wrangler d1 create humanist_vote          # update wrangler.toml with returned ID
wrangler secret put VOTE_HMAC_KEY         # paste a strong random
npm run db:push:local
npm run dev                                # wrangler dev :8787
cd frontend && npx vite                    # Vite HMR :5173, proxies /api → :8787
```

## Deploy

```bash
npm run db:push:prod
npm run deploy
```

## What was cut from the over-engineered version

| Cut | Why kept simple now |
|-----|----|
| Drizzle ORM | Raw SQL, three lines. We have one table. |
| KV rate limit | Cookie dedup is enough. Add later if abuse appears. |
| Fingerprint hash | Doesn't block anything; was audit-only. |
| `vote_aggregates` cache | `COUNT(*) GROUP BY` on a small table is fine. |
| Choices in DB | They're hard-coded constants. Edit the file, deploy. |
| `/api/me` + `/api/choices` + `/api/results` | Folded into `/api/state`. One endpoint, one trip. |

## What stays

- Signed cookie with constant-time HMAC verify (the 2026-05-09 audit lesson)
- Server-side dedup check in addition to cookie (defense-in-depth on a 5-line condition)
- Workers Assets for SPA — no extra hosting
- The cookie line: `HttpOnly; Secure; SameSite=Strict; Max-Age=2592000`

## IoT-Watchtower note

Same backend would serve a clinic waiting-room button-pad over LoRa. Token = per-firmware-flash HMAC of the device's MAC. Choice keys are short ASCII (fits LoRa MTU). The same ~80 LOC works for atoms or bits.
