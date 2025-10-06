//
//  MessageBubble.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//


import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    @State private var isExpanded: Bool = true // AI bubbles expanded by default
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if case .ai(let model) = message.sender {
                Image(avatarSymbol(for: model))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(avatarColor(for: model))
                    .clipShape(Circle())
                // Collapsible AI Bubble
                VStack(alignment: .leading) {
                    if model == .grok {
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }) {
                            if isExpanded {
                                Text(message.content)
                                    .padding(12)
                                    .background(bubbleGradient)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "eye")
                                    Text("View Grok’s reply")
                                }
                                .padding(12)
                                .background(bubbleGradient)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Normal AI Bubble
                        Text(message.content)
                            .padding(12)
                            .background(bubbleGradient)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                    }
                }
                
                Spacer()
            }
            
            if case .user = message.sender {
                Spacer()
                
                Text(message.content)
                    .padding(12)
                    .background(bubbleGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Helpers
    private func avatarSymbol(for model: AIModel) -> String {
        switch model {
        case .grok: return "grokAvatar"
        case .gemini: return "geminiAvatar"
        }
    }
    
    private func avatarColor(for model: AIModel) -> Color {
        switch model {
        case .grok: return .purple
        case .gemini: return .green
        }
    }
    
    private var bubbleGradient: LinearGradient {
        switch message.sender {
        case .user:
            return LinearGradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.9)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ai(let model):
            switch model {
            case .grok:
                return LinearGradient(colors: [Color.purple.opacity(0.9), Color.indigo.opacity(0.9)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            case .gemini:
                return LinearGradient(colors: [Color.green.opacity(0.9), Color.teal.opacity(0.9)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)
            }
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
