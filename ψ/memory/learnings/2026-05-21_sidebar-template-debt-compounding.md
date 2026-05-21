---
type: learning
topic: Sidebar O(N²) template debt compounds with each article — fix before 50 articles
source: rrr-session-friction
maturity: solid
retrieval_terms: [sidebar, template, technical-debt, devboy-lab, on-squared]
date: 2026-05-21
gate_hook: "START of next session: check article count. If ≥30, build sidebar.js BEFORE writing any new article. The template fix (docs/js/sidebar.js loading from docs/sidebar.json) takes 30 min and eliminates O(N²) edits permanently."
---

Sidebar sync is O(N²): each new article requires editing ALL existing articles. At 30 articles, 2 sidebar sync rounds = 60 perl batch edits per session. At 50 articles, each new article costs 49 edits — longer than writing the article.

**Evidence**: 4 consecutive retros (2026-05-20 23:54, 2026-05-21 00:00, 2026-05-21 01:01) note this friction without fixing it. Pattern is "note problem → choose to write articles instead → note problem again." This IS the anti-pattern from the guard table: "I'll fix it next session."

**Fix**: `docs/js/sidebar.js` — loads nav structure from `docs/sidebar.json`, injects sidebar HTML into every article via JS. Adding a new article = add one line to sidebar.json. O(1).

**Gate**: START of next session, before any article writing. Article count ≥30 triggers mandatory template build.

**Why this matters**: choosing visible output (articles) over invisible infrastructure (template) is a rationalization disguised as productivity. The fix takes 30 min; the debt costs 20+ min per article written.
