//
//  APIKeys.swift
//  CourtAi
//
//  Reads API keys from Keychain only.
//  Keys are set during onboarding and can be updated in Settings.
//

import Foundation

enum APIKeys {
    static var gemini: String { KeychainHelper.load("GeminiAPIKey") ?? "" }
    static var groq:   String { KeychainHelper.load("GroqAPIKey")   ?? "" }
    static var claude: String { KeychainHelper.load("ClaudeAPIKey") ?? "" }

    static func save(gemini: String? = nil, groq: String? = nil, claude: String? = nil) {
        if let v = gemini { KeychainHelper.save(v, for: "GeminiAPIKey") }
        if let v = groq   { KeychainHelper.save(v, for: "GroqAPIKey")   }
        if let v = claude { KeychainHelper.save(v, for: "ClaudeAPIKey") }
    }

    static func allSet() -> Bool {
        !(KeychainHelper.load("GeminiAPIKey") ?? "").isEmpty &&
        !(KeychainHelper.load("GroqAPIKey")   ?? "").isEmpty &&
        !(KeychainHelper.load("ClaudeAPIKey") ?? "").isEmpty
    }
}
