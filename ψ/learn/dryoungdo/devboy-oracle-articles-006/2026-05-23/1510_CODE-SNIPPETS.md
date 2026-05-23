# Discord Plugin — Code Snippets (extracted from Articles 006 + 041 + 2026-05-23 incident)

All blocks copy-paste ready. Substitute `<botname>`, `<v>`, `<CAPTAIN_USER_ID>` as appropriate.

## 1. Initial Bot Setup (Steps 1-6 from Article 041)

```bash
# Step 1: Discord Developer Portal (manual in UI)
# - New Application
# - Bot tab → Reset Token (copy once — only shown once)
# - Privileged Gateway Intents: enable PRESENCE + SERVER MEMBERS + MESSAGE CONTENT
# - OAuth2 → URL Generator → scopes: bot
#   permissions: Send Messages, Read Message History, Add Reactions
# - Invite bot to server via generated URL

# Step 6: User ID lookup
# Discord Settings → Advanced → Developer Mode → right-click user → Copy User ID
# Captain Dr.Do: 721061586910838804
# P'Nat:         691531480689541170
```

## 2. Plugin Enablement (settings.json)

```bash
# Verify enabledPlugins field exists
grep -A2 enabledPlugins ~/.claude/settings.json
```

Required JSON block at the top level of `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "discord@claude-plugins-official": true
  }
}
```

## 3. State Directory + .env + chmod 600

```bash
mkdir -p ~/.claude/channels/discord/<botname>/approved
mkdir -p ~/.claude/channels/discord/<botname>/inbox

echo 'DISCORD_BOT_TOKEN=<paste token>' > ~/.claude/channels/discord/<botname>/.env
chmod 600 ~/.claude/channels/discord/<botname>/.env

ls -la ~/.claude/channels/discord/<botname>/.env
```

`chmod 600` = owner-only read/write. Never commit `.env`.

## 4. access.json Templates

### Minimal (Step 5 from Article 041)

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["<CAPTAIN_USER_ID>"],
  "groups": {},
  "pending": {},
  "mentionPatterns": ["@BOTNAME", "@botname", "@everyone", "@here"],
  "ackReaction": "👀"
}
```

### Full (DEVBOY's 28-channel pattern, extracted from Article 041's example block)

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": [
    "721061586910838804",
    "691531480689541170"
  ],
  "groups": {
    "1501908949354680452": {
      "_name": "esp32-dev",
      "requireMention": false,
      "allowFrom": ["721061586910838804", "691531480689541170"]
    },
    "1501910141455437874": {
      "_name": "machine-learning-model",
      "requireMention": false,
      "allowFrom": ["721061586910838804", "691531480689541170"]
    },
    "1500775333283237970": {
      "_name": "road-to-dev",
      "requireMention": false,
      "allowFrom": ["721061586910838804", "691531480689541170"]
    }
  },
  "pending": {},
  "mentionPatterns": [
    "@everyone", "@here",
    "@all[-_ ]?oracles?",
    "@DEVBOY", "@devboy",
    "<@&1501022865661755392>"
  ],
  "ackReaction": "👀"
}
```

## 5. Session Start Commands

### CORRECT — marketplace-qualified name

```bash
# Continue from previous session
claude --channels plugin:discord@claude-plugins-official --continue

# Fresh start
claude --channels plugin:discord@claude-plugins-official
```

### WRONG — internal MCP id (will silently fail)

```bash
# DO NOT use — plugin loads but inbound dies 100%
claude --channels plugin:discord:discord
```

## 6. Diagnostic One-Liner (Article 041 verbatim)

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

Confirms in one shot: enabledPlugins, bot directories, dmPolicy values, `.env` presence + permissions.

## 7. Restart-After-Config-Change Procedure

```bash
# 1. Exit current session (Ctrl+D or /bye)

# 2. Verify config
cat ~/.claude/channels/discord/<botname>/access.json | grep dmPolicy

# 3. Restart with --channels flag
claude --channels plugin:discord@claude-plugins-official --continue
```

## 8. Live Diagnostic Extensions (NOT in source articles — derived from 2026-05-23 incident)

These probes cover the failure mode neither Article 006 nor 041 documents: **listener alive but bun MCP child never spawned**.

### 8a. Process tree — must show bun discord child

```bash
LISTENER_PID=$(pgrep -f "claude.*channels plugin:discord" | head -1)
pstree -spnal "$LISTENER_PID"
```

Expected: a `bun … server.ts` child under the listener PID. If missing → MCP spawn failed.

### 8b. Gateway socket — must show outbound 443 to gateway.discord.gg

```bash
ss -tnp | grep -iE "discord|gateway.discord.gg"
# or
lsof -i -p "$LISTENER_PID" 2>/dev/null | grep TCP
```

Expected: an ESTABLISHED TCP connection on port 443 with the bun process as owner.

### 8c. Manual server.ts spawn probe (rules out plugin/token/Discord in 3s)

```bash
timeout 8 env DISCORD_BOT_TOKEN=$(grep -oP 'DISCORD_BOT_TOKEN=\K.+' ~/.claude/channels/discord/<bot>/.env) \
  bun --cwd ~/.claude/plugins/cache/claude-plugins-official/discord/<v>/ run start 2>&1 | head -30
```

Expected within 3s: `discord channel: gateway connected as <BotName>#XXXX`.
- ✅ Success → plugin code + token + Discord intents all healthy. Root cause = Claude's plugin loader skipped MCP spawn. Restart the listener.
- ❌ Timeout/error → token invalid OR Discord intents missing OR server.ts bug. Check `.env`, rotate token, verify Developer Portal intents.

## 9. Restart Plan (2026-05-23 — needs Captain seal)

```bash
# 1. Clean stale .in_use/ locks (safe — advisory only)
rm ~/.claude/plugins/cache/claude-plugins-official/discord/0.0.4/.in_use/<dead-pid>

# 2. Kill broken listener (Captain seal required — not a dev server)
kill <listener-pid>

# 3. Relaunch via canonical script
bash /home/drdo/Code/github.com/dryoungdo/devboy-oracle/start.sh

# 4. Verify within 30s
sleep 20
pstree -spnal $(pgrep -f "claude.*channels plugin:discord" | head -1) | grep bun
ss -tnp | grep -i discord
```
