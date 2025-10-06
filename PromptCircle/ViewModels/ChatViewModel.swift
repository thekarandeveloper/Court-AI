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

        Grok's Response (for context only):
        \(grokResponse)

        Instructions for Gemini:
        1. Answer the user's original prompt.
        2. Use Grok's response to help refine or improve your answer.
        3. Keep the answer very short, crisp clear, and easy to understand.
        4. Conclude your message with a line labeled:

        (After a line brak)
        Final Answer: (In Bold)
        <your concise summary here>
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
