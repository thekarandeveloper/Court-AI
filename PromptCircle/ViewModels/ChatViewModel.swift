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

        // 1️⃣ Grok placeholder
        let grokIndex = messages.count
        let grokPlaceholder = Message(sender: .ai(model: .grok), content: "Thinking...", isCollapsed: false)
        messages.append(grokPlaceholder)

        // 2️⃣ Claude placeholder
        let claudeIndex = messages.count
        let claudePlaceholder = Message(sender: .ai(model: .claude), content: "Thinking...", isCollapsed: false)
        messages.append(claudePlaceholder)

        // 3️⃣ Gemini placeholder
        let geminiIndex = messages.count
        let geminiPlaceholder = Message(sender: .ai(model: .gemini), content: "Analysing...", isCollapsed: false)
        messages.append(geminiPlaceholder)

        // 4️⃣ Grok responds
        let grokPrompt = """
        User Prompt: \(prompt)
        
        Answer in short and crisp, but keep all imortant points
        
        """
        let grokResponse = await AIService.shared.getAIResponse(for: .grok, prompt: grokPrompt)
        withAnimation(.spring()) {
            messages[grokIndex] = Message(sender: .ai(model: .grok), content: grokResponse, isCollapsed: false)
        }

        // 5️⃣ Claude responds (uses Grok's response as context)
        let claudePrompt = """
        User Prompt: \(prompt)
        
        Answer in short and crisp, but keep all imortant points
        """
        let claudeResponse = await AIService.shared.getAIResponse(for: .claude, prompt: claudePrompt)
        withAnimation(.spring()) {
            messages[claudeIndex] = Message(sender: .ai(model: .claude), content: claudeResponse, isCollapsed: false)
            messages[grokIndex].isCollapsed = true
        }

        // 6️⃣ Gemini responds (final summary using Grok + Claude)
        let geminiPrompt = """
        User Prompt: \(prompt)

        Grok's Response:
        \(grokResponse)

        Claude's Response:
        \(claudeResponse)

        Instructions for Gemini:
        - Read both responses carefully, understand their key points, and combine the best ideas from each.
        - Think logically and naturally before answering — don’t sound robotic.
        - Write a new, single-line conclusion that feels thoughtful and human.
        - Use only collective terms like "we", "us", or "our" — never "I", "me", or "my".
        - Keep it short, crisp, and directly answer the user’s prompt.
        - Output only the final one-line answer.
        """
        let geminiResponse = await AIService.shared.getAIResponse(for: .gemini, prompt: geminiPrompt)
        messages[claudeIndex].isCollapsed = true
        print(messages[claudeIndex].isCollapsed)
        withAnimation(.easeInOut) {
            messages[geminiIndex] = Message(sender: .ai(model: .gemini), content: geminiResponse, isCollapsed: false)
            
            // Collapse Grok & Claude bubbles automatically
         
            
        }
    }
}
