# OFFICEBOY Phase 0 — Knowledge Audit Report

**Date**: 2026-05-26
**Queried**: DO arra (localhost:47778, 829 chunks) + Mac Studio arra (10.20.0.4:47778, 885 chunks)
**Tool**: `scripts/cross-arra-search.sh` (cross-arra search, --limit 5 per source)
**Parent issue**: dryoungdo/devboy-oracle#12

---

## Query Results

### 1. "claude code cowork"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/retrospectives/2026-03/13/15.14_youtube-claude-cowork-html-tutorial.md | 2026-03-13 | 1.0000 |
| [mac] | ψ/memory/retrospectives/2026-03/13/10.16_fix-cowork-virtiofs-permanent.md | 2026-03-13 | 0.9959 |
| [mac] | ψ/memory/retrospectives/2026-03/07/12.11_gcp-project-ownership-for-gm-autonomy.md | 2026-03-07 | 0.9956 |
| [do] | ψ/memory/learnings/glueboy__2026-03-13_claude-cowork-virtiofsplan9-permanent-fix-on-wind.md | 2026-03-13 | 0.1385 |
| [do] | ψ/memory/learnings/CoachBoy__2026-04-08_claude-code-v2194-effort-high-default.md | 2026-04-08 | 0.1324 |

**เราขาดอะไร**:
- Cowork setup guide for beginners (non-VirtioFS-specific)
- Claude Code + Google Workspace integration patterns (MCP-based)
- Cowork session management best practices (multi-window, project switching)
- Claude Code CLI tips & tricks for office workers (non-dev audience)

---

### 2. "google sheets ai"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/retrospectives/2026-04/04/15.37_google-sheets-formatting-mcp-upgrade.md | 2026-04-04 | 0.9965 |
| [mac] | ψ/memory/retrospectives/2026-04/17/17.10_sakaeo_invite_sheet.md | 2026-04-17 | 0.9965 |
| [mac] | ψ/memory/retrospectives/2026-03/06/18.54_gm-google-sheets-api-setup.md | 2026-03-06 | 0.9962 |
| [do] | ψ/memory/learnings/captain__2026-04-17_sheets-iterative-discipline.md | 2026-04-17 | 0.1680 |
| [do] | ψ/memory/retrospectives/forgeboy__2026-03__21__19.49_data-center-v6-and-sheets-portal.md | 2026-03-21 | 0.1668 |

**เราขาดอะไร**:
- Gemini IN Sheets (native AI features: Help me organize, Smart Fill, formula suggestions)
- Apps Script + AI patterns (Gemini API from Apps Script)
- Sheets as data hub for AI pipelines (structured data → AI analysis)
- Comparison: native Gemini vs MCP-based Sheets AI

---

### 3. "gemini workspace"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/learnings/2026-02-26_workspace-ai-roi-thai-salary.md | 2026-02-26 | 1.0000 |
| [mac] | ψ/memory/retrospectives/2026-02/26/00.50_workspace-ai-playbook.md | 2026-02-26 | 1.0000 |
| [do] | ψ/memory/retrospectives/glueboy__2026-02__26__00.50_workspace-ai-playbook.md | 2026-02-26 | 0.2653 |
| [do] | ψ/memory/learnings/glueboy__2026-02-26_workspace-ai-roi-thai-salary.md | 2026-02-26 | 0.2512 |

**เราขาดอะไร**:
- Gemini in Docs (writing assist, summarization, drafting)
- Gemini in Slides (auto-generate slides from prompts)
- Gemini in Meet (note-taking, summarization)
- Updated pricing/feature comparison (data is from Feb 2026 — 3 months old)
- Workspace add-ons/extensions with AI (third-party ecosystem)

---

### 4. "chatgpt team office"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/retrospectives/2026-02/18/00.57_townhall-2026-slides-creation.md | 2026-02-18 | 0.9958 |
| [mac] | ψ/memory/retrospectives/2026-03/24/07.52_chatboy-line-intelligence.md | 2026-03-24 | 0.9957 |
| [mac] | ψ/memory/learnings/2026-02-18_multi-ai-orchestration-for-creative-production.md | 2026-02-18 | 0.9956 |

**เราขาดอะไร**:
- ChatGPT Team plan features & pricing (dedicated workspace, admin controls)
- Custom GPTs for office automation (GPT Builder, Actions, knowledge upload)
- ChatGPT + Microsoft 365 integration patterns
- ChatGPT vs Claude for office tasks (comparison article)
- GPT Store / marketplace for office productivity

**Gap severity: HIGH** — almost no direct coverage. Results are tangentially related (townhall slides, multi-AI orchestration).

---

### 5. "notion ai integration"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/learnings/2026-01-31_confidence-scoring-for-ai-parsed-inputs.md | 2026-01-31 | 0.9957 |
| [mac] | ψ/memory/retrospectives/2026-02/11/16.17_yc-roadmap-sort-goals-ai.md | 2026-02-11 | 0.9957 |

**เราขาดอะไร**:
- Notion AI features (Q&A, summarize, autofill, write with AI)
- Notion + Claude integration (API, MCP server)
- Notion as knowledge base for AI agents
- Notion databases as structured data source
- Comparison: Notion AI vs standalone AI tools

**Gap severity: HIGH** — zero direct coverage. Results are false positives (confidence scoring, YC roadmap — no Notion content).

---

### 6. "office automation ai"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/learnings/eisenhower-matrix-en.md | undated | 0.9962 |
| [mac] | ψ/memory/retrospectives/2026-02/12/18.27_expense-analysis-audit-review-tool.md | 2026-02-12 | 0.9958 |
| [do] | ψ/memory/learnings/glueboy__2026-02-12_ai-human-in-the-loop-for-data-quality-audit-for.md | 2026-02-12 | 0.1527 |

**เราขาดอะไร**:
- Office automation overview (landscape map of tools)
- Workflow automation: Zapier/Make + AI (trigger → AI process → action)
- Document automation (contracts, invoices, reports)
- Meeting automation (scheduling, notes, action items)
- "AI office assistant" patterns for non-technical users

**Gap severity: HIGH** — results are about expense/data automation, not office automation broadly.

---

### 7. "knowledge worker ai"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/retrospectives/2026-03/19/17.57_webhook-relay-deploy.md | 2026-03-19 | 0.9956 |
| [mac] | ψ/memory/learnings/eisenhower-matrix-en.md | undated | 0.9955 |
| [mac] | ψ/memory/resonance/oracle.md | undated | 0.9953 |

**เราขาดอะไร**:
- Knowledge worker productivity with AI (research, writing, analysis workflows)
- AI-assisted research patterns (Claude for literature review, summarization)
- Personal knowledge management (PKM) with AI
- AI for email/communication triage
- "Second brain" patterns (Tiago Forte's methodology + AI)

**Gap severity: HIGH** — zero direct coverage.

---

### 8. "spreadsheet copilot"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/retrospectives/2026-02/01/17.23_cto-cofounder-proposal-refinement.md | 2026-02-01 | 0.9959 |
| [mac] | ψ/memory/retrospectives/2026-03/26/03.27_jera-ssot-production-sprint.md | 2026-03-26 | 0.9957 |
| [mac] | ψ/memory/retrospectives/2026-03/06/18.54_gm-google-sheets-api-setup.md | 2026-03-06 | 0.9957 |

**เราขาดอะไร**:
- Microsoft Copilot in Excel (features, pricing, limitations)
- Google Sheets Gemini (native AI vs API-driven)
- Spreadsheet AI comparison (Copilot vs Gemini vs Claude via MCP)
- Formula generation patterns (AI → complex formulas)
- Data analysis automation (pivot tables, charts via AI)

**Gap severity: MEDIUM** — we have practical Sheets experience but no comparative analysis.

---

### 9. "email ai gemini gmail"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/learnings/2026-03-03_gemini-video-analysis-via-google-genai.md | 2026-03-03 | 0.9961 |
| [mac] | ψ/memory/retrospectives/2026-01/31/12.10_expense-gchat-webhook-phase2.md | 2026-01-31 | 0.9961 |
| [do] | ψ/memory/learnings/glueboy__2026-03-03_gemini-video-analysis-via-google-genai.md | 2026-03-03 | 0.1533 |

**เราขาดอะไร**:
- Gmail Gemini features (Help me write, summarize threads, smart reply)
- Outlook Copilot features and comparison
- Email automation patterns (auto-categorize, draft replies, follow-up reminders)
- Calendar AI (scheduling assistant, meeting prep)
- Email + AI integration architecture (API vs native vs extension)

**Gap severity: HIGH** — results are about Gemini API/video analysis, not email AI.

---

### 10. "obsidian logseq ai"

**เรามีอะไร**:
| Source | File | Date | Score |
|--------|------|------|-------|
| [mac] | ψ/memory/retrospectives/2026-04/06/03.30_oracle-to-oracle-experiment.md | 2026-04-06 | 0.9956 |
| [mac] | ψ/memory/retrospectives/2026-02/14/15.15_boq-rev6-trace-and-analysis.md | 2026-02-14 | 0.9956 |

**เราขาดอะไร**:
- Obsidian + AI plugins (Smart Connections, Copilot, Text Generator)
- Logseq + AI features and plugins
- PKM tool comparison with AI capabilities (Obsidian vs Notion vs Logseq)
- Local-first AI (running LLMs with Obsidian/Logseq)
- Knowledge graph + AI patterns

**Gap severity: HIGH** — zero direct coverage.

---

## Gap Analysis Summary

| Topic | Coverage | Gap Severity | Existing Assets |
|-------|----------|-------------|-----------------|
| Claude Code Cowork | Moderate | MEDIUM | VirtioFS fix, HTML tutorial, GM setup |
| Google Sheets AI | Strong | LOW | MCP upgrade, formatting, portal, iterative discipline |
| Gemini Workspace | Strong | LOW | ROI analysis, playbook, pricing (but 3mo old) |
| ChatGPT Team/Office | None | HIGH | Zero direct content |
| Notion AI | None | HIGH | Zero direct content |
| Office Automation AI | Weak | HIGH | Only expense automation tangent |
| Knowledge Worker AI | None | HIGH | Zero direct content |
| Spreadsheet Copilot | Moderate | MEDIUM | Practical Sheets work, no comparison |
| Email/Calendar AI | None | HIGH | Zero email AI content |
| Obsidian/Logseq AI | None | HIGH | Zero PKM tool content |

**Strong areas (OFFICEBOY can build on):** Google Sheets AI, Gemini Workspace
**Complete gaps (OFFICEBOY must research from scratch):** ChatGPT Team, Notion AI, Obsidian/Logseq, Email/Calendar AI, Knowledge Worker AI

---

## 10-Article Publishing Roadmap — OFFICEBOY's First Month

Priority order: high-gap topics first, building on existing fleet knowledge where possible.

| # | Priority | Title | Why First |
|---|----------|-------|-----------|
| 1 | P0 | **Office AI Landscape 2026** — Map of all office AI tools (Gemini, Copilot, Claude, ChatGPT, Notion AI) | Foundation article — sets the stage for everything else |
| 2 | P0 | **Google Workspace + Gemini Deep Dive** — Updated features, pricing, Docs/Sheets/Slides/Meet AI | Build on strong existing knowledge (refresh Feb data) |
| 3 | P0 | **Claude Code Cowork for Office Workers** — Setup guide for non-devs, Sheets MCP, daily workflows | Captain's primary use case, builds on fleet experience |
| 4 | P1 | **Notion AI Complete Guide** — Features, Claude integration, knowledge base patterns | HIGH gap, Captain uses Notion |
| 5 | P1 | **ChatGPT Team & Custom GPTs for Office** — Team plan, GPT Builder, office automation Actions | HIGH gap, widely used by friends/family |
| 6 | P1 | **Email & Calendar AI** — Gmail Gemini, Outlook Copilot, scheduling assistants | HIGH gap, universal daily use case |
| 7 | P1 | **Spreadsheet AI Showdown** — Gemini in Sheets vs Copilot in Excel vs Claude via MCP | Builds on strong Sheets knowledge + adds comparisons |
| 8 | P2 | **PKM + AI** — Obsidian, Logseq, Notion as AI-enhanced knowledge management | HIGH gap, growing PKM interest |
| 9 | P2 | **Office Automation Playbook** — Zapier/Make + AI, document automation, workflow patterns | HIGH gap, practical for Captain's network |
| 10 | P2 | **Knowledge Worker AI Productivity** — Research, writing, analysis workflows with AI | META article — synthesizes all OFFICEBOY learnings |

### Publishing cadence
- **Week 1**: Articles 1-3 (foundation + strengths)
- **Week 2**: Articles 4-6 (fill biggest gaps)
- **Week 3**: Articles 7-8 (comparisons + PKM)
- **Week 4**: Articles 9-10 (automation + synthesis)

### Notes
- Each article should follow DEVBOY Lab style: Thai+English mix, technical terms in English, maturity tags
- OFFICEBOY sections on CCC Academy website: Office AI Suite, Data & Sheets, Knowledge & Notes, Email & Calendar AI
- Articles 2, 3, 7 can leverage existing arra knowledge; articles 4, 5, 6, 8 need fresh research
