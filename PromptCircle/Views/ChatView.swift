//
//  ChatView.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    
    // Sample hot topics
    let hotTopics = [
        "Climate change explained",
           "Boost productivity",
    ]
    
    let columns = [GridItem(.flexible())] // only 1 column
    var body: some View {
        VStack {
            CustomNavbar()
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        
                        if vm.messages.isEmpty {
                            // Empty state view
                            
                            VStack(spacing: 20) {
                                Text("Ask us anything, we are here for you!")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                              
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(hotTopics, id: \.self) { topic in
                                        Button {
                                            vm.userInput = topic
                                            Task {
                                                await vm.sendMessage()
                                            }
                                        } label: {
                                            Text(topic)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(LinearGradient(colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.7)],
                                                                             startPoint: .topLeading,
                                                                             endPoint: .bottomTrailing))
                                                )
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 180)
                        } else {
                            // Messages
                            ForEach(vm.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: vm.messages.count) { _ in
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
