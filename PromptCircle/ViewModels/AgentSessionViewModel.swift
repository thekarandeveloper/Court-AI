//
//  AgentSessionViewModel.swift
//  PromptCircle
//
//  Orchestrates the multi-round AI Council discussion.
//

import Foundation
import SwiftUI

@MainActor
class AgentSessionViewModel: ObservableObject {
    @Published var openingMessages:    [SessionMessage] = []
    @Published var discussionMessages: [SessionMessage] = []
    @Published var verdict:   String?
    @Published var currentPhase: SessionPhase = .opening
    @Published var isComplete: Bool  = false
    @Published var isRunning:  Bool  = false
    @Published var scrollTick: UUID  = UUID()   // bump to trigger auto-scroll

    private let service = AIService.shared
    private let models: [AIService.AIModel] = [.grok, .claude, .gemini]

    // MARK: - Entry point

    func startSession(question: String) async {
        guard !isRunning else { return }
        isRunning  = true
        isComplete = false
        openingMessages    = []
        discussionMessages = []
        verdict            = nil

        currentPhase = .opening
        await runOpeningRound(question: question)

        currentPhase = .discussion
        await runDiscussionRound(question: question)

        currentPhase = .verdict
        await runVerdictRound(question: question)

        isComplete = true
        isRunning  = false
    }

    // MARK: - Round 1 – Opening Stance

    private func runOpeningRound(question: String) async {
        // Fire all three API calls in parallel
        async let grokFuture   = service.getAIResponse(for: .grok,   prompt: openingPrompt(.grok,   q: question))
        async let claudeFuture = service.getAIResponse(for: .claude,  prompt: openingPrompt(.claude, q: question))
        async let geminiFuture = service.getAIResponse(for: .gemini,  prompt: openingPrompt(.gemini, q: question))

        // Add thinking cards one by one (visual stagger)
        withAnimation(.spring()) { openingMessages.append(SessionMessage(model: .grok,   content: "", phase: .opening, isThinking: true)) }
        scroll()
        try? await Task.sleep(nanoseconds: 250_000_000)
        withAnimation(.spring()) { openingMessages.append(SessionMessage(model: .claude, content: "", phase: .opening, isThinking: true)) }
        scroll()
        try? await Task.sleep(nanoseconds: 250_000_000)
        withAnimation(.spring()) { openingMessages.append(SessionMessage(model: .gemini, content: "", phase: .opening, isThinking: true)) }
        scroll()

        // Collect results
        let (grokRes, claudeRes, geminiRes) = await (grokFuture, claudeFuture, geminiFuture)

        // Reveal one by one
        withAnimation(.spring()) { openingMessages[0].content = grokRes;   openingMessages[0].isThinking = false }
        scroll()
        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.spring()) { openingMessages[1].content = claudeRes;  openingMessages[1].isThinking = false }
        scroll()
        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.spring()) { openingMessages[2].content = geminiRes; openingMessages[2].isThinking = false }
        scroll()
    }

    // MARK: - Round 2 – Cross-Examination

    private func runDiscussionRound(question: String) async {
        let grokR1   = openingMessages.first(where: { $0.model == .grok   })?.content ?? ""
        let claudeR1 = openingMessages.first(where: { $0.model == .claude })?.content ?? ""
        let geminiR1 = openingMessages.first(where: { $0.model == .gemini })?.content ?? ""

        async let grokFuture   = service.getAIResponse(for: .grok,   prompt: discussionPrompt(.grok,   q: question, g: grokR1, c: claudeR1, gem: geminiR1))
        async let claudeFuture = service.getAIResponse(for: .claude,  prompt: discussionPrompt(.claude, q: question, g: grokR1, c: claudeR1, gem: geminiR1))
        async let geminiFuture = service.getAIResponse(for: .gemini,  prompt: discussionPrompt(.gemini, q: question, g: grokR1, c: claudeR1, gem: geminiR1))

        withAnimation(.spring()) { discussionMessages.append(SessionMessage(model: .grok,   content: "", phase: .discussion, isThinking: true)) }
        scroll()
        try? await Task.sleep(nanoseconds: 250_000_000)
        withAnimation(.spring()) { discussionMessages.append(SessionMessage(model: .claude, content: "", phase: .discussion, isThinking: true)) }
        scroll()
        try? await Task.sleep(nanoseconds: 250_000_000)
        withAnimation(.spring()) { discussionMessages.append(SessionMessage(model: .gemini, content: "", phase: .discussion, isThinking: true)) }
        scroll()

        let (grokRes, claudeRes, geminiRes) = await (grokFuture, claudeFuture, geminiFuture)

        withAnimation(.spring()) { discussionMessages[0].content = grokRes;   discussionMessages[0].isThinking = false }
        scroll()
        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.spring()) { discussionMessages[1].content = claudeRes;  discussionMessages[1].isThinking = false }
        scroll()
        try? await Task.sleep(nanoseconds: 400_000_000)
        withAnimation(.spring()) { discussionMessages[2].content = geminiRes; discussionMessages[2].isThinking = false }
        scroll()
    }

    // MARK: - Round 3 – Verdict

    private func runVerdictRound(question: String) async {
        let grokR1   = openingMessages.first(where: { $0.model == .grok   })?.content ?? ""
        let claudeR1 = openingMessages.first(where: { $0.model == .claude })?.content ?? ""
        let geminiR1 = openingMessages.first(where: { $0.model == .gemini })?.content ?? ""
        let grokR2   = discussionMessages.first(where: { $0.model == .grok   })?.content ?? ""
        let claudeR2 = discussionMessages.first(where: { $0.model == .claude })?.content ?? ""
        let geminiR2 = discussionMessages.first(where: { $0.model == .gemini })?.content ?? ""

        let prompt = verdictPrompt(
            q: question,
            grokR1: grokR1, claudeR1: claudeR1, geminiR1: geminiR1,
            grokR2: grokR2, claudeR2: claudeR2, geminiR2: geminiR2
        )
        let result = await service.getAIResponse(for: .gemini, prompt: prompt)
        withAnimation(.spring()) { verdict = result }
        scroll()
    }

    private func scroll() { scrollTick = UUID() }

    // MARK: - Prompt builders

    private func openingPrompt(_ model: AIService.AIModel, q: String) -> String {
        switch model {
        case .grok:
            return """
            You are Grok — sharp, direct, occasionally witty. You're on a live AI panel discussion.
            Give your opening stance in exactly 2-3 crisp sentences. Be bold and opinionated, not generic.
            Question: \(q)
            """
        case .claude:
            return """
            You are Claude — nuanced, thoughtful, ethically-minded. You're on a live AI panel discussion.
            Give your opening stance in exactly 2-3 sentences. Highlight implications and consider edge cases.
            Question: \(q)
            """
        case .gemini:
            return """
            You are Gemini — analytical, comprehensive, data-driven. You're on a live AI panel discussion.
            Give your opening stance in exactly 2-3 sentences. Be analytical and mention key data or angles.
            Question: \(q)
            """
        }
    }

    private func discussionPrompt(_ model: AIService.AIModel, q: String, g: String, c: String, gem: String) -> String {
        switch model {
        case .grok:
            return """
            You are Grok on a live panel.
            Original question: \(q)

            Other panelists said:
            • Gemini: "\(gem)"
            • Claude: "\(c)"

            Cross-examine them. Reference them by name. Agree, disagree, or challenge. Be direct and sharp. Max 2-3 sentences.
            """
        case .claude:
            return """
            You are Claude on a live panel.
            Original question: \(q)

            Other panelists said:
            • Grok: "\(g)"
            • Gemini: "\(gem)"

            Cross-examine them. Reference them by name. Be nuanced — where do you agree or push back? Max 2-3 sentences.
            """
        case .gemini:
            return """
            You are Gemini on a live panel.
            Original question: \(q)

            Other panelists said:
            • Grok: "\(g)"
            • Claude: "\(c)"

            Cross-examine them. Reference them by name. Build on the strongest points analytically. Max 2-3 sentences.
            """
        }
    }

    private func verdictPrompt(q: String,
                               grokR1: String, claudeR1: String, geminiR1: String,
                               grokR2: String, claudeR2: String, geminiR2: String) -> String {
        return """
        You are the final voice of an AI council that just finished a live discussion.

        Question discussed: \(q)

        What was said:
        • Grok initially said: "\(grokR1)" and then responded: "\(grokR2)"
        • Claude initially said: "\(claudeR1)" and then responded: "\(claudeR2)"
        • Gemini initially said: "\(geminiR1)" and then responded: "\(geminiR2)"

        Write the final verdict. Rules:
        1. Start with: "After discussing with Grok (who [very short point]) and Claude (who [very short point]),"
        2. Then give the actual answer using "we". Max 2-3 short sentences.
        3. Use simple everyday words — no jargon, no fluff.
        4. Be direct and crisp. If the answer is simple, keep it simple.

        Write ONLY the verdict text. No headers, no bullet points.
        """
    }
}
