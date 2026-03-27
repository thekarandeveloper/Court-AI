//
//  APIKeys.swift
//  PromptCircle
//
//  Reads API keys from APIKeys.plist (gitignored).
//  To set up: copy APIKeys.plist.template → APIKeys.plist and fill in your keys.
//

import Foundation

enum APIKeys {
    static var gemini: String { value(for: "GeminiAPIKey") }
    static var groq:   String { value(for: "GroqAPIKey") }
    static var claude: String { value(for: "ClaudeAPIKey") }

    private static func value(for key: String) -> String {
        guard
            let path  = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
            let dict  = NSDictionary(contentsOfFile: path),
            let value = dict[key] as? String,
            !value.isEmpty,
            !value.hasPrefix("YOUR_")
        else {
            assertionFailure("""
            ⚠️  Missing API key: '\(key)'
            Copy  APIKeys.plist.template  →  APIKeys.plist
            and fill in your real keys before running.
            """)
            return ""
        }
        return value
    }
}
