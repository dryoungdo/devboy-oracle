# OFFICEBOY Phase 0 — Verify-Fresh Checklist

**Date**: 2026-05-26
**Method**: WebFetch + WebSearch against vendor docs, compared to arra memory (point-in-time snapshots)
**Parent issue**: dryoungdo/devboy-oracle#12

---

## Purpose

Arra memory is point-in-time. Before OFFICEBOY republishes or builds on existing fleet knowledge, we must verify what's still current and what's changed. This checklist covers 8 topics from the audit.

---

## Freshness Verification Table

| # | Topic | Vendor Doc URL | Checked | Diff vs Arra Notes | Verdict |
|---|-------|---------------|---------|---------------------|---------|
| 1 | Google Workspace + Gemini | [workspace.google.com/solutions/ai](https://workspace.google.com/solutions/ai/) | 2026-05-26 | **STALE** — Arra notes (Feb 2026) reference $20-30/user add-on for Gemini. Current: Gemini included in Business Standard at $18.80 SGD/user/mo. New features: NotebookLM, Studio (workflow automation), Vids (AI video). Enterprise tier now has agent management + data sovereignty. | MUST REFRESH |
| 2 | Notion AI | [notion.com/product/ai](https://www.notion.com/product/ai) | 2026-05-26 | **NEW** — Zero arra coverage. Current state: Notion Agent (executes complex tasks), Custom Agents (automate workflows on schedule), Enterprise Search (cross-app: Slack, Drive, GitHub), AI Meeting Notes, Research Mode, AI Blocks. Custom Agents free through May 3, 2026 → credit-based after May 4. Included in Business/Enterprise plans. | RESEARCH FROM SCRATCH |
| 3 | ChatGPT Team → Business | [chatgpt.com/pricing](https://chatgpt.com/pricing/) | 2026-05-26 | **NEW** — Zero arra coverage. Key finding: "ChatGPT Team" renamed to "ChatGPT Business" (Aug 2025). Price: $25/user/mo (monthly) or $20/user/mo (annual) — reduced $5 in Apr 2026. Features: GPTs, Projects, Apps, Company Knowledge, ChatGPT Agent, Deep Research, Codex. Connectors: Slack, Google Drive, SharePoint, GitHub. Admin: SSO/SAML, SCIM, 2FA, usage analytics. | RESEARCH FROM SCRATCH |
| 4 | Gmail + Gemini AI | [blog.google (Gmail Gemini era)](https://blog.google/products-and-platforms/products/gmail/gmail-is-entering-the-gemini-era/) | 2026-05-26 | **NEW** — Zero arra coverage on email AI. Current: AI Overviews (thread summarization), Help Me Write, Suggested Replies, Proofread, AI Inbox (to-do snapshot). NEW (I/O 2026): Gmail Live — conversational email search via voice/text, rolling out summer 2026 to AI Pro/Ultra. Gemini Spark — 24/7 agentic assistant with Gmail integration (announced Google I/O May 19, 2026). | RESEARCH FROM SCRATCH |
| 5 | Microsoft 365 Copilot | [microsoft.com/microsoft-365/copilot](https://www.microsoft.com/en-us/microsoft-365/copilot) | 2026-05-26 | **NEW** — Zero arra coverage. Current: Work IQ (org data intelligence layer), GPT-5.4 Thinking + GPT-5.3 Instant models, Agent Store + Copilot Studio (custom agents), Notebooks (combine chats/files/meetings), Copilot Cowork + Researcher (Frontier program). Data: never used for training, inherits M365 permissions + sensitivity labels. | RESEARCH FROM SCRATCH |
| 6 | Obsidian + AI | [obsidian.md](https://obsidian.md/) | 2026-05-26 | **NEW** — Zero arra coverage. Current: NO official AI features from Obsidian team. AI comes via community plugins (Smart Connections, Copilot, Text Generator — need separate research). Core: local-first, Markdown, thousands of plugins, Canvas, Graph view, Sync (E2E encrypted), Publish. | RESEARCH FROM SCRATCH — plugin ecosystem needs hands-on testing |
| 7 | Google Workspace Pricing | [workspace.google.com/solutions/ai](https://workspace.google.com/solutions/ai/) | 2026-05-26 | **STALE** — Arra notes (Feb 2026) referenced Workspace AI as separate $20-30/user add-on. Now: Gemini bundled into Business Standard ($18.80 SGD/user/mo annual). Enterprise = contact sales. New tiers: AI Plus, AI Pro, AI Ultra subscription levels for consumer Gemini (separate from Workspace). | MUST REFRESH |
| 8 | Gemini Spark (NEW — not in arra) | [TechCrunch: Gemini Spark](https://techcrunch.com/2026/05/19/google-introduces-gemini-spark-a-24-7-agentic-assistant-with-gmail-integration/) | 2026-05-26 | **BRAND NEW** — Announced Google I/O 2026 (May 19). 24/7 agentic assistant with deep Gmail integration. Not in any arra notes. OFFICEBOY's first article should cover this as it's the most significant recent development. | NEW TOPIC — priority coverage |

---

## Summary by Freshness Status

| Status | Count | Topics |
|--------|-------|--------|
| **MUST REFRESH** | 2 | Google Workspace + Gemini, Workspace Pricing |
| **RESEARCH FROM SCRATCH** | 5 | Notion AI, ChatGPT Business, Gmail Gemini, M365 Copilot, Obsidian AI |
| **NEW TOPIC** | 1 | Gemini Spark (I/O 2026) |

---

## Key Findings for OFFICEBOY

### What Changed Since Arra Snapshots

1. **ChatGPT Team → ChatGPT Business** (renamed Aug 2025, price cut Apr 2026) — any arra notes referencing "ChatGPT Team" are outdated terminology
2. **Google Workspace Gemini pricing restructured** — no longer a separate add-on, bundled into Business Standard
3. **Notion AI evolved significantly** — Custom Agents, Enterprise Search, credit-based pricing starting May 4, 2026
4. **Google I/O 2026 (May 19)** — Gemini Spark, Gmail Live, Gemini 3.5 announced just 7 days ago — freshest possible content opportunity
5. **Microsoft 365 Copilot** — now running GPT-5.4/5.3 models, Agent Store live, Copilot Cowork in Frontier

### Recommendations for OFFICEBOY Article 1

The "Office AI Landscape 2026" article should lead with the Google I/O 2026 announcements (Gemini Spark, Gmail Live) as the hook — these are less than 1 week old. Then map: Google Workspace AI vs Microsoft 365 Copilot vs ChatGPT Business vs Notion AI vs Claude. This positions OFFICEBOY as covering the absolute latest.

---

## Vendor Doc Sources

- [Google Workspace AI](https://workspace.google.com/solutions/ai/)
- [Notion AI](https://www.notion.com/product/ai)
- [ChatGPT Pricing](https://chatgpt.com/pricing/)
- [OpenAI Help: ChatGPT Business](https://help.openai.com/en/articles/8792828-what-is-chatgpt-team)
- [Google Blog: Gmail Gemini Era](https://blog.google/products-and-platforms/products/gmail/gmail-is-entering-the-gemini-era/)
- [TechCrunch: Gemini Spark](https://techcrunch.com/2026/05/19/google-introduces-gemini-spark-a-24-7-agentic-assistant-with-gmail-integration/)
- [Microsoft 365 Copilot](https://www.microsoft.com/en-us/microsoft-365/copilot)
- [Obsidian](https://obsidian.md/)
- [9to5Google: Gemini features by tier](https://9to5google.com/2026/05/25/google-ai-plus-pro-ultra-gemini-features/)
- [Gradually.ai: ChatGPT pricing comparison](https://www.gradually.ai/en/chatgpt-pricing/)
