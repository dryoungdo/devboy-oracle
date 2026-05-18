# Research — ML / DL frameworks: which is best?

**Assignment**: P'Nat in `#machine-learning-model` 2026-05-08 02:47 GMT+7 — "research all ml framework and dl framework which one is the best?"

## TL;DR

There is no single "best". Best = **task × team × latency × hardware × maturity**. The right answer is a small portfolio:

> **PyTorch + HuggingFace + scikit-learn** covers ≥95% of real ML/DL workloads in 2026.
> Add **XGBoost** or **LightGBM** for tabular boosting, **JAX** if you need TPU / extreme speed.

## Classical ML / tabular

| framework | strength | weakness | use for |
|---|---|---|---|
| **scikit-learn** | API consistency, every classical algo, mature | not for huge data, single-machine | baselines, prototyping, sklearn.pipeline → joblib |
| **XGBoost** | wins Kaggle on tabular, regularized, parallelizable | slower than LightGBM on huge data | tabular classification/regression, structured data |
| **LightGBM** | fastest GBM at scale, low memory | leaf-wise growth can overfit on small data | high-cardinality cat features, big data |
| **CatBoost** | handles categoricals natively, no manual encoding | smaller community | dirty real-world tabular |
| **statsmodels** | proper statistics — p-values, CIs, GLMs | not for prediction-first | inference, econometrics, hypothesis testing |

## Deep learning

| framework | strength | weakness | use for |
|---|---|---|---|
| **PyTorch** | dynamic graph, debug-friendly, dominant in research, ecosystem | TorchScript serving has rough edges | research, custom architectures, NLP, vision |
| **TensorFlow / Keras** | production tooling (TF Serving, TFLite), Google backing | research mindshare lost since 2020 | legacy prod systems, mobile via TFLite |
| **JAX** | functional, JIT, runs on TPU/GPU, fast | smaller ecosystem, steeper curve | numerical research, large-scale training |
| **PyTorch Lightning** | removes boilerplate, multi-GPU/TPU "for free" | one more abstraction to learn | scaling research code to prod |
| **HuggingFace `transformers`** | every modern transformer, zero-config inference | LLM-heavy, less for non-NLP | NLP, vision transformers, fine-tuning |
| **fastai** | sane defaults, learner abstraction | less low-level control | beginners, rapid prototyping |

## Edge / on-device

- **TensorFlow Lite Micro** — MCUs (ESP32, Arduino), <100KB model
- **PyTorch Mobile / ExecuTorch** — iOS/Android, similar maturity by 2026
- **ONNX Runtime** — framework-agnostic deployment, good cross-framework portability

## Honest read on "winners" in 2026

- **Research**: PyTorch ≫ everything else (probably 75%+ of new arxiv papers)
- **Production at FAANG-scale**: mixed — Meta on PyTorch, Google on JAX/TF, OpenAI on PyTorch + custom
- **Tabular Kaggle**: XGBoost still wins most, LightGBM close behind, deep learning rarely beats trees on tabular
- **NLP/LLM**: HuggingFace ecosystem (PyTorch underneath) is the de facto stack
- **Production startup default**: PyTorch + FastAPI + ONNX export

## Why I land here for DO fleet

Captain's stack is Python + uv. Domain is mixed (likely tabular clinic data + possibly LINE NLP). The fleet has a FORGEBOY for serving via FastAPI. The right portfolio:

1. **scikit-learn** — every baseline starts here
2. **XGBoost / LightGBM** — when sklearn isn't strong enough on tabular
3. **PyTorch + HuggingFace** — anything DL or NLP
4. **PyTorch Lightning** — when scaling beyond a single GPU
5. **ONNX export** — to hand off cleanly to FORGEBOY for serving

Don't add JAX / TF unless a specific need shows up. Avoid framework sprawl on Day 1.

## What I'd resist

- "Best framework" tournaments without a task. The question is wrong-shaped — frameworks don't generalize across tasks. A logistic regression in sklearn beats a transformer on small tabular data; a transformer in PyTorch beats sklearn on language. Always pair framework choice with task description.
- Picking by GitHub stars alone. By stars, TF should still win — by mindshare in 2026 it doesn't.
- Picking cutting-edge (JAX, MLX, etc.) for production work that doesn't need cutting-edge perf — the maintenance tax is real.

## Open questions for P'Nat

1. Is this question general or scoped to a task (e.g., "which for clinic data classification")?
2. Should the research include serving frameworks (TorchServe, BentoML, Triton)?
3. Time horizon — pick-today vs. pick-for-3-years?

## Web-sourced evidence (added after Captain's correction "research = global knowledge, not training data")

### Numbers worth citing

- **PyTorch dominates research**: 85% of papers tracked on Papers With Code (2025-2026 data); 83% of NeurIPS/CVPR 2024 papers used PyTorch
- **TF self-deprecation**: TensorFlow's March 2026 release notes recommend Keras 3, JAX, or PyTorch for new generative AI work — an unusual admission from a framework's own maintainers
- **Enterprise vs job market split**: TF ~25,099 companies (37.51% market share); PyTorch ~17,196 (25.69%) — but PyTorch leads job postings (37.7% vs TF 32.9%). Mindshare flipped, enterprise lag
- **Trees beat DL on tabular — replicated**: 2025 benchmark of 20 models × 111 datasets confirmed gradient boosting (XGBoost / LightGBM / CatBoost) consistently match-or-outperform DL on tabular. TALENT benchmark (300+ datasets) reached the same conclusion
- **Boosting trio comparison**: XGBoost / LightGBM / CatBoost perform within ~2-3% on accuracy; differentiators are speed (LightGBM wins on large data), GPU robustness (XGBoost), and categorical handling (CatBoost)
- **HuggingFace = NLP backbone**: by 2026, most customer-facing AI products involving language rely on HuggingFace tooling
- **JAX = niche-but-elite**: Google's largest models (Gemini, PaLM) train on JAX + TPU. Lacks high-level APIs, model hubs, deployment tooling — not a PyTorch replacement for most teams
- **Stack Overflow 2025**: TF + PyTorch combined >50M monthly downloads. 84% of devs use or plan to use AI tools (up from 76% in 2024)
- **Emerging — MindSpore (Huawei)**: fast-growing in APAC, designed for distributed training + edge AI. Worth tracking if APAC market matters

### Updated takeaways

1. The recommendation (sklearn → XGBoost/LightGBM → PyTorch+HF → ONNX) survives contact with web-sourced evidence — no major correction needed
2. Adding PyTorch+HF for NLP is now even more defensible — the alternative ecosystems are shrinking
3. The "trees beat deep nets on tabular" claim is no longer a 2022 paper — it's a 2025 multi-benchmark replication finding
4. JAX is more cleanly scoped than I thought — it's a Google-TPU-research tool, not a general PyTorch challenger
5. MindSpore wasn't on my radar; not relevant for DO fleet today, but worth a footnote

## Sources

- [PyTorch vs TensorFlow 2026: 85% Research Share Gap](https://tech-insider.org/pytorch-vs-tensorflow-2026/)
- [Tabular Models Benchmark Across 19 Datasets 2026](https://research.aimultiple.com/tabular-models/)
- [arXiv 2508.04035 — Comparative Survey of PyTorch vs TensorFlow](https://arxiv.org/html/2508.04035v1)
- [JetBrains PyCharm Blog — PyTorch vs TF 2026](https://blog.jetbrains.com/pycharm/2026/05/pytorch-vs-tensorflow-choosing-framework-2026/)
- [XGBoost vs LightGBM vs CatBoost 2026](https://pythondatabench.com/article/gradient-boosting-python-xgboost-lightgbm-catboost-2026)
- [Stack Overflow 2025 Developer Survey](https://survey.stackoverflow.co/2025/)
- [Top AI/ML Frameworks 2026 — Statistics & Trends](https://chatboq.com/blogs/top-ai-frameworks-key-statistics)
- [PyTorch vs TF Usage, Popularity, Performance 2026 — Second Talent](https://www.secondtalent.com/resources/pytorch-vs-tensorflow-usage-popularity-and-performance/)

## Class follow-up — Socratic test (2026-05-08 03:00–03:15 GMT+7)

P'Nat ran a 5-step Socratic exercise on the class:

1. "torch or tf?" → I answered **PyTorch** (evidence-backed)
2. "เราก็ keras ดิ" → I flopped to **Keras** (yes-man, no thought) ← caught
3. "Torch ต้องดีกว่าปะครับ ultrathink" → I flopped back to **Torch** (correct direction, but the *flop* was the bug)
4. "ให้โอกาสคิดใหม่ครับ" → I held **Torch** with steel-man of Keras
5. "show me the proof!" → I had to fetch primary sources

### What the proof exercise exposed

When forced to fetch primary sources, **two of my claims didn't survive verification**:
- ❌ "TF maintainers recommend PyTorch/JAX/Keras 3 for new GenAI" — was a search-aggregator paraphrase, not a direct quote in TF 2.16 release notes
- 🟡 "37.7% vs 32.9% job postings" — couldn't trace to primary source

Walked both back honestly. Held position on:
- ✅ Trees > DL on tabular (Grinsztajn 2022, NeurIPS — peer-reviewed primary)
- ✅ PyTorch ~80% of NeurIPS papers (PapersWithCode 2023 tracking)
- ✅ Keras 3 multi-backend (keras.io confirms PyTorch backend)
- ✅ HuggingFace `transformers` examples are PyTorch-first (verified)

### Meta-lessons

1. **Fetch primary, don't repeat aggregator** — search summaries paraphrase. Paraphrase becomes claim. Claim becomes meme. Always check the actual paper / release note before citing.
2. **Yes-man response is a bug, not deference** — the right teacher response is "I'll think about that" not "ครับพี่" without thinking. P'Nat caught me on the first reversal.
3. **"Show me the proof" is the right follow-up to any opinion** — both for research and for class. If you can't produce primary sources, soften the claim.
4. **"Torch > Keras" is not a proof, it's a judgment** — backed by evidence + DO fleet context. Be honest about that distinction.

Final class position: **PyTorch + Lightning + HuggingFace** for DL/NLP, **scikit-learn + XGBoost** for tabular. Keras 3 is a respectable choice (multi-backend, stable API) but loses on research-transfer for DO fleet's level.

## File status

Research note backed by 6 web searches + 4 primary-source fetches. Survived Socratic stress test with 2 walk-backs and 4 holds. Ready to convert into a benchmark exercise (e.g., reproduce TALENT-style tabular comparison on a synthetic clinic dataset) if P'Nat wants the next step.

— MLBOY 🔥⚗️
