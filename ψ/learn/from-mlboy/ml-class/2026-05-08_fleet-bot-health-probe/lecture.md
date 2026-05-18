# Lecture — Fleet Bot Health Probe (raw)

**From**: P'Nat (`nazt_`, `691531480689541170`)
**Where**: Discord `#road-to-dev` (channel `1500775333283237970`)
**Msg ID**: `1502138239212064769`
**Time**: 2026-05-08 02:41 GMT+7
**Hook**: "@everyone เอาเรื่องปะครับ" ("anyone want to take this on?")

## Raw command

```bash
for BOT in arthur-oracle calliope-oracle discord-oracle drdo-translator-oracle \
           dustboy-phd-oracle fireman-oracle fortal-oracle hermes-discord \
           metis-oracle mother-oracle odin-oracle pigment-oracle pulse-oracle \
           thor-oracle timekeeper-oracle volt-oracle xiaoer-oracle arr01-oracle; do
  CODE=$(/usr/bin/curl -s -o /dev/null -w '%{http_code}' -m 3 \
         -b /tmp/fleet-cookies \
         "http://localhost:4567/api/oracles/$BOT/bot")
  echo "$BOT: $CODE"
done
```

## Output

All 18 bots returned `200`:

```
arthur-oracle: 200       fireman-oracle: 200          odin-oracle: 200
calliope-oracle: 200     fortal-oracle: 200           pigment-oracle: 200
discord-oracle: 200      hermes-discord: 200          pulse-oracle: 200
drdo-translator-oracle: 200  metis-oracle: 200        thor-oracle: 200
dustboy-phd-oracle: 200  mother-oracle: 200           timekeeper-oracle: 200
                                                      volt-oracle: 200
                                                      xiaoer-oracle: 200
                                                      arr01-oracle: 200
```

(timeout was 1m total)

## What this is, in MLBOY's read

Fleet health probe — `localhost:4567/api/oracles/<bot>/bot` is an internal fleet API that returns per-bot status. `-m 3` cap = 3-second timeout per bot. `-b /tmp/fleet-cookies` = session cookie auth. `200` = endpoint responded successfully (not necessarily "healthy" — just reachable + auth accepted).

Important distinction: `HTTP 200` ≠ "bot is functioning". It only proves the API responded. The bot could be:
- Idle, stuck in a loop, out of context budget, throwing internal errors — and still return 200 from the wrapper API
- Need to inspect response body to confirm liveness vs. just reachability

## Why MLBOY cares

This is **time-series observability data** if probed regularly. ML angles:
1. **Drift detection** — latency distribution per bot over time; tail latency creep is an early-warning signal before 200 → 5xx
2. **Anomaly classification** — "bot returned 200 but body shape changed" — cluster on body schema/length to catch silent failures
3. **Survival analysis** — time-to-first-non-200 per bot; cox regression on bot type / load
4. **Fleet-wide correlation** — when bot A degrades, does B/C/D follow? (shared infra signal)

Not training anything yet. Just noting where the ore is.

## Open questions for P'Nat

1. Does the body actually contain liveness info, or is it just "alive enough to respond"?
2. Is there a logging endpoint that retains historical probe results, or is each probe ephemeral?
3. Is this probe scheduled (cron / loop) or hand-run? If scheduled, what cadence?

## File status

Raw lecture — no MLBOY work yet. Class material capture only.
