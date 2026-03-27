Okay. Final doc.

---

# CourtAI — Technical Specification

## What This App Does

User enters any question — personal, factual, or debatable.

Two LLMs are forced onto opposite sides. They swap roles. A judge decides based purely on argument quality.

**User gets:** A clear, reasoned decision — informed by both sides.

---

## Research Question

> *Does forced adversarial role-swapping between heterogeneous LLMs produce more accurate and less biased decisions than single-model inference?*

---

## Full Flow

```
User Input: "Should I accept this job offer?"
                    │
                    ▼
        ┌───────────────────────┐
        │   ROUND 1             │
        │                       │
        │ LLaMA   → FOR side    │
        │ Gemini  → AGAINST side│
        │                       │
        │ Both fire in parallel │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   ROUND 2 — SWAP      │
        │                       │
        │ LLaMA   → AGAINST side│
        │ Gemini  → FOR side    │
        │                       │
        │ Both fire in parallel │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   ROUND 3 — DECISION  │
        │                       │
        │ Judge sees:           │
        │ - LLaMA R1 (FOR)      │
        │ - Gemini R1 (AGAINST) │
        │ - LLaMA R2 (AGAINST)  │
        │ - Gemini R2 (FOR)     │
        │                       │
        │ Judge ignores model   │
        │ identity completely.  │
        │ Decides which SIDE    │
        │ had stronger arguments│
        └───────────────────────┘
                    │
                    ▼
            Final Verdict
    "Based on arguments presented,
     the stronger case is FOR because..."
```

---

## Prompts — Exact System Prompts

**Round 1 — FOR Agent:**
```
You are arguing FOR the following question.
Your job is to make the strongest possible case IN FAVOR.
Be direct, logical, and compelling.
Never concede. Never acknowledge the other side.
2-3 sentences only.
Question: [USER_QUESTION]
```

**Round 1 — AGAINST Agent:**
```
You are arguing AGAINST the following question.
Your job is to find every flaw and weakness.
Be direct, logical, and compelling.
Never concede. Never acknowledge the other side.
2-3 sentences only.
Question: [USER_QUESTION]
```

**Round 2 — Roles swapped. Same prompts, opposite assignments.**

**Round 3 — Judge:**
```
You have seen four arguments about the following question:
[USER_QUESTION]

FOR arguments: [R1_FOR] and [R2_FOR]
AGAINST arguments: [R1_AGAINST] and [R2_AGAINST]

Ignore who made which argument.
Evaluate purely on logical strength and evidence.
Which side made the stronger case overall?
Give a clear decision and explain why in 3-4 sentences.
Start with: "The stronger case is FOR/AGAINST because..."
```

---

## Models

| Role | Model | Provider |
|------|-------|----------|
| Agent A | LLaMA-3.3-70B | Groq |
| Agent B | Gemini-2.5-Flash | Google |
| Judge | Gemini-2.5-Flash (separate key) | Google |

---

## Concurrency Model

```swift
// Round 1 — parallel
async let forArgument = service.getResponse(
    model: .llama,
    prompt: forPrompt(question))
async let againstArgument = service.getResponse(
    model: .gemini,
    prompt: againstPrompt(question))

let (r1For, r1Against) = await (forArgument, againstArgument)

// Round 2 — swap, parallel
async let swappedFor = service.getResponse(
    model: .gemini,
    prompt: forPrompt(question))
async let swappedAgainst = service.getResponse(
    model: .llama,
    prompt: againstPrompt(question))

let (r2For, r2Against) = await (swappedFor, swappedAgainst)

// Round 3 — sequential, needs all prior
let verdict = await service.getResponse(
    model: .judge,
    prompt: judgePrompt(
        question: question,
        forArgs: [r1For, r2For],
        againstArgs: [r1Against, r2Against]))
```

---

## Architecture — MVVM

```
CourtAI/
├── Models/
│   ├── Question.swift
│   ├── Argument.swift        — role, content, round, model
│   └── Verdict.swift         — decision, reasoning, confidence
│
├── Services/
│   └── AIService.swift       — API calls, routing, parsing
│
├── ViewModels/
│   └── CourtViewModel.swift  — round management, role swap logic
│
└── Views/
    ├── CourtView.swift        — main screen
    ├── ArgumentCard.swift     — FOR/AGAINST display
    ├── VerdictCard.swift      — final decision
    └── InputView.swift        — question entry
```

---

## Why Role Swap Matters — The Key Insight

Without role swap — if Gemini is a stronger model, its side always wins. The debate is rigged.

With role swap — both models argue both sides. If FOR arguments are consistently stronger across both rounds — the answer is FOR. Model identity is irrelevant. Argument quality decides.

**This eliminates model bias from the decision.**

---

## Connection to MSR Research

**Agentic Reasoning via RL** — Protocol is currently prompt-engineered. Next step: use verdict quality as reward signal, train role assignment policy via RL.

**Scaling Agentic Capabilities** — Each round adds context. Role swap doubles it. Scaling this is a direct research problem.

**Learning When to Act or Refuse** — System always runs all rounds. A calibrated version would skip Round 2 if Round 1 shows strong consensus.

**Think Right** — Simple questions get full deliberation. Adaptive compute would short-circuit when confidence is high.

---

## What This Proves

Single model gives one perspective. CourtAI forces structured opposition — then removes model bias through role swapping. The result is a decision grounded in argument quality alone.

**This is the research contribution: role-swap as a bias elimination mechanism in multi-agent deliberation.**

---

Ye doc apne AI ko de do. Pura project is direction mein shape ho jaayega.

**Ek kaam abhi karo — `CourtViewModel.swift` mein round management aur role swap logic likhna shuru karo. Wahi core hai.**