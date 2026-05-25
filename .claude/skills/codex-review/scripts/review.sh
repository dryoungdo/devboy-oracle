#!/bin/bash
# Codex co-review — diff range (pre-PR / branch-vs-main)
# Usage: review.sh <repo_dir> [<base_ref>] (default base_ref: origin/main)
set -euo pipefail

REPO="${1:?need repo dir}"
BASE_REF="${2:-origin/main}"
BOY="${BOY_NAME:-${USER}}"
TS=$(date "+%Y-%m-%d %H:%M")
TS_TAG=$(date "+%Y%m%d-%H%M%S")
TS_ISO=$(date -Iseconds)

CHAT_LOG=/tmp/${BOY}-codex-chat.log
USAGE_JSONL=/tmp/codex-fleet-usage.jsonl
ANSWER=/tmp/codex-review-${BOY}-${TS_TAG}.md

cd "$REPO"

{
  echo ""
  echo "[$TS] CODEX-REVIEW (vs $BASE_REF) — boy=$BOY repo=$(basename "$REPO")"
  echo "─────────────────────────────────────────────────"
  echo "Q: codex review (commits between $BASE_REF and HEAD)"
  echo ""
  echo "A:"
} >> "$CHAT_LOG"

START=$(date +%s)

# flock is util-linux only; absent on macOS/BSD. Single-user dev hosts
# don't need fleet-wide rate limiting — detect + fall back gracefully.
HAVE_FLOCK=0
if command -v flock >/dev/null 2>&1; then
  HAVE_FLOCK=1
  exec 9>/tmp/codex-fleet.lock
  flock -w 60 9 || { echo "fleet semaphore busy >60s"; exit 2; }
  exec 8>/tmp/codex-auth.lock
  flock -w 30 8 || { echo "auth lock busy >30s"; exit 3; }
fi

# set +e: a non-zero `codex review` exit must not abort the script before
# we capture EXIT and write the footer + usage JSONL record.
set +e
codex review --base "$BASE_REF" 2>&1 | tee "$ANSWER" | sed 's/^/   /' >> "$CHAT_LOG"
EXIT=${PIPESTATUS[0]}
set -e
[ "$HAVE_FLOCK" = "1" ] && exec 8>&-

END=$(date +%s)
DURATION=$((END - START))

# Extract tokens + P-flag count. `set +eo pipefail` so no-match greps don't abort;
# `tr -dc '0-9'` guarantees a clean integer — `grep -c || echo 0` would emit "0\n0"
# on no-match and put a literal newline in VERDICT, corrupting the jsonl record.
set +eo pipefail
TOKENS=$(grep -A1 "^tokens used" "$ANSWER" 2>/dev/null | tail -1 | tr -dc '0-9')
[ -z "$TOKENS" ] && TOKENS=0
P_FLAGS=$(grep -cE "^- \[P[0-9]\]" "$ANSWER" 2>/dev/null | tr -dc '0-9')
[ -z "$P_FLAGS" ] && P_FLAGS=0
set -eo pipefail

[ "$P_FLAGS" = "0" ] && VERDICT="clean" || VERDICT="${P_FLAGS}-flags"

{
  echo ""
  echo "─── end CODEX-REVIEW-RANGE ($TS_TAG) — duration=${DURATION}s tokens=$TOKENS verdict=$VERDICT — see $ANSWER ───"
} >> "$CHAT_LOG"

echo "{\"ts\":\"$TS_ISO\",\"boy\":\"$BOY\",\"repo\":\"$(basename "$REPO")\",\"action\":\"review-vs-$BASE_REF\",\"duration_s\":$DURATION,\"tokens\":$TOKENS,\"exit\":$EXIT,\"verdict\":\"$VERDICT\",\"answer_file\":\"$ANSWER\"}" >> "$USAGE_JSONL"

[ "$HAVE_FLOCK" = "1" ] && exec 9>&-
echo "$ANSWER"
exit $EXIT
