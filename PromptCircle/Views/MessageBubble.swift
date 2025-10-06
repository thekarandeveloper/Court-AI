//
//  MessageBubble.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI


struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if case .ai(let model) = message.sender {
                // AI Avatar + Bubble (Left side)
                Image(avatarImage(for: model))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .padding(.leading, 4)

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundColor(.white)
                    .clipShape(ChatBubbleShape(isFromUser: false))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)

                Spacer() // push to left edge
            } else {
                Spacer() // push to right edge

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundColor(.white)
                    .clipShape(ChatBubbleShape(isFromUser: true))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers
    private var isFromUser: Bool {
        if case .user = message.sender { return true }
        return false
    }
    
    private var messageAlignment: Alignment {
        isFromUser ? .trailing : .leading
    }

    private var bubbleColor: Color {
        switch message.sender {
        case .user:
            return .blue
        case .ai(let model):
            switch model {
            case .grok: return .purple
            case .gemini: return .green
            }
        }
    }

    private func avatarImage(for model: AIModel) -> String {
        switch model {
        case .grok: return "grokAvatar"
        case .gemini: return "geminiAvatar"
        }
    }
}

// MARK: - Chat Bubble Shape
struct ChatBubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 16
        var path = Path()

        if isFromUser {
            // Bubble from right
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            path.move(to: CGPoint(x: rect.maxX - 8, y: rect.maxY - 8))
        } else {
            // Bubble from left
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            path.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY - 8))
        }

        return path
    }
}
