# Muninn Memory tech verify — MLBOY

**Source under review**: `iotboy/ψ/learn/muninn-memory/CAPTAIN_GUIDE.md` (106 lines, IOTBOY authored)
**Date**: 2026-05-11 15:15 GMT+7
**Authority**: per Captain Discord msg `1503307722060337253` + peer relay (IOTBOY+FORGEBOY)
**Scope**: verify Hebbian / ACT-R / Bayesian formula claims + license/benchmark cites — not architecture design

## Verdict: ✅ ผ่าน tech verify with 2 notes

### Formula provenance (Path D clean-room foundation)

```
claim                          public-domain?   patent risk?   ✓/✗
─────────────────────────────  ───────────────  ─────────────  ───
Hebbian (Donald Hebb 1949)     YES              NONE           ✓
ACT-R decay (Anderson 1993)    Academic         NONE           ✓
Bayesian (Thomas Bayes 1763)   YES              NONE           ✓
```

**Hebbian (1949)**: "The Organization of Behavior". Core: Δw_ij = η · x_i · x_j (basic rule). Variants: Oja's rule (normalized), BCM, STDP. **Important caveat**: vanilla Hebbian blows up weights without normalization — implementation must use Oja's or BCM variant, not raw Hebb's rule. Cite this when implementing.

**ACT-R decay (Anderson 1993)**: Base-level activation B_i = ln(Σ t_j^(-d)), default d ≈ 0.5. From "Rules of the Mind" + ACT-R 6.0 papers (Anderson, Bothell, Byrne, Douglass, Lebiere, Qin 2004). **Implementation note**: t_j = time-since-use in seconds works, but real ACT-R adds noise term + permanent_noise. Choose to include or simplify.

**Bayesian (1763)**: Bayes-Price posthumous publication. P(A|B) = P(B|A)·P(A)/P(B). **Implementation note**: for memory-confidence specifically, look at Bayesian Knowledge Tracing (Corbett & Anderson 1995) — applies Bayes to learner state estimation, closer to memory-system use case than raw Bayes.

### Benchmark cites

```
claim                                source-status      verify-path
───────────────────────────────────  ─────────────────  ─────────────────
mempalace 96.6% LongMemEval R@5      public benchmark   github.com/mem*pal*/README + LongMemEval paper (Wang et al. 2024)
mempalace 51,900 ⭐                    public github     observable via API
MuninnDB +21% Recall@10              synthetic 2k       NOT a public benchmark — vendor claim, low-trust
MuninnDB 285 ⭐                        public github     observable
```

**Note**: IOTBOY correctly flagged the MuninnDB +21% as synthetic-only claim. Mempalace's 96.6% is verifiable via LongMemEval which is a published benchmark dataset. **Path D's "inherit benchmark from mempalace" claim is valid** because mempalace's number lives on a real public benchmark, not a vendor-internal one.

### Path D risk analysis (clean-room from mempalace + colliery-io)

✅ **License chain ok**: mempalace MIT + colliery-io Apache → output MIT/Apache. Clean.
✅ **Patent chain ok**: textbook math + MIT/Apache code → no patent exposure (vs MuninnDB BSL+patent path).
⚠️ **Implementation risk note 1**: clean-room means **NOT reading scrypster/MuninnDB source code**. IOTBOY's wave-research used public docs only — confirm this is documented in research log so future contributors don't accidentally cross-contaminate.
⚠️ **Implementation risk note 2**: Hebbian variant choice matters (Oja's vs raw vs BCM). Spec the chosen variant up front, don't leave to implementer.

### 2 notes for IOTBOY's lesson content + FORGEBOY's web build

1. **Lesson should specify** which Hebbian variant (Oja recommended — naturally bounded weights, no manual normalization). Mention in CAPTAIN_GUIDE + lesson outline.
2. **Web inspector** (FORGEBOY's scope) should visualize the decay curve B_i = ln(Σ t_j^(-d)) — this is the most user-facing math and most-debatable parameter (d=0.5 default). Make d adjustable in inspector UI.

### Captain's 4 decisions — SEALED 2026-05-11 17:05 GMT+7

```
A. Path        → D (clean-room from mempalace + colliery-io) ✓
B. Repo        → github.com/dryoungdo/muninn-memory — PRIVATE first (Captain "เอาชัวร์" msg 1503337315144306749)
C. License     → MIT (matches mempalace, no patent-grant clause)
D. Timeline    → 10 weeks (midpoint of 8-12)
```

Captain sealed via Discord msg `1503337315144306749`. Risk-assessed: clean → executed (no DM-permission needed).

## File status

Read-only verify note. No code shipped. ready for FORGEBOY/IOTBOY to reference + Captain to decide.

🔥⚗️ — MLBOY (tech verify ผ่าน, 2 implementation notes added)
