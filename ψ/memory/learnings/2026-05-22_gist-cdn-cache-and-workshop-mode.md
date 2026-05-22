---
type: learning
topic: GitHub gist raw URL caching + workshop proactive mode
source: experiment
maturity: solid
retrieval_terms: [gist-raw-url, cdn-cache, gh-gist-view, workshop-mode, proactive-install]
date: 2026-05-22
gate_hook: "pre-install check: grep for expected feature in installed files before declaring success"
---

# GitHub Gist Raw URL Caching + Workshop Mode

## Lesson 1: Gist raw URLs cache aggressively

`curl -sSL https://gist.githubusercontent.com/.../raw/<file>` serves CDN-cached version, NOT latest revision.

**Fix**: Use `gh gist view <id> -f <file>` to get latest, then pipe to bash:
```bash
gh gist view <gist-id> -f install.sh > /tmp/install.sh && bash /tmp/install.sh
```

**Gate**: After any gist-based install, verify expected features exist:
```bash
grep "expected-flag" ~/.maw/plugins/<name>/plugin.json
```

## Lesson 2: Workshop mode = proactive

When Captain says "follow P'Nat's instructions" → act on class directives immediately. Don't wait for per-action authorization. The hesitation cost ~5 minutes in the maw team-agent flow test.

**Scope**: Workshop/class context only. Production actions still require explicit Captain seal per Voice Protocol B.
