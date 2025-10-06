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
        HStack {
            if case .ai = message.sender {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(bubbleColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            
            if case .user = message.sender {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
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
}
