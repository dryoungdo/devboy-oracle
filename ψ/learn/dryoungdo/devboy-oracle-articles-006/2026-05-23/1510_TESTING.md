# Discord Verification — 3 Layers (Articles 006 + 041 + 2026-05-23 incident)

## Layer 1 — Canonical (Article 041)

### 7-step debug flowchart (verbatim)

```
Bot ไม่ตอบ?
  +--> Bot online ไหม?
  |     No  --> Check .env token + restart session
  |     Yes -->
  +--> grep dmPolicy access.json
  |     "disabled" --> เปลี่ยนเป็น "allowlist"
  |     "allowlist" -->
  +--> User ID อยู่ใน allowFrom?
  |     No  --> เพิ่ม user ID
  |     Yes -->
  +--> Channel ID อยู่ใน groups?
  |     No  --> เพิ่ม channel group
  |     Yes -->
  +--> requireMention: true + ไม่ได้ @mention?
  |     Yes --> @mention bot หรือเปลี่ยนเป็น false
  |     No  -->
  +--> Session start ด้วย --channels flag?
  |     No  --> restart: claude --channels plugin:discord@claude-plugins-official
  |     Yes -->
  +--> MESSAGE_CONTENT intent เปิดใน Developer Portal?
  |     No  --> เปิด + restart bot
  |     Yes -->
  +--> diff access.json กับ bot ที่ใช้งานได้
        หา field ที่ต่าง
```

### Article 041 diagnostic one-liner (verbatim)

```bash
echo "=== settings.json ===" && \
grep -A2 enabledPlugins ~/.claude/settings.json && \
echo "=== bot dirs ===" && \
ls ~/.claude/channels/discord/ && \
echo "=== access.json ===" && \
cat ~/.claude/channels/discord/*/access.json 2>/dev/null | grep dmPolicy && \
echo "=== .env exists ===" && \
ls -la ~/.claude/channels/discord/*/.env 2>/dev/null
```

## Layer 2 — Process + Socket (the 2026-05-23 gap)

Article 041 assumes the listener is healthy. The 2026-05-23 incident proved: **listener alive ≠ Discord alive**. The discord plugin runs as a `bun` child of the listener. If that spawn silently fails, the parent stays alive but the bot is deaf.

### Probe 1 — Process tree must show `bun` discord child

```bash
LISTENER_PID=$(pgrep -f "claude.*channels plugin:discord" | head -1)
pstree -spnal "$LISTENER_PID"
```

Expected: a `bun … server.ts` child under the listener PID.
Missing → MCP spawn failed → restart required.

### Probe 2 — Socket must show outbound 443 to gateway.discord.gg

```bash
ss -tnp | grep -iE "discord|gateway.discord.gg"
# or
lsof -i -p "$LISTENER_PID" 2>/dev/null | grep TCP
```

Expected: an ESTABLISHED TCP connection on port 443.
Missing → bot never logged in → restart required.

### Probe 3 — Manual server.ts spawn (fastest root-cause eliminator)

```bash
timeout 8 env DISCORD_BOT_TOKEN=$(grep -oP 'DISCORD_BOT_TOKEN=\K.+' ~/.claude/channels/discord/devboy/.env) \
  bun --cwd ~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/ run start 2>&1 | head -30
```

Expected within 3s: `discord channel: gateway connected as DEVBOY-oracle#9792`.

- ✅ Success → server.ts + token + Discord intents healthy. Root cause = Claude's plugin loader skipped MCP spawn. Restart listener.
- ❌ Timeout/error → token invalid, Discord intent missing, or server.ts bug. Check `.env`, rotate token, verify Developer Portal intents.

## Layer 3 — Proposed gate_hook for `start.sh`

Mitigation per CLAUDE.md Shield #8 (know-do gap shield): bake a post-launch verifier into `start.sh` so the failure is detected in 12s, not 15 minutes later.

```bash
#!/bin/bash
# ============================================================================
# POST-LAUNCH DISCORD VERIFIER (gate_hook for incident 2026-05-23)
#
# Wraps the discord listener launch. Verifies bun MCP child + gateway socket
# appear within 12s. Retries once on failure. Exits with explicit error +
# remediation steps on second failure.
# ============================================================================

verify_discord_listener() {
  local listener_pid=$1
  local max_wait=12
  local elapsed=0

  while [ $elapsed -lt $max_wait ]; do
    if pstree -spnal "$listener_pid" 2>/dev/null | grep -qE "bun.*discord|bun.*server"; then
      if ss -tnp 2>/dev/null | grep -qE "pid=$listener_pid.*:443|gateway\.discord"; then
        echo "[✓] Discord listener healthy at PID $listener_pid" >&2
        echo "[✓]   - bun MCP child spawned" >&2
        echo "[✓]   - outbound 443 socket confirmed" >&2
        return 0
      fi
    fi
    sleep 1
    ((elapsed++))
  done

  echo "[✗] Listener PID $listener_pid is a zombie placeholder after ${max_wait}s" >&2
  if ! pstree -spnal "$listener_pid" 2>/dev/null | grep -q "bun"; then
    echo "[✗]   Root cause: MCP child spawn FAILED (no bun process)" >&2
  else
    echo "[✗]   Root cause: Gateway socket FAILED (bun child exists but no TCP 443)" >&2
  fi

  kill "$listener_pid" 2>/dev/null || true
  return 1
}

start_discord_listener() {
  local attempt=$1
  echo "[*] Launching Discord listener (attempt $attempt)..." >&2

  # NOTE: --model claude-opus-4-6 is intentional per Captain (2026-05-23 voice).
  #       Do NOT bump model version without explicit seal.
  cd /home/drdo/Code/github.com/dryoungdo/devboy-oracle
  export DISCORD_STATE_DIR="/home/drdo/.claude/channels/discord/devboy"

  claude --model claude-opus-4-6 \
         --dangerously-skip-permissions \
         --channels plugin:discord@claude-plugins-official \
         2>&1 &
  local listener_pid=$!

  echo "[*] Listener PID: $listener_pid" >&2

  if verify_discord_listener "$listener_pid"; then
    echo "$listener_pid"
    return 0
  fi

  if [ "$attempt" -lt 2 ]; then
    echo "[!] First attempt failed. Sleep 3s, retry once." >&2
    sleep 3
    start_discord_listener 2
    return $?
  fi

  echo "[✗] CRITICAL: Discord listener failed both attempts." >&2
  echo "[✗] Remediation:" >&2
  echo "[✗]   1. Check ~/.claude/channels/discord/devboy/.env (token validity + chmod 600)" >&2
  echo "[✗]   2. Verify Discord Developer Portal intents (MESSAGE_CONTENT etc.)" >&2
  echo "[✗]   3. Manual probe: timeout 8 bun --cwd ~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/ run start" >&2
  echo "[✗]   4. If manual probe shows 'gateway connected as ...' → plugin loader bug. File upstream issue." >&2
  echo "[✗]   5. Verify ~/.claude/settings.json has enabledPlugins.discord@claude-plugins-official = true" >&2
  echo "[✗]   6. Full reset: pkill -f 'claude.*channels' ; bash start.sh" >&2
  return 1
}

# Main
if start_discord_listener 1; then
  echo "[✓] DEVBOY Oracle live with Discord connected." >&2
else
  echo "[✗] Failed to start Discord listener. Exit." >&2
  exit 1
fi
```

### Summary table

| Layer | Article 041 covers? | What this adds | Timing |
|---|---|---|---|
| 1 | ✓ Full | Verbatim 7-step flowchart + diagnostic one-liner | Manual |
| 2 | ✗ Silent | pstree + ss + manual spawn probe | Seconds |
| 3 | ✗ Silent | Automated post-launch gate (bun child + socket) | 12s auto-retry |
