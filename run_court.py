#!/usr/bin/env python3
"""
CourtAI Research Runner
3-agent pipeline: LLaMA (Groq) · Claude (Anthropic) · Gemini 2.5 Flash (Google)
Runs 15 questions × 2 setups → court_research.json + full report
"""

import json, time, uuid
from datetime import datetime, timezone
import urllib.request

# ── API Keys ──────────────────────────────────────────────────────────────────
GROQ_KEY    = ""
CLAUDE_KEY  = ""
GEMINI_KEY  = ""   # set your Gemini API key here (console.cloud.google.com)

# ── Token budgets ─────────────────────────────────────────────────────────────
T_ARG     = 180
T_REBUTTAL= 200
T_VERDICT = 80

# ── Setups: swap FOR↔AGAINST, judge stays Gemini ─────────────────────────────
SETUPS = [
    {"name": "default", "for": "llama",  "against": "claude", "judge": "gemini"},
    {"name": "swapped", "for": "claude", "against": "llama",  "judge": "gemini"},
]

# ── 15 Questions ──────────────────────────────────────────────────────────────
QUESTIONS = [
    {"q": "Is coffee consumption net beneficial for human health?",            "cat": "factual"},
    {"q": "Is nuclear energy safer per unit of electricity than coal?",        "cat": "factual"},
    {"q": "Is remote work more productive than office work?",                  "cat": "factual"},
    {"q": "Does social media increase rates of teenage depression?",           "cat": "factual"},
    {"q": "Is exercise more effective than medication for mild depression?",   "cat": "factual"},
    {"q": "Is Python a better choice than JavaScript for backend development?","cat": "technical"},
    {"q": "Are microservices architectures better than monoliths for startups?","cat": "technical"},
    {"q": "Is TypeScript worth the added complexity over plain JavaScript?",   "cat": "technical"},
    {"q": "Should every mobile app support offline mode by default?",          "cat": "technical"},
    {"q": "Should AI be used in criminal sentencing?",                         "cat": "ai"},
    {"q": "Is AI-generated art real art?",                                     "cat": "ai"},
    {"q": "Will AI replace software engineers within 10 years?",               "cat": "ai"},
    {"q": "Should AI companies be regulated like pharmaceutical companies?",   "cat": "ai"},
    {"q": "Is it ethical to eat meat in 2025?",                                "cat": "ethical"},
    {"q": "Should social media platforms be banned for users under 16?",       "cat": "ethical"},
]

OUTPUT = "/Users/swipemac/Documents/CourtAI/court_research.json"

# ── Prompts (exact match to CourtViewModel.swift) ─────────────────────────────
def p_for(q):
    return f"""Opening statement IN FAVOR. The opposing side will respond to you.
Be direct. Simple English. No jargon.
ARGUMENT: [2-3 sentences making the strongest FOR case]
EVIDENCE: [one real fact or example — or "None." if nothing concrete]
Question: {q}"""

def p_against(q):
    return f"""Opening statement AGAINST. The opposing side will respond to you.
Find the strongest flaw or risk. Simple English. No jargon.
ARGUMENT: [2-3 sentences making the strongest AGAINST case]
EVIDENCE: [one real fact or example — or "None." if nothing concrete]
Question: {q}"""

def p_rebuttal_for(q, opp_arg, opp_ev):
    return f"""You heard the opposing side argue AGAINST: "{opp_arg}"
Their evidence: "{opp_ev}"
Directly attack their argument. Show why they are wrong. Then strengthen the FOR case.
Simple English. No jargon.
ARGUMENT: [2-3 sentences — attack their point, reinforce FOR]
EVIDENCE: [one real fact or example — or "None." if nothing concrete]
Question: {q}"""

def p_rebuttal_against(q, opp_arg, opp_ev):
    return f"""You heard the opposing side argue FOR: "{opp_arg}"
Their evidence: "{opp_ev}"
Directly attack their argument. Show where the logic breaks. Then strengthen the AGAINST case.
Simple English. No jargon.
ARGUMENT: [2-3 sentences — attack their point, reinforce AGAINST]
EVIDENCE: [one real fact or example — or "None." if nothing concrete]
Question: {q}"""

def p_verdict(q, h1fa, h1fe, h1aa, h1ae, h2fa, h2fe, h2aa, h2ae):
    return f"""You are the presiding judge. Check if the evidence is real, check if the logic holds.
Question: {q}
H1 FOR: {h1fa} | Evidence: {h1fe}
H1 AGAINST: {h1aa} | Evidence: {h1ae}
H2 FOR rebuttal: {h2fa} | Evidence: {h2fe}
H2 AGAINST rebuttal: {h2aa} | Evidence: {h2ae}
You MUST pick one side. No "it depends." No middle ground.
Output exactly ONE sentence. Format: "The court rules — [YES / NO]: [one sharp reason]."
"""

# ── Parsers ───────────────────────────────────────────────────────────────────
def parse(raw):
    text = raw.strip()
    idx  = text.upper().find("EVIDENCE:")
    if idx != -1:
        arg = text[:idx].replace("ARGUMENT:", "").replace("argument:", "").strip()
        ev  = text[idx + 9:].strip()
        return (arg if arg else text, ev)
    return (text, "")

def side(verdict):
    u = verdict.upper()
    dash = u.find("—")
    if dash != -1:
        after = u[dash+1:].strip()
        if after.startswith("YES"): return "YES"
        if after.startswith("NO"):  return "NO"
    if "RULES — YES" in u or "RULES: YES" in u: return "YES"
    if "RULES — NO"  in u or "RULES: NO"  in u: return "NO"
    if "COURT RULES YES" in u: return "YES"
    if "COURT RULES NO"  in u: return "NO"
    return "UNKNOWN"

# ── API callers ───────────────────────────────────────────────────────────────
GROQ_HEADERS = {
    "Authorization": f"Bearer {GROQ_KEY}",
    "Content-Type":  "application/json",
    "User-Agent":    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}

def call_groq(prompt, max_tokens):
    body = json.dumps({
        "model":      "llama-3.3-70b-versatile",
        "messages":   [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
    }).encode()
    req = urllib.request.Request(
        "https://api.groq.com/openai/v1/chat/completions",
        data=body, headers=GROQ_HEADERS, method="POST"
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())["choices"][0]["message"]["content"]

def call_claude(prompt, max_tokens):
    body = json.dumps({
        "model":      "claude-sonnet-4-6",
        "max_tokens": max_tokens,
        "messages":   [{"role": "user", "content": prompt}],
    }).encode()
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=body,
        headers={
            "x-api-key":          CLAUDE_KEY,
            "anthropic-version":  "2023-06-01",
            "Content-Type":       "application/json",
        },
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read())
    return next(b["text"] for b in data["content"] if b["type"] == "text")

def call_gemini(prompt, max_tokens):
    body = json.dumps({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "maxOutputTokens": max_tokens,
            "thinkingConfig": {"thinkingBudget": 0},
        },
    }).encode()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GEMINI_KEY}"
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read())
    return data["candidates"][0]["content"]["parts"][0]["text"]

def call(model_key, prompt, max_tokens):
    try:
        if model_key == "llama":  return call_groq(prompt, max_tokens)
        if model_key == "claude": return call_claude(prompt, max_tokens)
        if model_key == "gemini": return call_gemini(prompt, max_tokens)
    except Exception as e:
        return f"Error: {e}"
    return "Error: unknown model"

# ── One session ───────────────────────────────────────────────────────────────
def run_session(q, cat, setup):
    f, a, j = setup["for"], setup["against"], setup["judge"]
    t0 = time.time()

    print("  H1...", end="", flush=True)
    raw_fh1 = call(f, p_for(q),     T_ARG)
    raw_ah1 = call(a, p_against(q), T_ARG)
    h1fa, h1fe = parse(raw_fh1)
    h1aa, h1ae = parse(raw_ah1)

    print(" H2...", end="", flush=True)
    raw_fh2 = call(f, p_rebuttal_for(q,     h1aa, h1ae), T_REBUTTAL)
    raw_ah2 = call(a, p_rebuttal_against(q, h1fa, h1fe), T_REBUTTAL)
    h2fa, h2fe = parse(raw_fh2)
    h2aa, h2ae = parse(raw_ah2)

    print(" Verdict...", end="", flush=True)
    verdict  = call(j, p_verdict(q, h1fa, h1fe, h1aa, h1ae, h2fa, h2fe, h2aa, h2ae), T_VERDICT)
    duration = time.time() - t0
    s        = side(verdict)
    print(f" {s} ({duration:.1f}s)")

    # Show errors immediately so you know if something broke
    for lbl, v in [("FOR", raw_fh1), ("AGAINST", raw_ah1), ("VERDICT", verdict)]:
        if v.startswith("Error"):
            print(f"    ⚠ {lbl}: {v[:120]}")

    return {
        "id": str(uuid.uuid4()).upper(),
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "question": q, "category": cat, "setup": setup["name"],
        "forModel": f, "againstModel": a, "judgeModel": j,
        "h1ForArg": h1fa, "h1ForEvidence": h1fe,
        "h1AgArg":  h1aa, "h1AgEvidence":  h1ae,
        "h2ForArg": h2fa, "h2ForEvidence": h2fe,
        "h2AgArg":  h2aa, "h2AgEvidence":  h2ae,
        "verdict": verdict, "verdictSide": s,
        "durationSeconds": round(duration, 2),
    }

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    try:
        with open(OUTPUT) as f:
            results = json.load(f)
        clean = [r for r in results if r["verdictSide"] != "UNKNOWN"]
        if len(clean) != len(results):
            print(f"Dropped {len(results)-len(clean)} bad sessions — will rerun.")
        results = clean
    except:
        results = []

    done = {(r["question"], r["setup"]) for r in results}
    total = len(QUESTIONS) * len(SETUPS)

    print("CourtAI Research Runner")
    print("="*52)
    print(f"FOR/AGAINST: LLaMA (Groq)  ↔  Claude (Anthropic)")
    print(f"JUDGE:       Gemini 2.5 Flash (Google) — third-party, neutral")
    print(f"Sessions:    {len(done)}/{total} done\n")

    for setup in SETUPS:
        print(f"\n── {setup['name'].upper()}: FOR={setup['for'].upper()}  AGAINST={setup['against'].upper()}  JUDGE={setup['judge'].upper()}")
        for item in QUESTIONS:
            q, cat = item["q"], item["cat"]
            if (q, setup["name"]) in done:
                print(f"  SKIP [{cat}] {q[:55]}")
                continue
            print(f"  [{cat:9}] {q[:60]}")
            session = run_session(q, cat, setup)
            results.append(session)
            with open(OUTPUT, "w") as f:
                json.dump(results, f, indent=2)
            time.sleep(1)

    print(f"\n{'='*52}")
    print(f"Complete — {len(results)} sessions → {OUTPUT}")
    report(results)

# ── Report ─────────────────────────────────────────────────────────────────────
def report(results):
    print(f"\n{'='*52}")
    print("RESEARCH REPORT — Verdict Sensitivity to Model Role")
    print(f"{'='*52}")

    # 1. Verdict counts
    print("\n1. VERDICT DISTRIBUTION")
    for sname in ["default", "swapped"]:
        s   = [r for r in results if r["setup"] == sname]
        yes = sum(1 for r in s if r["verdictSide"] == "YES")
        no  = sum(1 for r in s if r["verdictSide"] == "NO")
        lbl = "LLaMA=FOR  Claude=AGAINST  Gemini=JUDGE" if sname == "default" else "Claude=FOR  LLaMA=AGAINST  Gemini=JUDGE"
        print(f"  {sname.upper():8} ({lbl})  YES={yes}  NO={no}  n={len(s)}")

    # 2. Flip table
    print("\n2. VERDICT FLIP TABLE")
    d_map = {r["question"]: r["verdictSide"] for r in results if r["setup"] == "default"}
    s_map = {r["question"]: r["verdictSide"] for r in results if r["setup"] == "swapped"}
    flips, total = 0, 0
    for q in d_map:
        if q not in s_map: continue
        d, s = d_map[q], s_map[q]
        if "UNKNOWN" in (d, s): continue
        total += 1
        flipped = d != s
        if flipped: flips += 1
        tag = "🔄 FLIP" if flipped else "  same"
        print(f"  {tag}  [{d}→{s}]  {q[:58]}")
    pct = flips/total*100 if total else 0
    print(f"\n  Flip rate: {flips}/{total} = {pct:.0f}%")

    # 3. By category
    print("\n3. FLIP RATE BY CATEGORY")
    cat_map = {item["q"]: item["cat"] for item in QUESTIONS}
    for cat in ["factual", "technical", "ai", "ethical"]:
        qs = [q for q in d_map if cat_map.get(q) == cat and q in s_map
              and "UNKNOWN" not in (d_map[q], s_map[q])]
        n_flip = sum(1 for q in qs if d_map[q] != s_map[q])
        print(f"  {cat:10}  {n_flip}/{len(qs)} flipped  ({n_flip/len(qs)*100:.0f}%)" if qs else f"  {cat:10}  no data")

    # 4. Evidence rate
    print("\n4. EVIDENCE QUALITY")
    evs   = [r.get(f, "") for r in results for f in ["h1ForEvidence","h1AgEvidence","h2ForEvidence","h2AgEvidence"]]
    real  = sum(1 for e in evs if e and not e.lower().startswith("none"))
    print(f"  Real evidence: {real}/{len(evs)} slots = {real/len(evs)*100:.0f}%")

    # 5. Speed
    print("\n5. SPEED")
    durs = [r["durationSeconds"] for r in results]
    print(f"  Avg={sum(durs)/len(durs):.1f}s  Min={min(durs):.1f}s  Max={max(durs):.1f}s")

    print(f"\nRaw data: {OUTPUT}")

if __name__ == "__main__":
    main()
