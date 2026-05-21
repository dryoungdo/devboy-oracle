---
type: learning
topic: HTML article publish requires post-push browser/fetch verification
source: experience
maturity: emerging
retrieval_terms: [article-verification, html-publish, website-qa, post-push-check, devboy-lab]
date: 2026-05-21
gate_hook: "pre-claim check: WebFetch live URL before telling Captain 'it's live'"
---

# Article Publish Verification Gate

## Pattern

When publishing HTML articles to DEVBOY Lab (docs/articles/*.html):
1. Write HTML following existing template
2. Update docs/home.html TOC
3. Commit + push
4. **GATE: WebFetch the live GitHub Pages URL** — verify it loads, no 404, no auth redirect loop
5. Only THEN report "it's live" to Captain

## Why

Article 042 (maw-js Advanced Guide, 435 lines) was pushed without any rendering verification. The template uses auth.js which can redirect, and CSS classes must match style.css. A broken article on the live site is visible to anyone with the URL.

## Evidence

- Commit `1f49033` pushed 2026-05-21 without browser check
- Live URL: https://dryoungdo.github.io/devboy-oracle/articles/042-maw-js-advanced-guide.html
- No verification performed before sending URL to Captain

## Gate Layer (not memory layer)

Pre-claim check: before any message containing a live article URL, WebFetch that URL first. If it returns non-200 or contains error indicators, fix before claiming success.

## Pre-publish ledger
- Sources checked: direct experience (article 042 publish flow)
- Claims made: 1 (emerging — no repeat verification yet)
- Conflicts resolved: none found
- Application evidence: N/A — lesson derived from skipped step
- Codex reviewed: no
