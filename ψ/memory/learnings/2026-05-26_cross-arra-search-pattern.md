---
type: learning
topic: Cross-arra search pattern — querying multiple arra instances and merging results
source: experiment
maturity: solid
retrieval_terms: [cross-arra, multi-arra, arra-search, arra-federation, cross-search]
date: 2026-05-26
sister_lineage: none
gate_hook: scripts/cross-arra-search.sh (tested with real queries + fail-soft)
---

# Cross-Arra Search Pattern

**Pattern**: Query multiple arra-oracle instances (different machines) and merge results with dedup.

## Endpoints

- DO arra: `http://localhost:47778/api/search?q=QUERY&limit=N`
- Mac Studio arra: `http://10.20.0.4:47778/api/search?q=QUERY&limit=N`
- API path is `/api/search` (NOT `/search` — that returns 404/NOT_FOUND)
- DO has 829 chunks, Mac Studio has 885 chunks (as of 2026-05-26)

## Merge Strategy

1. Fetch both in parallel (curl with --connect-timeout 5)
2. Tag each result with `_source_arra` = "do" or "mac"
3. Merge all results, sort by score descending
4. Dedupe by base chunk_id (strip trailing `_N` suffix)
5. Display with `[do]` / `[mac]` prefix

## Fail-Soft

If one arra is unreachable, return results from the other with a warning. Only fail if BOTH are down.

## Implementation

`scripts/cross-arra-search.sh` in dryoungdo/devboy-oracle (PR #16, merged at 31cd2a0).

## Pre-publish ledger
- Sources checked: live testing against both arra endpoints
- Claims made: 3 (all solid — verified by running script)
- Conflicts resolved: none found
- Application evidence: script tested with "claude code cowork" (real results) + unreachable host (fail-soft works)
- Codex reviewed: no (74 lines bash, sub-threshold)
