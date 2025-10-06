//
//  ChatViewModel.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var userInput: String = ""
    var panel: ChatPanel = ChatPanel(activeModels: [.grok, .gemini])
    
    func sendMessage() async {
        guard !userInput.isEmpty else { return }
        
        let userMessage = Message(sender: .user, content: userInput)
        messages.append(userMessage)
        let prompt = userInput
        userInput = ""
        
        // 1️⃣ First: Grok responds to the user prompt
        let grokModel: AIService.AIModel = .grok
        let grokResponse = await AIService.shared.getAIResponse(for: grokModel, prompt: prompt)
        let grokMessage = Message(sender: .ai(model: .grok), content: grokResponse)
        messages.append(grokMessage)
        
        // 2️⃣ Then: Gemini receives both user prompt + Grok response
        let geminiModel: AIService.AIModel = .gemini
        let geminiPrompt = """
        User Prompt: \(prompt)
        Grok Response: \(grokResponse)
        Please summarize both and provide a short, crisp, final answer.
        """
        let geminiResponse = await AIService.shared.getAIResponse(for: geminiModel, prompt: geminiPrompt)
        let geminiMessage = Message(sender: .ai(model: .gemini), content: geminiResponse)
        messages.append(geminiMessage)
    }
}
