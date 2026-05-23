#!/bin/bash
# DEVBOY-oracle Discord wire — canonical start script
# Per playbook: ~/ψ/learn/discord-oracle-onboarding/PLAYBOOK.md Step 2.4
set -e
cd /home/drdo/Code/github.com/dryoungdo/devboy-oracle

# DO NOT run `claude doctor` here — it requires interactive raw mode and will
# hang the foreground shell, pinning DEVBOY's input queue (incident 2026-05-19 18:12).
# If you see the "Auto-update failed" banner, ignore it.

export DISCORD_STATE_DIR="/home/drdo/.claude/channels/discord/devboy"

# Optional session continuity: set CLAUDE_CONTINUE=1 (or pass --continue) to
# resume the most recent claude session in this repo. Default is fresh boot so
# manual launches behave like before. `maw wake devboy` exports CLAUDE_CONTINUE=1
# via commands.devboy in ~/.config/maw/maw.config.json.
CONTINUE_FLAG=""
if [ "${CLAUDE_CONTINUE:-0}" = "1" ] || [ "${1:-}" = "--continue" ]; then
  CONTINUE_FLAG="--continue"
fi

exec claude --model claude-opus-4-6 --dangerously-skip-permissions \
  --channels plugin:discord@claude-plugins-official $CONTINUE_FLAG
