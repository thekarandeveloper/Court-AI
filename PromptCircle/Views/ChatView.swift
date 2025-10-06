//
//  ChatView.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    
    var body: some View {
        VStack {
            CustomNavbar()
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id) // Each message must have a unique id
                        }
                    }
                }
                .onChange(of: vm.messages.count) { _ in
                    // Scroll to the last message whenever a new one is added
                    if let lastMessage = vm.messages.last {
                        withAnimation(.easeOut) {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            ChatInputBar(message: $vm.userInput) {
                Task {
                    await vm.sendMessage()
                }
            }
            .padding()
        }
    }
}
