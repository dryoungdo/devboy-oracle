---
type: learning
topic: Team-Tile Code — bootstrap.ts review, maw tile commands, member spec
source: pnat-gist
maturity: emerging
retrieval_terms: [bootstrap-ts, findClaudeBin, parseMember, buildClaudeCmd, shellQuote, bun-script]
date: 2026-05-21
---

# Code Snippets: Team-Tile Bootstrap

## bootstrap.ts Key Functions

### findClaudeBin() — locate claude.exe
```typescript
function findClaudeBin(): string {
  const candidates = [
    `${homedir()}/.nvm/versions/node/v24.15.0/lib/.../claude.exe`,
    `/usr/local/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`,
    `${homedir()}/.bun/install/global/.../claude.exe`,
  ];
  for (const c of candidates) if (existsSync(c)) return c;
  return "claude";  // fallback to PATH
}
```
**Issue**: Hardcodes NVM v24.15.0. Should glob `~/.nvm/versions/node/*/` or prefer `which claude`.

### parseMember() — parse member spec
```typescript
// Input: "reader-a@/opt/Code/repo:magenta"
// Output: { role: "reader-a", cwd: "/opt/Code/repo", color: "magenta" }
function parseMember(spec: string, defaultColorIdx: number): Member {
  const atIdx = spec.indexOf("@");
  const role = spec.slice(0, atIdx);
  // ... split rest by colon for cwd:color
}
```

### shellQuote() — escape for shell
```typescript
function shellQuote(s: string): string {
  if (/^[A-Za-z0-9_@.\-\/:]+$/.test(s)) return s;
  return `'${s.replace(/'/g, "'\\''")}'`;
}
```
**Note**: Allowlist regex is incomplete (misses `~`, `$`, backtick) but fallback single-quote path is correct.

### buildClaudeCmd() — construct 7-flag invocation
```typescript
function buildClaudeCmd(member, team, parent, model, claudeBin): string {
  const env = `CLAUDECODE=1 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`;
  const args = [
    claudeBin,
    "--agent-id",   `${member.role}@${team}`,
    "--agent-name", member.role,
    // ... 5 more flags
  ].map(shellQuote).join(" ");
  return `env ${env} ${args}`;
}
```

## Code Review Summary

| Issue | Severity | Detail |
|-------|----------|--------|
| `--dangerously-skip-permissions` hardcoded | CRITICAL | Should be opt-in via flag |
| No partial-failure rollback | HIGH | Panes 1-2 orphaned if pane 3 fails |
| findClaudeBin hardcodes NVM version | MEDIUM | Breaks on Node version bump |
| @ts-nocheck unnecessary | MEDIUM | Code is valid TypeScript |
| sleep-based readiness | MEDIUM | Should poll for process start |
| UUID regex rejects uppercase | LOW | Use case-insensitive match |

## Complete Spawn Command (copy-paste ready)

```bash
# Post maw-js #1837 (single verb)
maw tile 1 \
  --path /home/drdo/Code/github.com/dryoungdo/devboy-oracle \
  --cmd "env CLAUDECODE=1 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
    claude.exe \
    --agent-id researcher@my-team \
    --agent-name researcher \
    --team-name my-team \
    --agent-color cyan \
    --parent-session-id $CLAUDE_SESSION_ID \
    --model sonnet \
    --dangerously-skip-permissions"
```

## 3 Skill Definitions

| Skill | Purpose | Args | Auto-cleanup |
|-------|---------|------|-------------|
| `/team-tile-spawn` | Production verb | `<team> <role@cwd:color:#mission>...` | No |
| `/team-tile-demo` | Educational 12-step walkthrough | `[--quick\|--narrate]` | No |
| `/full-auto-long-demo` | Self-running end-to-end | None | Yes |

## Install (from gist)

```bash
gh gist clone 1ffec5896ece7b911a8ab9134df99ae1 ~/tmp/team-tile-gist
mkdir -p ~/.claude/skills/{team-tile-spawn/scripts,team-tile-demo,full-auto-long-demo}
cp ~/tmp/team-tile-gist/team-tile-spawn.SKILL.md ~/.claude/skills/team-tile-spawn/SKILL.md
cp ~/tmp/team-tile-gist/bootstrap.ts ~/.claude/skills/team-tile-spawn/scripts/bootstrap.ts
cp ~/tmp/team-tile-gist/team-tile-demo.SKILL.md ~/.claude/skills/team-tile-demo/SKILL.md
cp ~/tmp/team-tile-gist/full-auto-long-demo.SKILL.md ~/.claude/skills/full-auto-long-demo/SKILL.md
```
