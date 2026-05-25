#!/usr/bin/env bash
# restore-codex-config.sh - restore the local arra-oracle MCP registration
# after the Codex MCP stdio hang workaround is no longer needed.

set -u

CONFIG="${HOME}/.codex/config.toml"
DRY_RUN=0
SKIP_TESTS=0

usage() {
  cat <<'EOF'
Usage: scripts/restore-codex-config.sh [OPTIONS]

Restores the local ~/.codex/config.toml arra-oracle MCP block by:
  1. Running scripts/test-codex-mcp.sh before the edit.
  2. Backing up the config to config.toml.bak-YYYYMMDD-HHMMSS-pre-arra-restore.
  3. Uncommenting the current ARRA-ORACLE DISABLED block if present.
  4. Flipping disabled = true to disabled = false in an active block if present.
  5. Running scripts/test-codex-mcp.sh after the edit.

Options:
  --config FILE   Config path to restore (default: ~/.codex/config.toml)
  --dry-run       Show the transformed config path, do not replace the original
  --skip-tests    Do not run scripts/test-codex-mcp.sh
  -h, --help      Show this help
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --config)
      [ "$#" -ge 2 ] || die "--config requires FILE"
      CONFIG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[ -f "$CONFIG" ] || die "config not found: $CONFIG"

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
TEST_SCRIPT="${SCRIPT_DIR}/test-codex-mcp.sh"
CONFIG_DIR="$(dirname "$CONFIG")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${CONFIG}.bak-${TIMESTAMP}-pre-arra-restore"
TMP="$(mktemp)"

cleanup() {
  [ -f "$TMP" ] && rm -f "$TMP"
}
trap cleanup EXIT

run_test() {
  local label="$1"
  if [ "$SKIP_TESTS" -eq 1 ]; then
    printf '[restore-codex-config] skip %s test (--skip-tests)\n' "$label"
    return 0
  fi
  if [ ! -f "$TEST_SCRIPT" ]; then
    printf '[restore-codex-config] skip %s test (missing %s)\n' "$label" "$TEST_SCRIPT"
    return 0
  fi
  printf '[restore-codex-config] %s test:\n' "$label"
  env CODEX_CONFIG="$CONFIG" CODEX_HOME="$CONFIG_DIR" bash "$TEST_SCRIPT"
}

run_test "before"

awk -v backup="$BACKUP" '
  BEGIN {
    in_disabled_comment = 0
    in_arra_table = 0
    in_arra_disabled_table = 0
    restored_comment_printed = 0
  }

  /^# ARRA-ORACLE DISABLED/ {
    print "# ARRA-ORACLE RESTORED by scripts/restore-codex-config.sh; backup: " backup
    restored_comment_printed = 1
    next
  }

  /^#\[mcp_servers\.arra-oracle\]$/ {
    print "[mcp_servers.arra-oracle]"
    in_disabled_comment = 1
    in_arra_table = 1
    next
  }

  /^#\[mcp_servers\.arra-oracle\.env\]$/ {
    print "[mcp_servers.arra-oracle.env]"
    in_disabled_comment = 1
    in_arra_table = 0
    next
  }

  in_disabled_comment && /^# .*TUI/ {
    in_disabled_comment = 0
    in_arra_table = 0
    print
    next
  }

  in_disabled_comment {
    line = $0
    if (line == "#") {
      print ""
      next
    }
    sub(/^#+/, "", line)
    if (line ~ /^disabled = true/) {
      print "disabled = false"
      next
    }
    print line
    next
  }

  /^\[mcp_servers\.arra-oracle\]$/ {
    in_arra_table = 1
    in_arra_disabled_table = 0
    print
    next
  }

  /^\[mcp_servers\.arra-oracle\.env\]$/ {
    in_arra_table = 0
    in_arra_disabled_table = 0
    print
    next
  }

  /^\[/ && $0 !~ /^\[mcp_servers\.arra-oracle/ {
    in_arra_table = 0
    in_arra_disabled_table = 0
    print
    next
  }

  in_arra_table && /^disabled = true/ {
    print "disabled = false"
    next
  }

  /^\[mcp_servers\.arra-oracle\.disabled\]$/ {
    print
    in_arra_table = 0
    in_arra_disabled_table = 1
    next
  }

  in_arra_disabled_table && /^disabled = true/ {
    print "disabled = false"
    next
  }

  { print }

  END {
    if (!restored_comment_printed) {
      # No-op; active disabled=true blocks are still handled above.
    }
  }
' "$CONFIG" > "$TMP"

if cmp -s "$CONFIG" "$TMP"; then
  printf '[restore-codex-config] no change needed: %s\n' "$CONFIG"
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf '[restore-codex-config] dry-run transformed config: %s\n' "$TMP"
  diff -u "$CONFIG" "$TMP" || true
  trap - EXIT
  exit 0
fi

cp "$CONFIG" "$BACKUP" || die "failed to write backup: $BACKUP"
cp "$TMP" "$CONFIG" || die "failed to update config: $CONFIG"
printf '[restore-codex-config] backup: %s\n' "$BACKUP"
printf '[restore-codex-config] restored: %s\n' "$CONFIG"

if ! run_test "after"; then
  printf '[restore-codex-config] after-test failed; restoring backup\n' >&2
  cp "$BACKUP" "$CONFIG"
  exit 1
fi

printf '[restore-codex-config] done\n'
