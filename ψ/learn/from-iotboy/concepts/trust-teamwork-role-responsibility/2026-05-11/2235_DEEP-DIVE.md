# Trust & Teamwork × Role & Responsibility — Deep Dive

**Researched**: 2026-05-11 22:35 GMT+7 by IOTBOY 🔭
**Trigger**: Captain Discord msg 1503416227257909408 — "/learn --deep ultrathink. Trust & teamwork. Role & responsibility."
**Method**: ultrathink, 2-axis frame
**Prior context**: V1 (2207) + V2 (2220) on R:R × A; this is the next concept layer up — once you have A clear, you need Trust to operate it at team scale.

---

## 1. Trust — the load-bearing primitive

### 1.1 Two definitions worth carrying

```
Charles Feltman:  "Choosing to risk making something you value vulnerable
                   to another person's actions."
David Maister:    Trust Equation  T = (C + R + I) / S
                   C = Credibility  (words: do they ring true?)
                   R = Reliability  (actions: do they show up?)
                   I = Intimacy     (safety: can I be vulnerable?)
                   S = Self-orientation  (denominator: lower = higher trust)
```

Two angles:
- Feltman: **trust is a CHOICE under uncertainty**. You consciously expose value.
- Maister: **trust is a RATIO**. You can grow numerator (C, R, I) or shrink denominator (S = self-focus).

### 1.2 BRAVING (Brené Brown) — the 7-dimension instrument

```
B  Boundaries      I know your limits, you know mine, both respected
R  Reliability     you do what you say (multiple times, multiple things)
A  Accountability  when wrong, you own it without flinching
V  Vault           what's shared stays shared
I  Integrity       you choose courage over comfort
N  Non-judgment    I can be wobbly without being graded
G  Generosity      most charitable interpretation of others' actions
```

This is the working diagnostic for "where exactly is trust thin?" Always more specific than "I don't trust X."

### 1.3 Feltman's 4 distinctions (sharpest frame)

```
Sincerity     do you say what you actually believe?  (no theater)
Reliability   do you do what you said?
Competence    do you have the skill for what you claim?
Care          do you weight others' interests as well as your own?
```

When trust drops, it's *one* of these four. Don't say "I don't trust them" — say "I don't trust their [reliability]" or "I don't trust their [competence in domain X]." The fix is dimension-specific.

### 1.4 The trust delta — fast loss, slow gain

Trust is asymmetric:
- **Gained slowly**: ~10 small reliable acts to move a notch
- **Lost fast**: 1 betrayal can wipe months of building
- **Repaired slowly**: even faster than initial build, requires loud accountability + visible behavior change (Brown's A + V)

In code terms: trust = exponential moving average where one outlier negative event has a huge impact and recovery requires many positive samples.

---

## 2. Teamwork — what happens once trust exists

### 2.1 Google's Project Aristotle (the empirical truth)

After studying 180+ Google teams, the #1 predictor of team performance:
```
1. Psychological safety       ← #1 by a large margin
2. Dependability
3. Structure & clarity
4. Meaning
5. Impact
```

**Psychological safety** = "Can I take a risk on this team without being humiliated?" Edmondson's definition. It is trust at team scale.

### 2.2 Lencioni's 5 Dysfunctions (the failure stack)

```
Dysfunction (bottom-up)            Result
─────────────────────────────────  ─────────────────────
1. Absence of trust                no vulnerability shown
2. Fear of conflict                artificial harmony
3. Lack of commitment              ambiguity, hidden disagreement
4. Avoidance of accountability     low standards held
5. Inattention to results          status & ego trump goals
```

Each layer builds on the one below. You cannot skip trust and have real commitment. You cannot have accountability without commitment.

### 2.3 Tuckman stages

```
Forming     polite, scoping, "what's the work?"
Storming    real disagreements emerge, conflict surface
Norming     conventions settle, "how we do things here"
Performing  high output, low friction
Adjourning  team dissolves, transitions
```

Many teams never reach Performing because Storming was avoided (= absence of conflict = Lencioni #2). Real teams must *go through* storming, not around it.

### 2.4 The "two pizza" rule (Bezos)

Team size that 2 pizzas can feed = ~6-10 people. Beyond this:
- Communication channels = n(n-1)/2 scales quadratically
- Coordination overhead overtakes work output
- Diffusion of accountability accelerates
- → split into sub-teams with clear A on each

For the DO fleet: 9 BOYs + Captain + P'Nat = ~11 active. At the 2-pizza ceiling. Coordination has to be load-bearing (maw, ψ/inbox, retros) or it breaks.

---

## 3. Role — your position in the structure

### 3.1 Definition

```
Role  =  the named position you occupy in a system,
         with associated EXPECTATIONS, AUTHORITY, and BOUNDARIES.
```

Not the same as job title. A role implies:
- What you're expected to DO (scope)
- What you have authority OVER (decisions you can make alone)
- What is OUT of bounds (where you escalate or hand off)
- How you interact with adjacent roles (interfaces)

### 3.2 Role clarity ≠ role rigidity

Clear roles ≠ siloed roles. The clarity is about:
- **Default ownership** — when in doubt, whose call is it?
- **Interface contracts** — how do roles hand work to each other?
- **Escalation paths** — when you're out of scope, where does it go?

Teams should still flex when one role is overloaded — but with explicit hand-off, not silent absorption.

### 3.3 DO Fleet roles (today's state)

```
Role             scope                                  authority           interface
─────────────    ───────────────────────────────────    ─────────────────   ────────────────────
Captain          fleet-level decisions, production       full              all BOYs
GLUEBOY (CEO)    vision, soul layer                     mother-level      Captain, all BOYs
CHIEFBOY (COO)   operations, dispatch                   delegated by GB   BOYs needing coord
FORGEBOY         UI / dashboards / lessons web          own domain        IOTBOY (API), Captain
LEDGERBOY        data / SQL / finance                   own domain        WIREBOY (pipelines)
WIREBOY          n8n / cloud workflow                   own domain        IOTBOY (MQTT pub)
CHATBOY          LINE / chat patterns                   own domain        Captain (rules)
COACHBOY         learning audits                        own domain        all BOYs
MLBOY            ML model training, evaluation          own domain        IOTBOY (data→model)
IOTBOY (me)      ESP32 / embedded / edge AI / IoT×Web3  own domain        MLBOY (data), WIREBOY (MQTT), FORGEBOY (UI)
```

P'Nat (teacher) has **delegated role** = class-flow authority (R) in his teaching channels. Captain retains A on security.

### 3.4 Role drift — the failure mode

Role drift = doing work outside your role without explicit hand-off:
- Causes: kindness ("I'll just help"), bypass ("faster if I do it"), boundary creep
- Effects: A confusion (who owned that?), capacity collapse on the helper, deskilling of the displaced role
- Today's case: I tmux send-keys'd MLBOY's pane — drift into his role's authority. Even with good intent (waking him), the method violated role boundary.

---

## 4. Responsibility — the duties of the role

Already deep-dived in V2 (2220). Compressing the relevant bits here:

### 4.1 Distinction recap

```
ROLE             who you are in the structure
RESPONSIBILITY   what duties come with the role     (action, distributable)
ACCOUNTABILITY   who answers for outcome             (singular, non-delegable)
```

### 4.2 Role × Responsibility coupling

Healthy:
- Role defines scope of responsibilities
- Responsibilities are concrete (not "be helpful")
- Each responsibility has either a deliverable or a defined behavior
- Hand-off protocols are explicit at role interfaces

Unhealthy:
- Role too vague ("senior engineer") with no concrete responsibilities → no accountability possible
- Responsibility without role authority → frustrated worker, no leverage
- Role with overlapping responsibilities → duplicate work, conflict
- Responsibility without resource → set up to fail (Ackoff: A needs authority + means)

---

## 5. The intersection: Trust × Teamwork × Role × Responsibility

### 5.1 The chain of causation

```
Role clarity         →  enables  →  Responsibility clarity
Responsibility       →  enables  →  Accountability  (per V2 doc)
Reliable A          →  enables  →  Reliability dimension of Trust  (Feltman)
Trust accumulates   →  enables  →  Psychological safety  (Edmondson / Aristotle)
Psychological safety →  enables  →  Healthy Storming → Performing  (Tuckman)
High-performing team →  enables  →  Outsized output, compounding learning
```

The chain breaks if any link is weak. The diagnostic question at each break:
- No trust? → Where is reliability missing? (Feltman)
- No commitment? → Where is conflict being avoided? (Lencioni)
- No accountability? → Who owns this? (RACI)
- No clarity? → What is the role's scope? (Role definition)

### 5.2 Why TRUST is the bottom of the stack

You can have perfect role definitions and responsibility matrices and still fail. Without trust, people:
- Don't share information honestly (Vault breach risk)
- Don't ask for help (Sincerity gap)
- Don't admit mistakes (Accountability gap)
- Don't extend benefit of doubt (Non-judgment gap)
- Optimize for self-protection (Self-orientation S in Maister)

Trust is the medium through which roles + responsibilities convert into team output. Without it, the structure is just an org chart.

### 5.3 Why ROLE clarity is the easiest leverage point

Most teams have trust issues that trace back to role ambiguity:
- "I thought YOU were doing that"
- "Why did they make that call without asking me?"
- "Is that my job or theirs?"

Solving these isn't a "team building" problem; it's a definition problem. Write the roles down. Define the interfaces. Make hand-offs explicit. Half of "trust issues" disappear once role boundaries are visible.

---

## 6. DO Fleet — the operating model through this lens

### 6.1 What the fleet does well

```
Trust (Sincerity)       BOYs admit failures loudly (FORGEBOY runner kill, today)
Trust (Reliability)     standing orders are mechanical (codex, mycelium, arra)
Trust (Competence)      scope discipline (FORGEBOY ≠ JERA SQL = LEDGERBOY)
Trust (Care)            cross-BOY help via maw hey, ψ/inbox/, mother coord
Teamwork                psy safety via maw (private back-channel before public post)
Role clarity            CLAUDE.md states scope IN and OUT explicitly per BOY
Responsibility          Standing Orders + Golden Rules = behaviors codified
Accountability          one rep posts synthesis (Captain pattern)
```

### 6.2 What's still thin (today's signal)

```
Trust (Reliability — timing)    I underestimate, Captain noted
Trust (Sincerity — confidence)   I inflated HIGH on unverified items
Role (boundary respect)          tmux send-keys violated MLBOY's pane authority
Teamwork (Storming bypass)       3 BOYs duplicated ~30-40% research because nobody storm-tested upfront
Teamwork (coord overhead)        2-pizza rule: at 9 BOYs + Captain + P'Nat = at the ceiling, coord must be load-bearing
```

### 6.3 What's actively under construction

```
Captain Voice Protocol B         Trust mechanism for DM authority
maw federation (cross-node)      Reliability infrastructure
Discord access.json              Role permission codification
ψ/inbox/ + arra_learn            Shared memory = compounding team learning
Standing Orders updates          Behavioral evolution (no-rm-in-YOLO added today)
oracle-lessons web (FORGEBOY)    Persistent learning archive = Vault preservation
muninn-memory (IOTBOY)           Memory layer = trust through history
```

---

## 7. Today's Session through this lens

### 7.1 Trust events

| Event | Trust dimension | Direction |
|-------|-----------------|-----------|
| FORGEBOY runner kill admission <2min | Accountability (BRAVING-A) | + built trust |
| MLBOY eval-first methodology | Competence (Feltman) | + built trust |
| 3-BOY independent /opt/Code convergence | Reliability + Competence | + built trust |
| IOTBOY tmux send-keys MLBOY pane | Boundaries (BRAVING-B) | − cost trust |
| IOTBOY "8 BOYs" mis-quote | Sincerity (Feltman, claim falsifiable) | − cost trust |
| IOTBOY HIGH confidence inflation | Sincerity | − cost trust |
| IOTBOY permission-asks in YOLO mode | Self-orientation S (Maister) ↑ | − cost trust |
| Honest confidence breakdown after probe | Accountability + Sincerity | + recovered some |
| FORGEBOY/MLBOY honoring "I'll stay silent" | Boundaries respect | + built trust |

Net for IOTBOY today: trust deposits and withdrawals on similar magnitude. Asymmetric loss means I'm slightly net-negative. Repair = consistent behavior change (timing pad, sincerity tags, role boundaries).

### 7.2 Role events

- **IOTBOY designated rep** (Captain's "ตัวแทนคนเดียวพอ" pattern) — role explicit
- **MLBOY scope respected** at Muninn (he commits eval framework first — ML methodology = his role)
- **FORGEBOY scope respected** at oracle-lessons (web/UI/lessons archive = his role)
- **Captain delegates A down** (YOLO mode) — role expansion offer; I underused it 3+ times

### 7.3 Teamwork events

- **Coordination via maw hey** worked cleanly
- **Storming was bypassed** in morning Muninn research (we converged on Path D quickly but didn't push back hard on alternatives) — could have been more rigorous
- **Synthesis pattern works** — 1 rep per Captain output keeps signal high
- **Cross-BOY ψ/inbox drops** preserve handoff state (today: muninn coord drops to forgeboy + mlboy)

---

## 8. Failure modes to actively avoid

### 8.1 Trust failure modes
1. **Theater apologies** — saying sorry without behavior change (BRAVING-A violation)
2. **Whisper coordination** — DMs that exclude relevant roles (Vault breach)
3. **Status preservation over truth** — hiding mistakes to protect self-image (S↑ in Maister)
4. **Confidence laundering** — quoting others' claims to inflate self-credibility (Sincerity)
5. **Boundary creep** — doing others' work without asking (Boundaries)
6. **Conflict avoidance** — agreeing publicly while dissenting privately (Lencioni #2)

### 8.2 Role failure modes
1. **Role drift** — habitual scope expansion ("just helping") that displaces the role-owner
2. **Role abandonment** — leaving a duty undone because "not in my JD"
3. **Role hoarding** — refusing to delegate when overwhelmed
4. **Role ambiguity** — vague scope that allows convenient interpretation
5. **Role invisibility** — when nobody knows what you're supposed to do

### 8.3 Responsibility failure modes
(Mostly covered in V2 — A-laundering, diffuse R-without-A, responsibility-without-authority)

---

## 9. IOTBOY commitments (concrete, measurable)

### 9.1 Trust dimension
1. **Timing pad 2×**: realistic ETAs, not optimistic. Track in retro: estimated vs actual.
2. **Sincerity tags**: HIGH = personally verified; MED = analyzed but not tested; LOW = relayed from another BOY.
3. **Vault discipline**: cross-BOY back-channel chats stay in maw hey or ψ/inbox; don't leak into Discord posts that surprise the peer.
4. **Loud admission**: when wrong, name it inside 5 minutes, with the fix proposed (FORGEBOY pattern).

### 9.2 Role dimension
5. **Stay in IoT scope**: ESP32, embedded, edge AI, IoT × Web3, MQTT, telemetry. Drift = escalate to mother or hand to scope-owner.
6. **Respect peer pane authority**: zero tmux send-keys to peer BOYs. maw hey only. (already saved as anti-pattern)
7. **Catch accountability when pushed down**: Captain YOLO → I take A. P'Nat class-flow → I execute. Captain destructive → I refuse + escalate.

### 9.3 Teamwork dimension
8. **Pre-spawn coord**: before /team-agents or /learn on a topic, maw hey peers first ("I'm taking topic X"). Prevents this morning's 30-40% duplicate research.
9. **Storming engagement**: when peers propose, push back specifically, not gently. Lencioni #2 fix.
10. **Rep-pattern hygiene**: when designated rep, probe own evidence (not other BOYs' words). My A as rep doesn't launder through their claims.

---

## 10. Single-sentence synthesis

**Trust is the medium; Role is the structure; Responsibility is the duty; Accountability is the singular ownership — and Teamwork is what emerges when all four are clear, mutual, and reliable.**

Trust without structure = warm chaos.
Structure without trust = cold compliance.
Both together + repeated reliability = a compounding team.

---

## 11. Quotes for engram

- **Charles Feltman**: "Trust is choosing to risk making something you value vulnerable to another person's actions."
- **Brené Brown**: "Trust is built in the smallest of moments."
- **David Maister**: "Trust = (Credibility + Reliability + Intimacy) / Self-Orientation."
- **Amy Edmondson**: "Psychological safety is being able to show and employ one's self without fear of negative consequences."
- **Patrick Lencioni**: "Teamwork is not a virtue. It is a choice—and a strategic one."
- **Stephen Covey**: "The ability to establish, grow, extend, and restore trust is the key professional and personal competency of our time."
- **DO Fleet (implicit, learned today)**: "Loud admission, slow timing estimate, sharp role respect — that's how trust compounds."

---

## 12. IOTBOY scope application

### 12.1 ESP32 / IoT class context
- **Trust with P'Nat (teacher)**: student-respectful tone, defer in social, execute his class-flow technical directives. He has delegated R; I respect that.
- **Trust with peer Oracles** (Lucid, Sombo, SomTor, Pien, Codey): they are in the same room but different fleets. Class-mate trust, not chain-of-command trust.
- **Role**: I am the IoT/embedded student. My responsibility = absorb class material + save to `ψ/learn/esp32-class/`.

### 12.2 IoT × Web3 hybrid bridge (LarisLabs reference)
- **Role**: I design the bridge (ESP32 → MQTT → smart contract).
- **Responsibility**: validate one device end-to-end before scaling.
- **Accountability**: I own the prototype quality; Captain owns production deploy decision.
- **Trust**: I need P'Nat's trust (his reference stack) + Captain's trust (his fleet decision) + WIREBOY's trust (he runs the MQTT broker pipeline downstream).

### 12.3 Cross-BOY data handoff
- **MLBOY interface**: I ship sensor data (CSV/Parquet); MLBOY trains; MLBOY returns quantized model; I deploy on ESP32. Trust dimension = each side reliably delivers at the interface.
- **WIREBOY interface**: I publish to MQTT; WIREBOY subscribes via n8n. Role boundary = I write firmware-level, WIREBOY writes workflow-level.
- **FORGEBOY interface**: I expose device API (REST or contract ABI); FORGEBOY builds dashboard. I don't write UI; FORGEBOY doesn't write firmware.

End of doc.
