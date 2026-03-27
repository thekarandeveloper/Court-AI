# CourtAI — Multi-Agent Deliberation System

> *Does forced adversarial role-swapping between heterogeneous LLMs produce more accurate and less biased decisions than single-model inference?*

A 3-agent iOS pipeline where LLMs independently form stances, cross-examine each other under partial observability, and synthesise a final verdict — built as a direct implementation of multi-agent deliberation as a research question.

---

## System Architecture

```
User Question
      │
      ▼
┌─────────────────────────────────────────────┐
│  HEARING 1 — Independent Stance Formation   │
│                                             │
│  Gemini-2.5-Flash  →  FOR                  │  parallel
│  LLaMA-3.3-70B     →  AGAINST             │  async let
│                                             │
│  Each agent: Argument + Evidence            │
└──────────────────────┬──────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────┐
│  HEARING 2 — Cross-Examination              │
│             (Partial Observability)         │
│                                             │
│  LLaMA  sees only Gemini's H1  →  rebuts   │  parallel
│  Gemini sees only LLaMA's H1   →  rebuts   │  async let
│                                             │
│  Each agent: Rebuttal + Evidence            │
└──────────────────────┬──────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────┐
│  VERDICT — Judicial Synthesis               │
│                                             │
│  Claude-Sonnet sees all 8 outputs           │
│  Verifies evidence, checks logic,           │
│  applies own knowledge                      │
│                                             │
│  Output: 1 sentence — YES or NO            │
└─────────────────────────────────────────────┘
```

---

## Key Design Decisions

### Partial Observability
In Hearing 2, each agent receives **only the opponent's Hearing 1 output** — not their own. This forces targeted rebuttals rather than generic argument repetition, and mirrors real cross-examination conditions where each side responds specifically to what was said.

### Heterogeneous Models
Using three architecturally distinct models (Gemini, LLaMA, Claude) ensures that argument quality — not a single model's internal biases — drives the outcome. A homogeneous setup (same model arguing both sides) produces echo chambers.

### Evidence Gating
Agents must submit concrete proof alongside every argument. If no verifiable evidence exists, they must declare it. Claude sees this during verdict synthesis — weak or absent evidence is weighted accordingly.

### Token Budgets
Each API call has a hard output token limit set at the call site:

| Call type      | Max output tokens |
|----------------|-------------------|
| H1 argument    | 180               |
| H2 rebuttal    | 200               |
| Verdict        | 60                |

Gemini uses `thinkingBudget: 0` to suppress internal reasoning tokens — saves ~300–500 tokens per call and reduces latency without affecting output quality.

---

## Models

| Role    | Model             | Provider  |
|---------|-------------------|-----------|
| Agent A | Gemini 2.5 Flash  | Google    |
| Agent B | LLaMA-3.3-70B     | Groq      |
| Judge   | Claude Sonnet     | Anthropic |

---

## Tech Stack

- **SwiftUI** — declarative UI, light mode
- **Swift Concurrency** — `async let` for true parallel API calls, `@MainActor` for state isolation
- **MVVM** — `CourtViewModel` owns all pipeline logic and phase transitions; views are stateless
- **3 REST APIs** — Gemini `generateContent`, Groq OpenAI-compatible, Anthropic Messages API

---

## Setup

1. Clone the repo
2. Copy the key template:
   ```bash
   cp PromptCircle/APIKeys.plist.template PromptCircle/APIKeys.plist
   ```
3. Open `APIKeys.plist` and fill in your keys:
   - **Gemini** — [Google AI Studio](https://aistudio.google.com/apikey)
   - **Groq** — [Groq Console](https://console.groq.com/keys)
   - **Claude** — [Anthropic Console](https://console.anthropic.com)
4. Open `PromptCircle.xcodeproj` in Xcode and run

> `APIKeys.plist` is listed in `.gitignore` — your keys will never be committed.

---

## Project Structure

```
PromptCircle/
├── APIKeys.swift              — reads keys from gitignored plist
├── APIKeys.plist              — your real keys (gitignored)
├── APIKeys.plist.template     — placeholder keys, safe to commit
├── Services/
│   └── AIService.swift        — Gemini / Groq / Anthropic clients, per-call token limits
├── ViewModels/
│   └── CourtViewModel.swift   — pipeline phases, prompt engineering, response parsing
└── Views/
    └── CourtView.swift        — full UI, light mode, progressive reveal
```

---

## Research Connection

This system is prompt-engineered, not trained. The natural next steps:

- Use **verdict quality as a reward signal**
- Train a **role assignment policy via RL** — instead of hardcoding which model argues FOR/AGAINST, learn optimal role assignment by question type
- **Adaptive compute** — skip Hearing 2 when Hearing 1 shows strong consensus (connects to *Think Right: Adaptive Attentive Compression*)
- **Synthetic deliberation datasets** — run the pipeline at scale to generate structured argument-evidence-verdict triples for fine-tuning

Directly related to: [Agentic Reasoning and Tool Integration via RL](https://lnkd.in/gDmg4nTf) · [Scaling Agentic Capabilities](https://lnkd.in/gp7bM-B2) · [Think Right](https://lnkd.in/gwZFWKcx)
