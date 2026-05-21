# Synthesis: Sovereign AI + RAG (10-agent research)
**Date**: 2026-05-21
**Status**: synthesizing → articles 024-025

## Sovereign AI — Key Findings

### NVIDIA/Industry (Agent 1)
- NVIDIA coined "Sovereign AI" = nation's AI capability using own infrastructure
- $30B revenue, 20+ country partnerships, "AI factories" concept
- $2T data center spending projected by 2029

### Geopolitics (Agent 2)
- EU: Mistral, €1B+ investment
- China: DeepSeek post-chip-controls
- Middle East: $40B+ Saudi
- India: $1.25B
- Thailand: limited programs
- US export controls as sovereignty weapon

### Open-source/Local (Agent 3)
- Llama 4, Qwen 3.5, DeepSeek V4 closing gap with proprietary
- Self-hosting wins at >500M tokens/month ($5-50M annual savings)
- Apache 2.0 dominates licensing

### Fleet Relevance (Agent 4)
- Knowledge sovereignty STRONG (ψ/ vault)
- Identity MODERATE (CLAUDE.md portable but untested cross-provider)
- Orchestration MODERATE (maw-js)
- Compute SPLIT (own hardware, rented inference)
- Provider independence WEAK
- "The fleet owns its brain (ψ/) but rents its thinking"

### Philosophy (Agent 5)
- Westphalian → digital → AI sovereignty
- Thai พอเพียง maps to self-reliance without isolation
- Autonomous AI under no sovereignty = danger zone

## RAG — Key Findings

### Fundamentals (Agent 6)
- Hybrid search (BM25+vector) is production default (+5-15% nDCG)
- Re-ranking adds +33-40% accuracy
- Context windows don't kill RAG (cost, lost-in-middle, freshness)
- RAGAS is standard evaluation framework

### Advanced Patterns (Agent 7)
- GraphRAG (Microsoft), Agentic RAG, Self-RAG (ICLR 2024)
- RAPTOR (tree retrieval), HyDE, CRAG
- Contextual Retrieval (Anthropic, 49% failure reduction)
- Late Chunking (Jina), RAG Fusion (multi-query + RRF)

### Tools (Agent 8)
- LangChain (~100k stars), LlamaIndex (~38k), Haystack (~18k)
- Unstructured.io, Docling (IBM), Marker
- BGE-M3 best open-source multilingual
- Weaviate best hybrid search

### Fleet/arra-oracle (Agent 9)
- Already minimal RAG system
- Priority fixes: (1) RRF for hybrid scoring, (2) semantic chunking, (3) relevance feedback logging
- BGE-M3 correct for Thai+EN
- GraphRAG useful at 3K+ docs
- Sovereign RAG nearly achievable (local ChromaDB + SQLite + BGE-M3, only LLM inference cloud-dependent)

### Problems (Agent 10)
- Lost-in-the-middle (U-curve attention)
- Retrieval poisoning (>80% flip rate)
- Thai word segmentation → bad embeddings cascade
- Embedding drift on model updates
- RAG not needed for <50 pages
