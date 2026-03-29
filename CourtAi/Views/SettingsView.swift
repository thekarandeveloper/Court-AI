//
//  SettingsView.swift
//  CourtAi
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("forModelRaw")            private var forModelRaw     = "grok"
    @AppStorage("againstModelRaw")        private var againstModelRaw = "claude"
    @AppStorage("judgeModelRaw")          private var judgeModelRaw   = "gemini"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @Environment(\.dismiss) private var dismiss

    // Load only user's own Keychain keys — not developer trial keys
    @State private var geminiKey = KeychainHelper.load("GeminiAPIKey") ?? ""
    @State private var groqKey   = KeychainHelper.load("GroqAPIKey")   ?? ""
    @State private var claudeKey = KeychainHelper.load("ClaudeAPIKey") ?? ""

    private let allModels: [AIService.AIModel] = [.grok, .claude, .gemini]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.975, green: 0.965, blue: 0.950).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        keysSection
                        rolesSection
                        resetSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(red: 0.62, green: 0.44, blue: 0.04))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.62, green: 0.44, blue: 0.04))
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - API Keys

    private var keysSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your API Keys")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
                Text("Use your own keys for unlimited sessions. Keys stay private on your device.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.54))
            }

            VStack(spacing: 10) {
                keyRow(
                    icon: "g.circle.fill", iconColor: Color(red: 0.09, green: 0.56, blue: 0.90),
                    label: "Gemini", placeholder: "Paste your Gemini key",
                    text: $geminiKey
                )
                keyRow(
                    icon: "l.circle.fill", iconColor: Color(red: 0.52, green: 0.32, blue: 0.88),
                    label: "LLaMA / Groq", placeholder: "Paste your Groq key",
                    text: $groqKey
                )
                keyRow(
                    icon: "c.circle.fill", iconColor: Color(red: 0.84, green: 0.46, blue: 0.10),
                    label: "Claude", placeholder: "Paste your Claude key",
                    text: $claudeKey
                )
            }

            Text("All three are free to get — aistudio.google.com · console.groq.com · console.anthropic.com")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.62))
        }
    }

    private func keyRow(icon: String, iconColor: Color, label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
            }
            SecureField(placeholder, text: text)
                .font(.system(size: 13))
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Court Roles

    private var rolesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Court Setup")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
                Text("Choose which AI argues for, against, and who judges.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.54))
            }

            VStack(spacing: 10) {
                rolePicker(label: "🟢  For",     selection: $forModelRaw,     locked: [againstModelRaw, judgeModelRaw])
                rolePicker(label: "🔴  Against", selection: $againstModelRaw, locked: [forModelRaw, judgeModelRaw])
                rolePicker(label: "⚖️  Judge",   selection: $judgeModelRaw,   locked: [forModelRaw, againstModelRaw])
            }
        }
    }

    private func rolePicker(label: String, selection: Binding<String>, locked: [String]) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.13))
            Spacer()
            HStack(spacing: 6) {
                ForEach(allModels, id: \.rawValue) { model in
                    let isSelected = selection.wrappedValue == model.rawValue
                    let isLocked   = locked.contains(model.rawValue)
                    Button { if !isLocked { selection.wrappedValue = model.rawValue } } label: {
                        Text(model.displayName)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(
                                isLocked   ? Color(red: 0.75, green: 0.75, blue: 0.77) :
                                isSelected ? .white :
                                             Color(red: 0.20, green: 0.20, blue: 0.23)
                            )
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                isSelected ? AnyView(model.chipColor) :
                                isLocked   ? AnyView(Color(red: 0.94, green: 0.93, blue: 0.91)) :
                                             AnyView(Color.white)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.clear : Color.black.opacity(0.07), lineWidth: 1))
                    }
                    .disabled(isLocked)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button {
            KeychainHelper.delete("GeminiAPIKey")
            KeychainHelper.delete("GroqAPIKey")
            KeychainHelper.delete("ClaudeAPIKey")
            hasCompletedOnboarding = false
        } label: {
            Text("Reset App")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.red.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.12), lineWidth: 1))
        }
    }

    // MARK: -

    private func saveAndDismiss() {
        APIKeys.save(
            gemini: geminiKey.trimmingCharacters(in: .whitespaces),
            groq:   groqKey.trimmingCharacters(in: .whitespaces),
            claude: claudeKey.trimmingCharacters(in: .whitespaces)
        )
        dismiss()
    }
}
