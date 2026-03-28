//
//  APIKeys.swift
//  CourtAi
//
//  Priority:
//    1. User's own keys (Keychain) — always preferred
//    2. Developer trial keys (APIKeys.plist, gitignored) — first 5 uses
//    3. Empty string (triggers error in AIService)
//

import Foundation

enum APIKeys {
    static var gemini: String { resolve(keychainKey: "GeminiAPIKey", plistKey: "GeminiAPIKey") }
    static var groq:   String { resolve(keychainKey: "GroqAPIKey",   plistKey: "GroqAPIKey")   }
    static var claude: String { resolve(keychainKey: "ClaudeAPIKey", plistKey: "ClaudeAPIKey") }

    static func save(gemini: String? = nil, groq: String? = nil, claude: String? = nil) {
        if let v = gemini { KeychainHelper.save(v, for: "GeminiAPIKey") }
        if let v = groq   { KeychainHelper.save(v, for: "GroqAPIKey") }
        if let v = claude { KeychainHelper.save(v, for: "ClaudeAPIKey") }
    }

    /// True only if the user has entered their own keys in Keychain.
    static func allSet() -> Bool {
        let g = KeychainHelper.load("GeminiAPIKey") ?? ""
        let r = KeychainHelper.load("GroqAPIKey")   ?? ""
        let c = KeychainHelper.load("ClaudeAPIKey") ?? ""
        return !g.isEmpty && !r.isEmpty && !c.isEmpty
    }

    // MARK: - Private

    private static let plistDict: NSDictionary? = {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }()

    private static func resolve(keychainKey: String, plistKey: String) -> String {
        // 1. User's own key
        if let v = KeychainHelper.load(keychainKey), !v.isEmpty { return v }
        // 2. Developer trial key from plist
        if TrialManager.isTrialActive,
           let v = plistDict?[plistKey] as? String, !v.isEmpty { return v }
        return ""
    }
}
