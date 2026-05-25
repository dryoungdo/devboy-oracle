---
type: learning
topic: Anthropic docs domain map — 3 domains, redirect chain
source: experiment
maturity: solid
retrieval_terms: [anthropic-docs, code-claude-com, platform-claude-com, docs-anthropic-com, redirect]
date: 2026-05-25
sister_lineage: none
gate_hook: "use code.claude.com for CC/SDK, platform.claude.com for API — skip docs.anthropic.com"
---

# Anthropic Docs Domain Map

## 3 Domains (2026-05-25)

| Domain | Content | Status |
|--------|---------|--------|
| code.claude.com | Claude Code + Agent SDK + Skills | Active |
| platform.claude.com | API + Tool Use + Prompt Caching + Extended Thinking | Active |
| docs.anthropic.com | Legacy — 301 redirects to above two | Deprecated |

## Redirect Chain

docs.anthropic.com/en/docs/claude-code/* → code.claude.com/docs/en/*
docs.anthropic.com/en/docs/build-with-claude/* → platform.claude.com/docs/en/docs/build-with-claude/*

## Tip

Fetch llms.txt index first: `code.claude.com/docs/llms.txt`

## Pre-publish ledger
- Sources checked: WebFetch 12+ calls tracing redirect chains
- Claims made: 1 (solid — verified by direct observation)
- Conflicts resolved: none
- Application evidence: articles 054 + 055 successfully fetched from correct domains
- Codex reviewed: no
