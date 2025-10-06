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
    
    var body: some View {
        HStack {
            TextField("Type your message...", text: $message)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)

            Button(action: sendAction) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.white.shadow(radius: 2))
    }
}
