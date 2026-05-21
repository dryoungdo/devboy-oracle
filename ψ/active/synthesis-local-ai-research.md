# Synthesis: Ollama + DGX Spark + Self-hosted + Local AI + Gemma 4
**Date**: 2026-05-21
**Status**: COMPLETE — all 10 agents returned

## Key Findings

### Ollama
- Go-based, wraps llama.cpp, 172K stars, 52M monthly downloads, 4,500+ models
- OpenAI-compatible API, REST + /v1/chat/completions
- Q4_K_M default quantization, CPU+GPU (CUDA/ROCm/Metal)
- 7B = 4-6GB RAM, 70B = 38-48GB RAM
- MCP servers exist (community), integrates with LangChain/LlamaIndex/CrewAI
- Open WebUI (137K stars) = dominant frontend
- Not production-grade (use vLLM/SGLang for that)

### DGX Spark
- GB10 Grace Blackwell, 128GB LPDDR5x unified, 1 PFLOP FP4, $4,699
- Runs 200B models single unit, 405B with 2 linked
- Breakeven vs cloud: 3.3 months at 24/7 usage
- Memory bandwidth 273 GB/s (Mac Studio = 819 GB/s, 3x faster)
- MediaTek co-developed, DGX OS (Ubuntu 24.04)
- 6 agents viable with 8B-20B models concurrent

### Self-Hosted Economics
- Breakeven: ~100M+ tokens/month sustained
- Fleet v3 at <50M tokens/month → API still cheaper
- Hybrid routing = winning strategy 2026
- RTX 4090 $1,600, Mac Studio $4K-8K, DGX Spark $4,699
- Hidden costs: ops team $750-3,000/month

### Self-Hosted Platforms
- vLLM/SGLang = production serving
- Ollama = dev/prototyping (172K stars)
- ExLlamaV2 = fastest consumer GPU
- LocalAI = sovereignty + multimodal (35K stars, 36+ backends)
- TGI = maintenance mode now

### Local AI Movement
- Edge AI market $30-48B in 2026, 21-29% CAGR
- NPUs: Snapdragon X2 80-85 TOPS, M4 35-38 TOPS
- Thai LLMs exist: ThaiLLM (NSTDA), Typhoon (SCB 10X), OpenJAI, Pathumma
- 55% enterprise inference now on-prem (up from 12% in 2023)
- RAG not needed <50 pages

### Local AI Privacy
- GDPR €2.3B fines in 2025, EU AI Act 7% global-turnover from Aug 2026
- Thailand PDPA + ThaiLLM on NSTDA ThaiSC supercomputer
- Retrieval poisoning >80% flip rate (local = no external adversarial content)
- DeepSeek V4-Pro within 0.2% of Claude Opus on SWE-bench
- Qwen Coder, Kimi K2.6 = frontier-competitive coding

### Gemma 4
- Released April 2, 2026, Apache 2.0 (finally!)
- 4 sizes: E2B (2.3B), E4B (4B), 26B MoE (3.8B active), 31B Dense
- 256K context, multimodal (text+image, audio+video on E2B/E4B)
- AIME 89.2%, MMLU Pro 85.2%, HumanEval 78.5%
- Thai in 140+ languages pretrained, 35+ supported
- 2M+ HuggingFace downloads, Ollama day-one
- QLoRA 26B MoE = single RTX 4090

### Fleet v3 Cross-Cutting
- DO = 2-core Intel VM, 8GB RAM, NO GPU → can't run local inference
- Mac mini + Ollama = Phase 1 (Qwen3 8B, free)
- Mac Studio + Qwen3 30B = Phase 2 (medium tasks)
- Qwen3 > Gemma for Fleet (better Thai, coding, community Thai variants)
- Sovereignty: WEAK → MODERATE with Ollama (graceful degradation)
- DGX Spark: NOT YET at current scale (<50M tokens/month)
- Hybrid router: high→API, medium→local 30B, low→local 4-8B
- Savings modest ($85-225/month) but sovereignty gain = real value
