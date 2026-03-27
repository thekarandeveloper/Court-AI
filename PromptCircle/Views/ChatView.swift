//
//  ChatView.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

// MARK: - AIModel display helpers (local to this file)

private extension AIModel {
    var color: Color {
        switch self {
        case .grok:   return Color(red: 0.54, green: 0.36, blue: 0.96)
        case .claude: return Color(red: 0.97, green: 0.62, blue: 0.27)
        case .gemini: return Color(red: 0.02, green: 0.72, blue: 0.84)
        }
    }

    var avatarName: String {
        switch self {
        case .grok:   return "grokAvatar"
        case .claude: return "claudeAvatar"
        case .gemini: return "geminiAvatar"
        }
    }
}

// MARK: - Model Picker

private struct ModelPicker: View {
    @Binding var selected: AIModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AIModel.allCases, id: \.self) { model in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = model
                    }
                } label: {
                    HStack(spacing: 6) {
                        // Avatar or initial
                        Group {
                            if UIImage(named: model.avatarName) != nil {
                                Image(model.avatarName)
                                    .resizable().scaledToFill()
                                    .frame(width: 18, height: 18)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(selected == model ? .white.opacity(0.9) : model.color)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Text(model.rawValue)
                            .font(.subheadline)
                            .fontWeight(selected == model ? .semibold : .regular)
                            .foregroundColor(selected == model ? .white : .primary.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selected == model ? model.color : Color.gray.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Chat View

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    @State private var showCouncil = false
    @State private var councilQuestion = ""

    let hotTopics = [
        "Climate change explained",
        "Boost productivity",
    ]

    let columns = [GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            CustomNavbar()

            // Model picker — always visible at top
            ModelPicker(selected: $vm.selectedModel)

            Divider().opacity(0.3)

            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 8) {

                        if vm.messages.isEmpty {
                            VStack(spacing: 20) {
                                Text("Ask us anything, we are here for you!")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue],
                                            startPoint: .leading, endPoint: .trailing
                                        )
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

                                HStack(spacing: 6) {
                                    Image(systemName: "person.3.fill")
                                        .foregroundColor(Color(red: 0.54, green: 0.36, blue: 0.96))
                                    Text("Tap the purple button for a council debate")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.top, 160)
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
                        withAnimation(.easeOut) {
                            scrollProxy.scrollTo(last.id, anchor: .bottom)
                        }
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
