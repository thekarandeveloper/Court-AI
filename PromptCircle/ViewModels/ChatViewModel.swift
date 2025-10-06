//
//  ChatViewModel.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//
import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var userInput: String = ""

    var panel: ChatPanel = ChatPanel(activeModels: [.grok, .gemini])

    func sendMessage() async {
        guard !userInput.isEmpty else { return }

        let prompt = userInput
        messages.append(Message(sender: .user, content: prompt))
        userInput = ""

        // 1️⃣ Insert Grok placeholder (expanded initially)
        let grokIndex = messages.count
        let grokPlaceholder = Message(sender: .ai(model: .grok), content: "Thinking...", isCollapsed: false)
        messages.append(grokPlaceholder)

        // 2️⃣ Insert Gemini placeholder (collapsed until real response)
        let geminiIndex = messages.count
        let geminiPlaceholder = Message(sender: .ai(model: .gemini), content: "Waiting for Grok's reply...", isCollapsed: false)
        messages.append(geminiPlaceholder)

        // 3️⃣ Grok responds
        let grokResponse = await AIService.shared.getAIResponse(for: .grok, prompt: prompt)
        withAnimation(.spring()) {
            messages[grokIndex] = Message(sender: .ai(model: .grok), content: grokResponse, isCollapsed: false)
        }

        // 4️⃣ Gemini responds after Grok
        let geminiPrompt = """
        User Prompt: \(prompt)
        Grok Response: \(grokResponse)
        Please summarize both and provide a short, crisp, final answer.
        """
        let geminiResponse = await AIService.shared.getAIResponse(for: .gemini, prompt: geminiPrompt)

        withAnimation(.easeInOut) {
            // Replace Gemini placeholder with real response
            messages[geminiIndex] = Message(sender: .ai(model: .gemini), content: geminiResponse, isCollapsed: false)

            // Collapse Grok bubble automatically after Gemini arrives
            let collapsedGrok = Message(sender: .ai(model: .grok), content: grokResponse, isCollapsed: true)
            messages[grokIndex] = collapsedGrok
        }
    }
}
