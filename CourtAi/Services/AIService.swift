//
//  AIService.swift
//  CourtAi
//

import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Gemini 2.5 Flash

    private let geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    private struct GeminiResponse: Codable {
        let candidates: [Candidate]?
        let error: GeminiError?
        struct Candidate: Codable {
            let content: Content
            struct Content: Codable {
                let parts: [Part]
                struct Part: Codable {
                    let text: String?
                    let thought: Bool?  // Gemini 2.5 thinking tokens — filtered out
                }
            }
        }
        struct GeminiError: Codable { let message: String? }
    }

    func generateGemini(prompt: String, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "\(geminiURL)?key=\(APIKeys.gemini)") else { throw URLError(.badURL) }
        let payload: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "maxOutputTokens": maxTokens,
                "thinkingConfig": ["thinkingBudget": 0]  // disable thinking — saves tokens + latency
            ]
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Gemini", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Gemini \(http.statusCode): \(body)"])
        }
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let msg = decoded.error?.message {
            throw NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return decoded.candidates?.first?.content.parts
            .first(where: { $0.thought != true })?.text ?? "No response"
    }

    // MARK: - LLaMA 3.3-70B via Groq

    private let grokURL = "https://api.groq.com/openai/v1/chat/completions"

    private struct GrokResponse: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let message: Message
            struct Message: Codable { let content: String }
        }
    }

    func generateGrok(prompt: String, maxTokens: Int) async throws -> String {
        guard let url = URL(string: grokURL) else { throw URLError(.badURL) }
        let payload: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": maxTokens
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(APIKeys.groq)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Groq", code: 0, userInfo: [NSLocalizedDescriptionKey: body])
        }
        let decoded = try JSONDecoder().decode(GrokResponse.self, from: data)
        return decoded.choices.first?.message.content ?? "No response"
    }

    // MARK: - Claude (Anthropic)

    private let claudeURL = "https://api.anthropic.com/v1/messages"

    private struct ClaudeResponse: Codable {
        let content: [Block]
        struct Block: Codable { let type: String; let text: String? }
    }

    func generateClaude(prompt: String, maxTokens: Int) async throws -> String {
        guard let url = URL(string: claudeURL) else { throw URLError(.badURL) }
        let payload: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": maxTokens,
            "messages": [["role": "user", "content": prompt]]
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue(APIKeys.claude, forHTTPHeaderField: "x-api-key")
        req.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Claude", code: 0, userInfo: [NSLocalizedDescriptionKey: body])
        }
        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return decoded.content.first(where: { $0.type == "text" })?.text ?? "No response"
    }

    // MARK: - Unified Interface

    enum AIModel: String, CaseIterable {
        case gemini = "Gemini"
        case grok   = "LLaMA"   // LLaMA-3.3-70B via Groq
        case claude = "Claude"
    }

    /// maxTokens is set per call site to minimise cost and latency.
    func getAIResponse(for model: AIModel, prompt: String, maxTokens: Int = 250) async -> String {
        do {
            switch model {
            case .gemini: return try await generateGemini(prompt: prompt, maxTokens: maxTokens)
            case .grok:   return try await generateGrok(prompt: prompt, maxTokens: maxTokens)
            case .claude: return try await generateClaude(prompt: prompt, maxTokens: maxTokens)
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
