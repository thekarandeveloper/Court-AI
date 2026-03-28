//
//  CourtViewModel.swift
//  CourtAi
//
//  3-agent deliberation pipeline:
//    Hearing 1 — agents independently form stances (FOR agent argues FOR, AGAINST agent argues AGAINST)
//    Hearing 2 — cross-examination with partial observability (each agent sees only opponent's H1)
//    Verdict   — Judge synthesises all arguments + evidence → 1-line ruling
//
//  Roles are read from @AppStorage so the user's choice from onboarding/settings is respected.
//

import Foundation
import SwiftUI

// MARK: - Token budgets (output tokens per call)
private enum Tokens {
    static let argument = 180
    static let rebuttal = 200
    static let verdict  = 60
}

enum CourtPhase: Equatable {
    case idle
    case hearing1
    case hearing2
    case judging
    case complete
}

@MainActor
class CourtViewModel: ObservableObject {
    @Published var phase: CourtPhase = .idle
    @Published var question: String = ""

    // Hearing 1
    @Published var h1ForArg:      String?
    @Published var h1ForEvidence: String?
    @Published var h1AgArg:       String?
    @Published var h1AgEvidence:  String?

    // Hearing 2
    @Published var h2ForArg:      String?
    @Published var h2ForEvidence: String?
    @Published var h2AgArg:       String?
    @Published var h2AgEvidence:  String?

    // Final verdict
    @Published var verdict: String?

    // Current role assignments (set before startCourt, read from AppStorage by CourtView)
    var forModel:     AIService.AIModel = .gemini
    var againstModel: AIService.AIModel = .grok
    var judgeModel:   AIService.AIModel = .claude

    // MARK: - Control

    func startCourt() {
        let q = question.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        Task { await runCourt(q) }
    }

    func reset() {
        phase = .idle; question = ""
        h1ForArg = nil; h1ForEvidence = nil; h1AgArg = nil; h1AgEvidence = nil
        h2ForArg = nil; h2ForEvidence = nil; h2AgArg = nil; h2AgEvidence = nil
        verdict = nil
    }

    // MARK: - Pipeline

    private func runCourt(_ q: String) async {
        let svc = AIService.shared
        let f = forModel
        let a = againstModel
        let j = judgeModel

        // ── Hearing 1: independent stance formation ──────────────────────────
        phase = .hearing1
        async let fH1 = svc.getAIResponse(for: f, prompt: Self.forPrompt(q),     maxTokens: Tokens.argument)
        async let aH1 = svc.getAIResponse(for: a, prompt: Self.againstPrompt(q), maxTokens: Tokens.argument)
        let (rawFH1, rawAH1) = await (fH1, aH1)
        let (h1fa, h1fe) = Self.parse(rawFH1)
        let (h1aa, h1ae) = Self.parse(rawAH1)
        withAnimation(.spring(duration: 0.4)) {
            h1ForArg = h1fa; h1ForEvidence = h1fe
            h1AgArg  = h1aa; h1AgEvidence  = h1ae
        }

        // ── Hearing 2: cross-examination (partial observability) ─────────────
        phase = .hearing2
        async let fH2 = svc.getAIResponse(
            for: f,
            prompt: Self.rebuttalForPrompt(q, opponentArg: h1aa, opponentEvidence: h1ae),
            maxTokens: Tokens.rebuttal
        )
        async let aH2 = svc.getAIResponse(
            for: a,
            prompt: Self.rebuttalAgainstPrompt(q, opponentArg: h1fa, opponentEvidence: h1fe),
            maxTokens: Tokens.rebuttal
        )
        let (rawFH2, rawAH2) = await (fH2, aH2)
        let (h2fa, h2fe) = Self.parse(rawFH2)
        let (h2aa, h2ae) = Self.parse(rawAH2)
        withAnimation(.spring(duration: 0.4)) {
            h2ForArg = h2fa; h2ForEvidence = h2fe
            h2AgArg  = h2aa; h2AgEvidence  = h2ae
        }

        // ── Verdict: judge synthesises all 8 outputs ─────────────────────────
        phase = .judging
        let ruling = await svc.getAIResponse(
            for: j,
            prompt: Self.verdictPrompt(q, h1fa, h1fe, h1aa, h1ae, h2fa, h2fe, h2aa, h2ae),
            maxTokens: Tokens.verdict
        )
        withAnimation(.spring(duration: 0.5)) { verdict = ruling; phase = .complete }
        TrialManager.recordUse()
    }

    // MARK: - Response Parser

    static func parse(_ raw: String) -> (arg: String, evidence: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = text.range(of: "EVIDENCE:", options: .caseInsensitive) {
            let arg = String(text[..<range.lowerBound])
                .replacingOccurrences(of: "ARGUMENT:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let evidence = String(text[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (arg.isEmpty ? text : arg, evidence)
        }
        return (text, "")
    }

    // MARK: - Prompts

    static func forPrompt(_ q: String) -> String {
        """
        Opening statement IN FAVOR. The opposing side will respond to you.
        Be direct. Simple English. No jargon.

        ARGUMENT: [2-3 sentences making the strongest FOR case]
        EVIDENCE: [one real fact or example — or "None." if nothing concrete]

        Question: \(q)
        """
    }

    static func againstPrompt(_ q: String) -> String {
        """
        Opening statement AGAINST. The opposing side will respond to you.
        Find the strongest flaw or risk. Simple English. No jargon.

        ARGUMENT: [2-3 sentences making the strongest AGAINST case]
        EVIDENCE: [one real fact or example — or "None." if nothing concrete]

        Question: \(q)
        """
    }

    static func rebuttalForPrompt(_ q: String, opponentArg: String, opponentEvidence: String) -> String {
        """
        You heard the opposing side argue AGAINST: "\(opponentArg)"
        Their evidence: "\(opponentEvidence)"

        Directly attack their argument. Show why they are wrong. Then strengthen the FOR case.
        Simple English. No jargon.

        ARGUMENT: [2-3 sentences — attack their point, reinforce FOR]
        EVIDENCE: [one real fact or example — or "None." if nothing concrete]

        Question: \(q)
        """
    }

    static func rebuttalAgainstPrompt(_ q: String, opponentArg: String, opponentEvidence: String) -> String {
        """
        You heard the opposing side argue FOR: "\(opponentArg)"
        Their evidence: "\(opponentEvidence)"

        Directly attack their argument. Show where the logic breaks. Then strengthen the AGAINST case.
        Simple English. No jargon.

        ARGUMENT: [2-3 sentences — attack their point, reinforce AGAINST]
        EVIDENCE: [one real fact or example — or "None." if nothing concrete]

        Question: \(q)
        """
    }

    static func verdictPrompt(
        _ q: String,
        _ h1fa: String, _ h1fe: String,
        _ h1aa: String, _ h1ae: String,
        _ h2fa: String, _ h2fe: String,
        _ h2aa: String, _ h2ae: String
    ) -> String {
        """
        You are the presiding judge. Think for yourself — check if the evidence is real, check if the logic holds, apply your own knowledge.

        Question: \(q)
        H1 FOR: \(h1fa) | Evidence: \(h1fe)
        H1 AGAINST: \(h1aa) | Evidence: \(h1ae)
        H2 FOR rebuttal: \(h2fa) | Evidence: \(h2fe)
        H2 AGAINST rebuttal: \(h2aa) | Evidence: \(h2ae)

        You MUST pick one side. No "it depends." No middle ground.
        Output exactly ONE sentence. Format: "The court rules — [YES / NO]: [one sharp reason]."
        """
    }
}
