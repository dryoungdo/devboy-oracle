#!/bin/bash
# Codex fleet usage report — answers Captain's "track time / tokens / money"
# Usage: usage-report.sh [today|week|month|all]  (default: today)
set -euo pipefail

PERIOD="${1:-today}"
USAGE_JSONL=/tmp/codex-fleet-usage.jsonl

if [ ! -f "$USAGE_JSONL" ]; then
  echo "no usage log yet at $USAGE_JSONL"
  exit 0
fi

# Tolerate malformed lines: parse each line independently and drop any that fail,
# so one corrupt legacy record can't abort the whole report with a jq parse error.
CLEAN_JSONL=$(mktemp)
trap 'rm -f "$CLEAN_JSONL"' EXIT
jq -Rc 'fromjson? // empty' "$USAGE_JSONL" > "$CLEAN_JSONL" 2>/dev/null || true
USAGE_JSONL="$CLEAN_JSONL"

case "$PERIOD" in
  today)  CUTOFF=$(date -d 'today 00:00' -Iseconds 2>/dev/null || date -v0H -v0M -v0S -Iseconds) ;;
  week)   CUTOFF=$(date -d '7 days ago' -Iseconds 2>/dev/null || date -v-7d -Iseconds) ;;
  month)  CUTOFF=$(date -d '30 days ago' -Iseconds 2>/dev/null || date -v-30d -Iseconds) ;;
  all)    CUTOFF="0000-01-01T00:00:00+00:00" ;;
  *) echo "usage: $0 [today|week|month|all]"; exit 1 ;;
esac

echo "=== Codex Fleet Usage — period: $PERIOD (since $CUTOFF) ==="
echo ""

# Per-BOY rollup
echo "Per BOY:"
jq -r --arg cutoff "$CUTOFF" '
  select(.ts >= $cutoff) |
  [.boy, .tokens, .duration_s, .verdict] | @tsv
' "$USAGE_JSONL" | awk -F'\t' '
  {
    boy=$1; tokens=$2; dur=$3; verdict=$4
    calls[boy]++
    tok[boy]+=tokens
    dur_total[boy]+=dur
    if (verdict ~ /flag/) flag[boy]++
    if (verdict ~ /skip/) skip[boy]++
  }
  END {
    printf "  %-12s %6s %10s %8s %6s %6s\n", "boy", "calls", "tokens", "dur(s)", "flags", "skips"
    for (b in calls) printf "  %-12s %6d %10d %8d %6d %6d\n", b, calls[b], tok[b], dur_total[b], (flag[b]+0), (skip[b]+0)
  }
'

echo ""
TOTAL_TOKENS=$(jq -r --arg cutoff "$CUTOFF" 'select(.ts >= $cutoff) | .tokens // 0' "$USAGE_JSONL" | awk '{s+=$1} END {print s+0}')
TOTAL_CALLS=$(jq -r --arg cutoff "$CUTOFF" 'select(.ts >= $cutoff) | .ts' "$USAGE_JSONL" | wc -l)
TOTAL_DUR=$(jq -r --arg cutoff "$CUTOFF" 'select(.ts >= $cutoff) | .duration_s // 0' "$USAGE_JSONL" | awk '{s+=$1} END {print s+0}')

# Approx $ — Codex Pro = $200/mo subscription, not per-token. So $ = subscription proration.
# We track tokens to monitor proximity to plan limits, not bill.
echo "Fleet totals:"
echo "  calls:  $TOTAL_CALLS"
echo "  tokens: $TOTAL_TOKENS"
echo "  duration: ${TOTAL_DUR}s"
echo ""
echo "Pro subscription: \$200/mo flat. Token count is for proximity-to-limit monitoring."
echo "GPT-5.5 Pro local-message ceiling: ~80-400 messages per 5h, weekly cap may apply."

# Last 5 calls
echo ""
echo "Last 5 calls:"
tail -5 "$USAGE_JSONL" | jq -r '"  \(.ts) | \(.boy) | \(.repo) | \(.verdict) | \(.tokens // 0)tok | \(.duration_s // 0)s"'
