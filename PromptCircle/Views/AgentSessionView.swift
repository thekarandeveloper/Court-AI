//
//  AgentSessionView.swift
//  PromptCircle
//
//  AI Council Session — single clean verdict UI
//

import SwiftUI

// MARK: - AIService.AIModel display helpers

private extension AIService.AIModel {
    var displayName: String {
        switch self {
        case .grok:   return "Grok"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        }
    }
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
    var initial: String { String(displayName.prefix(1)) }
}

private extension SessionPhase {
    var color: Color {
        switch self {
        case .opening:    return .blue
        case .discussion: return Color(red: 0.54, green: 0.36, blue: 0.96)
        case .verdict:    return Color(red: 0.98, green: 0.82, blue: 0.20)
        }
    }
    var label: String {
        switch self {
        case .opening:    return "Opening stances..."
        case .discussion: return "Cross-examining each other..."
        case .verdict:    return "Writing final verdict..."
        }
    }
}

// MARK: - Root View

struct AgentSessionView: View {
    let question: String
    @StateObject private var vm = AgentSessionViewModel()
    @Environment(\.dismiss) private var dismiss

    // Whether to show individual opinions drawer
    @State private var showOpinions = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            questionCard

                            councilRoomCard

                            // Collapsible individual opinions
                            if !vm.openingMessages.filter({ !$0.isThinking }).isEmpty {
                                opinionsToggle
                                if showOpinions {
                                    opinionsSection
                                }
                            }

                            // The main event — final verdict
                            if let text = vm.verdict {
                                verdictCard(text: text)
                                    .id("verdict")
                                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                            }

                            Color.clear.frame(height: 30).id("bottom")
                        }
                        .padding(16)
                        .animation(.spring(response: 0.5), value: vm.isComplete)
                        .animation(.spring(response: 0.4), value: showOpinions)
                        .animation(.spring(response: 0.5), value: vm.verdict != nil)
                    }
                    .onChange(of: vm.scrollTick) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: vm.verdict) { v in
                        if v != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation { proxy.scrollTo("verdict", anchor: .top) }
                            }
                        }
                    }
                }
            }
        }
        .task { await vm.startSession(question: question) }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Council Session")
                    .font(.headline).foregroundColor(.white)
                Text("3 AIs · live deliberation")
                    .font(.caption2).foregroundColor(.white.opacity(0.40))
            }

            Spacer()

            Group {
                if vm.isRunning {
                    LiveBadge()
                } else if vm.isComplete {
                    Text("Done")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(10)
                }
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
    }

    // MARK: Question card

    private var questionCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.bubble.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 2)

            Text(question)
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }

    // MARK: Council Room Card (the main animated section)

    private var councilRoomCard: some View {
        VStack(spacing: 16) {
            // Phase label
            if vm.isRunning {
                HStack(spacing: 6) {
                    PulsingDot(color: vm.currentPhase.color)
                    Text(vm.currentPhase.label)
                        .font(.caption).foregroundColor(vm.currentPhase.color)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: vm.currentPhase)
            } else if vm.isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
                    Text("Deliberation complete").font(.caption).foregroundColor(.green)
                }
            }

            // 3 AI rows
            VStack(spacing: 12) {
                ForEach([AIService.AIModel.grok, .claude, .gemini], id: \.rawValue) { model in
                    AIStatusRow(
                        model: model,
                        openingMsg: vm.openingMessages.first(where: { $0.model == model }),
                        discussionMsg: vm.discussionMessages.first(where: { $0.model == model }),
                        isActive: vm.isRunning
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.09), lineWidth: 1))
        )
    }

    // MARK: Opinions toggle

    private var opinionsToggle: some View {
        Button {
            withAnimation(.spring(response: 0.4)) { showOpinions.toggle() }
        } label: {
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.caption).foregroundColor(.secondary)
                Text("Individual opinions")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Image(systemName: showOpinions ? "chevron.up" : "chevron.down")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: Opinions section

    private var opinionsSection: some View {
        VStack(spacing: 10) {
            // Opening stances
            if !vm.openingMessages.filter({ !$0.isThinking }).isEmpty {
                ForEach(vm.openingMessages.filter({ !$0.isThinking })) { msg in
                    OpinionChip(model: msg.model, content: msg.content, label: "Opening")
                }
            }
            // Discussion
            if !vm.discussionMessages.filter({ !$0.isThinking }).isEmpty {
                Divider().background(Color.white.opacity(0.1))
                ForEach(vm.discussionMessages.filter({ !$0.isThinking })) { msg in
                    OpinionChip(model: msg.model, content: msg.content, label: "Response")
                }
            }
        }
    }

    // MARK: Verdict card

    private func verdictCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(red: 0.98, green: 0.82, blue: 0.20))
                    .font(.subheadline)
                Text("Council Verdict")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(Color(red: 0.98, green: 0.82, blue: 0.20))
                Spacer()
                // Three model dots
                HStack(spacing: 4) {
                    ForEach([AIService.AIModel.grok, .claude, .gemini], id: \.rawValue) { m in
                        Circle().fill(m.color).frame(width: 6, height: 6)
                    }
                }
            }

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(5)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.10, green: 0.09, blue: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.82, blue: 0.20).opacity(0.9),
                                    Color(red: 0.97, green: 0.50, blue: 0.10).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color(red: 0.98, green: 0.82, blue: 0.20).opacity(0.15), radius: 20, x: 0, y: 6)
        )
    }
}

// MARK: - AI Status Row

private struct AIStatusRow: View {
    let model: AIService.AIModel
    let openingMsg: SessionMessage?
    let discussionMsg: SessionMessage?
    let isActive: Bool

    private var statusIcon: some View {
        Group {
            if discussionMsg?.isThinking == false {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else if discussionMsg?.isThinking == true {
                TypingDots(color: model.color)
            } else if openingMsg?.isThinking == false {
                TypingDots(color: model.color)
            } else if openingMsg?.isThinking == true {
                TypingDots(color: model.color)
            } else if isActive {
                Circle().fill(Color.white.opacity(0.15)).frame(width: 22, height: 10)
            } else {
                Image(systemName: "circle").foregroundColor(Color.white.opacity(0.2))
            }
        }
        .font(.system(size: 13))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(model.color.opacity(0.18))
                    .frame(width: 36, height: 36)

                if UIImage(named: model.avatarName) != nil {
                    Image(model.avatarName)
                        .resizable().scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Text(model.initial)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(model.color)
                }
            }

            // Name + status text
            VStack(alignment: .leading, spacing: 2) {
                Text(model.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)

                if discussionMsg?.isThinking == false {
                    Text("Responded · done")
                        .font(.caption2).foregroundColor(.green.opacity(0.8))
                } else if discussionMsg?.isThinking == true {
                    Text("Cross-examining...").font(.caption2).foregroundColor(model.color.opacity(0.8))
                } else if openingMsg?.isThinking == false {
                    Text("Stated position · deliberating").font(.caption2).foregroundColor(model.color.opacity(0.8))
                } else if openingMsg?.isThinking == true {
                    Text("Forming opinion...").font(.caption2).foregroundColor(model.color.opacity(0.8))
                } else {
                    Text("Waiting to speak").font(.caption2).foregroundColor(.white.opacity(0.25))
                }
            }

            Spacer()
            statusIcon
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Opinion Chip (collapsible)

private struct OpinionChip: View {
    let model: AIService.AIModel
    let content: String
    let label: String
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35)) { expanded.toggle() }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                // Small avatar dot
                Circle()
                    .fill(model.color)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.caption).fontWeight(.bold).foregroundColor(model.color)
                        Text("· \(label)")
                            .font(.caption2).foregroundColor(.white.opacity(0.30))
                    }
                    Text(content)
                        .font(.caption).foregroundColor(.white.opacity(0.70))
                        .lineLimit(expanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: expanded)
                }

                Spacer()

                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption2).foregroundColor(.white.opacity(0.30))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(model.color.opacity(0.20), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live Badge

private struct LiveBadge: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.red)
                .frame(width: 7, height: 7)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .opacity(pulsing ? 0.55 : 1.0)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulsing)
                .onAppear { pulsing = true }
            Text("LIVE")
                .font(.system(size: 10, weight: .black)).foregroundColor(.red).tracking(1)
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(Color.red.opacity(0.12))
        .cornerRadius(10)
    }
}

// MARK: - Pulsing Dot (phase indicator)

private struct PulsingDot: View {
    let color: Color
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .scaleEffect(pulsing ? 1.4 : 1.0)
            .opacity(pulsing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}

// MARK: - Typing Dots

private struct TypingDots: View {
    let color: Color
    @State private var phase = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.5 : 1.0)
                    .opacity(phase == i ? 1.0 : 0.30)
                    .animation(.easeInOut(duration: 0.30), value: phase)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}
