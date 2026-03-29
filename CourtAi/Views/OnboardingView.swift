//
//  OnboardingView.swift
//  CourtAi
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("forModelRaw")            private var forModelRaw     = "grok"
    @AppStorage("againstModelRaw")        private var againstModelRaw = "claude"
    @AppStorage("judgeModelRaw")          private var judgeModelRaw   = "gemini"

    @State private var step       = 0
    @State private var geminiKey  = ""
    @State private var groqKey    = ""
    @State private var claudeKey  = ""

    private var keysValid: Bool {
        !geminiKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        !groqKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        !claudeKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color(red: 0.975, green: 0.965, blue: 0.950).ignoresSafeArea()
            VStack {
                switch step {
                case 0:  welcomeStep.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 1:  keysStep.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                default: rolesStep.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .animation(.spring(duration: 0.4), value: step)
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Image("courtAILogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                VStack(spacing: 10) {
                    Text("CourtAI")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
                    Text("Two sides. One truth.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.54))
                }
                VStack(spacing: 12) {
                    featureRow(icon: "person.3.fill",               text: "3 frontier AIs argue your question")
                    featureRow(icon: "arrow.triangle.2.circlepath", text: "Cross-examine each other in real time")
                    featureRow(icon: "hammer.fill",                 text: "One judge delivers a final ruling")
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            Spacer()
            bottomButton(label: "Get Started") { withAnimation { step = 1 } }
                .padding(.horizontal, 24).padding(.bottom, 52)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.62, green: 0.44, blue: 0.04))
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.30, green: 0.30, blue: 0.34))
            Spacer()
        }
    }

    // MARK: - Step 2: API Keys

    private var keysStep: some View {
        VStack(spacing: 0) {
            stepHeader(title: "Add Your API Keys", subtitle: "CourtAI uses three AI providers.\nAll have free tiers — takes 2 minutes.")
            VStack(spacing: 10) {
                keyField(label: "Gemini",  hint: "AIza…",   link: "aistudio.google.com",    text: $geminiKey)
                keyField(label: "Groq",    hint: "gsk_…",   link: "console.groq.com/keys",  text: $groqKey)
                keyField(label: "Claude",  hint: "sk-ant…", link: "console.anthropic.com",  text: $claudeKey)
            }
            .padding(.horizontal, 24)
            Spacer()
            bottomButton(label: "Continue", disabled: !keysValid) {
                APIKeys.save(
                    gemini: geminiKey.trimmingCharacters(in: .whitespaces),
                    groq:   groqKey.trimmingCharacters(in: .whitespaces),
                    claude: claudeKey.trimmingCharacters(in: .whitespaces)
                )
                withAnimation { step = 2 }
            }
            .padding(.horizontal, 24).padding(.bottom, 52)
        }
    }

    private func keyField(label: String, hint: String, link: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
                Spacer()
                Text(link)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.62, green: 0.44, blue: 0.04))
            }
            SecureField(hint, text: text)
                .font(.system(size: 13, design: .monospaced))
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Step 3: Role Picker

    private var rolesStep: some View {
        let allModels: [AIService.AIModel] = [.grok, .claude, .gemini]
        return VStack(spacing: 0) {
            stepHeader(title: "Set Up the Court", subtitle: "Assign each AI a role.\nYou can change this anytime in Settings.")
            VStack(spacing: 16) {
                rolePicker(role: "FOR",     emoji: "🟢", description: "Argues in favour",
                           selection: $forModelRaw,     locked: [againstModelRaw, judgeModelRaw], models: allModels)
                rolePicker(role: "AGAINST", emoji: "🔴", description: "Argues against",
                           selection: $againstModelRaw, locked: [forModelRaw, judgeModelRaw],     models: allModels)
                rolePicker(role: "JUDGE",   emoji: "⚖️", description: "Delivers the verdict",
                           selection: $judgeModelRaw,   locked: [forModelRaw, againstModelRaw],   models: allModels)
            }
            .padding(.horizontal, 24).padding(.top, 8)
            Spacer()
            bottomButton(label: "Enter the Court") {
                hasCompletedOnboarding = true
            }
            .padding(.horizontal, 24).padding(.bottom, 52)
        }
    }

    private func rolePicker(role: String, emoji: String, description: String,
                            selection: Binding<String>, locked: [String],
                            models: [AIService.AIModel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(emoji).font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text(role)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.54))
                }
            }
            HStack(spacing: 10) {
                ForEach(models, id: \.rawValue) { model in
                    let isSelected = selection.wrappedValue == model.rawValue
                    let isLocked   = locked.contains(model.rawValue)
                    Button {
                        if !isLocked { selection.wrappedValue = model.rawValue }
                    } label: {
                        Text(model.displayName)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isLocked ? Color(red: 0.70, green: 0.70, blue: 0.72) :
                                             isSelected ? .white : Color(red: 0.10, green: 0.10, blue: 0.13))
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected ? AnyView(model.chipColor) :
                                isLocked   ? AnyView(Color(red: 0.94, green: 0.93, blue: 0.91)) :
                                             AnyView(Color.white)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.clear : Color.black.opacity(0.08), lineWidth: 1))
                    }
                    .disabled(isLocked)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Shared UI

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text("CourtAI")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.62, green: 0.44, blue: 0.04))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(red: 1.00, green: 0.97, blue: 0.87))
                .clipShape(Capsule())
                .padding(.top, 56)
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
                .padding(.top, 4)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.54))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 20)
    }

    private func bottomButton(label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(disabled ? Color(red: 0.60, green: 0.60, blue: 0.62) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    disabled
                    ? AnyView(Color(red: 0.88, green: 0.87, blue: 0.85))
                    : AnyView(LinearGradient(
                        colors: [Color(red: 0.72, green: 0.52, blue: 0.06),
                                 Color(red: 0.88, green: 0.70, blue: 0.18)],
                        startPoint: .leading, endPoint: .trailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: disabled ? .clear : Color(red: 0.80, green: 0.62, blue: 0.14).opacity(0.35),
                        radius: 8, y: 3)
        }
        .disabled(disabled)
    }
}
