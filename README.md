# CourtAI

A 3-agent iOS deliberation system where two LLMs argue opposite sides of a question under partial observability, and a third model delivers a binary verdict. Each agent operates independently — no agent sees the full context of the other until cross-examination, which prevents echo chambers and forces genuine adversarial reasoning.

---

## Research Paper

| | |
|---|---|
| **Title** | [Verdict Sensitivity to Model Role Assignment in a Multi-Agent Deliberation System](RESEARCH.md) |
| **Question** | Does swapping which model argues FOR vs AGAINST change the final verdict? |
| **Result** | 33–53% of verdicts flipped across 60 sessions, 15 questions, 2 judge models |
| **Platform** | CourtAI — this app |

---

## Quick Look

A full deliberation session — question in, verdict out — showing all three phases live on device.

<video src="./demo/court-demo.mp4" controls width="100%"></video>

---

## How It Works

The pipeline runs in three sequential phases. Hearing 1 and 2 each make two API calls in parallel.

```
User Question
      │
      ├── Agent A (FOR)     ──► Argument + Evidence  ┐
      └── Agent B (AGAINST) ──► Argument + Evidence  ┘  Hearing 1 (parallel)

            │
            │  Partial observability: each agent sees only the opponent's H1,
            │  not their own. Forces targeted rebuttal, not repetition.
            │
      ├── Agent A rebuts B's H1 ──► Rebuttal + Evidence  ┐
      └── Agent B rebuts A's H1 ──► Rebuttal + Evidence  ┘  Hearing 2 (parallel)

            │
            └── Judge sees all 8 outputs ──► "The court rules — YES/NO: ..."
```

**Total: 5 API calls · ~15s end-to-end · all three roles are user-configurable**

### Key Design Decisions

**Partial observability** — In Hearing 2, each agent receives only the opponent's Hearing 1 output, not a recap of their own. This ensures agents respond to what was actually argued rather than restating their opening position.

**Heterogeneous models** — Using three models from three different providers (Google, Meta via Groq, Anthropic) means no single model's priors dominate the outcome. A homogeneous setup produces echo chambers.

**Evidence gating** — Every argument slot requires either a concrete fact or an explicit `"None."`. The judge sees argument and evidence as separate fields and weighs them independently.

**Token budgets** — Hard output limits at every call site prevent padding and keep total session time under 20 seconds.

| Phase | Max tokens |
|-------|-----------|
| H1 argument | 180 |
| H2 rebuttal | 200 |
| Verdict | 80 |

---

## Models

All three roles are independently assignable from the app's settings screen. The research experiment ran two configurations: LLaMA=FOR / Claude=AGAINST / Gemini=JUDGE and LLaMA=FOR / Claude=AGAINST / LLaMA-8B=JUDGE.

| Role | Available Models | Provider |
|------|-----------------|----------|
| FOR | Gemini 2.5 Flash · LLaMA-3.3-70B · Claude Sonnet 4.6 | Google · Groq · Anthropic |
| AGAINST | Gemini 2.5 Flash · LLaMA-3.3-70B · Claude Sonnet 4.6 | Google · Groq · Anthropic |
| Judge | Gemini 2.5 Flash · LLaMA-3.3-70B · Claude Sonnet 4.6 | Google · Groq · Anthropic |

---

## Project Structure

```
CourtAi/
├── Views/
│   ├── CourtView.swift          # main UI — progressive phase reveal as pipeline runs
│   └── OnboardingView.swift     # first-launch API key setup + model role selection
├── ViewModels/
│   └── CourtViewModel.swift     # pipeline orchestration, prompt templates, response parser
└── Services/
    ├── AIService.swift          # unified client for Gemini / Groq / Anthropic REST APIs
    └── SessionLogger.swift      # appends each completed session to court_sessions.json
```

**Stack:** SwiftUI · Swift Concurrency (`async let` for parallel calls, `@MainActor` for state) · MVVM · 3 REST APIs

---

## Setup

Requires Xcode 15+ and iOS 17+.

```bash
git clone https://github.com/your-username/CourtAI.git
open CourtAi.xcodeproj
```

On first launch, the onboarding screen prompts for your API keys. Keys are stored in Keychain and are never written to disk or committed to the repository. You can update them at any time from the settings screen.

| Provider | Key source |
|----------|-----------|
| Groq (LLaMA) | console.groq.com/keys |
| Anthropic (Claude) | console.anthropic.com |
| Google (Gemini) | aistudio.google.com/apikey |

All three providers have free tiers sufficient for personal use. The research experiment (60 sessions) cost approximately $0.04 total.

---

## Research

See [RESEARCH.md](RESEARCH.md) for the full paper.

The core question: does it matter *which* model argues FOR vs AGAINST, or does the better argument always win regardless of who makes it? To test this, the same 15 questions were deliberated twice — once with LLaMA arguing FOR and Claude arguing AGAINST, and once with roles reversed. The judge model was held constant across both conditions to isolate the effect.

The experiment was run twice with two different judge models (LLaMA-3.1-8B and Gemini 2.5 Flash), yielding 60 sessions total.

| Finding | Result |
|---------|--------|
| Flip rate with LLaMA judge | 53% of verdicts changed when roles were swapped |
| Flip rate with Gemini judge | 33% of verdicts changed |
| Factual questions | 80% flip rate under both judges |
| Ethical questions | 0% flip rate under both judges |
| Gemini judge baseline | 87% NO rate — strong intrinsic skeptical bias |
| Evidence quality | 94% of argument slots cited real facts (240 slots total) |

The most consistent finding: **factual questions are paradoxically the most sensitive to role assignment.** Questions with empirical answers (coffee and health, remote work productivity, exercise vs medication) flipped at 80% under both judge models — suggesting that framing and evidence selection override factual consensus in these models.
