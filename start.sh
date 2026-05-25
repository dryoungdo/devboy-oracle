#!/bin/bash
# DEVBOY-oracle Discord wire - canonical start script
# Per playbook: ~/ψ/learn/discord-oracle-onboarding/PLAYBOOK.md Step 2.4
set -u
cd /home/drdo/Code/github.com/dryoungdo/devboy-oracle || exit 1

DISCORD_MCP_SERVER="plugin:discord:discord"

discord_mcp_connected() {
  claude mcp list 2>&1 | grep -F "$DISCORD_MCP_SERVER" | grep -Fq "Connected"
}

listener_has_discord_mcp_child() {
  local listener_pid="$1"
  local process_tree

  if command -v pstree >/dev/null 2>&1; then
    process_tree="$(pstree -pnal "$listener_pid" 2>/dev/null || true)"
    [[ "$process_tree" =~ bun.*discord || "$process_tree" =~ discord.*server[.]ts ]]
    return
  fi

  if command -v pgrep >/dev/null 2>&1 && command -v ps >/dev/null 2>&1; then
    descendant_has_discord_mcp_child "$listener_pid"
    return
  fi

  echo "[gate_hook] WARN: cannot verify Discord MCP child; pstree/pgrep/ps unavailable" >&2
  return 1
}

descendant_has_discord_mcp_child() {
  local parent_pid="$1"
  local child_pid
  local child_args

  while IFS= read -r child_pid; do
    [ -n "$child_pid" ] || continue

    child_args="$(ps -p "$child_pid" -o args= 2>/dev/null || true)"
    if [[ "$child_args" =~ bun.*discord || "$child_args" =~ discord.*server[.]ts ]]; then
      return 0
    fi

    if descendant_has_discord_mcp_child "$child_pid"; then
      return 0
    fi
  done < <(pgrep -P "$parent_pid" 2>/dev/null)

  return 1
}

discord_mcp_healthy() {
  local listener_pid="$1"

  discord_mcp_connected && listener_has_discord_mcp_child "$listener_pid"
}

stop_listener_after_health_failure() {
  local listener_pid="$1"

  if kill -0 "$listener_pid" 2>/dev/null; then
    kill -TERM "$listener_pid" 2>/dev/null || true
  fi
}

verify_discord_mcp_after_launch() {
  local listener_pid="$1"

  sleep 12

  if discord_mcp_healthy "$listener_pid"; then
    echo "[gate_hook] OK: Discord MCP connected after 12s"
    return 0
  fi

  echo "[gate_hook] WARN: Discord MCP not connected after 12s, retrying..." >&2
  sleep 5

  if discord_mcp_healthy "$listener_pid"; then
    echo "[gate_hook] OK: Discord MCP connected on retry"
    return 0
  fi

  echo "[gate_hook] ERROR: Discord MCP failed to connect after retry. DEVBOY is deaf." >&2
  stop_listener_after_health_failure "$listener_pid"
  exit 1
}

# DO NOT run `claude doctor` here — it requires interactive raw mode and will
# hang the foreground shell, pinning DEVBOY's input queue (incident 2026-05-19 18:12).
# If you see the "Auto-update failed" banner, ignore it.

export DISCORD_STATE_DIR="/home/drdo/.claude/channels/discord/devboy"

# Optional session continuity: set CLAUDE_CONTINUE=1 (or pass --continue) to
# resume the most recent claude session in this repo. Default is fresh boot so
# manual launches behave like before. `maw wake devboy` exports CLAUDE_CONTINUE=1
# via commands.devboy in ~/.config/maw/maw.config.json.
CLAUDE_ARGS=(
  --model claude-opus-4-6
  --dangerously-skip-permissions
  --channels plugin:discord@claude-plugins-official
)
if [ "${CLAUDE_CONTINUE:-0}" = "1" ] || [ "${1:-}" = "--continue" ]; then
  CLAUDE_ARGS+=(--continue)
fi

verify_discord_mcp_after_launch "$$" &

exec claude "${CLAUDE_ARGS[@]}"
