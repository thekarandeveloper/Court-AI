//
//  MessageBubble.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

struct MessageBubble: View {
    @Binding var message: Message

  

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {

            if case .ai(let model) = message.sender {
                Image(avatarImage(for: model))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }

            VStack(alignment: messageAlignment == .leading ? .leading : .trailing) {

                // Single gesture controlling expanded state
                
                Group {
                    if !message.isCollapsed {
                        if let attributed = try? AttributedString(markdown: message.content) {
                            Text(attributed)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                            bubbleGradient
                                                .clipShape(ChatBubbleShape(isFromUser: isFromUser))
                                        )
                                .foregroundColor(isFromUser ? .black : .white)
                                .clipShape(ChatBubbleShape(isFromUser: isFromUser))
                        } else {
                            Text(message.content)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                            bubbleGradient
                                                .clipShape(ChatBubbleShape(isFromUser: isFromUser))
                                        )
                                .foregroundColor(isFromUser ? .black : .white)
                                .clipShape(ChatBubbleShape(isFromUser: isFromUser))
                        }
                           
                    } else {
                        HStack(spacing: 4) {
                            Text("View reply")
                                .foregroundStyle(bubbleGradient)
                            Image(systemName: "eye")
                                .foregroundStyle(bubbleGradient)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(bubbleGradient.opacity(0.5), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: messageAlignment)
                .onTapGesture {
                    withAnimation { message.isCollapsed.toggle() }
                }

            }
            .frame(maxWidth: .infinity, alignment: messageAlignment)

//            if case .user = message.sender {
//                Spacer()
//            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var isFromUser: Bool { if case .user = message.sender { return true } else { return false } }

    private var messageAlignment: Alignment { isFromUser ? .trailing : .leading }

    private var bubbleGradient: LinearGradient {
        switch message.sender {
        case .user:
            // Slightly richer gray with a hint of blue for user bubble
            return LinearGradient(
                colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ai(let model):
            switch model {
            case .grok:
                // Purple gradient with depth
                return LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.purple, Color.purple.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .gemini:
                // Green gradient with soft highlight
                return LinearGradient(
                    colors: [Color.green.opacity(0.7), Color.green.opacity(0.9), Color.green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .claude:
                return LinearGradient(
                    colors: [Color.orange.opacity(0.7), Color.orange.opacity(0.9), Color.red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private func avatarImage(for model: AIModel) -> String {
        switch model {
        case .grok: return "grokAvatar"
        case .gemini: return "geminiAvatar"
        case .claude:
            return "claudeAvatar"
        }
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 16
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}
