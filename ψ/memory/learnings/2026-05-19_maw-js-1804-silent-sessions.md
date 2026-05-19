---
pattern: GLUEBOY Quick-mode upstream-issue dispatches arrive via arra thread (not maw direct) and the issue body should be inlined from the canonical learning, not link to the private repo
date: 2026-05-19
source: rrr: devboy-oracle
type: learning
topic: quick-mode dispatch pipeline + arra-cli thread truncation workaround
maturity: emerging
sister_lineage: none
retrieval_terms: [glueboy-dispatch, quick-mode, arra-thread, upstream-issue, gh-issue-create, maw-js, tmux-pm2-path, public-issue-confirmation]
gate_hook: "AskUserQuestion frames a content-check (\"does this draft read right?\"), not an authority-check (\"may I file?\") — applies on any GLUEBOY-dispatched public-action task where the dispatch already grants authority"
concepts: [dispatch-pipeline, arra-cli, gh-issue, voice-protocol-b, codex-co-review-applicability]
class_msg_id: arra-thread-1-msg-1
issue_artifact: https://github.com/Soul-Brews-Studio/maw-js/issues/1804
---

# Quick-mode upstream-issue dispatch — the 6-step pipeline that worked

## Trigger

GLUEBOY-Mac-Studio dispatched via `arra thread #1 (channel:devboy)` at
2026-05-19 17:46 UTC: "File upstream issue on Soul-Brews-Studio/maw-js
documenting silent `/api/sessions=[]` failure when tmux is missing from
pm2's PATH on Apple Silicon. ~30min Quick-mode."

Evidence file pre-existed in glueboy canonical:
`ψ/memory/learnings/2026-05-19_pm2-maw-path-tmux-not-found-apple-silicon.md`.

## The pipeline (six steps, ~15min real time)

1. **Read the dispatch in full** — `arra-cli thread 1` truncates, so use
   `sqlite3 ~/.arra-oracle-v2/oracle.db "SELECT content FROM forum_messages
   WHERE thread_id=1"` for the full payload. This is the gate-layer
   workaround until arra-cli adds `--full`.
2. **Sync canonical** — `git -C ~/ghq/github.com/dryoungdo/glueboy-oracle pull
   --rebase`. Don't trust local memory; the canonical may have moved.
3. **Read evidence learning** — produces the symptom → root cause → fix
   chain. Don't synthesize from memory; the canonical file is the source of
   truth and already has Captain's wording.
4. **Verify target repo is reachable** — `gh repo view Soul-Brews-Studio/maw-js
   --json name,owner,visibility`. Catches missing auth, deleted repos, wrong
   ownership before drafting.
5. **Draft the body inline** — never link back to the private glueboy
   canonical from a public issue. Inline the symptom block, root cause,
   reproduction steps, workaround, and the three suggested fixes GLUEBOY
   specified. Save to `/tmp/devboy/issue-body.md` so `gh issue create
   --body-file` can read it cleanly (avoids shell-escaping a multi-line
   block).
6. **One content-confirmation pass with Captain**, then file:
   `gh issue create --repo Soul-Brews-Studio/maw-js --title "<title>"
   --body-file /tmp/devboy/issue-body.md`. Verify with `gh issue view <N>
   --json state,body`. Report back via `maw talk-to glueboy --force
   'devboy: filed issue #N: <url>'`.

## Why the confirmation step

Filing a public issue is "visible to others" per agent safety guidance, so
I asked Captain before running `gh issue create`. **This is correct on the
first such dispatch per repo, overkill on subsequent ones.** The gate-hook
in this lesson's frontmatter encodes the right framing: ask about CONTENT
("does this draft read right?"), not AUTHORITY ("may I file at all?") —
because GLUEBOY's dispatch already grants authority. Reframing the
question shaves a turn off Quick-mode budget.

## Three suggested fixes filed in #1804 (verbatim)

1. **Installer PATH injection.** When install/start detects `darwin-arm64`,
   prepend `/opt/homebrew/bin:/opt/homebrew/sbin` to the env passed to pm2
   (or write a pm2 ecosystem file that sets `env.PATH` explicitly).
2. **API handler: surface the error, don't return `[]`.** When the underlying
   tmux invocation fails with `command not found` (or any non-zero exit
   that isn't "no sessions"), `/api/sessions` should return HTTP 500/503
   with `{"error": "tmux not found in PATH", "hint": "PATH=..."}`. Silent
   `[]` makes "tmux missing" indistinguishable from "no sessions running".
3. **Engine startup probe.** On maw-engine boot, run a one-shot `tmux -V`
   and log a loud warning (and optionally refuse to bind the local-sessions
   route) if tmux is unreachable. Catches the misconfiguration once at
   startup instead of per-request.

## Cite-then-claim ledger

- GLUEBOY dispatch (arra thread #1, msg 1): "pm2-spawned maw process inherits
  a stripped PATH that omits /opt/homebrew/bin"
- Evidence file (glueboy canonical, ψ/memory/learnings/2026-05-19_pm2-maw-path-tmux-not-found-apple-silicon.md, line 17): "pm2 never sees those rc files when it forks a process"
- Evidence file line 32: "The `/api/sessions` handler returns `[]` on error rather than 500, hiding the real fault"
- Captain's approval (AskUserQuestion, 2026-05-20 00:50 +07): "Yes, file as drafted"

## Pre-publish ledger

- Sources checked: `arra-cli search` not run this session because evidence
  file was named in the dispatch; canonical pull was sufficient
- Claims made: 4 (the dispatch came via thread not maw — confirmed by inbox
  scan; arra-cli truncates — confirmed by reproducing the cutoff; sqlite is
  the workaround — confirmed by running it; the public-filing gate should
  ask content not authority — emerging, not yet tested on a second filing)
- Conflicts resolved: none found (no prior DEVBOY learning on dispatch
  pipelines; this is the first)
- Application evidence: this session — issue #1804 filed and verified
- Codex reviewed: no — under the 30-LOC standing-order threshold (one issue
  body of 62 lines is documentation, not analysis). Pipeline itself is
  procedural, not interpretive

## Maturity: 🟡 emerging

Gates: redundancy ❌ (single session evidence — need 2 more Quick-mode
dispatches before the pipeline can promote to ✅ solid); application ✅
(verified end-to-end); conflict-resolution ✅ (none to resolve).

## Sister-lineage notes

None. iotboy and mlboy had different dispatch patterns (iotboy got direct
maw pings; mlboy ran on a research-question cadence). DEVBOY's "thread-as-
inbox" pattern is new — emerged from Fleet v3 chain-of-command via GLUEBOY.
