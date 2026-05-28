#!/usr/bin/env bash
# install-sop-qa-hook.sh — Register the SOP-QA gate in each BOY's settings.local.json
# ---------------------------------------------------------------------------
# Per #61 decision (Captain 2026-05-25): use Option D — per-machine
# settings.local.json for hook registration. This script is the one-time
# install per machine; run it once on each machine that hosts BOY repos.
#
# Why settings.local.json (not committed settings.json):
# - `.claude/settings.local.json` is the per-machine layer (per shared-claude.md
#   §Configuration Layers: "local convenience allowlist only; never strategic
#   truth"). Hook absolute path is machine-specific — Mac Studio has
#   /Users/dr.dosmacstudio/..., DO has /root/..., MBA has /Users/dryoungdo/...
# - Committed settings.json stays portable across machines
# - settings.local.json is gitignored by Claude Code convention
#
# Usage:
#   bash scripts/install-sop-qa-hook.sh           # install in all configured BOYs
#   bash scripts/install-sop-qa-hook.sh --dry-run # show what would change
#   bash scripts/install-sop-qa-hook.sh --target <path>  # one specific BOY repo
#
# Idempotent: re-running with no changes is a no-op.
# ---------------------------------------------------------------------------

set -u

HOOK_MATCHER='Edit|Write|Bash|mcp__plugin_discord_discord__reply'

DEFAULT_FLEET=(
  "${GLUEBOY_FLEET_FORGEBOY_PATH:-$HOME/ghq/github.com/dryoungdo/forgeboy-oracle}"
  "${GLUEBOY_FLEET_LEDGERBOY_PATH:-$HOME/ghq/github.com/dryoungdo/ledgerboy-oracle}"
  "${GLUEBOY_FLEET_CHATBOY_PATH:-$HOME/ghq/github.com/dryoungdo/chatboy-oracle}"
  "${GLUEBOY_FLEET_COACHBOY_PATH:-$HOME/ghq/github.com/dryoungdo/coachboy-oracle}"
  "${GLUEBOY_FLEET_DEVBOY_PATH:-$HOME/ghq/github.com/dryoungdo/devboy-oracle}"
)

DRY_RUN=0
EXPLICIT_TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --target)
      if [[ $# -lt 2 ]]; then
        printf 'ERROR: --target requires a path\n' >&2
        exit 2
      fi
      EXPLICIT_TARGETS+=("$2")
      shift 2
      ;;
    -h|--help)
      cat <<EOF
Usage: bash scripts/install-sop-qa-hook.sh [OPTIONS]

Register the SOP-QA gate hook in each BOY's .claude/settings.local.json.

Options:
  --dry-run            Show what would change, no writes
  --target <path>      Install in one specific BOY repo (repeatable)
  -h, --help           Show this help

Idempotent. Skips silently when a BOY repo isn't cloned locally.
EOF
      exit 0
      ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ${#EXPLICIT_TARGETS[@]} -gt 0 ]]; then
  FLEET=("${EXPLICIT_TARGETS[@]}")
else
  FLEET=("${DEFAULT_FLEET[@]}")
fi

printf '==> Hook path: target-local scripts/hooks/sop-qa-gate.sh\n'
printf '==> Targets: %s\n' "${#FLEET[@]}"
[[ "$DRY_RUN" -eq 1 ]] && printf '==> DRY-RUN mode\n'
printf '\n'

OK_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

for boy_root in "${FLEET[@]}"; do
  boy_name="$(basename "$boy_root")"
  printf '──── %s ────\n' "$boy_name"

  if [[ ! -d "$boy_root" ]]; then
    printf '   ⚠ skip — not cloned at %s\n' "$boy_root"
    SKIP_COUNT=$((SKIP_COUNT+1))
    continue
  fi
  boy_root="$(cd "$boy_root" && pwd)"

  SETTINGS_LOCAL="$boy_root/.claude/settings.local.json"
  SETTINGS_DIR="$(dirname "$SETTINGS_LOCAL")"
  HOOK_PATH="$boy_root/scripts/hooks/sop-qa-gate.sh"

  if [[ ! -f "$HOOK_PATH" ]]; then
    printf '   ⚠ skip — no local hook script at %s (run fleet-propagate-shared.sh first)\n' "$HOOK_PATH"
    SKIP_COUNT=$((SKIP_COUNT+1))
    continue
  fi

  if [[ ! -d "$SETTINGS_DIR" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '   would mkdir: %s\n' "$SETTINGS_DIR"
    else
      mkdir -p "$SETTINGS_DIR"
    fi
  fi

python3 - "$SETTINGS_LOCAL" "$HOOK_PATH" "$DRY_RUN" "$HOOK_MATCHER" <<'PY'
import json, sys, os, shlex

settings_path = sys.argv[1]
hook_path = sys.argv[2]
dry_run = sys.argv[3] == '1'
hook_matcher = sys.argv[4]
desired_command = f'bash {shlex.quote(hook_path)}'
desired_timeout = 8

if os.path.exists(settings_path):
    try:
        with open(settings_path) as f:
            settings = json.load(f)
    except json.JSONDecodeError as e:
        print(f'   X invalid JSON in {settings_path} -- manual fix required: {e}')
        sys.exit(1)
else:
    settings = {}
    print('   (no existing settings.local.json -- will create)')

if 'hooks' not in settings:
    settings['hooks'] = {}
if 'PreToolUse' not in settings['hooks']:
    settings['hooks']['PreToolUse'] = []

existing_entry = None
existing_hook = None
for entry in settings['hooks']['PreToolUse']:
    if isinstance(entry, dict):
        for h in entry.get('hooks', []):
            if isinstance(h, dict) and 'sop-qa-gate.sh' in h.get('command', ''):
                existing_entry = entry
                existing_hook = h
                break
    if existing_entry is not None:
        break

if existing_entry is not None:
    changes = []
    if existing_entry.get('matcher') != hook_matcher:
        changes.append(f'matcher: {existing_entry.get("matcher")} -> {hook_matcher}')
    if existing_hook is not None and existing_hook.get('command') != desired_command:
        changes.append(f'command: {existing_hook.get("command")} -> {desired_command}')
    if existing_hook is not None and existing_hook.get('timeout') != desired_timeout:
        changes.append(f'timeout: {existing_hook.get("timeout")} -> {desired_timeout}')

    if changes:
        if dry_run:
            print('   would update existing SOP-QA hook:')
            for change in changes:
                print(f'     - {change}')
            sys.exit(0)
        existing_entry['matcher'] = hook_matcher
        existing_hook['command'] = desired_command
        existing_hook['timeout'] = desired_timeout
        with open(settings_path, 'w') as f:
            json.dump(settings, f, indent=2)
            f.write('\n')
        print(f'   ~ updated existing SOP-QA hook in {settings_path}')
        sys.exit(0)
    print('   = already registered, no change')
    sys.exit(0)

new_entry = {
    'matcher': hook_matcher,
    'hooks': [
        {
            'type': 'command',
            'command': desired_command,
            'timeout': desired_timeout
        }
    ]
}
settings['hooks']['PreToolUse'].append(new_entry)

if dry_run:
    print(f'   would add PreToolUse hook entry (matcher: {hook_matcher})')
    print('   would write:', settings_path)
    sys.exit(0)

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
print(f'   + registered hook in {settings_path}')
PY

  rc=$?
  if [[ $rc -eq 0 ]]; then
    OK_COUNT=$((OK_COUNT+1))
  else
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
done

printf '\n==== Summary ====\n'
printf '  registered: %s\n' "$OK_COUNT"
printf '  skipped:    %s\n' "$SKIP_COUNT"
printf '  failed:     %s\n' "$FAIL_COUNT"

[[ "$DRY_RUN" -eq 1 ]] && printf '\n(dry-run -- no files written)\n'

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
