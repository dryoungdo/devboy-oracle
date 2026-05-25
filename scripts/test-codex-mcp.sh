#!/usr/bin/env bash
# test-codex-mcp.sh - lightweight Codex MCP config smoke test.
#
# This verifies config parse + MCP registration through `codex mcp list`.
# It does not start the MCP server itself.

set -u

CONFIG="${CODEX_CONFIG:-${CODEX_HOME:-$HOME/.codex}/config.toml}"
CODEX_HOME_DIR="${CODEX_HOME:-$(dirname "$CONFIG")}"

if [ ! -f "$CONFIG" ]; then
  printf 'ERROR: config not found: %s\n' "$CONFIG" >&2
  exit 1
fi

printf '[codex-mcp] config=%s\n' "$CONFIG"
printf '[codex-mcp] arra-oracle config markers:\n'
grep -nE '^#?\[mcp_servers\.arra-oracle|^#?command = |^#?args = |^#?disabled = |ARRA-ORACLE DISABLED|disabled_reason|disabled_upstream_issue' "$CONFIG" 2>/dev/null || printf '  (no arra-oracle markers)\n'

TMP_OUT="$(mktemp)"
if env CODEX_HOME="$CODEX_HOME_DIR" codex mcp list > "$TMP_OUT" 2>&1; then
  sed 's/^/[codex-mcp] /' "$TMP_OUT"
  rm -f "$TMP_OUT"
  exit 0
fi

STATUS=$?
sed 's/^/[codex-mcp] /' "$TMP_OUT" >&2
rm -f "$TMP_OUT"
exit "$STATUS"
