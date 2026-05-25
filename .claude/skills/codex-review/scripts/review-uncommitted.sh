#!/bin/bash
# Codex co-review — fleet-hardened version (DO)
# Usage: review-uncommitted.sh <repo_dir>
#
# Hardenings per Mycelium architecture consult 2026-04-29:
# - flock auth-touching window (OAuth refresh race)
# - global semaphore max 2 concurrent fleet-wide
# - skip fixtures/migrations/generated/lockfiles
# - tracking log: /tmp/codex-fleet-usage.jsonl (append-only JSON-lines)
# - per-BOY identity in chat log
set -euo pipefail

REPO="${1:?need repo dir}"
BOY="${BOY_NAME:-$(basename "$(dirname "$(pwd)")")-${USER}}"   # override via env BOY_NAME=forgeboy
TS=$(date "+%Y-%m-%d %H:%M")
TS_TAG=$(date "+%Y%m%d-%H%M%S")
TS_ISO=$(date -Iseconds)

CHAT_LOG=/tmp/${BOY}-codex-chat.log
USAGE_JSONL=/tmp/codex-fleet-usage.jsonl
ANSWER=/tmp/codex-review-${BOY}-${TS_TAG}.md

cd "$REPO"

# --- Pre-flight: is this review worthy? -----------------------------------
SKIP_PATTERNS='(^|/)(fixtures|__fixtures__|migrations|node_modules)/|\.generated\.|\.lock$|^package-lock\.json$|^pnpm-lock\.yaml$|^yarn\.lock$|^bun\.lockb?$|^Cargo\.lock$|^poetry\.lock$'
CHANGED=$(git status --porcelain | awk '{print $2}')

if [ -z "$CHANGED" ]; then
  echo "{\"ts\":\"$TS_ISO\",\"boy\":\"$BOY\",\"repo\":\"$(basename "$REPO")\",\"action\":\"review-uncommitted\",\"exit\":0,\"verdict\":\"skip-no-changes\"}" >> "$USAGE_JSONL"
  echo "no uncommitted changes — skip"
  exit 0
fi

REAL_CHANGES=$(echo "$CHANGED" | grep -Ev "$SKIP_PATTERNS" || true)
if [ -z "$REAL_CHANGES" ]; then
  echo "{\"ts\":\"$TS_ISO\",\"boy\":\"$BOY\",\"repo\":\"$(basename "$REPO")\",\"action\":\"review-uncommitted\",\"exit\":0,\"verdict\":\"skip-noise-only\"}" >> "$USAGE_JSONL"
  echo "all changes are fixtures/migrations/generated/lockfiles — skip"
  exit 0
fi

# (No bot-author skip: this reviews the working tree, so the last commit's
# author is irrelevant — gating on it would skip a human's uncommitted work
# whenever the previous commit happened to be bot-made.)

# --- Header ---------------------------------------------------------------
{
  echo ""
  echo "[$TS] CODEX-REVIEW (--uncommitted) — boy=$BOY repo=$(basename "$REPO")"
  echo "─────────────────────────────────────────────────"
  echo "Q: codex review --uncommitted (staged + unstaged + untracked)"
  echo ""
  echo "A:"
} >> "$CHAT_LOG"

# --- Run codex with locks ------------------------------------------------
START=$(date +%s)

# flock is util-linux only. On macOS / BSD it's absent; single-user dev
# environments don't need fleet-wide rate limiting anyway. Detect + fallback.
HAVE_FLOCK=0
if command -v flock >/dev/null 2>&1; then
  HAVE_FLOCK=1
  # Global semaphore: max 2 fleet-wide. -w 60 = wait up to 60s for lock.
  exec 9>/tmp/codex-fleet.lock
  flock -w 60 9 || { echo "fleet semaphore busy >60s — aborting"; exit 2; }
  # Auth-touching window (codex itself touches auth.json on first call per session)
  exec 8>/tmp/codex-auth.lock
  flock -w 30 8 || { echo "auth lock busy >30s — aborting"; exit 3; }
fi

# Run review. set +e: a non-zero `codex review` exit must not abort the
# script before we capture EXIT and write the footer + usage JSONL record.
set +e
codex review --uncommitted 2>&1 | tee "$ANSWER" | sed 's/^/   /' >> "$CHAT_LOG"
EXIT=${PIPESTATUS[0]}
set -e

# Release auth lock once codex returns
[ "$HAVE_FLOCK" = "1" ] && exec 8>&-

END=$(date +%s)
DURATION=$((END - START))

# --- Extract tokens + P-flag count (set +eo pipefail to allow no-matches) -
set +eo pipefail
TOKENS=$(grep -A1 "^tokens used" "$ANSWER" 2>/dev/null | tail -1 | tr -dc '0-9')
[ -z "$TOKENS" ] && TOKENS=0
P_FLAGS=$(grep -cE "^- \[P[0-9]\]" "$ANSWER" 2>/dev/null | tr -dc '0-9')
[ -z "$P_FLAGS" ] && P_FLAGS=0
set -eo pipefail

if [ "$P_FLAGS" = "0" ]; then
  VERDICT="clean"
else
  VERDICT="${P_FLAGS}-flags"
fi

# --- Footer + tracking ----------------------------------------------------
{
  echo ""
  echo "─── end CODEX-REVIEW-UNCOMMITTED ($TS_TAG) — duration=${DURATION}s tokens=$TOKENS verdict=$VERDICT — see $ANSWER ───"
} >> "$CHAT_LOG"

# JSON line for usage tracking (jq-friendly)
echo "{\"ts\":\"$TS_ISO\",\"boy\":\"$BOY\",\"repo\":\"$(basename "$REPO")\",\"action\":\"review-uncommitted\",\"duration_s\":$DURATION,\"tokens\":$TOKENS,\"exit\":$EXIT,\"verdict\":\"$VERDICT\",\"answer_file\":\"$ANSWER\"}" >> "$USAGE_JSONL"

# Release fleet semaphore
[ "$HAVE_FLOCK" = "1" ] && exec 9>&-

echo "$ANSWER"
exit $EXIT
