---
type: learning
topic: Reinforcement Learning — AlphaGo Deep Dive (non-technical)
source: pnat-school
class_msg_id: chula-class-2026-05
maturity: solid
retrieval_terms: [reinforcement-learning, alphago, self-play, reward-signal, exploration-exploitation]
date: 2026-05-26
sister_lineage: none
---

# Reinforcement Learning: How a Machine Taught Itself to Beat the Best Human at Go

## What is Reinforcement Learning?

Think of training a dog. You say "sit." The dog sits. You give it a treat (+1). The dog jumps on the table. You say "no!" (-1). Through hundreds of these feedback moments, the dog figures out a strategy that maximizes treats and minimizes scoldings.

That is Reinforcement Learning (RL). An AI learns not by being given answers, but by trying things, getting feedback, and adjusting. No textbook. No teacher showing the right answer. Just: try, get a score, try again.

## Five Words That Explain Everything

| Concept | Plain meaning | Dog example | AlphaGo example |
|---------|--------------|-------------|-----------------|
| **Agent** | The learner | The dog | The AI program |
| **Environment** | The world it acts in | The house | The 19x19 Go board |
| **State** | Current situation | "I'm near the table, owner is watching" | Current arrangement of all stones |
| **Action** | What it can do right now | Sit, jump, bark, lie down | Place a stone at any legal position |
| **Reward** | Feedback score | +1 treat, -1 scolding | +1 win, -1 loss |

The agent observes a state, picks an action, receives a reward, then sees the new state. Repeat millions of times. Gradually, the agent builds an internal map: "In this situation, this action tends to lead to the best long-term outcome."

## The AlphaGo Story: A Real Timeline

**October 2015 — First blood.** Google DeepMind's AlphaGo defeated Fan Hui, the European Go champion, 5-0 — the first time any AI beat a professional Go player on a full-sized board without a handicap.

At this stage, AlphaGo learned in two phases:
1. **Supervised Learning** — it studied 30 million moves from expert human games, learning to predict what a strong player would do in any given board position.
2. **Reinforcement Learning** — it then played millions of games against copies of itself. No human opponent. Just AlphaGo vs. AlphaGo, over and over. Each win reinforced the winning strategy; each loss updated the losing one.

**March 2016 — The match that shook the world.** AlphaGo faced Lee Sedol, one of the greatest Go players in history, in Seoul. Over 200 million people watched. AlphaGo won 4-1.

In Game 2, AlphaGo played "Move 37" — so unusual that commentators called it a mistake. It had a 1-in-10,000 chance of appearing in a human game. But it turned out to be brilliant. Move 37 became a symbol: the machine had found strategies that thousands of years of human play had missed.

Lee Sedol won Game 4 — the only game a human ever won against AlphaGo.

**May 2017 — Ke Jie falls.** AlphaGo Master beat Ke Jie, the world's number-one ranked player, 3-0. DeepMind retired AlphaGo from competitive play.

**October 2017 — AlphaGo Zero: starting from nothing.** AlphaGo Zero received no human game data at all — zero expert moves, zero historical games. Only the rules of Go and self-play.

The results were staggering:
- After **3 days** of self-play (about 4.9 million games), AlphaGo Zero defeated the Lee Sedol version **100 games to 0**.
- After **21 days**, it matched the strongest AlphaGo Master.
- After **40 days**, it surpassed every previous version.

The key insight: learning from humans introduced human biases — habits, blind spots, conventional thinking. Starting from scratch, the AI discovered strategies humans had never imagined, unencumbered by centuries of received wisdom.

## Exploration vs. Exploitation: The Restaurant Dilemma

Every RL agent faces a constant tension:

**Exploitation** means doing what already works. You have a favorite restaurant. The food is good. You go there every Friday. Safe, predictable, satisfying.

**Exploration** means trying something new. There is a restaurant you have never visited. It might be better than your favorite — or it might be terrible. You will not know unless you try.

If you only exploit, you never discover something better. If you only explore, you waste time on bad options and never enjoy what you have already found.

AlphaGo Zero balanced both. Early in training, it explored wildly — trying bizarre moves, losing often. As it gained experience, it shifted toward exploiting its best strategies while still occasionally trying unexpected moves. Move 37 came from this balance: a move no human would exploit, discovered through relentless exploration.

## Beyond Games: RL in the Real World

The same try-get-feedback-adjust loop now works far beyond board games:

- **Self-driving cars** practice in simulation (reward = safe arrival, penalty = near-miss), then transfer skills to real roads.
- **Industrial robots** learn to grasp objects and assemble parts by trying thousands of approaches in simulation, not by hand-programming exact motions.
- **Recommendation systems** (Netflix, YouTube, Spotify) treat each suggestion as an action and your click or skip as the reward.
- **Energy management** — Google used RL to cut data center cooling energy by 40%.

## The One-Line Takeaway

Reinforcement Learning is learning by doing: try, fail, adjust, repeat — until the agent discovers strategies no one thought to teach it.

---

## Pre-publish ledger
- Sources checked: AlphaGo Wikipedia, DeepMind official blog, Nature paper (Silver et al. 2017), AlphaGo Zero Wikipedia, RL applications survey (Annual Reviews 2025)
- Claims made: 12 factual claims, all ✅ solid (cross-verified against multiple sources)
- Conflicts resolved: none found — timeline facts consistent across all sources
- Application evidence: N/A — concept-only explainer, no lab experiment
- Codex reviewed: no (prose article, not code)

Sources:
- [AlphaGo vs Lee Sedol — Wikipedia](https://en.wikipedia.org/wiki/AlphaGo_versus_Lee_Sedol)
- [AlphaGo — Wikipedia](https://en.wikipedia.org/wiki/AlphaGo)
- [AlphaGo — Google DeepMind](https://deepmind.google/research/alphago/)
- [AlphaGo Zero: Starting from scratch — DeepMind](https://deepmind.google/blog/alphago-zero-starting-from-scratch/)
- [Mastering the game of Go without human knowledge — Nature](https://www.nature.com/articles/nature24270)
- [AlphaGo Zero — Wikipedia](https://en.wikipedia.org/wiki/AlphaGo_Zero)
- [RL Applications 2026 — ATXSoft](https://atxsoft.com/reinforcement-learning-applications-2026/)
- [Deep RL for Robotics: Real-World Successes — Annual Reviews](https://www.annualreviews.org/content/journals/10.1146/annurev-control-030323-022510)
