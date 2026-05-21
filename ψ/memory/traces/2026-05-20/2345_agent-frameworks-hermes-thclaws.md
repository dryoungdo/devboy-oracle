---
query: "agent frameworks hermes-agent thClaws openclaw"
target: "hermes-agent, thClaws, openclaw"
mode: deep
timestamp: 2026-05-20 23:45
friction_score: 0.7
coverage: [oracle, files, git, cross-repo]
confidence: high
---

# Trace: Agent Frameworks (hermes-agent, thClaws, openclaw)

**Target**: hermes-agent, thClaws, openclaw
**Mode**: deep | **Friction**: 0.7 | **Confidence**: high
**Time**: 2026-05-20 23:45

## Oracle Results
- thClaws article 010 exists (v0.11.0, raw maturity) — needs heavy update to v0.13.0
- hermes-agent: no prior Oracle entries — fresh territory

## Files Found
- `/home/drdo/Code/github.com/nousresearch/hermes-agent/` — v0.14.0, Python 3.11+, MIT, self-improving agent
- `/home/drdo/Code/github.com/thClaws/thClaws/` — v0.13.0, Rust, Apache-2.0, autoLearn + 6 surfaces
- `/home/drdo/Code/github.com/openclaw/openclaw/` — empty repo (no commits on master)

## Git History
- hermes-agent: active development, v0.14.0 latest release
- thClaws: v0.11.0 → v0.13.0, rapid release cadence (5 releases in 5 days pattern continues)

## Cross-Repo Matches
- 5 agent repos on machine via ghq
- hermes-agent + thClaws unstudied in ψ/ prior to this trace

## Oracle Memory
- thClaws article 010 written with v0.11.0 data — needs heavy update
- hermes-agent = net-new to Oracle

## Session History (from /dig)
- thClaws first studied in session 5158a157 (current session) — article 010 written with v0.11.0
- hermes-agent: never studied before — fresh territory
- No prior trace for agent framework comparison

## Friction Analysis
**Score**: 0.7 — repos exist locally (ghq cloned), one article exists but outdated
**Coverage**: oracle, files, git, cross-repo
**Goal check**: Yes — comprehensive data gathered. hermes-agent v0.14.0 fully profiled. thClaws delta v0.11.0→v0.13.0 captured. openclaw confirmed empty.

## Key Findings

### hermes-agent v0.14.0 (NousResearch)
- **Language**: Python 3.11+, MIT license
- **Self-improving**: autonomous skill creation via `skill_manager_tool.py`, skills auto-improve during use
- **22 messaging platforms**: Telegram, Discord, Slack, WhatsApp, Signal, Matrix, LINE, WeChat, etc.
- **29 LLM providers**: OpenRouter (200+), Anthropic, OpenAI, Gemini, xAI Grok, Qwen, DeepSeek, Bedrock, etc.
- **MCP**: both consumer + server mode (`hermes mcp serve`)
- **OAuth**: provider-level OAuth + MCP OAuth + local proxy for Claude Pro/ChatGPT Pro
- **ACP**: Editor integration (VS Code, Zed, JetBrains) via `hermes acp`
- **Trajectory compression**: post-processes agent trajectories for training data (16K token budget)
- **Memory**: MEMORY.md (2,200 chars) + USER.md (1,375 chars), bounded, frozen at session start
- **70+ tools**, 28 toolsets, 1,137 test files
- **Key differentiator**: distributed deployment (VPS, GPU cluster, serverless) + research focus (training data generation)

### thClaws v0.13.0 (delta from v0.11.0)
- **6 surfaces** (was 4): added LINE Chat + AI Agent API Server
- **589 models** (was "300+")
- **autoLearn**: opt-in, session-end KMS ingest + reconcile, MIN_TURNS=5, throttle 6h
- **AI Agent API**: POST `/agent/run` + GET `/v1/agent/info` (v0.12.0)
- **3 Anthropic cache breakpoints**: system prompt, last tool def, second-to-last message → 46-74% savings
- **AGENTS.md**: vendor-neutral standard, load order with CLAUDE.md compatibility

### openclaw
- Empty GitHub repo (no commits)
- "openclaw" in P'Nat fleet = Linux user account on white.local, not a platform
- hermes-agent migrates openclaw settings via `hermes claw migrate`

## Summary
Two serious agent frameworks studied. hermes-agent is messaging-first + research-focused (trajectory compression). thClaws is sovereign-first + developer-focused (native Rust, multi-surface). Both have self-learning capabilities. openclaw is the predecessor to hermes-agent, now archived.

**Next**: Write articles 022 (hermes-agent), 023 (comparison), update 010 (thClaws v0.13.0), arra learn, sidebar sync.
