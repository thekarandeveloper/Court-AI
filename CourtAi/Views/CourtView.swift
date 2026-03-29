//
//  CourtView.swift
//  CourtAi
//

import SwiftUI

// MARK: - Palette

private enum P {
    static let bg       = Color(red: 0.975, green: 0.965, blue: 0.950)
    static let card     = Color.white
    static let border   = Color.black.opacity(0.07)
    static let ink      = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let muted    = Color(red: 0.50, green: 0.50, blue: 0.54)
    static let faint    = Color(red: 0.88, green: 0.87, blue: 0.85)

    // FOR — green
    static let forBg    = Color(red: 0.93, green: 0.98, blue: 0.94)
    static let forBd    = Color(red: 0.60, green: 0.84, blue: 0.65)
    static let forText  = Color(red: 0.07, green: 0.50, blue: 0.22)

    // AGAINST — rose
    static let agBg     = Color(red: 0.99, green: 0.93, blue: 0.93)
    static let agBd     = Color(red: 0.88, green: 0.58, blue: 0.58)
    static let agText   = Color(red: 0.72, green: 0.10, blue: 0.16)

    // Evidence
    static let evBg     = Color.black.opacity(0.035)

    // Gold — verdict
    static let goldBg   = Color(red: 1.00, green: 0.97, blue: 0.87)
    static let goldBd   = Color(red: 0.80, green: 0.62, blue: 0.14)
    static let goldText = Color(red: 0.62, green: 0.44, blue: 0.04)
}

// MARK: - Root

struct CourtView: View {
    @StateObject private var vm = CourtViewModel()
    @FocusState  private var focused: Bool

    @AppStorage("forModelRaw")     private var forModelRaw     = "gemini"
    @AppStorage("againstModelRaw") private var againstModelRaw = "grok"
    @AppStorage("judgeModelRaw")   private var judgeModelRaw   = "claude"

    @State private var showSettings    = false
    @State private var showTrialExpired = false

    var forModel:     AIService.AIModel { AIService.AIModel(rawValue: forModelRaw)     ?? .gemini }
    var againstModel: AIService.AIModel { AIService.AIModel(rawValue: againstModelRaw) ?? .grok   }
    var judgeModel:   AIService.AIModel { AIService.AIModel(rawValue: judgeModelRaw)   ?? .claude }

    
    var body: some View {
        ZStack {
            P.bg.ignoresSafeArea()
            if vm.phase == .idle {
                inputScreen
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                courtScreen
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(duration: 0.45), value: vm.phase == .idle)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings)    { SettingsView() }
        .sheet(isPresented: $showTrialExpired) { TrialExpiredView() }
    }

    // MARK: - Input Screen

    private var inputScreen: some View {
        VStack(spacing: 0) {
            // Settings gear — top right
            HStack {
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(P.muted)
                        .padding(16)
                }
            }

            Spacer()

            // Logo
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(P.goldBg)
                        .frame(width: 88, height: 88)
                    Circle()
                        .stroke(P.goldBd.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 88, height: 88)
                    Text("⚖").font(.system(size: 42))
                }

                VStack(spacing: 6) {
                    Text("CourtAI")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(P.ink)
                    Text("Two sides. One truth.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(P.muted)
                }
            }

            Spacer().frame(height: 44)

            // Input
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if vm.question.isEmpty {
                        Text("Ask anything — personal, factual, or debatable…")
                            .font(.system(size: 15))
                            .foregroundColor(P.muted.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.question)
                        .font(.system(size: 15))
                        .foregroundColor(P.ink)
                        .tint(P.goldText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 96, maxHeight: 140)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .focused($focused)
                }
                .background(P.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(focused ? 0.08 : 0.04), radius: focused ? 12 : 6, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(focused ? P.goldBd.opacity(0.6) : P.border, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: focused)

                Button {
                    focused = false
                    guard TrialManager.isTrialActive || TrialManager.hasOwnKeys else {
                        showTrialExpired = true
                        return
                    }
                    vm.forModel     = forModel
                    vm.againstModel = againstModel
                    vm.judgeModel   = judgeModel
                    vm.startCourt()
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "scale.3d").font(.system(size: 14, weight: .semibold))
                        Text("Start Court").font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        vm.question.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AnyView(P.faint)
                            : AnyView(LinearGradient(
                                colors: [Color(red: 0.72, green: 0.52, blue: 0.06),
                                         Color(red: 0.88, green: 0.70, blue: 0.18)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
                    .foregroundColor(
                        vm.question.trimmingCharacters(in: .whitespaces).isEmpty
                            ? P.muted : .white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(
                        color: P.goldBd.opacity(vm.question.isEmpty ? 0 : 0.35),
                        radius: 8, y: 3
                    )
                }
                .disabled(vm.question.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: vm.question.isEmpty)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Trial badge
            if !TrialManager.hasOwnKeys {
                let remaining = TrialManager.usesRemaining
                HStack(spacing: 5) {
                    Image(systemName: remaining > 0 ? "gift.fill" : "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(remaining > 0 ? Color(red: 0.62, green: 0.44, blue: 0.04) : P.muted)
                    Text(remaining > 0
                         ? "\(remaining) free session\(remaining == 1 ? "" : "s") left"
                         : "Add your API keys to continue")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(remaining > 0 ? Color(red: 0.62, green: 0.44, blue: 0.04) : P.muted)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(remaining > 0 ? Color(red: 1.00, green: 0.97, blue: 0.87) : P.faint.opacity(0.6))
                .clipShape(Capsule())
                .padding(.bottom, 8)
            }

            // Agent row — dynamic from user's role choices
            HStack(spacing: 6) {
                agentChip(forModel.displayName,     color: forModel.chipColor)
                Text("vs").font(.system(size: 10)).foregroundColor(P.muted.opacity(0.5))
                agentChip(againstModel.displayName, color: againstModel.chipColor)
                Capsule().fill(P.faint).frame(width: 1, height: 14)
                    .padding(.horizontal, 4)
                Image(systemName: "hammer.fill")
                    .font(.system(size: 8)).foregroundColor(judgeModel.chipColor.opacity(0.7))
                agentChip(judgeModel.displayName,   color: judgeModel.chipColor)
                Text("· Judge").font(.system(size: 10)).foregroundColor(P.muted.opacity(0.5))
            }
            .padding(.bottom, 44)
        }
    }

    private func agentChip(_ name: String, color: Color) -> some View {
        Text(name)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Court Screen

    private var courtScreen: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚖  CourtAI")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(P.muted.opacity(0.6))
                                Text(vm.question)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(P.ink)
                                    .lineLimit(3)
                            }
                            Spacer(minLength: 12)
                            if vm.phase != .complete { liveTag }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)

                        Divider()
                            .overlay(P.faint)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)

                    // Hearing 1
                    hearingBlock(
                        number: "1",
                        subtitle: "Opening Arguments",
                        forModel: forModel,   forArg: vm.h1ForArg, forEv: vm.h1ForEvidence,
                        agModel: againstModel, agArg: vm.h1AgArg,  agEv: vm.h1AgEvidence,
                        isActive: vm.phase == .hearing1
                    )

                    // Hearing 2
                    if vm.phase != .hearing1 {
                        hearingBlock(
                            number: "2",
                            subtitle: "Cross-Examination",
                            forModel: forModel,   forArg: vm.h2ForArg, forEv: vm.h2ForEvidence,
                            agModel: againstModel, agArg: vm.h2AgArg,  agEv: vm.h2AgEvidence,
                            isActive: vm.phase == .hearing2
                        )
                        .id("h2")
                        .onAppear { scrollTo(proxy, id: "h2") }
                    }

                    // Verdict
                    if vm.phase == .judging || vm.phase == .complete {
                        verdictBlock
                            .id("verdict")
                            .onAppear { scrollTo(proxy, id: "verdict") }
                    }

                    // Reset
                    if vm.phase == .complete {
                        Button(action: vm.reset) {
                            Text("Ask Another Question")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(P.muted)
                                .padding(.vertical, 11).padding(.horizontal, 24)
                                .background(P.card)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
                        }
                        .padding(.top, 4).padding(.bottom, 52)
                    }
                }
            }
        }
    }

    // MARK: - Hearing Block

    private func hearingBlock(
        number: String,
        subtitle: String,
        forModel: AIService.AIModel, forArg: String?, forEv: String?,
        agModel: AIService.AIModel,  agArg: String?,  agEv: String?,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Label
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(isActive ? P.ink : P.faint).frame(width: 20, height: 20)
                    Text(number)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isActive ? .white : P.muted)
                }
                Text("HEARING \(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? P.ink : P.muted)
                Text("·  \(subtitle)")
                    .font(.system(size: 11))
                    .foregroundColor(P.muted.opacity(0.6))
                Spacer()
                if isActive { liveTag }
            }
            .padding(.horizontal, 20)

            // Cards
            HStack(alignment: .top, spacing: 10) {
                argCard(side: "FOR",     model: forModel, arg: forArg, ev: forEv, loading: isActive)
                argCard(side: "AGAINST", model: agModel,  arg: agArg,  ev: agEv,  loading: isActive)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 28)
    }

    // MARK: - Argument Card

    private func argCard(
        side: String,
        model: AIService.AIModel,
        arg: String?, ev: String?,
        loading: Bool
    ) -> some View {
        let isFOR = side == "FOR"
        let sideBg    = isFOR ? P.forBg  : P.agBg
        let sideBd    = isFOR ? P.forBd  : P.agBd
        let sideColor = isFOR ? P.forText : P.agText
        let noEvidence = ev?.lowercased().hasPrefix("none") == true || ev?.isEmpty == true

        return VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .center) {
                Text(side)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(sideColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(sideColor.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                HStack(spacing: 3) {
                    Circle().fill(model.chipColor).frame(width: 5, height: 5)
                    Text(model.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(model.chipColor)
                }
            }
            .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 10)

            // Argument
            Group {
                if loading && arg == nil {
                    TypingDots(color: sideColor.opacity(0.5))
                } else if let a = arg {
                    Text(a)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundColor(P.ink.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 12)
            .animation(.spring(duration: 0.4), value: arg != nil)

            // Evidence section
            if arg != nil {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Rectangle().fill(sideBd.opacity(0.5)).frame(width: 16, height: 1)
                        Text("EVIDENCE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(sideColor.opacity(0.7))
                    }
                    if loading && ev == nil {
                        TypingDots(color: P.muted.opacity(0.4))
                    } else if let e = ev {
                        Text(e)
                            .font(.system(size: 11, weight: noEvidence ? .medium : .regular))
                            .foregroundColor(noEvidence ? P.muted : P.ink.opacity(0.65))
                            .italic(noEvidence)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(P.evBg)
                .padding(.horizontal, 8).padding(.vertical, 8)
                .animation(.spring(duration: 0.35), value: ev != nil)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(sideBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(sideBd.opacity(0.5), lineWidth: 1))
        .shadow(color: sideBd.opacity(0.12), radius: 6, y: 2)
    }

    // MARK: - Verdict Block

    private var verdictBlock: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(P.goldText)
                    Text("FINAL VERDICT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(P.goldText)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(judgeModel.chipColor).frame(width: 5, height: 5)
                    Text("Hon. \(judgeModel.displayName)  ·  Presiding Judge")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(judgeModel.chipColor.opacity(0.75))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(P.goldBd.opacity(0.1))

            Rectangle().fill(P.goldBd.opacity(0.3)).frame(height: 1)

            // Ruling
            Group {
                if vm.phase == .judging {
                    HStack(spacing: 10) {
                        TypingDots(color: P.goldText.opacity(0.6))
                        Text("The court is in deliberation…")
                            .font(.system(size: 13)).italic()
                            .foregroundColor(P.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                } else if let v = vm.verdict {
                    Text(v)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(P.ink)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.spring(duration: 0.5), value: vm.verdict != nil)
        }
        .background(P.goldBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(P.goldBd.opacity(0.5), lineWidth: 1.5))
        .shadow(color: P.goldBd.opacity(0.2), radius: 10, y: 3)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Helpers

    private var liveTag: some View {
        HStack(spacing: 5) {
            Circle().fill(Color.red).frame(width: 5, height: 5).modifier(Pulse())
            Text("LIVE").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Color.red.opacity(0.08))
        .clipShape(Capsule())
    }

    private func scrollTo(_ proxy: ScrollViewProxy, id: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(duration: 0.4)) { proxy.scrollTo(id, anchor: .top) }
        }
    }
}

// MARK: - Reusable

private struct TypingDots: View {
    var color: Color = P.muted
    @State private var on = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(color)
                    .frame(width: 5, height: 5)
                    .scaleEffect(on ? 1 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                        value: on
                    )
            }
        }
        .onAppear { on = true }
    }
}

private struct Pulse: ViewModifier {
    @State private var p = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(p ? 1.5 : 1).opacity(p ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true), value: p)
            .onAppear { p = true }
    }
}
