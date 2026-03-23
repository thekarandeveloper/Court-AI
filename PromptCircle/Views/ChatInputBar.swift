//
//  ChatInputBar.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var message: String
    var sendAction: () -> Void
    var councilAction: () -> Void = {}

    var body: some View {
        let hasText = !message.trimmingCharacters(in: .whitespaces).isEmpty

        HStack(spacing: 10) {
            TextField("Type your message...", text: $message)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)

            // Council button — appears only when user has typed something
            if hasText {
                Button(action: councilAction) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.54, green: 0.36, blue: 0.96),
                                         Color(red: 0.35, green: 0.20, blue: 0.80)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(red: 0.54, green: 0.36, blue: 0.96).opacity(0.45), radius: 6, x: 0, y: 3)
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            }

            // Send button
            Button(action: sendAction) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasText)
        .padding(.vertical, 6)
    }
}
