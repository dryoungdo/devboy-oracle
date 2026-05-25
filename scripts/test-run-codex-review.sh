#!/usr/bin/env bash
# test-run-codex-review.sh - focused tests for scripts/run-codex-review.sh.

set -u

ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
WRAPPER="${ROOT}/scripts/run-codex-review.sh"
TMP_ROOT="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
  [ -d "$TMP_ROOT" ] && rm -R "$TMP_ROOT" 2>/dev/null
}
trap cleanup EXIT

record_pass() {
  PASS=$((PASS + 1))
  printf 'ok - %s\n' "$1"
}

record_fail() {
  FAIL=$((FAIL + 1))
  printf 'not ok - %s\n' "$1" >&2
}

assert_eq() {
  local want="$1"
  local got="$2"
  local label="$3"
  if [ "$want" = "$got" ]; then
    record_pass "$label"
  else
    record_fail "$label (want=$want got=$got)"
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE -- "$pattern" "$file" 2>/dev/null; then
    record_pass "$label"
  else
    record_fail "$label"
    [ -f "$file" ] && sed 's/^/  | /' "$file" >&2
  fi
}

make_fake_codex() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "${bin_dir}/codex" <<'EOF'
#!/usr/bin/env bash
set -u

printf '%s\n' "$*" >> "${FAKE_CODEX_ARGS_LOG:?}"
printf '%s\n' "${CODEX_HOME:-}" >> "${FAKE_CODEX_HOME_LOG:?}"
if [ -n "${CODEX_HOME:-}" ] && [ -f "${CODEX_HOME}/review.config.toml" ]; then
  printf 'review.config.toml present\n' >> "${FAKE_CODEX_HOME_LOG:?}"
fi

case "${FAKE_CODEX_MODE:-clean}" in
  clean)
    printf 'CLEAN: no actionable findings in the reviewed scope.\n'
    exit 0
    ;;
  findings)
    printf -- '- [P2] scripts/example.sh:12 - real finding for test\n'
    exit 0
    ;;
  fatal)
    printf 'fatal codex error\n' >&2
    exit 7
    ;;
  stagnant)
    printf 'starting review\n'
    sleep 20
    printf 'late output\n'
    exit 0
    ;;
  *)
    printf 'unknown fake mode\n' >&2
    exit 9
    ;;
esac
EOF
  chmod +x "${bin_dir}/codex"
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  printf 'hello\n' > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q -m init
}

run_wrapper() {
  local mode="$1"
  local out_file="$2"
  local home_dir="$3"
  local repo="$4"
  shift 4

  FAKE_CODEX_MODE="$mode" \
  FAKE_CODEX_ARGS_LOG="${TMP_ROOT}/args.log" \
  FAKE_CODEX_HOME_LOG="${TMP_ROOT}/home.log" \
  HOME="$home_dir" \
  PATH="${TMP_ROOT}/bin:$PATH" \
    bash "$WRAPPER" --repo "$repo" --output "$out_file" --tail-interval 1 --no-tail "$@"
  return $?
}

make_fake_codex "${TMP_ROOT}/bin"
REPO="${TMP_ROOT}/repo"
make_repo "$REPO"

# Clean review returns 0 and logs clean.
HOME1="${TMP_ROOT}/home-clean"
mkdir -p "$HOME1/.codex" "$HOME1/.claude"
OUT1="${TMP_ROOT}/clean.out"
run_wrapper clean "$OUT1" "$HOME1" "$REPO" --uncommitted --max-runtime 5 --stagnation-seconds 3
RC=$?
assert_eq 0 "$RC" "clean review exits 0"
assert_file_contains "$OUT1" 'CLEAN: no actionable findings' "clean output captured"
assert_file_contains "$HOME1/.claude/.codex-review/runs.log" '"status":"clean"' "clean run logged"

# Findings review returns 1.
HOME2="${TMP_ROOT}/home-findings"
mkdir -p "$HOME2/.codex" "$HOME2/.claude"
OUT2="${TMP_ROOT}/findings.out"
run_wrapper findings "$OUT2" "$HOME2" "$REPO" --uncommitted --max-runtime 5 --stagnation-seconds 3
RC=$?
assert_eq 1 "$RC" "findings review exits 1"
assert_file_contains "$OUT2" '\[P2\]' "findings output captured"
assert_file_contains "$HOME2/.claude/.codex-review/runs.log" '"status":"findings"' "findings run logged"

# Fatal non-finding Codex failure returns 2.
HOME3="${TMP_ROOT}/home-fatal"
mkdir -p "$HOME3/.codex" "$HOME3/.claude"
OUT3="${TMP_ROOT}/fatal.out"
run_wrapper fatal "$OUT3" "$HOME3" "$REPO" --uncommitted --max-runtime 5 --stagnation-seconds 3
RC=$?
assert_eq 2 "$RC" "fatal review exits 2"
assert_file_contains "$HOME3/.claude/.codex-review/runs.log" '"status":"failed"' "fatal run logged"

# Stagnant output is killed and returns 2.
HOME4="${TMP_ROOT}/home-stagnant"
mkdir -p "$HOME4/.codex" "$HOME4/.claude"
OUT4="${TMP_ROOT}/stagnant.out"
run_wrapper stagnant "$OUT4" "$HOME4" "$REPO" --uncommitted --max-runtime 10 --stagnation-seconds 2
RC=$?
assert_eq 2 "$RC" "stagnant review exits 2"
assert_file_contains "$HOME4/.claude/.codex-review/runs.log" '"status":"killed"' "stagnant run logged"

# ~/.codex/profiles/review.toml is loaded through temporary CODEX_HOME + --profile-v2 review.
HOME5="${TMP_ROOT}/home-profile"
mkdir -p "$HOME5/.codex/profiles" "$HOME5/.claude"
printf 'model = "gpt-5.5"\n' > "$HOME5/.codex/config.toml"
printf 'model_reasoning_effort = "xhigh"\n' > "$HOME5/.codex/profiles/review.toml"
: > "${TMP_ROOT}/args.log"
: > "${TMP_ROOT}/home.log"
OUT5="${TMP_ROOT}/profile.out"
run_wrapper clean "$OUT5" "$HOME5" "$REPO" --uncommitted --max-runtime 5 --stagnation-seconds 3
RC=$?
assert_eq 0 "$RC" "profile clean review exits 0"
assert_file_contains "${TMP_ROOT}/args.log" '--profile-v2 review review --uncommitted' "profile-v2 review args used"
assert_file_contains "${TMP_ROOT}/home.log" 'review\.config\.toml present' "profiles/review.toml copied into temp CODEX_HOME"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
