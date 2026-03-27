//
//  ChatViewModel.swift
//  CourtAi
//
//  Created by Karan Kumar on 06/10/25.
//
import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var userInput: String = ""
    @Published var selectedModel: AIModel = .gemini

    func sendMessage() async {
        guard !userInput.isEmpty else { return }

        let prompt = userInput
        messages.append(Message(sender: .user, content: prompt))
        userInput = ""

        // Placeholder
        let idx = messages.count
        let placeholder = Message(
            sender: .ai(model: selectedModel),
            content: selectedModel == .gemini ? "Analysing..." : "Thinking...",
            isCollapsed: false
        )
        messages.append(placeholder)

        // Map to AIService model
        let serviceModel: AIService.AIModel
        switch selectedModel {
        case .grok:   serviceModel = .grok
        case .claude: serviceModel = .claude
        case .gemini: serviceModel = .gemini
        }

        let response = await AIService.shared.getAIResponse(for: serviceModel, prompt: prompt)

        withAnimation(.spring()) {
            messages[idx] = Message(
                sender: .ai(model: selectedModel),
                content: response,
                isCollapsed: false
            )
        }
    }
}
