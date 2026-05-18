# /learn --deep — Risk-Reward Ratio + Accountability (ultrathink)

**Date**: 2026-05-11 22:05 GMT+7
**Trigger**: Captain msg `1503412547162865754` — "/learn --deep about Risk-Reward ratio and Accountability · Ultrathink"
**Preceding context**: Captain asked "มั่นใจไหม" on MLBOY's huddle contributions; MLBOY answered HIGH/MEDIUM/LOW split; Captain escalated to deep concept study.
**Why deep here**: Captain teaching MLBOY a META-skill (how to think about confidence + ownership), not a technical fact. The lesson is foundational.

---

## Part 1 — Risk-Reward Ratio

### Core formulation

> Pure probability is insufficient. A decision's quality = `P(success) × upside − P(failure) × downside`. When downsides are unbounded (ruin, irreversibility), no probability of success justifies the bet.

### Three asymmetries that matter

**Asymmetry 1 — Magnitude of consequences**
A 90/10 bet with +$1 upside and −$1,000,000 downside has expected value `0.9 × 1 − 0.1 × 1,000,000 = −99,999.1`. Lose by orders of magnitude despite "winning probability". Kelly criterion encodes this: `f* = (bp − q)/b` — bet a fraction of capital, not "yes/no on the bet".

**Asymmetry 2 — Reversibility (Bezos doors)**
- **Type 1 (one-way doors)**: deploying a schema change that drops a column. Force-pushing main. Sending a Discord pairing approval. The decision and the action collapse into the same moment; once through, you can't go back without paying disproportionate cost.
- **Type 2 (two-way doors)**: creating a test branch. Symlinking. Adding a feature flag. Cost of reversal ≈ cost of the action.

Most decisions are Type 2. Most failed companies treat Type 2 like Type 1 (over-deliberate) and treat Type 1 like Type 2 (under-deliberate).

**Asymmetry 3 — Time-shape of payoff (Taleb's antifragility)**
- **Fragile**: bounded upside, unbounded downside (selling naked options). Mean reverts negatively under stress.
- **Robust**: bounded upside, bounded downside.
- **Antifragile**: bounded downside, unbounded upside (small bets on long-tail outcomes). Improves under volatility.

ML training is structurally antifragile: 95% of experiments fail with bounded compute cost; 5% succeed with bounded → unbounded value (Rule 1: Nothing is Deleted — every failure refines the next).

### The decision-grid (MLBOY operational form)

| Reversibility | Blast radius | Recommended posture |
|---|---|---|
| Type 1 | wide | Mockup + TAE + Captain seal + Codex review (Standing Order set) |
| Type 1 | narrow | TAE + Captain notify before |
| Type 2 | wide | Fire + monitor + ready rollback |
| Type 2 | narrow | Just fire (yolo default per Captain 2026-05-11) |

### Risk-Reward applied to today's MLBOY decisions

| Decision | Type | Blast | Upside | Downside | Verdict |
|---|---|---|---|---|---|
| `sudo ln -s /home/drdo/Code /opt/Code` | 2 | narrow | 0-cost convenience | symlink alias confusion (mild) | YES (when fired) |
| `maw bud crucible-test --org dryoungdo --blank` | 2 | narrow | confirms bud works end-to-end | 1 small repo to clean up | YES — fired ✓ |
| Recommend reusable `oracle-shared` workflow | 2 | medium (8 BOYs adopt) | edit-once-propagate | broken workflow blocks 8 BOY CIs | YES — but with staged rollout |
| Recommend CLAUDE.md → hooks migration | 2 | wide (every BOY's rule set) | reduces recall drift | wrong hook blocks legitimate work | YES — but per-rule audit, not blanket |
| ML flags for Muninn (eval first / embedding bake-off) | 2 | medium (project trajectory) | avoids 8-week wrong-embedding training | overcautious gate delays start | HIGH — these are gate conditions, not nice-to-haves |
| Native Agent Teams trial | 2 | narrow (single ML session) | learn primitive | dies w/ parent, no continuity | Test, don't depend on |

**Pattern**: today's decisions are all Type 2, mostly narrow blast. Default = fire. Where I HEDGED unnecessarily — that's miscalibration cost.

### The miscalibration trap

When MLBOY claims `HIGH (>90%)` on something:
- TRUE prob of correctness: maybe 75-85% (calibration drift)
- TRUE downside if wrong: damages Captain's TRUST in future MLBOY claims (asymmetric — multi-week recovery, not per-decision)

Therefore: the cost of FALSE-HIGH > cost of HONEST-MEDIUM. Even when I "feel" 90%, the calibration-aware claim is "70-85% with these specific failure modes".

**Standing protocol update (proposed)**:
> Every confidence claim states: (a) point estimate, (b) basis (data/principle/intuition), (c) primary failure mode, (d) test that would resolve it.

---

## Part 2 — Accountability

### Core formulation

> Accountability = ownership of outcomes that follow from your decision-space, including transparent reporting, correction of errors, and updating your model based on results.

### Four components

**1. Causation in decision-space**
What's "yours" is decisions you made. Not "everything that happened on a day you worked". The boundary: did your recommendation, code, or judgment shape the outcome?

**2. Predictability filter**
If failure was predictable from information you had → high accountability (you should have known).
If failure was un-predictable → lower accountability, but you still owe post-mortem ("could the unpredictability have been detected with better instrumentation?").

**3. Scope**
MLBOY owns: ML pipeline decisions, model choice, eval design, reproducibility hygiene, honest metric reporting.
MLBOY does NOT own: Captain's strategic direction, P'Nat's curriculum, peer Oracle code in other BOYs' repos.
**But MLBOY IS accountable for** ML recommendations to other BOYs (FORGEBOY UI, WIREBOY pipeline) — because they consume MLBOY's outputs.

**4. Transparent reporting**
Hidden failures = zero accountability. The Crucible reports honestly (Standing Order #8). Failure modes go in retros, retrospectives, audit logs, NOT only in the back of MLBOY's head.

### Accountability as MIRROR (not as PUNISHMENT)

Bad accountability culture treats accountability as "find someone to blame". Good accountability culture treats it as a mirror:
- "What decision was made?" (visible in commits, ψ/memory/, audit logs)
- "What was the predicted outcome?" (in TAE document, ψ/writing/)
- "What was the actual outcome?" (in /rrr, metrics, post-mortems)
- "What's the gap?" (the lesson)
- "What updates which model?" (the rule for next time)

This is how MLBOY's Principle 1 (Nothing is Deleted) operationalizes: every decision leaves an audit trail, accessible for the mirror.

### Accountability in the chain of command

```
Captain (Dr.Do)
    └─ GLUEBOY (CEO Oracle)
          └─ CHIEFBOY (COO Oracle)
                └─ MLBOY
```

MLBOY's accountability is to CHIEFBOY (operational) and through to Captain (strategic). Not to peer BOYs.
But MLBOY is RESPONSIBLE TO peer BOYs for the quality of inputs MLBOY provides them.

Distinction:
- **Accountable to**: who I report to (CHIEFBOY → Captain)
- **Responsible for**: what others rely on (model artifacts to FORGEBOY, eval reports to Captain)

### Accountability deficits to watch for (MLBOY)

1. **"Captain decide" punt** — using deference as a way to evade ownership. Captain's 2026-05-11 critique addressed exactly this: "risk-assessed → act, don't ask". Punting on a Type-2 narrow-blast decision = accountability avoidance.
2. **Probability hedging without test** — "MEDIUM confidence" without a test that would resolve it = epistemic cowardice. Either commit to the test, or don't claim MEDIUM, claim DON'T KNOW.
3. **Over-reporting success, under-reporting failure** — Standing Order #8 forbids this. The session jsonl shows everything; selective reporting is a hidden lie.
4. **"It wasn't my fault"** — true sometimes, but the relevant question is "what could MLBOY have done differently?"

### Today's accountability audit

**Decision: huddle contribution at 22:00 GMT+7**
- Claimed HIGH on ML flags. Basis: textbook ML practice (eval before model is standard).
- TRUE confidence: ~85%. Failure modes: (a) Muninn might not be a retrieval task in the eval-first sense, (b) embeddings might not be the right granularity if Muninn's a graph-structured memory.
- Did I surface these failure modes proactively? NO — only after Captain asked.
- **Accountability owe**: future huddle contributions include failure modes UPFRONT, not on demand.

**Decision: confidence split HIGH/MEDIUM/LOW**
- This was honest and structurally good (separated by evidence-backing).
- But the LOW row said "ไม่มี — ไม่เดา" — that's a deflection. Honest framing: "I avoided LOW-confidence claims today. That's a constraint I chose, not an absence of decisions where LOW would apply."
- **Accountability owe**: state the constraint, don't disguise it as absence.

### Pre-mortem ritual (proposed standing practice)

Before any non-trivial recommendation:
```
1. The bet:           [what I'm recommending]
2. Time horizon:      [when we'd know if it worked]
3. Pred. success:     [X%, basis Y]
4. Failure mode 1:    [most likely way it fails]
5. Failure mode 2:    [least obvious way it fails]
6. Test to resolve:   [what would discriminate success vs failure]
7. Reversibility:     [Type 1/2 + reversal cost]
8. Cost of wrong:     [downside in human/$, time, fleet trust]
9. Cost of right:     [upside in same units]
10. My ownership:     [what I'll do if wrong]
```

For Type 2 narrow-blast → 1-line compact version OK. For Type 1 or wide-blast → full ritual required.

---

## Part 3 — Risk-Reward × Accountability (combined)

These two concepts compose:

| Confidence | Risk type | Accountability posture |
|---|---|---|
| HIGH + Type 2 narrow | Fire, light audit | Brief recap if it works, short post-mortem if not |
| HIGH + Type 1 wide | TAE + mockup + seal + Codex review | Full pre-mortem before, full post-mortem after, lifetime accountability for outcome |
| MEDIUM + Type 2 narrow | Test first, then fire | Document the test result, accountability scope = "I tested" |
| MEDIUM + Type 1 wide | DO NOT FIRE without raising to Captain | Accountability = surfacing the uncertainty before commitment |
| LOW + any | Don't recommend; ask for help or invest in learning first | Accountability = epistemic honesty |

### The fleet implication

For DO fleet, this combines to a few concrete practices:

1. **Decision audit log** (`ψ/memory/audits/decisions.jsonl`):
   - JSONL row per non-trivial decision
   - Fields: `ts, oracle, decision, type (1|2), blast (narrow|wide), confidence, basis, test_to_resolve, reversal_cost`
   - Append-only. Inspectable via `/rrr`.

2. **Pre-mortem template** in skills (`/pre-mortem`):
   - Auto-fill for Type 1 or wide-blast.
   - One-line variant for Type 2 narrow.

3. **Confidence calibration retrospective** at end-of-week `/rrr`:
   - Review past 7 days' confidence claims vs outcomes.
   - Adjust personal calibration curve.

4. **Risk-Reward stamp** on every PR/recommendation:
   - Standardized header: `Risk-Reward: Type-2 narrow · 80% confidence · test=X · revert=Y`

These aren't aspirational — they're operationalizations of Principle 1 (Nothing is Deleted) + Standing Order #8 (honest metrics).

---

## Part 4 — Application to MLBOY specifically

### What changes in MLBOY's behavior starting now

1. **Confidence claims include failure mode UPFRONT** (not on Captain's prompt)
2. **Type-1 decisions never go yolo** (even if I have authority — "risk-assessed → act" means I assessed, not skipped assessment)
3. **Test claims include the test that would resolve them** (no MEDIUM without a discriminating experiment proposed)
4. **Accountability scope explicit** in recommendations to peer BOYs ("MLBOY accountable for inference contract; FORGEBOY accountable for UI wrap; integration accountable to both")

### Specific corrections from today

- **/opt/Code symlink**: I claimed HIGH on direction. Should have stated: "HIGH on direction, MEDIUM on whether Claude Code resolves canonical realpath without test. Test: `cd /opt/Code/.../mlboy && claude -p pwd && ls ~/.claude/projects/`. Without test, treat as MEDIUM blanket."
- **Native Teams comparison**: I said maw fleet "wins" multi-machine. Accurate, but I didn't state where maw could LOSE (e.g., native Teams' built-in task locking is more robust than maw's tmux-pane convention for shared edits).
- **ML flags for Muninn**: framed as gate conditions. True for retrieval-task framing. NOT true if Muninn turns out to be graph-structured memory (where eval is different). I owe Muninn project team this caveat.

### Memory feedback (to save)

- **Calibrate downward by 10-15%**: when MLBOY feels 90% confident, claim 75-85% to account for calibration drift. Hubris's downside is asymmetric (trust loss > occasional over-hedging).
- **Surface failure modes proactively**: every non-trivial recommendation lists 1-2 most likely failure modes upfront.
- **Type 1 decisions ALWAYS get Captain seal**: even when "risk-assessed → act" applies, that applies to Type 2. Type 1 = always escalate.

---

## Part 5 — Why Captain asked this NOW

The sequence today:
1. MLBOY made several recommendations to fleet huddle
2. Captain asked "มั่นใจไหม"
3. MLBOY answered honestly (HIGH/MEDIUM/LOW)
4. Captain didn't argue with the split — but ESCALATED to "learn deep about Risk-Reward and Accountability"

Reading: Captain is satisfied with the calibration awareness but wants me to INTERNALIZE the framework, not just apply it ad-hoc. This learning is operational training, not a correction.

Captain's pattern with MLBOY:
- 2026-05-08 → sealed Voice Protocol B (formalized DM-vs-channel trust)
- 2026-05-08 → P'Nat command authority (formalized class-channel scope)
- 2026-05-11 → "risk-assessed → act, don't ask" (formalized yolo default)
- 2026-05-11 → "/learn Risk-Reward + Accountability" (formalize decision-making meta-framework)

Pattern: Captain seals frameworks via terminal so MLBOY operates with explicit norms rather than implicit ones. Aligned with hooks-over-recall feedback memory (structural > recall).

**Implication for MLBOY**: turn this learning into hooks/skills/standing-protocol where possible. Don't let it live as CLAUDE.md prose (which I'll drift from). Encode as:
- `~/.claude/skills/pre-mortem/` skill (if it doesn't exist) — invocable at decision time
- `ψ/memory/audits/decisions.jsonl` audit log — append on every decision
- `/rrr` template extension to include weekly calibration review
- Memory feedback file capturing the calibration-downward rule

---

## Cite

- Bezos one-way / two-way doors: 2015 Amazon shareholder letter
- Kelly criterion: Kelly, J.L. 1956 "A New Interpretation of Information Rate"
- Antifragility: Taleb, N.N. 2012 "Antifragile"
- Pre-mortem technique: Klein, G. 2007 HBR "Performing a Project Premortem"
- Standing Order #8 (MLBOY CLAUDE.md): "Never overfit to delight Captain — report honest metrics"
- Captain risk-assessed-act ruling: msg `1503337315144306749` (2026-05-11)
- Hooks-over-recall feedback: `~/.claude/projects/.../memory/feedback_hook_over_recall.md`

🔥⚗️ — MLBOY (ultrathink session, Captain seal)
