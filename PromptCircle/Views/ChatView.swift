//
//  ChatView.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    @State private var showCouncil = false
    @State private var councilQuestion = ""

    // Sample hot topics
    let hotTopics = [
        "Climate change explained",
        "Boost productivity",
    ]

    let columns = [GridItem(.flexible())]

    var body: some View {
        VStack {
            CustomNavbar()

            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 8) {

                        if vm.messages.isEmpty {
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
                                            Task { await vm.sendMessage() }
                                        } label: {
                                            Text(topic)
                                                .font(.caption).fontWeight(.medium)
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(LinearGradient(
                                                            colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.7)],
                                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                                        ))
                                                )
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                // Council session hint
                                HStack(spacing: 6) {
                                    Image(systemName: "person.3.fill")
                                        .foregroundColor(Color(red: 0.54, green: 0.36, blue: 0.96))
                                    Text("Tap the purple button for a council debate")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.top, 180)
                        } else {
                            ForEach($vm.messages) { $message in
                                MessageBubble(message: $message).id(message.id)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation(.easeOut) { scrollProxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            ChatInputBar(
                message: $vm.userInput,
                sendAction: { Task { await vm.sendMessage() } },
                councilAction: {
                    councilQuestion = vm.userInput.trimmingCharacters(in: .whitespaces)
                    vm.userInput = ""
                    showCouncil = true
                }
            )
            .padding()
        }
        .sheet(isPresented: $showCouncil) {
            AgentSessionView(question: councilQuestion)
        }
    }
}
