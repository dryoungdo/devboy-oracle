#!/bin/bash
# GLUEBOY × Codex co-review — verify-mode (custom prompt + repo context)
# Use when you need to ASK Codex specific questions about prior findings,
# regression risks, or design choices. Works around the `codex review --base`
# + custom-prompt mutex by using `codex exec` agent mode instead.
# Usage: exec-review.sh <repo_dir> <prompt_file>
set -euo pipefail

REPO="${1:?need repo dir}"
PROMPT_FILE="${2:?need prompt file}"
TS=$(date "+%Y-%m-%d %H:%M")
TS_TAG=$(date "+%Y%m%d-%H%M%S")

LOG=/tmp/glueboy-codex-chat.log
ANSWER=/tmp/codex-exec-review-${TS_TAG}.md

cd "$REPO"

{
  echo ""
  echo "[$TS] CODEX-EXEC-REVIEW — repo $(basename "$REPO")"
  echo "─────────────────────────────────────────────────"
  echo "Q (custom verify-mode prompt):"
  sed 's/^/   /' "$PROMPT_FILE"
  echo ""
  echo "A:"
} >> "$LOG"

# --ephemeral: don't persist session to ~/.codex/sessions/ (lower disk + token waste)
# --skip-git-repo-check: allow running outside git root if -C points elsewhere
# -C: tell agent the working dir
# -s read-only: never modify code, review-only
# (note: `codex review` rejects --color but `codex exec` accepts it; we don't need it here)
codex exec \
  --ephemeral \
  --skip-git-repo-check \
  -s read-only \
  -C "$REPO" \
  -o "$ANSWER" \
  "$(cat "$PROMPT_FILE")" 2>&1 | tail -3 > /dev/null || {
    echo "[codex exec failed; check $ANSWER for partial output]"
    exit 1
  }

sed 's/^/   /' "$ANSWER" >> "$LOG"
{
  echo ""
  echo "─── end CODEX-EXEC-REVIEW ($TS_TAG) — see $ANSWER ───"
} >> "$LOG"

echo "$ANSWER"
