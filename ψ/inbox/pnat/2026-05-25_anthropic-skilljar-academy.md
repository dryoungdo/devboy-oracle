# Anthropic Academy (Skilljar) — Full Course Catalog

**Source**: https://anthropic.skilljar.com/
**Fetched**: 2026-05-25 via WebFetch
**Total**: 18 courses (all free)
**Support**: academy-support@anthropic.com

## Course Catalog

### Developer Track (8 courses)

#### 1. Claude Code 101
- **Modules**: 5 (What is CC, Installing, Daily Workflows, Customizing, Assessment)
- **Key topics**: Agentic loop, context window, tools, permissions, Explore→Plan→Code→Commit workflow, /compact /clear /context, CLAUDE.md, subagents, MCP, hooks
- **Prerequisites**: Basic CLI + Claude account (Pro/Max/Enterprise) or API key

#### 2. Claude Code in Action
- **Modules**: 5 (What is CC, Hands On, Controlling Context, Hooks and SDK, Wrap Up)
- **Key topics**: Multi-tool systems, context management, visual communication for UI, custom commands, MCP servers, GitHub workflow automation, code review, hooks (defining, implementing, gotchas, useful patterns), Claude Code SDK
- **Prerequisites**: CLI + Git basics

#### 3. Introduction to Claude Cowork
- **Modules**: 5 (Meet Cowork, Make it yours, Use everywhere, Sharing/safety, Wrap up)
- **Key topics**: Cowork task loop, plugins and skills, file/research workflows, standing context (global instructions + projects), Chrome extension, Microsoft 365, validating skills for plugins, team sharing
- **NEW concept**: Cowork = Claude working directly with files/folders/apps on your machine, not conversation format

#### 4. Introduction to Agent Skills
- **Modules**: 6 (What are skills, Creating first skill, Config + multi-file, Skills vs other features, Sharing, Troubleshooting)
- **Key topics**: SKILL.md frontmatter, descriptions for reliable triggering, skill directories, allowed-tools config, team repo sharing, enterprise deployment, integration with custom subagents, diagnostics

#### 5. Introduction to Subagents
- **Modules**: 4 (What are subagents, Creating, Designing effective, Using effectively)
- **Key topics**: Separate context windows, /agents command, structured outputs, error reporting, when to delegate vs not, completion criteria, reporting mechanisms

#### 6. Introduction to Model Context Protocol
- **Modules**: 4 (Intro, Hands-on Servers, Connecting Clients, Assessment)
- **Key topics**: 3 core primitives (tools, resources, prompts), Python MCP servers with decorators, server inspector (browser debugging), document management, static/templated URIs, autocomplete, context injection
- **Prerequisites**: Python + JSON/HTTP

#### 7. MCP Advanced Topics
- **Modules**: 4 (Intro, Core Features, Transports, Assessment)
- **Key topics**: Sampling (LM integration), notifications/logging, roots (file system access), JSON message types, STDIO transport, StreamableHTTP, SSE, state management, stateless vs stateful scaling, production deployment with load balancers
- **Prerequisites**: Python + async + JSON/HTTP + SSE

#### 8. Building with the Claude API
- **Modules**: 11 (Intro, API Access, Prompt Eval, Prompt Engineering, Tool Use, RAG, Features, MCP, Apps, Agents/Workflows, Final)
- **Key topics**: API auth, multi-turn, system prompts, temperature, streaming, structured data, eval workflows, test datasets, model-based grading, XML tags, examples, tool schemas, message blocks, multi-turn tool use, text edit tool, web search tool, RAG (chunking, embeddings, BM25, multi-index), extended thinking, image/PDF support, citations, prompt caching, code execution, Files API, MCP full coverage, parallelization/chaining/routing workflows, agents vs workflows
- **Most comprehensive** — covers nearly everything

### AI Fluency Track (6 courses)

#### 9. AI Fluency: Framework & Foundations
- Collaborate with AI effectively, efficiently, ethically, safely

#### 10. AI Fluency for Educators
- Apply AI fluency into teaching practice and institutional strategy

#### 11. AI Fluency for Students
- Enhance learning, career planning, academic success

#### 12. Teaching AI Fluency
- Teach and assess AI fluency in instructor-led settings

#### 13. AI Fluency for Nonprofits
- AI fluency for organizational impact while maintaining mission alignment

#### 14. AI Fluency for Small Businesses
- Develop fluency for business impact

### Platform-Specific (2 courses)

#### 15. Claude with Amazon Bedrock
- Working with Anthropic models through Amazon Bedrock

#### 16. Claude with Google Cloud's Vertex AI
- Full spectrum of Anthropic models through Vertex AI

### General (2 courses)

#### 17. Claude 101
- Core features for everyday work tasks

#### 18. AI Capabilities and Limitations
- Introductory course about how AI works

## Cross-Reference with P'Nat's CCC Academy

| P'Nat Lesson | Closest Anthropic Course |
|-------------|------------------------|
| 1. CLAUDE.md | Claude Code 101 Module 4 |
| 2. Shortcode → Skill | Intro to Agent Skills |
| 3. Oracle Birth | — (fleet-specific, no Anthropic equivalent) |
| 4. Team Agents & Trio | Intro to Subagents (partial — subagents only, no team-agents) |
| 5. Token Security | Building with API Module 2 (API key) |
| 6. Federation | — (fleet-specific) |
| 7. Channels | — (fleet-specific, Discord/Telegram) |
| 8. Worktrees | — (fleet-specific) |
| 9. /learn | — (fleet-specific skill) |
| 10. /rrr | — (fleet-specific skill) |
| 22. npx skills | Intro to Agent Skills Module 5 (sharing) |

**Key insight**: P'Nat's course covers fleet-specific patterns (Oracle, Federation, Channels, Worktrees) that Anthropic doesn't teach. Anthropic covers foundational Claude Code + API + MCP + Prompt Engineering that P'Nat's course assumes as prerequisite.
