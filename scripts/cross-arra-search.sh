#!/usr/bin/env bash
# Cross-arra search — query both DO and Mac Studio arra instances
# Usage: bash scripts/cross-arra-search.sh "query" [--limit N]
# Closes #13

set -euo pipefail

QUERY="${1:?Usage: cross-arra-search.sh \"query\" [--limit N]}"
LIMIT=10

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

DO_HOST="http://localhost:47778"
MAC_HOST="http://10.20.0.4:47778"
ENCODED_Q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))")

fetch_arra() {
  local label="$1" host="$2"
  local url="${host}/api/search?q=${ENCODED_Q}&limit=${LIMIT}"
  local response
  if ! response=$(curl -s --connect-timeout 5 --max-time 15 "$url" 2>/dev/null); then
    echo "⚠️  [${label}] unreachable (${host})" >&2
    return 1
  fi
  if echo "$response" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('results', []):
    r['_source_arra'] = '${label}'
json.dump(data.get('results', []), sys.stdout)
"
  else
    echo "⚠️  [${label}] invalid response" >&2
    return 1
  fi
}

do_results=$(fetch_arra "do" "$DO_HOST" 2>/dev/null) || do_results="[]"
mac_results=$(fetch_arra "mac" "$MAC_HOST" 2>/dev/null) || mac_results="[]"

do_ok=$([[ "$do_results" != "[]" ]] && echo true || echo false)
mac_ok=$([[ "$mac_results" != "[]" ]] && echo true || echo false)

if [[ "$do_ok" == "false" && "$mac_ok" == "false" ]]; then
  echo "❌ Both arras unreachable or returned no results." >&2
  exit 1
fi

python3 - "$do_results" "$mac_results" <<'PYEOF'
import sys, json

do_results = json.loads(sys.argv[1]) if sys.argv[1] != "[]" else []
mac_results = json.loads(sys.argv[2]) if sys.argv[2] != "[]" else []

seen_ids = set()
merged = []

all_results = do_results + mac_results
all_results.sort(key=lambda r: r.get('score', 0), reverse=True)

for r in all_results:
    chunk_id = r.get('id', '')
    base_id = chunk_id.rsplit('_', 1)[0] if '_' in chunk_id else chunk_id
    if base_id in seen_ids:
        continue
    seen_ids.add(base_id)
    merged.append(r)

if not merged:
    print("No results found.")
    sys.exit(0)

print(f"\n{'='*60}")
print(f" Cross-Arra Search: {len(merged)} results (DO: {len(do_results)}, Mac: {len(mac_results)})")
print(f"{'='*60}\n")

for i, r in enumerate(merged, 1):
    source = r.get('_source_arra', '?')
    score = r.get('score', 0)
    source_file = r.get('source_file', 'unknown')
    content = r.get('content', '')[:200]
    print(f"[{source}] #{i}  score={score:.4f}")
    print(f"  file: {source_file}")
    print(f"  {content}")
    print()
PYEOF
