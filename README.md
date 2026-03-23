# PromptCircle
### A Multi-Agent Deliberation System for iOS

Most AI apps route your question to one model and return one answer. PromptCircle treats your question as a **discussion topic** — it runs it through a structured three-agent deliberation protocol and surfaces a unified verdict grounded in inter-model reasoning.

---

## The Core Idea

Single-model reasoning collapses all possible perspectives into whatever the model's dominant training distribution favors. PromptCircle introduces **disagreement by design**: agents first form independent positions, then directly respond to each other's arguments, and finally a synthesis layer resolves the tension into one grounded answer.

This maps to a real research question — does structured adversarial collaboration between multiple LLMs produce better reasoning than a single model reasoning alone?

---

## Two Modes

| Mode | What Happens |
|------|-------------|
| **Standard Chat** | Question goes to Grok → Claude → Gemini sequentially. Each model sees the previous responses. Gemini synthesizes a final answer using collective context. |
| **Council Session** | Structured three-round protocol. Round 1: independent stance. Round 2: cross-examination by name. Round 3: verdict that cites each agent explicitly. |

---

## Full System Flow

### Standard Chat

```
User Input
    │
    ▼
Grok  ←  "short & crisp answer to: [question]"
    │
    ▼
Claude  ←  "short & crisp answer to: [question]"
    │
    ▼
Gemini  ←  "Grok said: [X]. Claude said: [Y]. Synthesize final answer."
    │
    ▼
Screen (Grok + Claude bubbles auto-collapse, Gemini response stays visible)
```

This is **context-aware synthesis** — Gemini receives external information (the other models' responses) to produce a better answer. A form of Retrieval-Augmented Generation, except the "retrieved" content is other models' reasoning rather than documents.

---

### Council Session — The Agentic Pipeline

```
User types question → taps purple council button
            │
            ▼
    AgentSessionViewModel.startSession()
            │
┌───────────▼────────────────────────────────────────┐
│  ROUND 1 — Opening Stance  (all 3 in parallel)     │
│                                                    │
│  Grok   ← "You are Grok — sharp, direct.           │
│             Give opening stance in 2-3 sentences." │
│                                                    │
│  Claude ← "You are Claude — nuanced, careful.      │
│             Give opening stance in 2-3 sentences." │
│                                                    │
│  Gemini ← "You are Gemini — analytical.            │
│             Give opening stance in 2-3 sentences." │
└───────────┬────────────────────────────────────────┘
            │  (wait for all 3, reveal staggered)
            ▼
┌───────────▼────────────────────────────────────────┐
│  ROUND 2 — Cross-Examination  (all 3 in parallel)  │
│                                                    │
│  Grok   ← sees: Gemini R1 + Claude R1 (not own)   │
│  Claude ← sees: Grok R1 + Gemini R1 (not own)     │
│  Gemini ← sees: Grok R1 + Claude R1 (not own)     │
│                                                    │
│  Each must reference others by name.               │
│  Each sees only what others said — not itself.     │
└───────────┬────────────────────────────────────────┘
            │  (wait for all 3, reveal staggered)
            ▼
┌───────────▼────────────────────────────────────────┐
│  ROUND 3 — Verdict  (sequential — needs all prior) │
│                                                    │
│  Gemini (moderator) ← full transcript:             │
│    • Grok R1 + R2                                  │
│    • Claude R1 + R2                                │
│    • Gemini R1 + R2                                │
│                                                    │
│  Output: "After discussing with Grok (who...)      │
│  and Claude (who...), we conclude..."              │
└────────────────────────────────────────────────────┘
```

**Why partial observability in Round 2?**
Each agent sees only the other two's outputs — not its own Round 1. If Grok saw its own response, it would reinforce its position rather than genuinely engage with external arguments. Hiding its own output forces authentic cross-examination. This is a deliberate architectural choice, not a limitation.

**Why parallel in Round 1 and 2, sequential in Round 3?**
Rounds 1 and 2 have no inter-agent dependencies within the round — they can fire simultaneously. Round 3 must wait for all six prior responses. Total latency = `max(R1 calls) + max(R2 calls) + verdict_call` instead of summing all six calls serially.

---

## Technical Architecture

```
PromptCircle/
├── Models/
│   ├── Message.swift              — chat message, SenderType, AIModel enums
│   └── AgentSession.swift         — SessionMessage, SessionPhase for council mode
│
├── Services/
│   └── AIService.swift            — all API calls, routing, response decoding
│
├── ViewModels/
│   ├── ChatViewModel.swift        — standard chat orchestration (@MainActor)
│   └── AgentSessionViewModel.swift — council protocol, prompts, round management
│
└── Views/
    ├── ChatView.swift             — root view, sheet presentation
    ├── AgentSessionView.swift     — council room UI, verdict card, opinion chips
    ├── MessageBubble.swift        — collapsible message cards per model
    ├── ChatInputBar.swift         — council button appears only on text input
    └── CustomNavbar.swift
```

### API Routing

| Label in App | Actual Model | Provider |
|---|---|---|
| Grok | `llama-3.3-70b-versatile` | Groq (OpenAI-compatible) |
| Gemini | `gemini-2.5-flash` | Google Generative AI |
| Claude | `gemini-2.5-flash` (second key, Claude persona prompt) | Google Generative AI |

"Claude" runs on Gemini with role-conditioned prompting. Same weights, different instructions. Persona conditioning meaningfully shifts output style — the cross-examination outputs are demonstrably different in tone and focus even from the same base model. A real Anthropic API key is a one-line swap in `AIService.swift`.

### Concurrency Model

```swift
// Round 1 — all three fire simultaneously
async let grokFuture   = service.getAIResponse(for: .grok,   prompt: openingPrompt(.grok,   q: question))
async let claudeFuture = service.getAIResponse(for: .claude, prompt: openingPrompt(.claude, q: question))
async let geminiFuture = service.getAIResponse(for: .gemini, prompt: openingPrompt(.gemini, q: question))

let (g, c, gem) = await (grokFuture, claudeFuture, geminiFuture)
```

Swift's structured concurrency (`async let`) — all three API calls dispatch simultaneously. UI updates happen on `@MainActor`. The `scrollTick: UUID` pattern triggers auto-scroll on every state change without tight coupling between ViewModel and View.

### UI State Machine

Every screen transition is driven by `@Published` state — no manual event handling:

```
openingMessages[i].isThinking = true   →  typing dots animate
openingMessages[i].isThinking = false  →  content reveals with spring animation
currentPhase = .discussion             →  phase label updates
verdict != nil                         →  golden verdict card animates in
isComplete = true                      →  LIVE badge switches to "Done"
```

---

## Key Technical Decisions and Why

**1. Role-conditioned prompting instead of fine-tuning**
Each model gets a persona prompt assigning it a distinct reasoning style. This shifts output distribution without touching weights. In production, you'd validate empirically whether fine-tuning a dedicated "challenger" model improves verdict quality over prompting — but prompting lets you ship and iterate fast.

**2. Staggered visual reveal despite parallel execution**
All three API calls complete before any card updates. The 300–400ms stagger is purely visual — it creates the feeling of a live discussion rather than a batch dump of results. The underlying execution is still maximally parallel.

**3. Council button appears only on text input**
The button is hidden when the field is empty and animates in with a spring when the user types. This prevents confusion — the session is always about a specific question the user has in mind, never a blank slate.

**4. Full transcript in verdict prompt**
All six prior responses go to the moderator. This is expensive in tokens but necessary — the synthesizer needs to know not just what each agent concluded, but how their position evolved between Round 1 and Round 2. A model that only sees R1 misses the cross-examination dynamics.

---

## Connection to Current Research

| Research Problem | How This App Touches It |
|---|---|
| **Scaling Agentic Capabilities, Not Context** | Verdict prompt context grows linearly with rounds — exactly the problem the paper addresses. More agents or more rounds would hit context limits fast. |
| **Learning When to Act or Refuse** | System always runs all three rounds regardless of question complexity. A calibrated system would short-circuit for simple questions. |
| **Fara-7B: Computer Use** | Same agentic loop — observe, reason, act — but in a text-only environment. Fara-7B handles stochastic visual environments; this handles static text state. |
| **Think Right: Under-Over Thinking** | Simple questions get three full rounds — over-processing. Adaptive compute would run one round when Round 1 consensus is strong, three rounds when agents diverge. |
| **Agentic Reasoning via RL** | Protocol is entirely prompt-engineered — static and hand-crafted. RL training would let the deliberation policy emerge from reward signal rather than be specified by hand. |

---

## What I'd Build Next (Research Directions)

**Synthetic data pipeline**
The council transcript is structured training data by design:
- Question → 3 independent stances → 3 cross-examinations → 1 verdict
- Run 50,000 questions across factual, reasoning, and ethical domains
- Extract preference pairs from Round 1 outputs → DPO fine-tuning data
- Score verdicts against ground truth on factual questions → reward model training data
- Zero human annotation beyond question sourcing

**Fine-tune the synthesizer**
Train a 7B model specifically on (6-response transcript → verdict) pairs. Hypothesis: a model trained on deliberation transcripts will learn to weight agent contributions more intelligently than a general-purpose model following a synthesis prompt. When Grok and Claude strongly disagree, it should hedge — not average.

**RL on the full protocol**
Use verdict quality as a reward signal and train the entire pipeline end-to-end — not just the synthesizer, but how each agent frames its Round 2 response to maximize final verdict quality. This is the experiment that connects most directly to "Agentic Reasoning and Tool Integration via RL."

**Adaptive stopping**
After Round 1, classify whether further deliberation will change the verdict — if agent consensus is strong, go straight to verdict. If divergence is high, run Round 2. This directly applies the "Think Right" insight to multi-agent orchestration.

**Tool use layer**
Give agents access to search and a calculator. Round 2 cross-examination with tool calls — Grok fetches a stat, Claude verifies a source. Verdict grounds claims against retrieved evidence rather than model weights alone.

---

## Frequently Asked Questions

---

**"How is this different from chain-of-thought prompting?"**

Chain-of-thought is single-agent, single-perspective. The model talks to itself — generates intermediate reasoning steps, but all within one consistent viewpoint. There's no external pressure, no genuine challenge.

This system introduces external adversarial pressure. In Round 2, each agent reads arguments it didn't generate and must respond to them — it can't just continue its own thread. That's qualitatively different.

The analogy: CoT is thinking alone before answering. This is presenting your argument to two critics and revising based on their objections.

There's empirical support for this — Du et al. (2023) showed multi-agent debate outperforms single-model CoT on reasoning benchmarks. This app is an implementation of that principle in a product context.

---

**"What do you understand about agentic systems? Where is the field headed?"**

Agentic systems are LLMs that operate in a loop — perceive state, reason about what action to take, execute (via tools, code, API calls), observe result, and iterate. The shift from "LLM as oracle" to "LLM as agent" changes everything: now you care about error recovery, tool selection, context management, and when to stop.

Three directions the field is moving simultaneously:

**Tool use at scale** — early agents had 3–5 tools. As toolspace grows to hundreds, naively stuffing all descriptions into context degrades reasoning quality and burns tokens. The more interesting solution is a learned policy that selects tools efficiently — which is exactly what "Scaling Agentic Capabilities, Not Context" is about.

**Safety and refusal** — agents that act confidently are dangerous, agents that refuse constantly are useless. The right behavior is calibrated uncertainty. This requires accurate model self-knowledge — does the model know when it's likely wrong? "Learning When to Act or Refuse" is tackling exactly this.

**Computer use** — Fara-7B represents agents operating on real interfaces. The challenge is enormous action spaces, stochastic environments, and mistakes that compound across steps. RL is the right training paradigm here, but sparse reward over long episodes is a hard credit assignment problem.

Where it's headed: agents with persistent memory across sessions, asynchronous coordination between agents, and self-improvement loops where agents generate and verify their own training data.

---

**"What do you know about fine-tuning? When would you use it vs. prompting?"**

Fine-tuning updates model weights on a task-specific dataset — shifts behavior more durably than prompting, but at the cost of generality and compute.

Key techniques:

**LoRA / QLoRA** — learn low-rank update matrices on top of frozen weights. Dramatically reduces memory and compute. Most practical fine-tuning today uses this.

**SFT** — train on (input, ideal output) pairs. Good for style, format, domain adaptation. Doesn't inherently improve reasoning.

**DPO** — train on preference pairs without a separate reward model. More stable than RLHF in practice, increasingly the default for alignment fine-tuning.

**RLHF** — human feedback as reward signal, train a reward model, optimize via PPO. More powerful but complex and prone to reward hacking.

In this system, the natural fine-tuning target is the synthesizer. The council generates structured training data naturally — question → 6 diverse perspectives → verdict. With quality scores on verdicts, DPO fine-tuning could teach a dedicated model to be a better deliberation moderator than a general-purpose model following a prompt.

---

**"Explain RL. How would you apply it to agentic LLMs?"**

RL is a framework for learning behavior through interaction. Agent observes state, takes action, receives reward, updates policy to maximize cumulative expected reward. Core challenge: credit assignment — which actions in a long sequence actually caused the eventual reward.

For LLMs, the action space is the vocabulary — each token is an action. RLHF uses human preference as reward. More recent work uses verifiable rewards — math with checkable answers, code with runnable tests.

For agentic systems specifically, RL is the right paradigm because:
- Tasks are sequential — prompting can't capture multi-step dependencies
- You want the model to discover strategies not present in training data
- Tool use requires exploration — try things, learn from results

Applied to this system:
- **Verdict quality as reward** — score verdicts on factual questions against ground truth, use to optimize the moderator's behavior
- **Adaptive rounds** — learn a policy for when to stop deliberating based on Round 1 consensus
- **Full protocol training** — optimize how each agent frames Round 2 to maximize final verdict quality

The hard problem is reward shaping. For end-to-end agent tasks, you often only observe success at the end — sparse signal over hundreds of steps. Intermediate rewards that reflect genuine progress without over-specifying the solution path are difficult to design. Get it wrong and the agent reward-hacks.

---

**"What are the real limitations of this system?"**

**No evaluation.** There's no benchmark. No measurement of whether the council verdict is actually better than a single strong model. It feels more grounded, but intuition is not a metric.

**Context grows linearly.** Each round appends more text. Verdict prompt contains all six prior responses. Doesn't scale to five rounds or ten agents — exactly the problem "Scaling Agentic Capabilities, Not Context" solves.

**No memory.** Every session is independent. Agents don't know what was discussed before. Real agentic systems maintain persistent state.

**No tool use.** Agents can only reason from training weights. For factual questions, they're all hallucinating to some degree. Search and retrieval would ground the outputs significantly.

**Static protocol.** Always three rounds, always three agents. A learned policy would adapt round count and agent configuration based on question complexity and inter-agent divergence.

**Reward signal is zero.** System never improves. RL-based optimization would change this.

---

**"How would you build a synthetic data pipeline from this?"**

The council pipeline is a structured data factory:

**Step 1 — Question sourcing:** Sample from TriviaQA, MMLU, HotpotQA, EthicsQA, HumanEval. Mix factual, reasoning, ethical, and creative for diverse deliberation dynamics.

**Step 2 — Run council sessions at scale:** Each session produces 7 pieces of relationally linked text — 3 opening stances, 3 cross-examination responses, 1 verdict.

**Step 3 — Extract training formats:**
- Preference pairs from Round 1 rankings → DPO data
- Full debate transcript → chain-of-thought fine-tuning
- Verdict vs. ground truth scores → reward model training data
- High-disagreement sessions with no resolution → uncertainty calibration data

**Step 4 — Quality filter:** Auto-filter rounds where agents didn't genuinely engage — responses under a length threshold, responses that don't reference the other agents by name, verdicts that ignore the discussion.

At scale: 50,000 questions × 7 outputs = 350,000 structured examples, zero human annotation beyond question sourcing. The deliberation protocol itself is the synthetic environment.

---

**"If you had compute and access to your infrastructure, what would you build first?"**

Turn the council protocol into a fine-tuning experiment on the synthesizer role.

Concretely: generate 20,000 council transcripts, use GPT-4 as a judge to score verdicts on accuracy and groundedness, run DPO fine-tuning on a 7B base model — teaching it to produce better verdicts given a discussion transcript.

Hypothesis: a model trained on deliberation data will learn to weight agent contributions intelligently. When Grok and Claude strongly disagree, it should hedge. When all three converge, it should commit. A general-purpose model following a prompt doesn't have this calibration.

If that works, the next experiment is RL on the full protocol — use verdict quality as reward and optimize how each agent deliberates, not just how the synthesizer synthesizes. That's the experiment that connects most directly to your group's work on agentic reasoning via RL.

---

## Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (reactive, state-driven)
- **Concurrency:** Swift Structured Concurrency — `async/await`, `async let` for parallel API orchestration
- **APIs:** Groq (LLaMA-3.3-70B), Google Generative AI (Gemini-2.5-Flash)
- **Architecture:** MVVM, `@MainActor` for thread-safe UI updates
- **Models:** Open-source (LLaMA via Groq) + frontier (Gemini)
